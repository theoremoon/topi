import topi;

import std.stdio;
import std.outbuffer;

void main(string[] args) {
	Source src = new Source(stdin);
	env = new Env();

	Ast[] stmts;
	while (true) {
		auto stmt = src.read_stmt;
		if (!stmt) { 
			break;
		}
		stmts ~= stmt;
	}
	foreach (stmt; stmts) {
		stmt.analyze;
	}
	if (args.length > 1 && args[1] == "-a") {
		foreach (stmt; stmts) {
			writeln(stmt);
		}
	}
	else {
		OutBuffer buf = new OutBuffer();
		buf.write("bits 64\n");
		buf.write("global _func\n");
		buf.write("section .text\n");
		buf.write("_func:\n");
		buf.write("\tpush rbp\n");
		buf.write("\tmov rbp, rsp\n");
		foreach (stmt; stmts) {
			stmt.emit(buf);
		}
		buf.write("\tleave\n");
		buf.write("\tret\n");
		writeln(buf);
	}

}
