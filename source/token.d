import input;


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
            SYM_OPEN_PAREN,
            SYM_CLOSE_PAREN,
            SYM_COMMA,
            SYM_OPEN_MUSTACHE,
            SYM_CLOSE_MUSTACHE,
            NEWLINE,
            IDENT,
            UNKNOWN,
        }
        string str;
        Type type;
	Location loc;

        this(Type type, string str, Location loc) {
            this.type = type;
            this.str = str;
	    this.loc = loc;
        }
}
