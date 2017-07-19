module topi.token;

class Token {
	public:
		enum Type {
			STRING,
			IDENT,
			INT,
			SYMBOL,
			K_INT, // keyword int
			K_RET,
		}

		Type type;
		string str;
		this(Type type, string str) {
			this.type = type;
			this.str = str;
		}
		override string toString() {
			return str;
		}
}
