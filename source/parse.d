import std.conv;


import token;
import lex;
import node;
import func;
import exception;

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

Node parseExpr(Lexer lexer, Node left = null) {
    if (left is null) {
        left = lexer.parseNum;
        if (left is null) {
            return null;
        }
    }

    auto op = lexer.get;
    if (op is null) {
        return left;
    }

    // binary +
    if (op.type == Token.Type.SYM_ADD || op.type == Token.Type.SYM_SUB) {
        auto right = lexer.parseNum;
        if (right is null) {
            throw new TopiException("right hand expression is expected", op.loc);
        }
        return parseExpr(lexer, new FuncCall(op.str, [left, right]));
    }
    // otherwise
    lexer.unget(op);
    throw new TopiException("expression is required", lexer.loc);
}
