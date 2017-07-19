module topi.ast.declast;

import topi;
import std.outbuffer;
import std.format;

class DeclAst : Ast {
	public:
		Type type;
		string name;
		this(Type type, string name) {
			this.type = type;
			this.name = name;
		}

		override void analyze() {
			if (env.getScope(name) == 0) {
				throw new Exception("Variable %s is already declared".format(name));
			}
			env.add(name, type);
		}

		override void emit(ref OutBuffer o) {
		}

		override string toString() {
			return "%s:%s".format(name, type);
		}
}
