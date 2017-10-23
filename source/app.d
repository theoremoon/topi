import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input, lex, parse;

void main(string[] args)
{
    Input input = new Input(stdin);
    auto lexer = new Lexer(input);
}
