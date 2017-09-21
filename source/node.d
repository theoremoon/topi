import std.outbuffer;
import std.conv;

import type;
import func;

class Node {
    public:
        abstract void emit(OutBuffer o);
        abstract Type type();
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

        override void emit(OutBuffer o) {
            func.call(args, o);
        }
        override Type type() {
            return func.rettype;
        }
}

// class AddNode : Node {
//     private:
//         Node left, right;
//     public:
//         this(Node left, Node right) {
//             this.left = left;
//             this.right = right;
//         }
//         override void emit(OutBuffer o) {
//             if (left.type is Type.Int) {
//                 left.emit(o);
//                 o.write("\tpush rax\n");
//                 right.emit_int(o);
//                 o.write("\tmov rcx,rax\n");
//                 o.write("\tpop rax\n");
//                 o.write("\tadd rax,rcx\n");
//             }
//             else if (left.type is Type.Real) {
//                 left.emit(o);
//                 o.write("\tsub rsp,0x8\n");
//                 o.write("\tmovsd [rsp],xmm0\n");
//                 right.emit_real(o);
//                 o.write("\tmovsd xmm1,xmm0\n");
//                 o.write("\tmovsd xmm0,[rsp]\n");
//                 o.write("\tadd rsp,0x8\n");
//                 o.write("\taddsd xmm0,xmm1\n");
//             }
//             else {
//                 throw new Exception("unimplemented");
//             }
//         }
//         override Type type() {
//             return left.type;
//         }
// }
