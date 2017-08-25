import topi;

import std.stdio;
import std.outbuffer;

void main(string[] args) {
	Source src = new Source(stdin);

	auto expr = src.read_expr;
	if (args.length > 1 && args[1] == "-a") {
		writeln(expr);
	}
	else {
		OutBuffer buf = new OutBuffer();
		buf.write("bits 64\n");
		buf.write("global _func\n");
		buf.write("section .text\n");
		buf.write("_func:\n");
		buf.write("\tpush rbp\n");
		buf.write("\tmov rbp, rsp\n");
		expr.emit(buf);
		buf.write("\tleave\n");
		buf.write("\tret\n");
		writeln(buf);
	}

}
