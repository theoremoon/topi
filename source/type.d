class Type {
    public:
	static Type Int;
	static Type Real;
	static this() {
	    Int = new Type();
	    Real = new Type();
	}
}
