module topi.env;

import topi;
import std.format;
import std.algorithm;

class Env {
   public:
      Type[string] vars;
      string[] names;
      FunctionAst[string] funcs;
      Env pre;

      this() {
	 this.pre = null;
      }
      this(Env pre) {
	 this.pre = pre;
      }
      long getAddr(string name) {
	 if (name !in vars) {
	    throw new Exception("unreferencable variable %s".format(name));
	 }
	 return -(countUntil(names, name)+1)*8;
      }
      int getScope(string name) {
	 if (name in vars) {
	    return 0;
	 }
	 if (! pre) {
	    return -1;
	 }
	 return pre.getScope(name)+1;
      }
      void add(string name, Type type) {
	 vars[name] = type;
	 names ~= name;
      }
      uint countFuncs(string signature) {
	 uint c = 0;
	 if (signature in funcs) {
	    c++;
	 }
	 if (! pre) {
	    return c;
	 }
	 return pre.countFuncs(signature) + c;
      }
      string add_func(FunctionAst func) {
	 if (func.signature in funcs) {
	    throw new Exception("Function %s is already defined".format(func.name));
	 }
	 funcs[func.signature] = func;
	 int c = countFuncs(func.signature);
	 return "%s_%d".format(func.signature, c);
      }
}

Env env;
