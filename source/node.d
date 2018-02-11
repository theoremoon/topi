/// node module. node makes AST
module node;

import token;
import ssanode;

/// parent class of all Node
abstract class Node
{
public:
	Store store;   /// in memory, this value is here
	this(Token tok)
	{
		this.tok = tok;
	}
	abstract SSASymbol knormalize(ref SSANode[]);   /// k normalize 
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

	override SSASymbol knormalize(ref SSANode[] ssaNodes) {
		auto sym = SSASymbol.create(this.tok);
		ssaNodes ~= new SSAInt(sym, this.v);
		return sym;
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

	override SSASymbol knormalize(ref SSANode[] ssaNodes) {
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
class FuncallNode : Node
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

	override SSASymbol knormalize(ref SSANode[] ssaNodes) {
		import std.algorithm, std.array;
		SSASymbol[] argSyms = []; 
		foreach (arg; this.args) {
			argSyms ~= arg.knormalize(ssaNodes);
		}

		auto sym = SSASymbol.create(tok);
		ssaNodes ~= new SSAFuncall(sym, this.op, argSyms);
		return sym;
	}

	override string toString()
	{
		import std.format, std.array, std.algorithm, std.conv;
		return "(%s %s)".format(this.op, this.args.map!(to!string).join(" "));
	}
}
