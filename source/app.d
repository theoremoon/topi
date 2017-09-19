import std.conv;
import std.stdio;
import std.range;
import std.outbuffer;

class Input {
    private:
        dstring s;
        dchar[] line;
        uint p = 0;
        File f;
        dchar[] ungetbuf = [];
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
            else if (f.isOpen) {
                if (line.length  == 0) {
                    line = f.readln.to!dstring.dup;
                }
                c = line.front;
                line.popFront;
            }
            else {
                c = s[p++];
            }
            return c;
        }
        void unget(dchar c) {
            ungetbuf ~= c;
        }
}

void asmhead(ref OutBuffer o) {
    o.write("bits 64\n");
    o.write("global _func\n");
    o.write("section .text\n");
}

bool isDigit(dchar c) {
    return '0' <= c && c <= '9';
}
long parse_int(Input input) {
    dchar[] buf;
    while (true) {
        dchar c = input.get;
        if (!c.isDigit) {
            input.unget(c);
            break;
        }
        buf ~= c;
    }
    long v = 0;
    foreach (c; buf) {
        v = v * 10 + (c-'0');
    }
    return v;
}

void main()
{
    Input input = new Input(stdin);
    OutBuffer o = new OutBuffer();

    auto v = parse_int(input);

    asmhead(o);
    o.write("_func:\n");
    o.writef("\tmov rax,%d\n", v);
    o.write("\tret\n");

    writeln(o.toString);
}
