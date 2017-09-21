import std.algorithm;
import std.outbuffer;
import std.array;
import std.conv;

import type;
import func;
import asmstate;

class Node {
    public:
        bool is_constexpr() { return false; }
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
            auto state = AsmState.cur;
            auto idx = state.assign(8);

            o.writef("\tmov rax,%d\n", double2long(v));
            o.writef("\tmov [rbp-%d],rax\n", idx);
            o.writef("\tmovupd xmm0,[rbp-%d]\n", idx);
            // o.write("\tcall print_real\n");
        }
        override Type type() { return Type.Real; }
        override bool is_constexpr() { return true; }
        override string toString() { return v.to!string; }
}

class FuncCall : Node {
    public:
        dstring fname;
        Node[] args;
        Func func;

        this(dstring fname, Node[] args) {
            this.fname = fname;
            this.args = args;
            this.func = Func.get(fname, args);
            if (func is null)  {
                throw new Exception("Unimplemented function: " ~ Func.signature(fname, args).to!string); 
            }
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
            if (!is_constexpr) { throw new Exception("Internal error"); }
            return func.eval(args);
        }
}

