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


// parse for a*b or a/b
Node parseMuldiv(Lexer lexer, Node left = null) {
	if (left is null) {
		left = lexer.parseNum();
		if (left is null) {
			return null;
		}
	}
	auto op = lexer.get();
	// binary * /
	if (op.type == Token.Type.OP_MUL || op.type == Token.Type.SYM_SLASH) {
		auto right = lexer.parseMuldiv();
		if (right is null) {
			throw new TopiException("expected right hand expr", op.loc);
		}
		return lexer.parseAddsub(new FuncCallNode(op, op.str, [left, right]));
	}
	// otherwise
	lexer.unget(op);
	return left;
}

Node parseAddsub(Lexer lexer, Node left = null) {
	if (left is null) {
		left = lexer.parseMuldiv();
		if (left is null) {
			return null;
		}
	}

	auto op = lexer.get;
	// binary +-
	if (op.type == Token.Type.SYM_ADD || op.type == Token.Type.SYM_SUB) {
		auto right = lexer.parseMuldiv();
		if (right is null) {
			throw new TopiException("expected right hand expr", op.loc);
		}
		return lexer.parseAddsub(new FuncCallNode(op, op.str, [left, right]));
	}
	// otherwise
	lexer.unget(op);
	return left;
}

// parse variable declaration
VarDeclNode parseDecl(Lexer lexer) {
	auto type = lexer.get();
	// keyword such as Int, Real
	if (type.type != Token.Type.KEYWORD) {
		lexer.unget(type);
		return null;
	}

	// read variable name
	auto name = lexer.get();
	if (name.type != Token.Type.IDENT) {
		throw new TopiException("variable name expected", name.loc);
	}

	return new VarDeclNode(type, type.str, name.str);
}

// variable declaration block likes [Int a\n Int b\n Real c]
VarDeclBlockNode parseDeclBlock(Lexer lexer) {
	// open bracket [
	auto open = lexer.get();
	if (open.type != Token.Type.OPEN_BRACKET) {
		lexer.unget(open);
		return null;
	}

	// variable declarations which separated by \n
	VarDeclNode[] declNodes;
	while (true) {
		auto declNode = lexer.parseDecl();
		if (declNode is null) { break; }
		declNodes ~= declNode;

		if (!lexer.is_next_newline) { break; }
	}

	// close bracket ]
	auto close = lexer.get();
	if (close.type != Token.Type.CLOSE_BRACKET) {
		throw new TopiException("expected ]", close.loc);
	}

	return new VarDeclBlockNode(open, declNodes);
}

// block is { ... } or []{ ... }
BlockNode parseBlock(Lexer lexer) {
	// { or [
	VarDeclBlockNode vardeclblockNode = null;
	auto open = lexer.get();

	// [ ... ]
	if (open.type == Token.Type.OPEN_BRACKET) {
		lexer.unget(open);
		vardeclblockNode = lexer.parseDeclBlock();

		open = lexer.get();
	}

	// not a block or error
	if (open.type != Token.Type.OPEN_MUSTACHE) {
		if (vardeclblockNode is null) { 
			lexer.unget(open);
			return null;
		}
		throw new TopiException("{ is expected after [...]", open.loc);
	}

	// { ... }
	Node[] nodes = [];
	while (true) {
		auto node = lexer.parseTopLevel();
		if (node is null) { break; }
		nodes ~= node;
		if (!lexer.is_next_newline) { break; }
	}

	// }
	auto close = lexer.get();
	if (close.type != Token.Type.CLOSE_MUSTACHE) {
		throw new TopiException("} is expected", close.loc);
	}

	return new BlockNode(open, vardeclblockNode, nodes);
}

Node parseExpr(Lexer lexer) {
	return lexer.parseAddsub();
}

Node parseTopLevel(Lexer lexer) {
	Node node = null;

	node = lexer.parseExpr();
	if (node !is null) { return node; }

	node = lexer.parseBlock();
	if (node !is null) { return node; }

	return node;
}

