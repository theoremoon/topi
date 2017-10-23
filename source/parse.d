import std.conv;

import node, lex, token;

Node parseNum(Lexer lexer) {
    auto num = lexer.get();
    if (num.type == Token.Type.DIGIT) {
	return new IntNode(num, num.str.to!long);
    }
    if (num.type == Token.Type.HEX) {
	return new IntNode(num, num.str.to!long(16));
    }
    lexer.unget(num);
    return null;
}

Node parseTopLevel(Lexer lexer) {
    return lexer.parseNum();
}

