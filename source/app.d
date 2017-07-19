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
		expr.emit(buf);
		writeln(buf);
	}

}
