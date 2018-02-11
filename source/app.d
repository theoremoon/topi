import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input, lex, token, parse, node; 
import ssanode;

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
	auto node = parseAddSub(lexer);

	SSANode[] ssaNodes = [];
	auto ssanode = node.knormalize(ssaNodes);
	foreach (n; ssaNodes) {
		writeln(n);
	}

	// auto cc = new CompileContext();
	// cc.add_func(add_int_operator());
	// node.compile(cc, false, false, []);
	//
	//
	// writeln(cc.buf.toString());
}
