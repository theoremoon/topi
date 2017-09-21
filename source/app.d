import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import type;
import input;
import lex;
import node;
import func;
import parse;

void asm_head(OutBuffer o) {
    o.write("bits 64\n");
    o.write("global _func\n");
    o.write("extern print_int\n");
    o.write("extern print_real\n");
    o.write("section .text\n");
}



void main(string[] args)
{
    register_builtin();

    Input input = new Input(stdin);
    OutBuffer o = new OutBuffer();

    auto lexer = new Lexer(input);
    auto node = parseExpr(lexer);

    if (args.length > 1 && args[1] == "-a") {
        writeln(node.to!string);
    }
    else {
        asm_head(o);
        o.write("_func:\n");
        o.write("\tpush rbp\n");
        o.write("\tmov rbp,rsp\n");
        o.write("\tsub rsp,0x10\n");

        node.emit(o);

        if (node.type is Type.Int) {
            o.write("\tmov rdi,rax\n");
            o.write("\tcall print_int\n");
        }
        else if (node.type is Type.Real) {
            o.write("\tcall print_real\n");
        }

        o.write("\tleave\n");
        o.write("\tret\n");

        writeln(o.toString);
    }
}
