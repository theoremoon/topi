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
import ctnode;

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
    auto ctenv = ct_init();

    Input input = new Input(stdin);

    auto lexer = new Lexer(input);
    auto ctnode = parseToplevel(lexer);

    if (args.length > 1 && args[1] == "-a") {
        writeln(ctnode.to!string);
    }
    else {
        ctnode = ctnode.eval(ctenv);
        writeln(ctnode.to!string);
        auto node = ctnode.toNode;
        writeln(node.to!string);
//        OutBuffer o = new OutBuffer();
//        node.analyze;
//        node = node.eval;
//        node.emit;
//
//        OutBuffer header = new OutBuffer();
//        asm_head(header);
//        Env.cur.state.emit_header(header, "_func");
//        o.write(AsmState.buf.toString);
//        Env.cur.state.emit_footer(o);
//
//        write(header.toString);
//        write(o.toString);
//        writeln();
    }
}
