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
    if (open.type != Token.Type.OPEN_PAREN) {
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
        if (comma.type != Token.Type.COMMA) {
            lexer.unget(comma);
            break;
        }
    }
    auto close = lexer.get;
    if (close.type != Token.Type.CLOSE_PAREN) {
        throw new TopiException("CLOSE PARENTHES ) is required", close.loc);
    }
    return new FuncCall(fname.str, exprs);
}

Node parseFactor(Lexer lexer) {
    auto tok = lexer.get;
    // unary +
    if (tok.type == Token.Type.SYM_ADD) {
        return parseFactor(lexer);
    }
    // unary -
    if (tok.type == Token.Type.SYM_SUB) {
        return new FuncCall("-", [lexer.parseFactor]);
        // return new FuncCall("*", [new IntNode(-1), parseFactor(lexer)]);
    }
    // identifier
    if (tok.type == Token.Type.IDENT) {
        auto paren = lexer.get;
        // func call
        if (paren.type == Token.Type.OPEN_PAREN) {
            lexer.unget(paren);
            lexer.unget(tok);

            auto call = parseFuncCall(lexer);
            if (call is null) {
                throw new TopiException("function call syntax is expected", lexer.loc);
            }
            return call;
        }
        lexer.unget(paren);

        // variable
        return new VarNode(tok.str);
    }
    // (expr)
    if (tok.type == Token.Type.OPEN_PAREN) {
        auto expr = lexer.parseExpr;
        if (expr is null) {
            throw new TopiException("expression is required for (expr)", lexer.loc);
        }
        auto close = lexer.get;
        if (close.type != Token.Type.CLOSE_PAREN) {
            throw new TopiException("close paren is required", lexer.loc);
        }
        return expr;
    }
    lexer.unget(tok);
    return lexer.parseNum;
}

Node parseTerm(Lexer lexer, Node left = null) {
    if (left is null) {
        left = lexer.parseFactor;
        if (left is null) { return null; }
    }

    auto op = lexer.get;
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

Node parseAddsub(Lexer lexer, Node left = null) {
    if (left is null) {
        left = lexer.parseTerm;
        if (left is null) {
            return null;
        }
    }

    auto op = lexer.get;
    // binary +-
    if (op.type == Token.Type.SYM_ADD || op.type == Token.Type.SYM_SUB) {
        auto right = lexer.parseTerm;
        if (right is null) {
            throw new TopiException("expected right hand expr", lexer.loc);
        }
        return lexer.parseAddsub(new FuncCall(op.str, [left, right]));
    }
    // otherwise
    lexer.unget(op);
    return left;
}

Node parseAssign(Lexer lexer) {
    auto left = lexer.parseAddsub;
    if (left is null) { return null; }
    if (!left.is_lvalue) { return left; }

    auto op = lexer.get;
    if (op.type != Token.Type.OP_ASSIGN) {
        lexer.unget(op);
        return left;
    }

    auto right = lexer.parseAssign;
    if (right is null) {
        throw new TopiException("expected right hand expr", lexer.loc);
    }
    return new FuncCall(op.str, [left, right]);
}

Node parseExpr(Lexer lexer) {
    auto node = lexer.parseAssign;
    if (node !is null) { return node; }
    node = lexer.parseAddsub;
    if (node !is null) { return node; }
    return null;
}


DeclBlock parseDecl(Lexer lexer) {
    auto type = lexer.get;
    if (type.type != Token.Type.KEYWORD) { 
        lexer.unget(type);
        return null;
    }

    DeclNode[] decls = [];
    while (true) {
        auto name = lexer.get;
        if (name.type != Token.Type.IDENT) {
            throw new TopiException("expected variable name", name.loc);
        }
        decls ~= new DeclNode(type.str, name.str);

        auto comma = lexer.get;
        if (comma.type != Token.Type.COMMA) {
            lexer.unget(comma);
            break;
        }
    }

    return new DeclBlock(decls);
}

DeclBlock parseDeclBlock(Lexer lexer) {
    auto open = lexer.get;
    if (open.type != Token.Type.OPEN_BRACKET) {
        lexer.unget(open);
        return null;
    }

    DeclBlock[] decls;
    while (true) {
        auto decls2 = lexer.parseDecl;
        if (decls2 is null) { break; }
        decls ~= decls2;

        if (!lexer.is_next_newline) { break; }
    }

    auto close = lexer.get;
    if (close.type != Token.Type.CLOSE_BRACKET) {
        throw new TopiException("expected ]", close.loc);
    }
    return new DeclBlock(decls);
}

Node parseBlock(Lexer lexer) {
    DeclBlock declBlock = null;
    auto open = lexer.get;

    if (open.type == Token.Type.OPEN_BRACKET) {
        lexer.unget(open);
        declBlock = lexer.parseDeclBlock;
        if (declBlock is null) {
            throw new TopiException("Variable Declaration is required", open.loc);
        }
        open = lexer.get; // will be {
        if (open.type != Token.Type.OPEN_MUSTACHE) {
            throw new TopiException("Block { is required", open.loc);
        }
    }

    if (open.type != Token.Type.OPEN_MUSTACHE) {
        lexer.unget(open);
        return null;
    }

    Node[] nodes = [];
    while (true) {
        auto node = lexer.parseToplevel;
        if (node is null) { break; }
        nodes ~= node;

        if (!lexer.is_next_newline) { break; }
    }

    auto close = lexer.get;
    if (close.type != Token.Type.CLOSE_MUSTACHE) {
        throw new TopiException("expected }", close.loc);
    }
    return new BlockNode(nodes, declBlock);
}

Node parseToplevel(Lexer lexer) {
    Node node;
    node = lexer.parseBlock;
    if (node !is null) { return node; }

    node = lexer.parseExpr;
    if (node !is null) { return node; }

    return null;
}
