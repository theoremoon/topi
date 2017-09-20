import std.outbuffer;

import type;

abstract class Node {
    public:
        void emit(OutBuffer o);
        Type type();
}

class IntNode : Node {
    private:
        long v;
    public:
        this(long v) {
            this.v = v;
        }
        override void emit(OutBuffer o) {
            o.writef("\tmov rax,%d\n", v);
            // o.write("\tpush rdi\n");
            // o.writef("\tmov rdi,%d\n", v);
            // o.write("\tcall print_int\n");
            // o.write("\tpop rdi\n");
        }
        override Type type() {
            return Type.Int;
        }
}

class RealNode : Node {
    private:
        double v;
        long double2long(double v) {
            import std.bitmanip;
            import std.system : Endian;

            ubyte[] buf;
            buf.length = 8;
            std.bitmanip.write!(double, Endian.littleEndian)(buf, v, 0);
            return buf.peek!(long, Endian.littleEndian);
        }
    public:
        this(double v) {
            this.v = v;
        }
        override void emit(OutBuffer o) {
            o.writef("\tmov rax,%d\n", double2long(v));
            o.writef("\tmov [rbp-8],rax\n");
            o.write("\tmovupd xmm0,[rbp-8]\n");
            // o.write("\tcall print_real\n");
        }
        override Type type() {
            return Type.Real;
        }
}

class AddNode : Node {
    private:
        Node left, right;
    public:
        this(Node left, Node right) {
            this.left = left;
            this.right = right;
        }
        override void emit(OutBuffer o) {
            left.emit(o);
            o.write("\tpush rax\n");
            right.emit(o);
            o.write("\tmov rcx,rax\n");
            o.write("\tpop rax\n");
            o.write("\tadd rax,rcx\n");
        }
        override Type type() {
            return Type.Int;
        }
}
