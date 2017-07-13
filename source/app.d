import std.stdio;
import std.conv;
import topi;



void main(string[] args)
{
	Source src = new Source(stdin);
	Ast[] stmts;
	// FIXME: this is valid now -> func stmt func stmt
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
	auto mainFunc = new FunctionAst("_func", [], new BlockAst(stmts));
	FunctionAst.functions["_func"] = mainFunc;

	// output S exp
	if (args.length > 1 && args[1] == "-a") {
		char[] buf = [];
		foreach(func; FunctionAst.functions) {
			buf ~= func.to!string;
			buf ~= " ";
		}
		write(buf[0..$-1]);
	}

	// output nasm
	else {
		write("bits 64\n");
		write("section .data\n");
		StringAst.emitData();
		write("section .text\n");
		foreach(func; FunctionAst.functions) {
			writef("global %s\n", func.name);
		}
		foreach(func; FunctionAst.functions) {
			func.emit();
		}
	}
}
