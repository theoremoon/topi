import topi;

import std.stdio;
import std.conv;
import std.string;
import std.outbuffer;


string readAll(File f) {
    const SIZE = 4096; 
    ubyte[] buf;
    foreach (buffer; f.byChunk(SIZE)) {
	buf ~= buffer;
    }
    return buf.assumeUTF;
}

void main(string[] args) {
    // 準備
    builtin_funcs(); 

    auto srcstr = stdin.readAll.strip.to!dstring;
    Source src = Lex(srcstr);

    auto expr = src.read_expr;
    if (args.length > 1 && args[1] == "-a") {
	writeln(expr);
    }
    else {
	OutBuffer buf = new OutBuffer();
	buf.write("bits 64\n");
	buf.write("global _func\n");
	buf.write("section .text\n");
	buf.write("_func:\n");
	buf.write("\tpush rbp\n");
	buf.write("\tmov rbp, rsp\n");
	expr.emit(buf);
	buf.write("\tleave\n");
	buf.write("\tret\n");
	writeln(buf);
    }

}
