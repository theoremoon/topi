module topi.type;

import std.range;

// 型
class Type {
    public:
	static Type[string] types;

	// Primitivies
	static Type Int;
	static Type Char;
	static this() {
	    Int = new Type([], null);
	    Int.outType = Int;
	    types["Int"] = Int;

	    Char = new Type([], null);
	    Char.outType = Char;
	    types["Char"] = Char;
	}

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
	    if (name in types) {
		throw new Exception("");
	    }
	    types[name] = this;
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
