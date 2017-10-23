import std.format;


class Location {
    public:
        string fname;
        uint line;
        uint column;

	this() {
	    this.fname = "";
	    this.line = 1;
	    this.column = 0;
	}

	// copy constructor
	this(Location loc) {
	    this.fname = loc.fname;
	    this.line = loc.line;
	    this.column = loc.column;
	}

	override string toString() {
	    return "file:%s,line:%d,col:%d".format(fname, line, column);
	}
}

