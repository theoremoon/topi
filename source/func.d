import std.conv;
import std.format;
import std.array;
import std.algorithm;

import node;
import type;
import env;


class Func {
    public:
	alias ProcT = Node function(Env env, Node[] args);
	string name;
	Type[] argtypes;
	Type rettype;
	ProcT proc;

	this (string name, Type[] argtypes, Type rettype, ProcT proc) {
	    this.name = name;
	    this.argtypes = argtypes;
	    this.rettype = rettype;
	    this.proc = proc;
	}
	string signature() {
	    return Func.signature(name, argtypes);
	}
	static string signature(string name, Type[] types) {
	    return "%s(%s)".format(name, types.map!(to!string).join(","));
	}
}
