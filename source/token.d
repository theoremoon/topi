import input;


class Token {
    public:
        enum Type {
            DIGIT,
            HEX,
            REAL,
            SYM_ADD,
            SYM_SUB,
            OP_MUL,
            SYM_OPEN_PAREN,
            SYM_CLOSE_PAREN,
            UNKNOWN,
        }
        dstring str;
        Type type;
	Location loc;

        this(Type type, dstring str, Location loc) {
            this.type = type;
            this.str = str;
	    this.loc = loc;
        }
}
