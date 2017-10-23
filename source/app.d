import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input, lex, token;

void main(string[] args)
{
    Input input = new Input(stdin);
    auto lexer = new Lexer(input);

    for (Token tok = lexer.get(); tok.type != Token.Type.UNKNOWN; tok = lexer.get()) {
	writeln(tok);
    }
}
