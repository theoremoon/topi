import std.conv;

import node, lex, token;
import exception;

/// parse number literals
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

/// parse +a or -a 
Node parseUnaryPlusMinus(Lexer lexer)
{
	auto op = lexer.get();
	if (op.type == Token.Type.SYM_PLUS || op.type == Token.Type.SYM_HYPHEN) {
		auto expr = lexer.parseNum();  // higher-coupling-level rule
		if (expr is null) {
			throw new TopiException("expression is expected", op.loc);
		}
		return new FuncallNode(op, op.str, [expr]);
	}

	lexer.unget(op);
	return lexer.parseNum();
}

/// parse a*b or a/b
Node parseMulDiv(Lexer lexer)
{
	// get left hand argument
	Node left = lexer.parseUnaryPlusMinus(); // higher-coupling-level rule
	if (left is null) {
		return null;
	}

	// parse left-recursion syntax without infinite-loop
	while (true) {
		auto op = lexer.get();
		if (op.type != Token.Type.SYM_ASTERISK && op.type != Token.Type.SYM_SLASH) {
			lexer.unget(op);
			break;
		}

		auto right = lexer.parseUnaryPlusMinus();  // higher-coupling-level rule
		if (right is null) {
			throw new TopiException("right hand operand is expected", op.loc);
		}
		left = new FuncallNode(op, op.str, [left, right]);
	}
	return left;
}

/// parse a+b or a-b
/// if left is null a+b<- parse here
/// else a (+b) <- parse here. this will parse a+b+c as (+ (+ a b) c))
Node parseAddSub(Lexer lexer)
{
	// get left hand argument
	Node left = lexer.parseMulDiv();  // higher-coupling-level rule
	if (left is null) {
		return null;
	}


	// parse left-recursion syntax without infinite-loop
	while (true) {
		auto op = lexer.get();
		if (op.type != Token.Type.SYM_PLUS && op.type != Token.Type.SYM_HYPHEN) {
			lexer.unget(op);
			break;
		}

		auto right = lexer.parseMulDiv();  // higher-coupling-level rule
		if (right is null) {
			throw new TopiException("right hand operand is expected", op.loc);
		}
		left = new FuncallNode(op, op.str, [left, right]);
	}
	return left;
}
