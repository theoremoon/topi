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
			if (op == '+') {
				this.left.emit;
				write("\tpush rax\n");
				write("\tpop rbx\n");
				this.right.emit;
				
				write("\tadd rax, rbx\n");
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
Ast read_expr(Source src) {
	dchar c;
	src.get(c);
	auto left = src.read_number(c-'0');

	dchar op;
	src.get(op);

	src.get(c);
	auto right = src.read_number(c-'0');

	return new BinopAst(op, left, right);
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
