module topi.func;

import topi;
import std.array;
import std.range;
import std.format;
import std.algorithm;
import std.outbuffer;

// TODO: 引数の渡し方を実装する
class Func {
    public:
	alias procT = void delegate(ref OutBuffer);
	string name;
	Type type;
	procT proc;

	this (string name, Type type, procT proc) {
	    this.name = name;
	    this.type = type;
	    this.proc = proc;

	    if (! Env.cur.registerFunc(this)) {
		throw new Exception("function <%s> is already defined".format(this.signature));
	    }
	}

	string signature() {
	    return this.name ~ "_" ~ type.inType.map!((t) => t.name).join("_");
	}
	static string signature(string fname, ValueAst[] args) {
	    return fname ~ "_" ~ args.map!((a) => a.rtype.name).join("_");
	}

	// 関数の引数があってるか調べる
	bool typeCheck(ValueAst[] args) {
	    if (type.inType.length != args.length) {
		return false;
	    }
	    foreach (a,b; zip(type.inType, args)) {
		if (a != b.rtype) {
		    return false;
		}
	    }
	    return true;
	}

	void call(ref OutBuffer o, ValueAst[] args) {
	    if (! typeCheck(args)) {
		throw new Exception("invalid arguments for calling function <%s>.".format(signature));
	    }

	    // 引数をpush （ここは呼出規約によってかわる）
	    foreach (arg; args) {
		arg.emit(o);
		o.write("\tpush rax\n");
	    }

	    // 関数よびだし（ここもオペレータとかインラインとかだと変わりそう）
	    proc(o);
	}
}


void builtin_funcs() {
    new Func("+", new Type([Type.Int, Type.Int], Type.Int), (ref OutBuffer o) {
	    o.writef("\tpop rbx\n");
	    o.writef("\tpop rax\n");
	    o.writef("\tadd rax, rbx\n");
    });
    new Func("-", new Type([Type.Int, Type.Int], Type.Int), (ref OutBuffer o) {
	    o.writef("\tpop rbx\n");
	    o.writef("\tpop rax\n");
	    o.writef("\tsub rax, rbx\n");
    });
    new Func("*", new Type([Type.Int, Type.Int], Type.Int), (ref OutBuffer o) {
	    o.writef("\tpop rbx\n");
	    o.writef("\tpop rax\n");
	    o.writef("\timul rax, rbx\n");
    });
}
