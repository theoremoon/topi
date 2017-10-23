import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input, lex, token, parse, evall;

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
}
