module topi.parse;

import topi;
import std.conv;
import std.format;
debug import std.stdio;

ValueAst read_factor(Source src) {
	auto tok = src.get;
	if (!tok) {
		return null;
	}
	switch (tok.type) {
		case Token.Type.INT:
			return new IntegerAst(tok.str.to!int);
		case Token.Type.SYMBOL:
			if (tok.str != "(") {
				src.unget(tok);
				return null;
			}
			auto expr = src.read_expr;
			if (! expr ) {
				throw new Exception("expression is required");
			}
			auto close = src.get;
			if (!close) {
				throw new Exception("Close parenthesis is required");
			}
			if (close.str != ")") {
				throw new Exception("Close parenthesis is required");
			}
			return expr;
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
		if (op.type != Token.Type.SYMBOL) {
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
			throw new Exception("Right hand expression is required. line %d".format(src.line));
		}
		left = new OperatorAst(op.str, [left, right]);
	}
	return left;
}

Ast read_stmt(Source src) {
	auto k_int = src.get;
	if (!k_int) {
		return null;
	}
	if (k_int.type == Token.Type.K_INT) {
		auto name = src.get;
		if (!name || name.type != Token.Type.IDENT) {
			throw new Exception("Identifier is required. line %d".format(src.line));
		}
		src.next(";");
		return new DeclAst(Type.INT, name.str);
	}
	src.unget(k_int);

	auto expr = src.read_expr;
	if (!expr) {
		return null;
	}
	src.next(";");
	return expr;
}
