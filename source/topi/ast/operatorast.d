module topi.ast.operatorast;

import topi;
import std.conv;
import std.array;
import std.range;
import std.format;
import std.algorithm;
import std.outbuffer;

class OperatorAst : ValueAst {
	public:
		enum OPTYPE {
			ADD_INT_INT,
			SUB_INT_INT,
			MUL_INT_INT,
		}

		string op;
		ValueAst[] args;
		OPTYPE optype;
		Type rtype;

		this(string op, ValueAst[] args) {
			this.op = op;
			this.args = args;
			// オペレータを決めます
			switch (op) {
				case "+":
					if (args.length != 2) {
						throw new Exception("internal error: invalid argument number for operator +");
					}
					if (!(args[0].type == Type.INT && args[1].type == Type.INT)) {
						throw new Exception("invalid type for operator +");
					}
					this.rtype = Type.INT;
					this.optype = OPTYPE.ADD_INT_INT;
					break;
				case "-":
					if (args.length != 2) {
						throw new Exception("internal error: invalid argument number for operator -");
					}
					if (!(args[0].type == Type.INT && args[1].type == Type.INT)) {
						throw new Exception("invalid type for operator -");
					}
					this.rtype = Type.INT;
					this.optype = OPTYPE.SUB_INT_INT;
					break;
				case "*":
					if (args.length != 2) {
						throw new Exception("internal error: invalid argument number for operator *");
					}
					if (!(args[0].type == Type.INT && args[1].type == Type.INT)) {
						throw new Exception("invalid type for operator *");
					}
					this.rtype = Type.INT;
					this.optype = OPTYPE.MUL_INT_INT;
					break;
 				default:
					throw new Exception("invalid operator %c".format(op));
			}
		}
		override Type type() {
			return rtype;
		}
		override void analyze() {
			args.each!(a => a.analyze);
		}
		override void emit(ref OutBuffer o) {
			switch (optype) {
				case OPTYPE.ADD_INT_INT:
					args[0].emit(o);
					o.writef("\tpush rax\n");
					args[1].emit(o);
					o.writef("\tpush rax\n");

					o.writef("\tpop rbx\n");
					o.writef("\tpop rax\n");
					o.writef("\tadd rax, rbx\n");
					break;
				case OPTYPE.SUB_INT_INT:
					args[0].emit(o);
					o.writef("\tpush rax\n");
					args[1].emit(o);
					o.writef("\tpush rax\n");

					o.writef("\tpop rbx\n");
					o.writef("\tpop rax\n");
					o.writef("\tsub rax, rbx\n");
					break;
				case OPTYPE.MUL_INT_INT:
					args[0].emit(o);
					o.writef("\tpush rax\n");
					args[1].emit(o);
					o.writef("\tpush rax\n");

					o.writef("\tpop rbx\n");
					o.writef("\tpop rax\n");
					o.writef("\timul rax, rbx\n");
					break;
				default:
					throw new Exception("Emit for %s is unimplemented".format(optype));
			}
		}
		override string toString() {
			return "(%s %s)".format(op, args.map!(to!string).join(" "));
		}
}
