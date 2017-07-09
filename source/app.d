import std.stdio;
import std.conv;
import topi;




void emit_nasm_head() {
	write("bits 64\n",
		"global _func\n",
		"section .text\n");
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
		char[] buf = [];
		foreach(func; FunctionAst.functions) {
			buf ~= func.to!string;
			buf ~= " ";
		}
		foreach(stmt; stmts) {
			buf ~= stmt.to!string;
			buf ~= " ";
		}
		write(buf[0..$-1]);
	}
	else {
		emit_nasm_head();
		foreach(func; FunctionAst.functions) {
			writef("global %s\n", func.name);
		}
		foreach(func; FunctionAst.functions) {
			func.emit();
		}

		auto mainFunc = new FunctionAst("_func", new BlockAst(stmts));
		mainFunc.emit;
	}
}
