module ssanode;

import token;

/// k-normalized node
/// left = expr 
/// (strictly this is not a SSA form, but this is k-normalized form)
abstract class SSANode
{
public:
	SSASymbol sym;
	this(SSASymbol sym)
	{
		this.sym = sym;
	}
}

/// symbol.
/// left-hand argument
class SSASymbol
{
private:
	static SSASymbol[string] symbols;
	static uint id = 0;


	this(Token tok)
	{
		import std.format;
		this.name = "$%d".format(this.id);
		this.id++;
		this.tok = tok;
		this.symbols[this.name] = this;
	}
	this(Token tok, string name)
	{
		this.tok = tok;
		this.name = name;
		this.symbols[this.name] = this;
	}
public:
	string name;
	Token tok;

	/// create temporary symbol
	static SSASymbol create(Token tok)
	{
		return new SSASymbol(tok);
	}

	/// create or get named symbol
	static SSASymbol create(Token tok, string name)
	{
		if (auto sym = name in this.symbols) {
			return *sym;
		}
		return new SSASymbol(tok, name);
	}

	override string toString()
	{
		return this.name;
	}
}

/// immidiate integer
class SSAInt : SSANode
{
public:
	long v;
	this(SSASymbol sym, long v)
	{
		super(sym);
		this.v = v;
	}

	override string toString()
	{
		import std.format;
		return "%s = %d".format(this.sym, this.v);
	}
}

/// function call (or operator)
class SSAFuncall : SSANode
{
public:
	string name;
	SSASymbol[] args;
	this(SSASymbol sym, string name, SSASymbol[] args)
	{
		super(sym);
		this.name = name;
		this.args = args;
	}

	override string toString()
	{
		import std.format, std.array, std.algorithm, std.conv;
		return "%s = (%s %s)".format(this.sym.to!string(), this.name, this.args.map!(a => a.to!string()).join(" "));
	}
}
