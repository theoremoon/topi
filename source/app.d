import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import env;
import asmstate;
import type;
import input;
import lex;
import node;
import builtin;
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
    Env.init();
    Input input = new Input(stdin);

    auto lexer = new Lexer(input);
    auto node = parseToplevel(lexer);

    if (args.length > 1 && args[1] == "-a") {
        writeln(node.to!string);
    }
    else {
        OutBuffer o = new OutBuffer();
        node.analyze;
        node = node.eval;
        node.emit;

        OutBuffer header = new OutBuffer();
        asm_head(header);
        Env.cur.state.emit_header(header, "_func");
        o.write(AsmState.buf.toString);
        Env.cur.state.emit_footer(o);

        write(header.toString);
        write(o.toString);
        writeln();
    }
}
