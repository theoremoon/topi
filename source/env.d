import std.conv;

import func;
import var;
import node;
import type;
import asmstate;
import builtin;

class Env {
    public:
	static Env cur;
	static void init() {
	    cur = new Env();

	    Type.init();
	    cur.registerType(Type.Void);
	    cur.registerType(Type.Int);
	    cur.registerType(Type.Real);

	    register_builtin(cur);
	}

	Env parent = null;
	Func[string] funcs;
	Type[string] types;
	Var[string] vars;
	AsmState state;

	this() {
	    state = new AsmState();
	}

	Func getFunc(string name, Node[] args) {
	    auto sign = Func.signature(name, args);
	    return getFunc(sign);
	}
	Func getFunc(string name, Type[] argtypes) {
	    auto sign = Func.signature(name, argtypes);
	    return getFunc(sign);
	}
	Func getFunc(string sign) {
	    if (sign in funcs) { return funcs[sign]; }
	    if (parent is null) { return null; }
	    return parent.getFunc(sign);
	}
	bool registerFunc(Func f) {
	    if (getFunc(f.signature) !is null) { return false; }
	    funcs[f.signature] = f;
	    return true;
	}

	Type getType(string typename) {
	    if (typename in types) { return types[typename]; }
	    if (parent is null) { return null; }
	    return parent.getType(typename);
	}
	bool registerType(Type t) {
	    if (getType(t.to!string) !is null) { return false; }
	    types[t.to!string] = t;
	    return true;
	}

	Var getVar(string varname) {
	    if (varname in vars) { return vars[varname]; }
	    if (parent is null) { return null; }
	    return parent.getVar(varname);
	}
	bool registerVar(Var v) {
	    if (getVar(v.to!string) !is null) { return false; }
	    vars[v.to!string] = v;
	    return true;
	}


}
