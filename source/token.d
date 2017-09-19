import input;


class Token {
    public:
        enum Type {
            DIGIT,
            HEX,
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
