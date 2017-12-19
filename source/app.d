import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input, lex, token, parse, evall, compile;

bool opt_exist(string[] args, string key, string[] prefixes = [""]) {
	foreach (arg; args) {
		foreach (p; prefixes) {
			if (p~arg == key) { return true; }
		}
	}
	return false;
}


void main(string[] args)
{
    Input input = new Input(stdin);
    auto lexer = new Lexer(input);

    auto rootNode = lexer.parseTopLevel();
    writeln("== AST ==");
    writeln(rootNode);

    writeln("== Compile Time Execution ==");
    auto evaled = eval(rootNode);
    writeln(evaled);

	if (args.opt_exist("compile")) {
		auto compiled = compile.compile(evaled);
		compiled.write();
	}
}
