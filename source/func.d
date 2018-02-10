/// function
module func;

import type;
import compile;
import node;


/// language built-in functions
class BuiltInFunc
{
public:
	alias CallFunc = string delegate(CompileContext cc, Node[] args, bool imm_ok, bool mem_ok, string[] require_here);
	alias DefFunc = void delegate(CompileContext cc); 

	CallFunc callFunc;  /// this function emit call instruction
	DefFunc defFunc;  /// this function emit function definition
	string name;
	TypeCheck[] argtypes;
	Type rettype;

	this (string name, TypeCheck[] argtypes, Type rettype, CallFunc callFunc, DefFunc defFunc)
	{
		this.name = name;
		this.argtypes = argtypes;
		this.rettype = rettype;
		this.callFunc = callFunc;
		this.defFunc = defFunc;
	}

	/// emit codes on called this
	string call(CompileContext cc, Node[] args, bool imm_ok, bool mem_ok, string[] require_here)
	{
		return this.callFunc(cc, args, imm_ok, mem_ok, require_here);
	}

	/// check does args match to this
	bool check_args(CompileContext cc, Node[] args)
	{
		if (this.argtypes.length != args.length) { return false; }
		// check from front
		foreach (i; 0..(args.length)) {
			if (! this.argtypes[i](args[i].type(cc))) {
				return false;
			}
		}
		return true;
	}
}

/// create builtin + operator for int + int
BuiltInFunc add_int_operator()
{
	auto typecheck = delegate (Type t) => t.is_int;
	auto callFunc = delegate (CompileContext cc, Node[] args, bool imm_ok, bool mem_ok, string[] require_here) {
		import std.algorithm, std.array;
		auto regs = ["rax", "rbx", "rcx", "rdx"];
		auto dst = args[0].compile(cc, false, true, require_here);
		auto src = args[1].compile(cc, true, true, regs.setDifference([dst]).array);
		cc.buf.writefln("\taddi %s, %s", dst, src);
		return dst;
	};
	auto defFunc = delegate (CompileContext cc) {};
	return new BuiltInFunc("+", [typecheck, typecheck], Type.Int(), callFunc, defFunc);
}
