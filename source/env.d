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

	    AsmState.init();
	}
	static void newScope() {
	    // TODO asmstate
	    Env newEnv = new Env();
	    newEnv.parent = cur;
	    cur = newEnv;
	}
	static void exitScope() {
	    cur = cur.parent;
	}

	Env parent = null;
	Func[string] funcs;
	Type[string] types;
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
}
