import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input;
import token;

class TopiException : Exception {
    public:
        this(string msg, Location loc) {
            super(msg ~ " <---- on line:%d column:%d in %s".format(loc.line, loc.column, loc.fname));
        }
}

void asmhead(ref OutBuffer o) {
    o.write("bits 64\n");
    o.write("global _func\n");
    o.write("section .text\n");
}

Token lex_number(Input input) {
    Token tok = null;
    dchar c = input.get;
    // 0-prefixed number
    if (c == '0') {
        input.unget(c);
        tok = new Token(Token.Type.UNKNOWN, "", input.location);
    }
    // digit
    else if (c.isDigit) {
        dchar[] buf = [];
        while (c.isDigit) {
            buf ~= c;
            c = input.get;
        }
        input.unget(c);
        tok = new Token(Token.Type.DIGIT, buf.idup, input.location);
    }
    // not a number
    else {
        input.unget(c);
        tok = new Token(Token.Type.UNKNOWN, "", input.location);
    }
    return tok;
}

bool isDigit(dchar c) {
    return '0' <= c && c <= '9';
}
long parse_int(Token tok) {
    if (tok.type == Token.Type.DIGIT) {
        long v = tok.str.to!long(10);
        return v;
    }
    throw new TopiException("Unimplemented", tok.loc);
}

void main()
{
    Input input = new Input(stdin);
    OutBuffer o = new OutBuffer();

    auto tok = lex_number(input);
    auto v = parse_int(tok);

    asmhead(o);
    o.write("_func:\n");
    o.writef("\tmov rax,%d\n", v);
    o.write("\tret\n");

    writeln(o.toString);
}
