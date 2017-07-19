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
		case Token.Type.INT:
			return new IntegerAst(tok.str.to!int);
		default:
			break;
	}
	src.unget(tok);
	return null;
}

ValueAst read_expr(Source src) {
	auto left = src.read_factor;
	if (!left) {
		return null;
	}
	auto op = src.get;
	if (!op) {
		return left;
	}
	if (op.type != Token.Type.SYMBOL) {
		src.unget(op);
		return left;
	}
	auto right = src.read_factor;
	if (!right) {
		throw new Exception("Error at %d: righthand factor is required".format(src.line));
	}
	return new OperatorAst(op.str, [left, right]);
}
