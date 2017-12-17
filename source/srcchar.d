import location;
// character with location
struct SrcChar {
    public:
	dchar c;
	Location loc;

	this(dchar c, Location loc) {
	    this.c = c;
	    this.loc = loc;
	}

	bool opEquals(const dchar c){
	    return this.c == c;
	}

	alias c this;
}

class SrcStr {
    public:
	dchar[] str;
	Location loc;
	this() {
	    str = [];
	    loc = null;
	}
	this(SrcChar[] s) {
	    this();
	    foreach (c; s) {
		this.add(c);
	    }
	}
	SrcStr add(SrcChar c) {
	    if (this.loc is null) { this.loc = c.loc; }
	    str ~= c.c;
	    return this;
	}
	SrcStr add(dstring s) {
	    str ~= s.dup;
	    return this;
	}
	SrcStr add(SrcStr s) {
	    if (this.loc is null) { this.loc = s.loc; }
	    str ~= s.str.dup;
	    return this;
	}
}
