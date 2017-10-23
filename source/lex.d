import std.conv;
import std.range;
import std.format;


import input;
import token;
import exception;
import location;

class Lexer {
    private:
        Token[] ungetbuf = [];
        Input input;
    public:
        this(Input input) {
            this.input = input;
        }

	Token[] getAll() {
	    Token[] tokens = [];
	    while (!input.end) {
		tokens ~= this.get();
	    }
	    return tokens;
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
        dchar c = input.peek();
        if (c.isSpace) { space = true; }
        else if (c.isNewline) { newline = true; }
        else { 
            break; 
        }
	input.consume();
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

    return token.with_spaces(space[0], space[1]) ;
}

// lexer read number 123.45 like
Token lex_real(Input input, dchar[] buf) {
    // until dot is already read
    // read after dot
    dchar[] buf2 = [];
    dchar c = input.peek();
    while (c.isDigit) {
        buf2 ~= c;
	input.consume();
        c = input.peek();
    }
    // real value
    return new Token(Token.Type.REAL, (buf ~ buf2).to!string, input.location);
}

Token lex_hex(Input input) {
    // 0x is already read

    dchar[] buf = [];
    dchar c = input.peek();
    while (c.isHex) {
        buf ~= c;
	input.consume();
        c = input.peek();
    }
    if (buf.length == 0) {
        throw new TopiException("Invalid number 0x. hexadecimal number is expected.", input.location);
    }
    return new Token(Token.Type.HEX, "0x"~buf.to!string, input.location);
}

Token lex_number(Input input) {
    dchar c = input.peek();
    // may be 0-prefixed number
    if (c == '0') {
	input.consume();
        dchar c2 = input.peek();
        // hex
        if (c2 == 'x') {
	    input.consume();
            return lex_hex(input);
        }
        // float
        if (c2 == '.') {
	    input.consume();
            return lex_real(input, "0.".to!dstring.dup);
        }
        throw new TopiException("Unknown prefix 0%c".format(c2), input.location);
    }
    // digit
    else if (c.isDigit) {
        dchar[] buf = [];
        while (c.isDigit) {
            buf ~= c;
	    input.consume();
            c = input.peek();
        }
        // float
        if (c == '.') {
	    buf ~= c;
	    input.consume();
            return lex_real(input, buf);
        }
        // digit
        return new Token(Token.Type.DIGIT, buf.to!string, input.location);
    }

    // not a number
    return new Token(Token.Type.UNKNOWN, c.to!string, input.location);
}

Token lex_symbol(Input input) {
    dchar c = input.peek();

    switch (c) {
        case '+':
	    input.consume();
            return new Token(Token.Type.SYM_ADD, "+", input.location);
        case '-':
	    input.consume();
            return new Token(Token.Type.SYM_SUB, "-", input.location);
        case '*':
	    input.consume();
            return new Token(Token.Type.OP_MUL, "*", input.location);
        case '/':
	    input.consume();
            return new Token(Token.Type.SYM_SLASH, "/", input.location);
        case '=':
	    input.consume();
            return new Token(Token.Type.OP_ASSIGN, "=", input.location);
        case ',':
	    input.consume();
            return new Token(Token.Type.COMMA, ",", input.location);
        case '(':
	    input.consume();
            return new Token(Token.Type.OPEN_PAREN, "(", input.location);
        case ')':
	    input.consume();
            return new Token(Token.Type.CLOSE_PAREN, ")", input.location);
        case '{':
	    input.consume();
            return new Token(Token.Type.OPEN_MUSTACHE, "{", input.location);
        case '}':
	    input.consume();
            return new Token(Token.Type.CLOSE_MUSTACHE, "}", input.location);
        case '[':
	    input.consume();
            return new Token(Token.Type.OPEN_BRACKET, "[", input.location);
        case ']':
	    input.consume();
            return new Token(Token.Type.CLOSE_BRACKET, "]", input.location);
        default:
            break;
    }
    return new Token(Token.Type.UNKNOWN, c.to!string, input.location);
}

Token lex_identifier(Input input) {
    dchar c = input.peek();
    if (! c.isFirstChar) {
        return new Token(Token.Type.UNKNOWN, c.to!string, input.location);
    }
    dchar[] buf = [];
    while (c.isIdentChar) {
        buf ~= c;
	input.consume();
        c = input.peek();
    }

    if (buf == "Int" || buf == "Real" || buf == "Void") {
        return new Token(Token.Type.KEYWORD, buf.to!string, input.location);
    }

    return new Token(Token.Type.IDENT, buf.to!string, input.location);
}
