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
        abstract Type type();
        abstract void emit();
}


class IntNode : Node {
    public:
        long v;
        this(long v) {
            this.v = v;
        }
        override Type type() { return Type.Int; }
        override void emit() {
            Env.cur.state.write("mov rax,%d".format(v));
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
        override Type type() { return Type.Real; }
        override void emit() {
            Env env = Env.cur;
            auto idx = env.state.assign(8);

            env.state.write("mov rax,%d".format(double2long(v)));
            env.state.write("mov [rbp-%d],rax".format(idx));
            env.state.write("movupd xmm0,[rbp-%d]".format(idx));
        }
        override string toString() { return v.to!string; }
}

