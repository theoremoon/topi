import std.conv;
import std.stdio;
import std.format;
import std.outbuffer;

import input;
import token;

class TopiException : Exception {
    public:
        this(string msg, Location loc, string file = __FILE__, size_t line = __LINE__) {
            super(msg ~ " <---- on line:%d column:%d in %s".format(loc.line, loc.column, loc.fname), file, line);
        }
}

void asmhead(ref OutBuffer o) {
    o.write("bits 64\n");
    o.write("global _func\n");
    o.write("section .text\n");
}

Token lex_hex(Input input) {
    if (input.get != '0') {
        throw new TopiException("Internal error", input.location);
    }
    if (input.get != 'x') {
        throw new TopiException("Internal error", input.location);
    }
    dchar[] buf = [];
    dchar c = input.get;
    while (c.isHex) {
        buf ~= c;
        c = input.get;
    }
    input.unget(c);
    if (buf.length == 0) {
        throw new TopiException("Invalid number 0x. hexadecimal number is expected.", input.location);
    }
    return new Token(Token.Type.HEX, buf.idup, input.location);
}

Token lex_number(Input input) {
    Token tok = null;
    dchar c = input.get;
    // 0-prefixed number
    if (c == '0') {
        dchar c2 = input.get;
        if (c2 == 'x') {
            input.unget(c2);
            input.unget(c);
            return lex_hex(input);
        }
        throw new TopiException("Unknown prefix 0%c".format(c2), input.location);
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

bool isHex(dchar c) {
    return isDigit(c) || ('A' <= c && c <= 'F');
}
bool isDigit(dchar c) {
    return '0' <= c && c <= '9';
}
long parse_int(Token tok) {
    if (tok.type == Token.Type.DIGIT) {
        long v = tok.str.to!long(10);
        return v;
    }
    if (tok.type == Token.Type.HEX) {
        long v = tok.str.to!long(16);
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
