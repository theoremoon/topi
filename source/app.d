import std.stdio;
import core.stdc.stdio : ungetc, getc;
import std.uni;

class Source {
	public:
		dchar[] buf;
		File f;

		alias f this;
		this(File f) {
			this.f = f;
		}
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

int read_number(Source src, int n) {
	dchar c;
	while (src.get(c)) {
		if (! c.isNumber) {
			src.unget(c);
			break;
		}
		n = n*10 + (c-'0');
	}
	return n;
}

void emit_nasm(int n) {
	write ("bits 32\n",
		"section .text\n",
		"global _func\n",
		"_func:\n");
	writef("\tmov eax, %d\n", n);
	write("\tret\n");
}


void main()
{
	Source src = new Source(stdin);
	dchar c;
	if (src.get(c) == 0) {
		throw new Exception("source is empty");
	}
	if (!c.isNumber) {
		throw new Exception("number is required");
	}

	int n = read_number(src, c-'0');
	emit_nasm(n);
}
