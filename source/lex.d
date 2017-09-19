import std.format;


import input;
import token;
import exception;


bool isHex(dchar c) {
    return isDigit(c) || ('A' <= c && c <= 'F');
}
bool isDigit(dchar c) {
    return '0' <= c && c <= '9';
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
