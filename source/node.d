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
        bool is_constexpr() { return false; }
        void analyze() { env = Env.cur; }
        abstract void emit(OutBuffer o);
        abstract Type type();
        Node eval() { return this; }
}

void emit_int(Node node, OutBuffer o) {
    if (node.type is Type.Int) {
        node.emit(o);
    }
    else if (node.type is Type.Real) {
        node.emit(o);
        o.write("\tcvtsd2si rax, xmm0\n");
    }
    else {
        throw new Exception("unimplemented");
    }
}
void emit_real(Node node, OutBuffer o) {
    if (node.type is Type.Real) {
        node.emit(o);
    }
    else if (auto intNode = cast(IntNode)node) {
        auto realNode = new RealNode(cast(double)intNode.v);
        realNode.emit(o);
    }
    else if (node.type is Type.Int) {
        node.emit(o);
        o.write("\tcvtsi2sd xmm0, rax\n");
    }
    else {
        throw new Exception("unimplemented");
    }
}

class IntNode : Node {
    public:
        long v;
        this(long v) {
            this.v = v;
        }
        override void emit(OutBuffer o) { o.writef("\tmov rax,%d\n", v); }
        override Type type() { return Type.Int; }
        override bool is_constexpr() { return true; }
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
        override void emit(OutBuffer o) {
            auto state = env.state;
            auto idx = state.assign(8);

            o.writef("\tmov rax,%d\n", double2long(v));
            o.writef("\tmov [rbp-%d],rax\n", idx);
            o.writef("\tmovupd xmm0,[rbp-%d]\n", idx);
        }
        override Type type() { return Type.Real; }
        override bool is_constexpr() { return true; }
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

        override bool is_constexpr() { return func.is_constexpr; }
        override void emit(OutBuffer o) { 
            func.call(args, o);
        }
        override Type type() { return func.rettype; }
        override string toString() {
            return "("~fname.to!string~" "~args.map!(a => a.to!string).join(" ")~")";
        }
        override Node eval() {
            this.func = env.getFunc(fname, args);
            if (func is null)  {
                throw new Exception("Unimplemented function: " ~ Func.signature(fname, args).to!string); 
            }
            if (is_constexpr) { return func.eval(args); }
            return this;
        }
}


class BlockNode : Node {
    public:
        DeclBlock declBlock;
        Node[] nodes;

        this(Node[] nodes, DeclBlock declBlock) {
            this.declBlock = declBlock;
            this.nodes = nodes;
        }

        override void analyze() {
            env = Env.cur;
            Env.newScope();

            declBlock.analyze();
            foreach (node; nodes) { node.analyze(); }

            Env.exitScope();
        }
        override bool is_constexpr() {
            return all(nodes.map!(a => a.is_constexpr));
        }
        override void emit(OutBuffer o) {
            if (declBlock !is null) { declBlock.emit(o); }
            foreach (node; nodes) { node.emit(o); }
        }
        override Type type() { return Type.Void; } 
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
        override void emit(OutBuffer o) {}
        override Type type() { return Type.Void; }
        override string toString() {
            return "(Decl %s %s)".format(typename, varname);
        }
}

class DeclBlock : Node {
    public:
        DeclNode[] decls;

        this(DeclNode[] decls) {
            this.decls = decls;
        }
        this(DeclBlock[] decls) {
            this.decls = [];
            foreach (decl; decls) {
                this.decls ~= decl.decls;
            }
        }
        override Node eval() {
            foreach (decl; decls) { decl.eval(); }
            return this;
        }
        override void emit(OutBuffer o) {
            foreach (decl; decls) { decl.emit(o); }
        }
        override Type type() { return Type.Void; }
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
        
        override bool is_constexpr() { /*return still_constexpr;*/ return false; }
        override Node eval() {
            var = env.getVar(varname);
            if (var is null) {
                throw new Exception("undefined name %s".format(varname));
            }
            return this;
        }
        override void emit(OutBuffer o) { 
            throw new Exception("unimplemented");
        }
        override Type type() {
            return var.type;
        }
        override string toString() {
            return "("~varname~")";
        }
}
