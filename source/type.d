import std.conv;

class Type {
    public:
	string typestr;
	bool islvalue = false;

	// primitives
	static Type Int;
	static Type Real;
	static Type Void;

	static void init() {
	    Void = new Type();
	    Void.typestr = "Void";
	    Int = new Type();
	    Int.typestr = "Int";
	    Real = new Type();
	    Real.typestr = "Real";
	}

	override string toString() {
	    return typestr;
	}

	// ignoring islvalue
	bool same_signature(Type t) {
	    if (this.typestr != t.typestr) { return false; }
	    return true;
	}

	// allow t as rvalue even if t is lvalue
	bool same_rvalue(Type t) {
	    if (!same_signature(t)) { return false; }
	    if (!t.islvalue && islvalue) { return false; }
	    return true;
	}
}
