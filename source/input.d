import std.conv;
import std.stdio;
import std.range;

import location;

class Input {
    private:
        dstring s;
        dchar[] line;
        uint p = 0;
        File f;
        dchar[] ungetbuf = [];
	bool iseof = false;
        Location loc;
    public:
	this() {
	    this.loc = new Location();
	}
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
            return loc;
        }
        dchar get() {
            dchar c;
            // from unget buffer
            if (ungetbuf.length > 0) {
                c = ungetbuf.back;
                ungetbuf.popBack;

                return c;
            }
            // reached eof
	    else if (iseof) {
		c = cast(dchar)0;
                return c;
	    }
            // from file
            else if (f.isOpen) {
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
                c = line.front;
                line.popFront;
            }
            // from string
            else {
                c = s[p++];
		if (s.length >= p) {
		    iseof = true;
		}
            }
            loc.column++;

            if (c == '\r' || c == '\n') {
                loc.column = 1;
                loc.line++;
                if (c == '\r') {
                    dchar c2 = get;
                    if (c2 != '\n') { unget(c2); }
                    c = '\n';
                }
            }
            return c;
        }
        void unget(dchar c) {
            ungetbuf ~= c;
        }
}
