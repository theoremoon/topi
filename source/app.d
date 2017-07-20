import topi;

import std.stdio;
import std.conv;
import std.array;
import std.algorithm;
import std.outbuffer;

void main(string[] args) {
   Source src = new Source(stdin);
   env = new Env();

   Ast[] stmts;
   while (true) {
      auto stmt = src.read_stmt;
      if (!stmt) { 
	 break;
      }
      stmts ~= stmt;
   }
   foreach (stmt; stmts) {
      stmt.analyze;
   }
   if (args.length > 1 && args[1] == "-a") {
      write(stmts.map!(to!string).join(" "));
   }
   else {
      OutBuffer buf = new OutBuffer();
      buf.write("bits 64\n");
      buf.write("global _func\n");
      buf.write("section .text\n");
      buf.write("_func:\n");
      buf.write("\tpush rbp\n");
      buf.write("\tmov rbp, rsp\n");
      if (env.vars.length > 0) {
	 buf.writef("\tsub rsp, %d\n", env.vars.length*8);
      }
      foreach (stmt; stmts) {
	 stmt.emit(buf);
      }
      buf.write("\tleave\n");
      buf.write("\tret\n");
      writeln(buf);
   }

}
