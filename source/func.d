import std.algorithm;
import std.conv;
import std.array;

import env;
import type;
import asmstate;
import node;

class Func {
    public:
	alias EmitT = void function(AsmState);

	string name;
	Type[] argtypes;
	Type rettype;
	EmitT emitfunc;
	bool constexpr_flag = false;

	static string signature(string name, Node[] args) {
	    return name~"("~args.map!(a => a.type.to!string).join(",")~")";
	}
	static string signature(string name, Type[] argtypes) {
	    return name~"("~argtypes.map!(to!string).join(",")~")";
	}

	this(string name, Type[] argtypes, Type rettype, EmitT emitfunc) {
	    this.name = name;
	    this.argtypes = argtypes;
	    this.rettype = rettype;
	    this.emitfunc = emitfunc;
	}

	string signature() {
	    return Func.signature(name, argtypes);
	}
	void emit(AsmState state) {
	    // emitfunc may be null
	    if (emitfunc !is null) {
		emitfunc(state);
	    }
	}
	void call(Node[] args, AsmState state) {
	    throw new Exception("unimplemented");
	}
	Node eval(Node[] args, Env env) {
	    if (!is_constexpr) { 
		throw new Exception("internal error");
	    }
	    return null;
	}

	Type type() {
	    return rettype;
	}
	bool is_constexpr() {
	    return constexpr_flag;
	}
}

class BuiltinFunc : Func {
    public:
	alias CallT = void function(Node[], AsmState);
	alias ConstexprT = Node function(Node[], Env env); 
	CallT callfunc;
	ConstexprT constexprfunc;

	this(string name, Type[] argtypes, Type rettype, EmitT emitfunc, CallT callfunc, ConstexprT constexprfunc = null) {
	    super(name, argtypes, rettype, emitfunc);
	    this.callfunc = callfunc;
	    this.constexprfunc = constexprfunc;
	}
	override void call(Node[] args, AsmState state) {
	    callfunc(args, state);
	}
	override Node eval(Node[] args, Env env) {
	    if (!is_constexpr) {
		throw new Exception("internal error");
	    }
	    return constexprfunc(args, env);
	}
	override bool is_constexpr() {
	    return constexprfunc !is null;
	}
}

