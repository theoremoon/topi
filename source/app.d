import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input;
import token;
import exception;
import lex;
import node;
import type;

void asm_head(OutBuffer o) {
    o.write("bits 64\n");
    o.write("global _func\n");
    o.write("extern print_int\n");
    o.write("extern print_real\n");
    o.write("section .text\n");
}

Node parseNum(Lexer lexer) {
    auto tok = lexer.get;

    if (tok.type == Token.Type.REAL) {
        return new RealNode(tok.str.to!double);
    }
    if (tok.type == Token.Type.DIGIT) {
        return new IntNode(tok.str.to!long(10));
    }
    if (tok.type == Token.Type.HEX) {
        return new IntNode(tok.str.to!long(16));
    }
    lexer.unget(tok);
    return null;
}

Node parseExpr(Lexer lexer) {
    auto num = lexer.parseNum;
    auto op = lexer.get;

    if (op is null) {
        if (num is null) {
            throw new TopiException("expression is required", lexer.loc);
        }
        return num;
    }

    // binary or unary add
    if (op.type == Token.Type.SYM_ADD) {
        // binary
        if (num !is null) {
            auto right = lexer.parseNum;
            if (right is null) {
                throw new TopiException("right hand expression is expected", op.loc);
            }
            return new AddNode(num, right);
        }
        // unary
        throw new TopiException("unary operator + is not implemented yet", op.loc);
    }
    lexer.unget(op);
    if (num !is null) {
        return num;
    }
    throw new TopiException("expression is required", lexer.loc);
}


void main()
{
    Input input = new Input(stdin);
    OutBuffer o = new OutBuffer();

    auto lexer = new Lexer(input);
    auto node = parseExpr(lexer);

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
