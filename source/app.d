import std.stdio;
import topi;




void emit_nasm_head() {
	write("bits 64\n",
		"global _func\n",
		"section .text\n",
		"_func:\n");
}
void emit_nasm_foot() {
	write("\tret\n");
}


void main(string[] args)
{
	Source src = new Source(stdin);
	Ast[] stmts;
	while (true) {
		auto stmt = src.read_stmt;
		if (!stmt) {
			break;
		}
		stmts ~= stmt;
	}

	if (args.length > 1 && args[1] == "-a") {
		foreach(stmt; stmts) {
			write(stmt);
		}
	}
	else {
		emit_nasm_head();
		foreach(stmt; stmts) {
			stmt.emit();
		}
		emit_nasm_foot();
	}
}
