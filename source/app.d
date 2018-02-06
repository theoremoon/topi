import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input, lex, token, parse; 

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
	auto node = parseMuldiv(lexer);

	writeln(node);
}
