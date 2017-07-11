module topi.token;

class Token {
	public:
		enum Type {
			IDENT,
			INT,
			SYMBOL,
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
