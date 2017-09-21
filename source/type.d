import std.conv;

class Type {
    public:
	string typestr;

	// primitives
	static Type Int;
	static Type Real;
	static Type Void;

	static this() {
	    Void = new Type();
	    Void.typestr = "Void";
	    Int = new Type();
	    Int.typestr = "Int";
	    Real = new Type();
	    Real.typestr = "Real";
	}

	override string toString() {
	    return typestr.to!string;
	}
}
