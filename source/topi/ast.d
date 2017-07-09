module topi.ast;

import std.stdio;
import std.conv;
import std.format;

/// Ast: Abstract Syntax Tree
class Ast {
	/// emit: emit nasm source code
	abstract void emit();
}

/// IdentifierAst: identifier
/// (this is available on source code only) 
class IdentifierAst : Ast {
	public:
		string name;
		this(string name) {
			this.name = name;
		}
		override void emit() {
			throw new Exception("IdentifierAst is not emittable");
		}
		override string toString() {
			return name;
		}
}

/// IntegerAst: integer type
class IntegerAst : Ast {
	public:
		int v;
		this(int v) {
			this.v = v;
		}

		/// emit: set value to rax
		override void emit() {
			writef("\tmov rax, %d\n", v);
		}

		override string toString() {
			return v.to!string;
		}
}

/// BlockAst: block is { ... } which is collection of statements
class BlockAst : Ast {
	public:
		Ast[] stmts;
		this(Ast[] stmts) {
			this.stmts = stmts;
		}
		override void emit() {
			throw new Exception("Not Implemented yet");
		}
		override string toString() {
			char[] buf;
			buf ~= "{";
			foreach(stmt; stmts) {
				buf ~= stmt.to!string;
				buf ~= " ";
			}
			buf = buf[0..$-1];
			buf ~= "}";
			return cast(string)buf;
		}
}

/// BinopAst: Ast of Binary operator like +, -, ... 
class BinopAst : Ast {
	public:
		Ast left, right;
		dchar op;
		this(dchar op, Ast left, Ast right) {
			this.left = left;
			this.right = right;
			this.op = op;
		}
		override void emit() {
			this.left.emit;
			write("\tpush rax\n");
			this.right.emit;
			write("\tpush rax\n");
			if (op == '+') {
				write("\tpop rbx\n");
				write("\tpop rax\n");
				write("\tadd rax, rbx\n");
				return;
			}
			else if (op == '-') {
				write("\tpop rbx\n");
				write("\tpop rax\n");
				write("\tsub rax, rbx\n");
				return;
			}
			else if (op == '*') {
				write("\tpop rbx\n");
				write("\tpop rax\n");
				write("\timul rbx\n");
				return;
			}
			throw new Exception("Unknwon operator '%c'".format(op));
		}
		override string toString() {
			char[] buf;
			buf ~= "(%c %s %s)".format(op, left, right);
			return buf.to!string;
		}
}
