module topi.parse;

import topi;
import std.uni;
import std.conv;
import std.format;



Ast read_identifier(Source src, dchar c) {
	dchar[] buf;
	buf ~= c;
	while (src.get(c)) {
		if (! c.isAlphaNum && c != '_') {
			src.unget(c);
			break;
		}
		buf ~= c;
	}
	return new IdentifierAst(buf.to!string);
}
Ast read_number(Source src, int n) {
	dchar c;
	while (src.get(c)) {
		if (! c.isNumber) {
			src.unget(c);
			break;
		}
		n = n*10 + (c-'0');
	}
	return new IntegerAst(n);
}
Ast read_factor(Source src) {
	dchar c;
	if (! src.get_with_skip(c)) {
		return null;
	}
	if (c.isNumber) {
		return src.read_number(c-'0');
	}
	if (c.isAlpha || c == '_') {
		return src.read_identifier(c);
	}
	if (c == '(') {
		auto e = src.read_expr;
		if (! e) {
			throw new Exception("Meaningless parentheses");
		}
		if (! src.get_with_skip(c)) {
			throw new Exception("Unterminated parentheses");
		}
		if (c != ')') {
			throw new Exception("')' is expected but got '%c'".format(c));
		}
		return e;

	}
	throw new Exception("Unexpected character: '%c'".format(c));
}
Ast read_term(Source src) {
	auto f1 = src.read_factor;
	if (! f1) {
		return null;
	}
	dchar c;
	if (! src.get_with_skip(c)) {
		return f1;
	}
	if (c != '*') {
		src.unget(c);
		return f1;
	}
	auto f2 = src.read_term;
	if (! f2) {
		throw new Exception("Incomplete term");
	}
	return new BinopAst(c, f1, f2);
}
Ast read_expr(Source src) {
	auto t1 = src.read_term;
	if (!t1) {
		return null;
	}
	dchar c;
	if (! src.get_with_skip(c)) {
		return t1;
	}
	if (c != '+' && c != '-') {
		src.unget(c);
		return t1;
	}
	auto t2 = src.read_expr;
	if (!t2) {
		throw new Exception("Incomplete expr");
	}
	return new BinopAst(c, t1, t2);
}
Ast read_stmt(Source src) {
	auto e = src.read_expr;
	if (!e ) {
		return null;
	}
	if (! src.expect_with_skip([' ', ';'])) {
		throw new Exception("Expression should end with ; or \\n");
	}
	return e;
}
