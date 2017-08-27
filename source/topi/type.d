module topi.type;

import topi;
import std.range;

// 型
class Type {
    public:

	// Primitivies
	static Type Int;
	static Type Char;

	// Argument Types and Return Type
	Type[] inType;
	Type outType;
	string name;

	this(Type[] inType, Type outType) {
	    this.inType = inType;
	    this.outType = outType;
	}
	this(string name, Type[] inType, Type outType) {
	    this(inType, outType);
	    this.name = name;
	    Env.cur.registerType(this);
	}

	Type rtype() {
	    return this.outType;
	}

	// Type Checker
	bool check(Type[] inType) {
	    if (this.inType.length != inType.length) {
		return false;
	    }
	    foreach (a,b; zip(this.inType, inType)) {
		if (a != b) {
		    return false;
		}
	    }
	    return true;
	}
}

void builtin_types() {
    Type.Int = new Type([], null);
    Type.Int.outType = Type.Int;
    Env.cur.registerType(Type.Int);

    Type.Char = new Type([], null);
    Type.Char.outType = Type.Char;
    Env.cur.registerType(Type.Char);
}
