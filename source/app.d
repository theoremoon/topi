import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input;
import token;
import exception;
import lex;

void asm_head(ref OutBuffer o) {
    o.write("bits 64\n");
    o.write("global _func\n");
    o.write("extern print_int\n");
    o.write("section .text\n");
}

void asm_print_int(ref OutBuffer o, long v) {
    o.write("\tpush rax\n");
    o.writef("\tmov rax,%d\n", v);
    o.write("\tcall print_int\n");
    o.write("\tpop rax\n");
}

long parse_int(Token tok) {
    if (tok.type == Token.Type.DIGIT) {
        long v = tok.str.to!long(10);
        return v;
    }
    if (tok.type == Token.Type.HEX) {
        long v = tok.str.to!long(16);
        return v;
    }
    throw new TopiException("Unimplemented", tok.loc);
}

void main()
{
    Input input = new Input(stdin);
    OutBuffer o = new OutBuffer();

    auto tok = lex_number(input);
    auto v = parse_int(tok);

    asm_head(o);
    o.write("_func:\n");
    o.asm_print_int(v);
    o.write("\tret\n");

    writeln(o.toString);
}
