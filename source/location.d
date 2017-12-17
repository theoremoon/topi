import std.format;
class Location {
    public:
        string fname;
        uint line;
        uint column;

	this() {
	    fname = "";
	    line = 1;
	    column = 1;
	}

	// copy constructor
	this(Location loc) {
	    this.fname = loc.fname;
	    this.line = loc.line;
	    this.column = loc.column;
	}

	override string toString() {
	    return "(file:%s line:%d col:%d)".format(fname, line, column);
	}
}

