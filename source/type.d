class Type {
    private:
	this() {
	    name = "";
	    isvar = false;
	};
    public:
	string name;
	bool isvar;

	static Type Int;
	static Type Real;
	static Type Void;
	
	static Type primitive(string name) {
	    Type t = new Type();
	    t.name = name;
	    return t;
	}
	static void init() {
	    Int = primitive("Int");
	    Real = primitive("Real");
	    Void = primitive("Void");
	}
	
	override string toString() {
	    string s = name;
	    if (isvar) {
		s = s ~ "&";
	    }
	    return s;
	}
}
