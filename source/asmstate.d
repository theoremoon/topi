import std.outbuffer;

class AsmState {
    public:
	static AsmState cur;
	static this() {
	    cur = new AsmState();
	}
	uint rsp = 0;
	uint assign(uint size) {
	    rsp += size;
	    rsp += rsp%16;
	    return rsp;
	}

	void emit_header(OutBuffer o, string fname) {
	    if (fname.length == 0) {
		throw new Exception("internal error");
	    }
	    o.write(fname~":\n");
	    if (rsp > 0) {
		o.write("\tpush rbp\n");
		o.write("\tmov rbp,rsp\n");
		o.writef("\tsub rsp,%d\n", rsp);
	    }
	}

	void emit_footer(OutBuffer o) {
	    if (rsp > 0) {
		o.write("\tleave\n");
	    }
	    o.write("\tret\n");
	}
}
