import std.stdio;
import topi;




void emit_nasm_head() {
	write("bits 64\n",
		"global _func\n",
		"section .text\n");
}
void emit_main_head() {
	write("_func:\n");
}
void emit_main_foot() {
	write("\tret\n");
}


void main(string[] args)
{
	Source src = new Source(stdin);
	Ast[] stmts;
	while (true) {
		auto stmt = src.read_toplevel;
		if (!stmt) {
			break;
		}
		if (auto func = cast(FunctionAst)stmt) {
			continue;
		}
		stmts ~= stmt;
	}
	if (args.length > 1 && args[1] == "-a") {
		foreach(func; FunctionAst.functions) {
			write(func);
		}
		foreach(stmt; stmts) {
			write(stmt);
		}
	}
	else {
		emit_nasm_head();
		foreach(func; FunctionAst.functions) {
			writef("global %s\n", func.name);
		}
		foreach(func; FunctionAst.functions) {
			func.emit();
		}

		emit_main_head();
		foreach(stmt; stmts) {
			stmt.emit();
		}
		emit_main_foot();
	}
}
