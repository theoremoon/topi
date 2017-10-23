import std.conv;
import std.stdio;
import std.range;

import location;
import srcchar;

class Input {
    private:
        dstring s;
        dchar[] line;
        uint p = 0;
        File f;
        SrcChar[] ungetbuf = [];
	bool iseof = false;
        Location loc;

	dchar peekFromStr() {
	    if (p >= s.length) {
		iseof = true;
		return cast(dchar)0;
	    }
	    if (s[p] == '\r') { return '\n'; }
	    return s[p];
	}
	void consumeFromStr() {
	    if (p >= s.length) { return; }
	    if (s[p] == '\r' && p+1 < s.length && s[p+1] == '\n') {
		p++;
		p++;
		loc.column = 1;
		loc.line++;
	    }
	    else if (s[p] == '\r' || s[p] == '\n') {
		p++;
		loc.column = 1;
		loc.line++;
	    }
	    else {
		p++;
		loc.column++;
	    }
	}
	dchar peekFromFile() {
	    if (line.length == 0) {
		if (f.eof) {
		    iseof = true;
		    return cast(dchar)0;
		}
		line = f.readln.to!dstring.dup;
		if (line.length == 0) {
		    iseof = true;
		    return cast(dchar)0;
		}
	    }
	    if (line.front == '\r') { return '\n'; }
	    return line.front;
	}
	void consumeFromFile() {
	    if (line.length == 0) { return; }
	    if (line.front == '\r' && line.length >= 2 && line[1] == '\n') {
		line.popFront;
		line.popFront;
		loc.column = 1;
		loc.line++;
	    }
	    else if (line.front == '\r' || line.front == '\n') {
		line.popFront;
		loc.column = 1;
		loc.line++;
	    }
	    else {
		line.popFront;
		loc.column++;
	    }
	}
	this() {
	    this.loc = new Location();
	}
    public:
        this(dstring str) {
	    this();
            s = str;
            loc.fname = "-";
        }
        this(File f) {
	    this();
            this.f = f;
            if (f is stdin) {
                loc.fname = "-";
            }
            else {
                loc.fname = f.name;
            }
        }
        SrcChar get() {
            dchar c;
	    Location curLoc = new Location(loc);
            // from unget buffer
            if (ungetbuf.length > 0) {
                auto v = ungetbuf.back;
                ungetbuf.popBack;

                return v;
            }
            // reached eof
	    else if (iseof) {
		c = cast(dchar)0;
                return SrcChar(c, curLoc);
	    }
            // from file
            else if (f.isOpen) {
		c = peekFromFile();
		consumeFromFile();
            }
            // from string
            else {
		c = peekFromStr();
		consumeFromStr();
            }
            return SrcChar(c, curLoc);
        }
        void unget(SrcChar c) {
            ungetbuf ~= c;
        }
}
