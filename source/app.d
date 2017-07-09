import std.stdio;
import std.format;
import core.stdc.stdio : ungetc, getc;
import std.uni;

/// Ast: Abstract Syntax Tree
class Ast {
	/// emit: emit nasm source code
	abstract void emit();
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
}

/// Source: management source string
class Source {
	public:
		dchar[] buf;
		File f;

		alias f this;
		this(File f) {
			this.f = f;
		}

		/// get: get one character from source
		uint get(ref dchar c) {
			if (buf.length > 0) {
				c = buf[$-1];
				buf = buf[0..$-1];
				return 1;
			}
			int a = f.getFP.getc;
			if (a == EOF) {
				return 0;
			}
			c = a;
			return 1;
		}
		uint skip_space() {
			uint cnt = 0;
			dchar c;
			while (get(c)) {
				if (!c.isWhite) {
					unget(c);
					break;
				}
				cnt++;
			}
			return cnt;
		}
		uint get_with_skip(ref dchar c) {
			skip_space();
			return get(c);
		}
		void unget(dchar c) {
			buf ~= c;
		}
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

void emit_nasm_head() {
	write("bits 64\n",
		"global _func\n",
		"section .text\n",
		"_func:\n");
}
void emit_nasm_foot() {
	write("\tret\n");
}


void main()
{
	Source src = new Source(stdin);
	auto binop = src.read_expr;

	emit_nasm_head();
	binop.emit();
	emit_nasm_foot();
}
