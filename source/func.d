import std.algorithm;
import std.outbuffer;
import std.conv;
import std.array;

import type;
import node;

class Func {
    public:
	alias EmitT = void function(OutBuffer);

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
	void emit(OutBuffer o) {
	    // emitfunc may be null
	    if (emitfunc !is null) {
		emitfunc(o);
	    }
	}
	void call(Node[] args, OutBuffer o) {
	    // constexpr
	    if (is_constexpr && all(args.map!(a => a.is_constexpr))) {
		eval(args).emit(o);
	    }
	    // not constexpr
	    else {
	    }
	}
	Node eval(Node[] args) {
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
	alias CallT = void function(Node[], OutBuffer);
	alias ConstexprT = Node function(Node[]); 
	CallT callfunc;
	ConstexprT constexprfunc;

	this(string name, Type[] argtypes, Type rettype, EmitT emitfunc, CallT callfunc, ConstexprT constexprfunc = null) {
	    super(name, argtypes, rettype, emitfunc);
	    this.callfunc = callfunc;
	    this.constexprfunc = constexprfunc;
	}
	override void call(Node[] args, OutBuffer o) {
	    // constexpr
	    if (is_constexpr && all(args.map!(a=>a.is_constexpr))) {
		eval(args).emit(o);
		return;
	    }
	    // not constexpr
	    callfunc(args, o);
	}
	override Node eval(Node[] args) {
	    return constexprfunc(args);
	}
	override bool is_constexpr() {
	    return constexprfunc !is null;
	}
}

