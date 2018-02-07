/// node module. node makes AST
module node;

import compile;
import token;

/// parent class of all Node
abstract class Node
{
public:
	Store store;   /// in memory, this value is here
	this(Token tok)
	{
		this.tok = tok;
	}
	abstract string compile(CompileContext cc, bool imm_ok, bool mem_ok, string[] required_registers);
private:
	Token tok;  /// symbol of this expression in source code
}


/// integer number node such as ..., -2, -1, 0, 1, 2, ...
class IntNode : Node
{
public:
	long v;  /// value

	/// constructor: initialize v
	this(Token tok, long v)
	{
		super(tok);
		this.v = v;
	}

	override string compile(CompileContext cc, bool imm_ok, bool mem_ok, string[] require_here)
	{
		if (imm_ok) {
			import std.conv;
			return this.v.to!string;
		}
		foreach (reg; require_here) {
			if (super.store is null) {
				super.store = new Store(8);
			}
			super.store.require_register(cc, reg);
			break;
		}
		cc.buf.writefln("\tmov %s, %d", super.store.memory_str(cc), this.v);
		return super.store.memory_str(cc);
	}

	override string toString()
	{
		import std.conv;
		return this.v.to!string();
	}
}

/// real number node. 0.1, 1.4 and so on
class RealNode : Node
{
public:
	double v;   /// value

	/// constructor: initialize v
	this(Token tok, double v)
	{
		super(tok);
		this.v = v;
	}

	override string compile(CompileContext cc, bool imm_ok, bool mem_ok, string[] require_here)
	{
		throw new Exception("internal error: not implemented yet");
	}
	override string toString()
	{
		import std.conv;
		return this.v.to!string();
	}
}

/// unary/binary/more operand operator node like +,-,*,/, ...
/// this class will be replaced to funccall 
class BinopNode : Node
{
public:
	string op;
	Node[] args;
	this(Token tok, string op, Node[] args)
	{
		super(tok);
		this.op = op;
		this.args = args;
	}

	override string compile(CompileContext cc, bool imm_ok, bool mem_ok, string[] require_here)
	{
		if (this.op == "+") {
			auto dst = this.args[0].compile(cc, false, true, ["rax"]);
			auto src = this.args[1].compile(cc, true, true, ["rbx", "rcx"]);

			cc.buf.writefln("\taddi %s, %s", dst, src);
			return dst;
		}

		throw new Exception("internal error: not implemented yet");
	}

	override string toString()
	{
		import std.format, std.array, std.algorithm, std.conv;
		return "(%s %s)".format(this.op, this.args.map!(to!string).join(" "));
	}
}
