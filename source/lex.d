import std.conv;
import std.range;
import std.format;


import input;
import token;
import exception;
import location;
import srcchar;

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
        SrcChar c = input.get;
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
    bool[] space = skip_space(input);

    auto token = lex_symbol(input);
    if (token.type != Token.Type.UNKNOWN) { return token.with_spaces(space[0], space[1]); }
    token = lex_number(input);
    if (token.type != Token.Type.UNKNOWN) { return token.with_spaces(space[0], space[1]); }
    token = lex_identifier(input);
    if (token.type != Token.Type.UNKNOWN) { return token.with_spaces(space[0], space[1]); }

    return token.with_spaces(space[0], space[1]) ;
}

Token lex_real(Input input) {
    // before dot
    SrcStr buf = new SrcStr();
    SrcChar c = input.get;
    if (! c.isDigit) {
        throw new TopiException("Internal error", c.loc);
    }
    while (c.isDigit) {
        buf.add(c);
        c = input.get;
    }
    if (c != '.') {
        throw new TopiException("Internal error", buf.loc);
    }
    // after dot
    SrcStr buf2 = new SrcStr();
    c = input.get;
    while (c.isDigit) {
        buf2.add(c);
        c = input.get;
    }
    input.unget(c);
    // real value
    return new Token(Token.Type.REAL, buf.add(".").add(buf2));
}

Token lex_hex(Input input) {
    SrcStr buf = new SrcStr();
    SrcChar c = input.get;
    if (c != '0') {
        throw new TopiException("Internal error", c.loc);
    }
    buf.add(c);
    c = input.get();
    if (c != 'x') {
        throw new TopiException("Internal error", buf.loc);
    }

    c = input.get;
    while (c.isHex) {
        buf.add(c);
        c = input.get;
    }
    input.unget(c);
    if (buf.str.length <= 2) {
        throw new TopiException("Invalid number 0x. hexadecimal number is expected.", buf.loc);
    }
    return new Token(Token.Type.HEX, buf);
}

Token lex_number(Input input) {
    SrcChar c = input.get;
    // 0-prefixed number
    if (c == '0') {
        SrcChar c2 = input.get;
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
		
		// like 0
		input.unget(c2);
    }
    // digit
    if (c.isDigit) {
	SrcChar[] buf;
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
        return new Token(Token.Type.DIGIT, new SrcStr(buf));
    }
    // not a number
    input.unget(c);
    return new Token(Token.Type.UNKNOWN, new SrcStr([c]));
}

Token lex_symbol(Input input) {
    SrcChar c = input.get;

    switch (c) {
        case '+':
            return new Token(Token.Type.SYM_ADD, new SrcStr([c]));
        case '-':
            return new Token(Token.Type.SYM_SUB, new SrcStr([c]));
        case '*':
            return new Token(Token.Type.SYM_ASTERISK,  new SrcStr([c]));
        case '/':
            return new Token(Token.Type.SYM_SLASH, new SrcStr([c]));
        case '=':
            return new Token(Token.Type.OP_ASSIGN, new SrcStr([c]));
        case ',':
            return new Token(Token.Type.COMMA, new SrcStr([c]));
        case '(':
            return new Token(Token.Type.OPEN_PAREN, new SrcStr([c]));
        case ')':
            return new Token(Token.Type.CLOSE_PAREN, new SrcStr([c]));
        case '{':
            return new Token(Token.Type.OPEN_MUSTACHE, new SrcStr([c]));
        case '}':
            return new Token(Token.Type.CLOSE_MUSTACHE, new SrcStr([c]));
        case '[':
            return new Token(Token.Type.OPEN_BRACKET, new SrcStr([c]));
        case ']':
            return new Token(Token.Type.CLOSE_BRACKET, new SrcStr([c]));
        default:
            break;
    }
    input.unget(c);
    return new Token(Token.Type.UNKNOWN, new SrcStr([c]));
}

Token lex_identifier(Input input) {
    SrcChar c = input.get;
    if (! c.isFirstChar) {
        input.unget(c);
        return new Token(Token.Type.UNKNOWN, new SrcStr([c]));
    }
    SrcChar[] buf = [];
    while (c.isIdentChar) {
        buf ~= c;
        c = input.get;
    }
    input.unget(c);

    if (buf == "Int" || buf == "Real" || buf == "Void") {
        return new Token(Token.Type.KEYWORD, new SrcStr(buf));
    }

    return new Token(Token.Type.IDENT, new SrcStr(buf));
}
