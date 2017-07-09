import std.stdio;
import core.stdc.stdio : ungetc;
import std.uni;

auto getc(ref dchar c) {
	return readf("%c", c);
}
void ungetc(ref File f, dchar c) {
	ungetc(c, f.getFP);
}

int read_number(int n) {
	dchar c;
	while (getc(c)) {
		if (! c.isNumber) {
			stdin.ungetc(c);
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
	dchar c;
	getc(c);
	if (!c.isNumber) {
		throw new Exception("number is required");
	}

	int n = read_number(c-'0');
	emit_nasm(n);
}
