/// node module. node makes AST
module node;


import token;

/// parent class of all Node
abstract class Node
{
public:
	this(Token tok)
	{
		this.tok = tok;
	}
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

	override string toString()
	{
		import std.format, std.array, std.algorithm, std.conv;
		return "(%s %s)".format(this.op, this.args.map!(to!string).join(" "));
	}
}
