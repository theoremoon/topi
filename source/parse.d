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

Node parseFactor(Lexer lexer) {
    auto uop = lexer.get;
    // unary +
    if (uop.type == Token.Type.SYM_ADD) {
        return parseFactor(lexer);
    }
    // unary -
    if (uop.type == Token.Type.SYM_SUB) {
        return new FuncCall("*", [new IntNode(-1), parseFactor(lexer)]);
    }
    // (expr)
    if (uop.type == Token.Type.SYM_OPEN_PAREN) {
        auto expr = lexer.parseExpr;
        if (expr is null) {
            throw new TopiException("expression is required for (expr)", lexer.loc);
        }
        auto close = lexer.get;
        if (close.type != Token.Type.SYM_CLOSE_PAREN) {
            throw new TopiException("close paren is required", lexer.loc);
        }
        return expr;
    }
    lexer.unget(uop);

    return lexer.parseNum;
}

Node parseTerm(Lexer lexer, Node left = null) {
    if (left is null) {
        left = lexer.parseFactor;
        if (left is null) { return null; }
    }

    auto op = lexer.get;
    if (op is null) { return left; }

    // binary *
    if (op.type == Token.Type.OP_MUL) {
        auto right = lexer.parseTerm;
        if (right is null) {
            throw new TopiException("expected right hand expr", lexer.loc);
        }
        return parseTerm(lexer, new FuncCall(op.str, [left, right]));
    }
    // otherwise
    lexer.unget(op);
    return left;
}

Node parseExpr(Lexer lexer, Node left = null) {
    if (left is null) {
        left = lexer.parseTerm;
        if (left is null) {
            return null;
        }
    }

    auto op = lexer.get;
    if (op is null) {
        return left;
    }

    // binary +-
    if (op.type == Token.Type.SYM_ADD || op.type == Token.Type.SYM_SUB) {
        auto right = lexer.parseTerm;
        if (right is null) {
            throw new TopiException("expected right hand expr", lexer.loc);
        }
        return lexer.parseExpr(new FuncCall(op.str, [left, right]));
    }
    // otherwise
    lexer.unget(op);
    return left;
}
