import std.format;
import input;

class TopiException : Exception {
    public:
        this(string msg, Location loc, string file = __FILE__, size_t line = __LINE__) {
            super(msg ~ " <---- on line:%d column:%d in %s".format(loc.line, loc.column, loc.fname), file, line);
        }
}
