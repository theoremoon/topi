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

	Type type() {
	    return rettype;
	}
}

class BuiltinFunc : Func {
    public:
	alias CallT = void function(Node[], AsmState);
	CallT callfunc;

	this(string name, Type[] argtypes, Type rettype, EmitT emitfunc, CallT callfunc) {
	    super(name, argtypes, rettype, emitfunc);
	    this.callfunc = callfunc;
	}
	override void call(Node[] args, AsmState state) {
	    callfunc(args, state);
	}
}

