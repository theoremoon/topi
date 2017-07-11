module topi.ast;

import std.stdio;
import std.conv;
import std.format;
import std.algorithm;


/// Env: management local variables
alias Env=string[];


/// Ast: Abstract Syntax Tree
class Ast {
	/// emit: emit nasm source code
	abstract void emit();
}

/// DeclarationAst : declrataion of arguments 
class DeclarationAst : Ast {
	public:
		string type;
		string name;
		this(string type, string name) {
			this.type = type;
			this.name = name;
		}
		override void emit() {
			throw new Exception("DeclarationAst is not emittable");
		}
		override string toString() {
			return "%s:%s".format(type, name);
		}
}

/// DefinitionAst : definition of variable like Int a = 10
class DefinitionAst : Ast {
	public:
		string name;
		string type;
		Ast value;
		this(string type, string name, Ast value) {
			this.name = name;
			this.type = type;
			this.value = value;
		}	
		override void emit() {
			auto p = FunctionAst.search(name);
			value.emit;
			writef("\tmov DWORD[rbp%+d], eax\n", p*8);
		}
		override string toString() {
			return "(def %s:%s %s)".format(type, name, value);
		}
}

/// IdentifierAst: identifier
class IdentifierAst : Ast {
	public:
		string name;
		this(string name) {
			this.name = name;
		}
		override void emit() {
			auto p = FunctionAst.search(name);
			if (p == 0) {
				throw new Exception("variable %s is not defined".format(name));
			}
			writef("\tmov eax, DWORD[rbp%+d]\n", p*8);
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
/// TODO: block will be create new scope
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
		string op;
		this(string op, Ast left, Ast right) {
			this.left = left;
			this.right = right;
			this.op = op;
		}
		override void emit() {
			this.left.emit;
			write("\tpush rax\n");
			this.right.emit;
			write("\tmov rbx, rax\n");
			write("\tpop rax\n");
			switch (op) {
				case "+":
					write("\tadd rax, rbx\n");
					return;
				case "-":
					write("\tsub rax, rbx\n");
					return;
				case "*":
					write("\timul rbx\n");
					return;
				default:
					break;
			}
			throw new Exception("Unknwon operator '%s'".format(op));
		}
		override string toString() {
			char[] buf;
			buf ~= "(%s %s %s)".format(op, left, right);
			return buf.to!string;
		}
}

/// FunctionAst: definition of function
class FunctionAst : Ast {
	public:
		/// functions: management all functions (*currently*, all function is in global scope)
		static FunctionAst[string] functions;
		static Env vars; // local variables
		static Env argvars; // arugment variables
		static auto search(string name) {
			auto p = vars.countUntil(name);
			if (p != -1) {
				return -(p+1);
			}
			p = argvars.countUntil(name);
			if (p != -1) {
				return p+2; // 0: rbp 1: return addr 2: arg1 3: arg2...
			}
			return 0;
		}

		string name;
		DeclarationAst[] args;
		BlockAst block;
		this(string name, DeclarationAst[] args, BlockAst block) {
			if ((name in functions) !is null) {
				throw new Exception("Duplicated definition: function %s".format(name));
			}
			this.name = name;
			this.args = args;
			this.block = block;

			functions[name] = this;
		}
		override void emit() {
			auto preEnv = vars.dup;
			vars = [];
			foreach (arg; args) {
				argvars ~= arg.name;
			}
			foreach (stmt; block.stmts) {
				if (auto def = cast(DefinitionAst)stmt) {
					if (search(def.name) != 0) {
						throw new Exception("variable %s is already defined".format(def.name));
					}
					vars ~= def.name;
				}
			}
			writef("%s:\n", name);
			write("\tpush rbp\n");
			write("\tmov rbp, rsp\n");
			if (vars.length > 0) {
				writef("\tsub rsp, %d\n", vars.length*8);
			}
			foreach (stmt; block.stmts) {
				stmt.emit();
			}
			write("\tleave\n");
			write("\tret\n");
			vars = preEnv;
		}
		override string toString() {
			char[] buf;
			buf ~= "(func %s (".format(name);
			foreach (arg; args) {
				buf ~= "%s ".format(arg);
			}
			if (args.length > 0) {
				buf = buf[0..$-1];
			}
			buf ~= ") %s)".format(block);
			return cast(string)buf;
		}

}
/// FunctionCallAst: function call expression
class FunctionCallAst : Ast
{
	public:
		string fname;
		Ast[] args;
		this(string fname, Ast[] args) {
			this.fname = fname;
			this.args = args;
		}
		override void emit() {
			foreach(arg; args) {
				arg.emit;
				write("\tpush rax\n");
			}
			writef("\tcall %s\n", fname);
			writef("\tadd rsp, %d\n", args.length*8);
		}
		override string toString() {
			char[] buf;
			buf ~= "(%s".format(fname);
			foreach(arg; args) {
				buf ~= " %s".format(arg);
			}
			buf ~= ")";
			return cast(string)buf;
		}
}
