module topi.parse;

import topi;
import std.uni;
import std.conv;
import std.range;
import std.format;


/// read_factor: read factor (number or identifier or  function call or (expr)) or return null
Ast read_factor(Source src) {
	auto tok = src.get;
	if (! tok) {
		return null;
	}
	final switch (tok.type) {
		case Token.Type.INT:
			return new IntegerAst(tok.str.to!int);
		case Token.Type.IDENT:
			if (src.next('(')) {
				return src.read_function_call(tok.str);
			}
			return new IdentifierAst(tok.str);
		case Token.Type.SYMBOL:
			if (tok.str == "(") {
				auto e = src.read_expr;
				if (! e) {
					throw new Exception("Meaningless parentheses");
				}
				if (! src.next(')')) {
					throw new Exception("')' is expected but %s got".format(src.get.str));
				}
				return e;
			}
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

/// read_expr: read expression or return null
Ast read_expr(Source src, int p = -1) {
	// left hand
	auto left = src.read_factor;
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
			throw new Exception("Right hand expression is required. left:%s, op:%s".format(left, op));
		}
		left = new BinopAst(op.str, left, right);
	}
	return left;
}


/// read_stmt: read statement( {...} or expr\n or definition ) or return null
Ast read_stmt(Source src) {
	auto tok = src.get;
	if (! tok) {
		return null;
	}
	if (tok.str == "{") {
		return src.read_block;
	}
	if (tok.str == "Int") {
		auto ident = src.get;
		if (!ident || ident.type != Token.Type.IDENT) {
			throw new Exception("Identifier expected");
		}
		if (!src.next('=')) {
			throw new Exception("= is required");
		}
		auto v = src.read_expr;
		if (!v) {
			throw new Exception("Expression expected");
		}
		if (!src.next('\n') && !src.next(';')) {
			throw new Exception("Expression should end with ; or \\n");
		}
		return new DefinitionAst(tok.str, ident.str, v);
	}
	if (tok.str == "if") {
		auto cond = src.read_expr;
		if (!cond) {
			throw new Exception("Condition required");
		}
		if (! src.next('{')) {
			throw new Exception("Block rquired");
		}
		auto block = src.read_block;
		if (!block) {
			throw new Exception("Block rquired");
		}
		return new IfAst(cond, block);
	}
	src.unget(tok);
	auto e = src.read_expr;
	if (!e) {
		return null;
	}
	if (!src.next('\n') && !src.next(';')) {
		throw new Exception("Expression should end with ; or \\n");
	}
	return e;
}
/// read_block: read block {...} collection of statements
BlockAst read_block(Source src) {
	Ast[] asts;
	while (true) {
		if (src.next('}')) {
			return new BlockAst(asts);
		}
		asts ~= src.read_stmt;
	}
}

/// read_toplevel: read toplevel element: function definition or statements or null
Ast read_toplevel(Source src) {
	auto tok = src.get;
	if (! tok) {
		return null;
	}
	if (tok.type == Token.Type.IDENT && tok.str == "Func") {
		return src.read_function;
	}
	src.unget(tok);
	return src.read_stmt;
}

/// read_declaration: read variable declrataion or return null
DeclarationAst read_declaration(Source src) {
	auto type = src.get;
	if (! type) {
		return null;
	}
	if (type.type != Token.Type.IDENT || type.str != "Int") {
		src.unget(type);
		return null;
	}
	auto name = src.get;
	if (!name) {
		throw new Exception("variabel name is required");
	}
	return new DeclarationAst(type.str, name.str);
}

/// read_function_type: read function types
string[] read_function_type(Source src) {
	string[] types;
	while (true) {
		auto t = src.get;
		if (!t || t.type != Token.Type.IDENT) {
			if (types.length > 0) {
				throw new Exception("type is expected");
			}
			if (! src.next(')')) {
				throw new Exception(") is expected");
			}
			break;
		}
		types ~= t.str;
		if (src.next(',')) {
			continue;
		}
		if (src.next(')')) {
			break;
		}
		throw new Exception(", or ) is expected");
	}
	return types;
}

/// read_function: read function definition or throw exception 
Ast read_function(Source src) {
	// read function type
	string[] argtypes;
	if (src.next('(')) {
		foreach(t; src.read_function_type) {
			argtypes ~= t;
		}
	}
		
	// read function name
	auto name = src.get;
	if (!name || name.type != Token.Type.IDENT) {
		throw new Exception("Function Name Required");
	}
	if (!src.next('(')) {
		throw new Exception("( is expected");
	}

	// read arguments
	string[] argnames;
	while (true) {
		auto arg = src.get;
		if (!arg || arg.type != Token.Type.IDENT) {
			if (arg) {
				src.unget(arg);
			}
			if (argnames.length > 0) {
				throw new Exception(") is expected");
			}
			if (!src.next(')')) {
				throw new Exception(") is expected but %s got".format(src.get.str));
			}
			break;
		}

		argnames ~= arg.str;
		if (src.next(',')) {
			continue;
		}
		if (src.next(')')) {
			break;
		}
		throw new Exception(", or ) is expected");
	}

	if (argtypes.length != argnames.length) {
		throw new Exception("Invalid function definition: count of argument type and argument is mismatched");
	}

	DeclarationAst[] args;
	foreach (t, n; zip(argtypes, argnames)) {
		args ~= new DeclarationAst(t, n);
	}

	if (!src.next('{')) {
		throw new Exception("{ is expected");
	}
	BlockAst block = src.read_block;
	
	return new FunctionAst(name.str, args, block);
}

/// read_function_call: read calling function
FunctionCallAst read_function_call(Source src, string fname) {
	Ast[] args;
	while (true) {
		auto arg = src.read_expr;
		if (! arg) {
			if (args.length > 0) {
				throw new Exception("Expression is expected");
			}
			if (!src.next(')')) {
				throw new Exception(") is expected");
			}
			break;
		}
		args ~= arg;
		if (src.next(',')) {
			continue;
		}
		if (src.next(')')) {
			break;
		}
		throw new Exception(", or ) is expected");
	}
	return new FunctionCallAst(fname, args);
}
