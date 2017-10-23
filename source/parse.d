import std.conv;

import node, lex, token;
import exception;

Node parseNum(Lexer lexer) {
    auto num = lexer.get();
    if (num.type == Token.Type.DIGIT) {
	return new IntNode(num, num.str.to!long);
    }
    if (num.type == Token.Type.HEX) {
	return new IntNode(num, num.str.to!long(16));
    }
    if (num.type == Token.Type.REAL) {
	return new RealNode(num, num.str.to!double);
    }
    lexer.unget(num);
    return null;
}

Node parseAddsub(Lexer lexer, Node left = null) {
    if (left is null) {
        left = lexer.parseNum();
        if (left is null) {
            return null;
        }
    }

    auto op = lexer.get;
    // binary +-
    if (op.type == Token.Type.SYM_ADD || op.type == Token.Type.SYM_SUB) {
        auto right = parseAddsub(lexer);
        if (right is null) {
            throw new TopiException("expected right hand expr", op.loc);
        }
        return lexer.parseAddsub(new FuncCallNode(op, op.str, [left, right]));
    }
    // otherwise
    lexer.unget(op);
    return left;
}

Node parseTopLevel(Lexer lexer) {
    return lexer.parseAddsub();
}

