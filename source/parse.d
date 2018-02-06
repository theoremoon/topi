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

/// parse a*b or a/b
/// if left is null a*b<- parse here
/// else a (*b) <- parse here. this will parse a*b*c as (* (* a b) c))
Node parseMuldiv(Lexer lexer, Node left=null)
{
	// get left hand argument
	if (left is null) {
		left = lexer.parseNum(); // higher-coupling-level rule
		if (left is null) {
			return null;
		}
	}


	// parse left-recursion syntax without infinite-loop
	while (true) {
		auto op = lexer.get();
		if (op.type != Token.Type.SYM_ASTERISK && op.type != Token.Type.SYM_SLASH) {
			lexer.unget(op);
			break;
		}

		auto right = lexer.parseNum();  // higher-coupling-level rule
		if (right is null) {
			throw new TopiException("right hand operand is expected", op.loc);
		}
		left = new BinopNode(op, op.str, [left, right]);
	}
	return left;
}

/// parse a+b or a-b
/// if left is null a+b<- parse here
/// else a (+b) <- parse here. this will parse a+b+c as (+ (+ a b) c))
Node parseAddsub(Lexer lexer, Node left=null)
{
	// get left hand argument
	if (left is null) {
		left = lexer.parseMuldiv();  // higher-coupling-level rule
		if (left is null) {
			return null;
		}
	}


	// parse left-recursion syntax without infinite-loop
	while (true) {
		auto op = lexer.get();
		if (op.type != Token.Type.SYM_PLUS && op.type != Token.Type.SYM_HYPHEN) {
			lexer.unget(op);
			break;
		}

		auto right = lexer.parseMuldiv();  // higher-coupling-level rule
		if (right is null) {
			throw new TopiException("right hand operand is expected", op.loc);
		}
		left = new BinopNode(op, op.str, [left, right]);
	}
	return left;
}
