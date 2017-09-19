import std.conv;
import std.stdio;
import std.range;

class Input {
    private:
        dstring s;
        dchar[] line;
        uint p = 0;
        File f;
        dchar[] ungetbuf = [];
	bool iseof = false;
    public:
        this(dstring str) {
            s = str;
        }
        this(File f) {
            this.f = f;
        }
        dchar get() {
            dchar c;
            if (ungetbuf.length > 0) {
                c = ungetbuf.back;
                ungetbuf.popBack;
            }
	    else if (iseof) {
		c = cast(dchar)0;
	    }
            else if (f.isOpen) {
                if (line.length == 0) {
                    line = f.readln.to!dstring.dup;
                }
                c = line.front;
                line.popFront;

		if (line.length == 0 && f.eof) {
		    iseof = true;
		}
            }
            else {
                c = s[p++];
		if (s.length >= p) {
		    iseof = true;
		}
            }
            return c;
        }
        void unget(dchar c) {
            ungetbuf ~= c;
        }
}
