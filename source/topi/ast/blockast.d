module topi.ast.blockast;

import topi;
import std.conv;
import std.array;
import std.format;
import std.algorithm;
import std.outbuffer;

class BlockAst : ValueAst {
	public:
		ValueAst[] exprs;
		this(ValueAst[] exprs) {
		    this.exprs = exprs;
		}
		override Type rtype() {
		    if (exprs.length == 0) {
			return Type.Unit;
		    }

		    return exprs[$-1].rtype;
		}
		override void emit(ref OutBuffer o) {
		    foreach (expr; exprs) {
			expr.emit(o);
		    }
		}
		override string toString() {
		    return "{%s}".format(exprs.map!(to!string).join("; "));
		}
}
