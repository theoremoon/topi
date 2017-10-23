import std.conv;
import std.format;

import input;
import location;
import srcchar;


class Token {
    public:
        enum Type {
            DIGIT,
            HEX,
            REAL,
            SYM_ADD,
            SYM_SUB,
            SYM_SLASH,
            OP_MUL,
            OP_ASSIGN,
            OPEN_PAREN,
            CLOSE_PAREN,
            COMMA,
            OPEN_MUSTACHE,
            CLOSE_MUSTACHE,
            OPEN_BRACKET,
            CLOSE_BRACKET,
            IDENT,
            KEYWORD,
            UNKNOWN,
        }
        string str;
        Type type;
	Location loc;

        bool pre_space = false;
        bool pre_newline = false;

        this(Type type, SrcStr s) {
            this.type = type;
            this.str = s.str.to!string;
	    this.loc = s.loc;
        }
        Token with_spaces(bool pre_space, bool pre_newline) {
            this.pre_space = pre_space;
            this.pre_newline = pre_newline;
            return this;
        }

	override string toString() {
	    return "(type:%s str:%s loc:%s)".format(type, str, loc);
	}
}
