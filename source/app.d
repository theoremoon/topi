import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import type, input, lex, parse, node;

void main(string[] args)
{
    Type.init();
    
    Input input = new Input(stdin);
    auto lexer = new Lexer(input);
    auto node = parseToplevel(lexer);
    auto evaled = node.eval;

    writeln("== ast ==");
    writeln(node);

    writeln("== evaled ==");
    writeln(evaled);
}
