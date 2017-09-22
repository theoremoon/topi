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

Node parseFuncCall(Lexer lexer) {
    auto fname = lexer.get;
    if (fname.type != Token.Type.IDENT) {
        lexer.unget(fname);
        return null;
    }

    auto open = lexer.get;
    if (open.type != Token.Type.SYM_OPEN_PAREN) {
        lexer.unget(fname);
        lexer.unget(open);
        return null;
    }
    
    Node[] exprs = [];
    while (true) {
        auto expr = lexer.parseExpr;
        if (expr is null) { break; }
        exprs ~= expr;
        auto comma = lexer.get;
        if (comma.type != Token.Type.SYM_COMMA) {
            lexer.unget(comma);
            break;
        }
    }
    auto close = lexer.get;
    if (close.type != Token.Type.SYM_CLOSE_PAREN) {
        throw new TopiException("CLOSE PARENTHES ) is required", close.loc);
    }
    return new FuncCall(fname.str, exprs);
}

Node parseFactor(Lexer lexer) {
    auto uop = lexer.get;
    // unary +
    if (uop.type == Token.Type.SYM_ADD) {
        return parseFactor(lexer);
    }
    // unary -
    if (uop.type == Token.Type.SYM_SUB) {
        return new FuncCall("-", [lexer.parseFactor]);
        // return new FuncCall("*", [new IntNode(-1), parseFactor(lexer)]);
    }
    // identifier
    if (uop.type == Token.Type.IDENT) {
        auto paren = lexer.get;
        // func call
        if (paren.type == Token.Type.SYM_OPEN_PAREN) {
            lexer.unget(paren);
            lexer.unget(uop);

            auto call = parseFuncCall(lexer);
            if (call is null) {
                throw new TopiException("function call syntax is expected", lexer.loc);
            }
            return call;
        }
        throw new TopiException("variable like is unimplemented", lexer.loc);
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
        auto right = lexer.parseFactor;
        if (right is null) {
            throw new TopiException("expected right hand expr", lexer.loc);
        }
        return parseTerm(lexer, new FuncCall(op.str, [left, right]));
    }
    // binary /
    if (op.type == Token.Type.SYM_SLASH) {
        auto right = lexer.parseFactor;
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

Node parseBlock(Lexer lexer) {
    auto open = lexer.get;
    if (open.type != Token.Type.SYM_OPEN_MUSTACHE) {
        lexer.unget(open);
        return null;
    }

    Node[] nodes = [];
    while (true) {
        auto node = lexer.parseToplevel;
        if (node is null) { break; }
        nodes ~= node;
        auto nl = lexer.get;
        if (nl.type != Token.Type.NEWLINE) {
            lexer.unget(nl);
            break;
        }
    }

    auto close = lexer.get;
    if (close.type != Token.Type.SYM_CLOSE_MUSTACHE) {
        throw new TopiException("expected }", close.loc);
    }
    return new BlockNode(nodes);
}

Node parseToplevel(Lexer lexer) {
    Node node;
    node = lexer.parseBlock;
    if (node !is null) { return node; }

    node = lexer.parseExpr;
    if (node !is null) { return node; }

    return null;
}
