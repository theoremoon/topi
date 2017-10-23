import std.conv;
import std.stdio;
import std.range;

import location;

class Input {
    private:
        dstring s;
	dchar last;
        dchar[] line;
        uint p;
        File f;
	bool iseof;
        Location loc;
	this() {
	    this.loc = new Location();
	    p = 0;
	    iseof = false;
	}

	// peek one character from source string	
	dchar peekFromStr() {
	    // reached to eof
	    if (p >= s.length) {
		iseof = true;
		return cast(dchar)0;
	    }
	    return s[p];
	}

	// consume one character from source string
	void consumeFromStr() {
	    if (p >= s.length) { return; }

	    // consume \r\n as \n
	    if (s[p] == '\r' && p+1 < s.length && s[p+1] == '\n') {
		p++;
	    }
	    p++;
	}

	// peek one character from file
	dchar peekFromFile() {
	    // all characters of line are consumed
	    if (line.length == 0) {
		// reached eof
		if (f.eof) {
		    iseof = true;
		    return cast(dchar)0;
		}

		// read one line
		line = f.readln.to!dstring.dup;

		if (f.eof) {
		    iseof = true;
		    return cast(dchar)0;
		}
	    }
	    return line.front;
	}

	// consume one character from file
	void consumeFromFile() {
	    // avoid exception
	    if (line.length <= 0) { return; }

	    bool cr = (line.front == '\r');
	    line.popFront;
	    // consume \r\n as \n
	    if (cr && line.length > 0 && line.front == '\n') {
		line.popFront;
	    }
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
        Location location() {
            return new Location(loc);
        }
	// peek one character
	dchar peek() {
            dchar c;

            // reached eof
	    if (iseof) { c = cast(dchar)0; }
	    // from file
	    else if (f.isOpen) { c = peekFromFile(); }
            // from string
            else { c = peekFromStr(); }

	    // replace newline char
	    if (c == '\r') {
		c = '\n';
	    }

	    last = c;
	    return last;
	}

	// consume string or file
	void consume() {
	    consumeFromStr(); // consume or do nothing
	    consumeFromFile(); // consume or do nothing

	    loc.column++;
	    // newline
	    if (last == '\n') {
                loc.column = 1;
                loc.line++;
            }
	}

	bool end() {
	    return iseof;
	}
}
