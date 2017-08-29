module topi.ast.funccallast;

import topi;
import std.conv;
import std.array;
import std.format;
import std.algorithm;
import std.outbuffer;


// 関数呼び出し
class FuncCallAst : ValueAst {
	public:
		string fname;
		ValueAst[] args;
		Func f;

		this (string fname, ValueAst[] args) {
			this.fname = fname;
			this.args = args;

			// 関数が定義されてなければ死ぬ
			f = Env.cur.getFunc(fname, args);
			if (f is null) {
			    throw new Exception("Function <%s> is not defined".format(Func.signature(fname, args)));
			}
		}
		override Type rtype() {
		    return f.type.outType;
		}

		// call に投げるだけ
		override void emit(ref OutBuffer o) {
			f.call(o, args);
		}

		override string toString() {
			return "(%s %s)".format(fname, args.map!(to!string).join(" "));
		}
}
