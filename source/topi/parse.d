module topi.parse;

import topi;
import std.conv;
import std.format;

IntegerAst read_factor(Source src) {
	auto tok = src.get;
	if (!tok) {
		return null;
	}
	switch (tok.type) {
		case TokenType.INT:
			return new IntegerAst(tok.str.to!int);
		default:
			break;
	}
	src.unget(tok);
	return null;
}

int get_priority(Token op) {
	switch (op.str) {
		case "=":
			return 1;
		case "==":
			return 2;
		case "+": case "-":
			return 3;
		case "*":
			return 4;
		default:
			break;
	}
	return 0;
}
ValueAst read_expr(Source src, int p = -1) {
	// open paren
	if (src.is_next("{")) {
		return src.read_block;
	}


	// left hand
	ValueAst left = src.read_factor;
	if (! left) {
		return null;
	}

	while (true) {
		// operator (or return left)
		auto op = src.get;
		if (! op) {
			break;
		}
		if (op.type != TokenType.SYMBOL) {
			src.unget(op);
			break;
		}
		int priority = op.get_priority;
		if (priority == 0 || priority <= p) {
			src.unget(op);
			break;
		}
		auto right = src.read_expr(priority);
		if (! right) {
			throw new Exception("Right hand expression is required. line %d".format(src.get.pos.line));
		}
		left = new FuncCallAst(op.str.to!string, [left, right]);
	}
	return left;
}
BlockAst read_block(Source src) {
	ValueAst[] exprs;
	while (true) {
		auto expr = src.read_expr;
		if (!expr) { 
			break;
		}
		exprs ~= expr;
		if (! src.is_next(";")) {
			break;
		}
	}
	if (! src.is_next("}")) {
		throw new Exception("} is expected at %d".format(src.get.pos.line));
	}
	return new BlockAst(exprs);
}
