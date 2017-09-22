import std.conv;
import std.range;
import std.format;


import input;
import token;
import exception;

class Lexer {
    private:
        Token[] ungetbuf = [];
        Input input;
    public:
        this(Input input) {
            this.input = input;
        }

        Token get() {
            if (ungetbuf.length > 0) {
                Token tok = ungetbuf.back;
                ungetbuf.popBack;
                return tok;
            }

            return lexOne(input);
        }
        void unget(Token tok) {
            ungetbuf ~= tok;
        }
        Location loc() {
            return input.location;
        }
        bool is_next_newline() {
            auto next = get;
            unget(next);
            return next.pre_newline;
        }
}


bool isHex(dchar c) {
    return isDigit(c) || ('A' <= c && c <= 'F');
}
bool isDigit(dchar c) {
    return '0' <= c && c <= '9';
}
bool isFirstChar(dchar c) {
    return ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || c == '_';
}
bool isIdentChar(dchar c) {
    return isFirstChar(c) || isDigit(c);
}
bool isSpace(dchar c) {
    return c == ' ';
}
bool isNewline(dchar c) {
    return c == '\n';
}

bool[] skip_space(Input input) {
    bool space = false;
    bool newline = false;

    while (true) {
        dchar c = input.get;
        if (c.isSpace) { space = true; }
        else if (c.isNewline) { newline = true; }
        else { 
            input.unget(c);
            break; 
        }
    }
    return [space, newline];
}

Token lexOne(Input input) {
    auto space = skip_space(input);

    auto token = lex_symbol(input);
    if (token.type != Token.Type.UNKNOWN) { return token.with_spaces(space[0], space[1]); }
    token = lex_number(input);
    if (token.type != Token.Type.UNKNOWN) { return token.with_spaces(space[0], space[1]); }
    token = lex_identifier(input);
    if (token.type != Token.Type.UNKNOWN) { return token.with_spaces(space[0], space[1]); }

    return null;
}

Token lex_real(Input input) {
    // before dot
    dchar[] buf = [];
    dchar c = input.get;
    if (! c.isDigit) {
        throw new TopiException("Internal error", input.location);
    }
    while (c.isDigit) {
        buf ~= c;
        c = input.get;
    }
    if (c != '.') {
        throw new TopiException("Internal error", input.location);
    }
    // after dot
    dchar[] buf2 = [];
    c = input.get;
    while (c.isDigit) {
        buf2 ~= c;
        c = input.get;
    }
    // member function call
    if (buf2.length == 0) {
        input.unget('.');
        input.unget(c);
        return new Token(Token.Type.DIGIT, buf.to!string, input.location);
    }
    input.unget(c);
    // real value
    return new Token(Token.Type.REAL, (buf ~ "." ~ buf2).to!string, input.location);
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
    return new Token(Token.Type.HEX, buf.to!string, input.location);
}

Token lex_number(Input input) {
    dchar c = input.get;
    // 0-prefixed number
    if (c == '0') {
        dchar c2 = input.get;
        // hex
        if (c2 == 'x') {
            input.unget(c2);
            input.unget(c);
            return lex_hex(input);
        }
        // float
        if (c2 == '.') {
            input.unget(c2);
            input.unget(c);

            return lex_real(input);
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
        // float
        if (c == '.') {
            foreach_reverse (r; buf) {
                input.unget(r);
            }
            return lex_real(input);
        }
        // digit
        return new Token(Token.Type.DIGIT, buf.to!string, input.location);
    }
    // not a number
    input.unget(c);
    return new Token(Token.Type.UNKNOWN, c.to!string, input.location);
}

Token lex_symbol(Input input) {
    dchar c = input.get;

    switch (c) {
        case '+':
            return new Token(Token.Type.SYM_ADD, "+", input.location);
        case '-':
            return new Token(Token.Type.SYM_SUB, "-", input.location);
        case '*':
            return new Token(Token.Type.OP_MUL, "*", input.location);
        case '/':
            return new Token(Token.Type.SYM_SLASH, "/", input.location);
        case '=':
            return new Token(Token.Type.OP_ASSIGN, "=", input.location);
        case ',':
            return new Token(Token.Type.COMMA, ",", input.location);
        case '(':
            return new Token(Token.Type.OPEN_PAREN, "(", input.location);
        case ')':
            return new Token(Token.Type.CLOSE_PAREN, ")", input.location);
        case '{':
            return new Token(Token.Type.OPEN_MUSTACHE, "{", input.location);
        case '}':
            return new Token(Token.Type.CLOSE_MUSTACHE, "}", input.location);
        case '[':
            return new Token(Token.Type.OPEN_BRACKET, "[", input.location);
        case ']':
            return new Token(Token.Type.CLOSE_BRACKET, "]", input.location);
        default:
            break;
    }
    input.unget(c);
    return new Token(Token.Type.UNKNOWN, c.to!string, input.location);
}

Token lex_identifier(Input input) {
    dchar c = input.get;
    if (! c.isFirstChar) {
        input.unget(c);
        return new Token(Token.Type.UNKNOWN, c.to!string, input.location);
    }
    dchar[] buf = [];
    while (c.isIdentChar) {
        buf ~= c;
        c = input.get;
    }
    input.unget(c);

    if (buf == "Int" || buf == "Real" || buf == "Void") {
        return new Token(Token.Type.KEYWORD, buf.to!string, input.location);
    }

    return new Token(Token.Type.IDENT, buf.to!string, input.location);
}
