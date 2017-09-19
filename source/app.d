import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input;
import token;
import exception;
import lex;

void asm_head(OutBuffer o) {
    o.write("bits 64\n");
    o.write("global _func\n");
    o.write("extern print_int\n");
    o.write("extern print_real\n");
    o.write("section .text\n");
}


abstract class Node {
    public:
        void emit(OutBuffer o);
}

class IntNode : Node {
    private:
        long v;
    public:
        this(long v) {
            this.v = v;
        }
        override void emit(OutBuffer o) {
            o.write("\tpush rdi\n");
            o.writef("\tmov rdi,%d\n", v);
            o.write("\tcall print_int\n");
            o.write("\tpop rdi\n");
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
            o.write("\tcall print_real\n");
        }
}

Node parseOne(Token tok) {
    if (tok.type == Token.Type.REAL) {
        return new RealNode(tok.str.to!double);
    }
    if (tok.type == Token.Type.DIGIT) {
        return new IntNode(tok.str.to!long(10));
    }
    if (tok.type == Token.Type.HEX) {
        return new IntNode(tok.str.to!long(16));
    }
    throw new TopiException("Unimplemented", tok.loc);
}


void main()
{
    Input input = new Input(stdin);
    OutBuffer o = new OutBuffer();

    auto tok = lex_number(input);
    auto node = parseOne(tok);

    asm_head(o);
    o.write("_func:\n");
    o.write("\tpush rbp\n");
    o.write("\tmov rbp,rsp\n");
    o.write("\tsub rsp,0x10\n");

    node.emit(o);

    o.write("\tleave\n");
    o.write("\tret\n");

    writeln(o.toString);
}
