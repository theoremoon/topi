import std.algorithm;
import std.outbuffer;
import std.format;
import std.array;
import std.conv;

import var;
import env;
import type;
import func;
import asmstate;

class Node {
    public:
        Env env = null;
        abstract bool is_lvalue();
        abstract bool is_constexpr();
        abstract Type type();
        abstract void analyze();
        abstract Node eval();
        abstract void emit();
}


class IntNode : Node {
    public:
        long v;
        this(long v) {
            this.v = v;
        }
        override bool is_lvalue() { return false; }
        override bool is_constexpr() { return true; }
        override Type type() { return Type.Int; }
        override void analyze() { env = Env.cur; }
        override Node eval() { return this; }
        override void emit() {
            env.state.write("mov rax,%d".format(v));
        }
        override string toString() { return v.to!string; }
}

class RealNode : Node {
    private:
        long double2long(double v) {
            import std.bitmanip;
            import std.system : Endian;

            ubyte[] buf;
            buf.length = 8;
            std.bitmanip.write!(double, Endian.littleEndian)(buf, v, 0);
            return buf.peek!(long, Endian.littleEndian);
        }
    public:
        double v;
        this(double v) {
            this.v = v;
        }
        override bool is_lvalue() { return false; }
        override bool is_constexpr() { return true; }
        override Type type() { return Type.Real; }
        override void analyze(){ env = Env.cur; }
        override Node eval() { return this; }
        override void emit() {
            auto idx = env.state.assign(8);

            env.state.write("mov rax,%d".format(double2long(v)));
            env.state.write("mov [rbp-%d],rax".format(idx));
            env.state.write("movupd xmm0,[rbp-%d]".format(idx));
        }
        override string toString() { return v.to!string; }
}

class FuncCall : Node {
    public:
        string fname;
        Node[] args;
        Func func;

        this(string fname, Node[] args) {
            this.fname = fname;
            this.args = args;
        }

        void load() {
            if (func !is null) { return; }
            func = env.getFunc(fname, args);
            if (func is null)  {
                throw new Exception("Unimplemented function: " ~ Func.signature(fname, args).to!string); 
            }
        }

        override bool is_lvalue() { return false; }
        override bool is_constexpr() {
            load();
            return func.is_constexpr;
        }
        override Type type() { 
            load();
            return func.rettype;
        }
        override void analyze() {
            env = Env.cur;
            foreach (arg; args) { arg.analyze; }
        }
        override Node eval() {
            load();
            foreach (i; 0..args.length) { args[i] = args[i].eval; }
            if (is_constexpr) { return func.eval(args, env); }
            return this;
        }
        override void emit() { 
            func.call(args, env.state);
        }
        override string toString() {
            return "("~fname.to!string~" "~args.map!(a => a.to!string).join(" ")~")";
        }
}


class BlockNode : Node {
    public:
        Node declBlock;
        Node[] nodes;

        this(Node[] nodes, DeclBlock declBlock) {
            this.declBlock = declBlock;
            this.nodes = nodes;
        }

        override bool is_lvalue() { return false; }
        override bool is_constexpr() {
            return all(nodes.map!(a => a.is_constexpr));
        }
        override Type type() { return Type.Void; } 
        override void analyze() {
            env = Env.cur;
            Env.newScope();

            declBlock.analyze();
            foreach (node; nodes) { node.analyze(); }

            Env.exitScope();
        }
        override Node eval() {
            if (declBlock !is null) { declBlock = declBlock.eval; }
            foreach (i; 0..nodes.length) { nodes[i] = nodes[i].eval(); }
            return this;
        }
        override void emit() {
            if (declBlock !is null) { declBlock.emit; }
            foreach (node; nodes) { node.emit; }
        }
        override string toString() {
            return "{"~nodes.map!(a => a.to!string).join(" ")~"}";
        }
}

class DeclNode : Node {
    public:
        string typename;
        string varname;

        this(string typename, string varname) {
            this.typename = typename;
            this.varname = varname;
        }

        override bool is_lvalue() { return false; }
        override bool is_constexpr() { return true; }
        override Type type() { return Type.Void; }
        override void analyze() { env = Env.cur; }
        override Node eval() {
            Type t = env.getType(typename);
            if (t is null) {
                throw new Exception("type %s is not defiend".format(typename)); 
            }
            bool success = env.registerVar(new Var(t, varname));
            if (!success) {
                throw new Exception("variable %s id already defined".format(varname));
            }
            return this;
        }
        override void emit() {}
        override string toString() {
            return "(Decl %s %s)".format(typename, varname);
        }
}

class DeclBlock : Node {
    public:
        Node[] decls;

        this(DeclNode[] decls) {
            foreach (decl; decls) { this.decls ~= decl; }
        }
        this(DeclBlock[] decls) {
            this.decls = [];
            foreach (decl; decls) {
                this.decls ~= decl.decls;
            }
        }
        override bool is_lvalue() { return false; }
        override bool is_constexpr() { return true; }
        override Type type() { return Type.Void; }
        override void analyze() {
            env = Env.cur;
            foreach (decl; decls) { decl.analyze(); }
        }
        override Node eval() {
            foreach (i; 0..decls.length) { decls[i] = decls[i].eval(); }
            return this;
        }
        override void emit() {
            foreach (decl; decls) { decl.emit; }
        }
        override string toString() { return "("~decls.map!(a=>a.to!string).join(" ")~")"; }
}

class VarNode : Node {
    public:
        string varname;
        bool still_constexpr = true;
        Var var = null;
        this(string varname) {
            this.varname = varname;
        }

        void load() {
            if (var !is null) { return; }
            var = env.getVar(varname);
            if (var is null) {
                throw new Exception("undefined name %s".format(varname));
            }
        }
        
        override bool is_lvalue() { return true; }
        override bool is_constexpr() { return still_constexpr; }
        override Type type() {
            load();
            return var.type;
        }
        override void analyze() { env = Env.cur; }
        override Node eval() {
            load();
            if (var.constexprNode !is null) { return var.constexprNode; }
            return this;
        }
        override void emit() { 
            throw new Exception("unimplemented");
        }
        override string toString() {
            return "("~varname~")";
        }
}
