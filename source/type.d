import std.conv;

class Type {
    public:
	dstring typestr;

	static Type Int;
	static Type Real;
	static this() {
	    Int = new Type();
	    Int.typestr = "Int";
	    Real = new Type();
	    Real.typestr = "Real";
	}

	override string toString() {
	    return typestr.to!string;
	}
}
