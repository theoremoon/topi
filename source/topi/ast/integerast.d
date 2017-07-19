module topi.ast.integerast;

import topi;
import std.conv;
import std.outbuffer;

class IntegerAst : ValueAst {
	public:
		int value;
		this(int value) {
			this.value = value;
			this.type = Type.INT;
		}
		override void emit(ref OutBuffer o) {
			o.writef("\tmov rax, %d\n", value);
		}
		override string toString() {
			return value.to!string;
		}
}
