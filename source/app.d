import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input;
import token;
import exception;
import lex;
import node;

void asm_head(OutBuffer o) {
    o.write("bits 64\n");
    o.write("global _func\n");
    o.write("extern print_int\n");
    o.write("extern print_real\n");
    o.write("section .text\n");
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
