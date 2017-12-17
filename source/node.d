import std.conv;
import std.array;
import std.algorithm;
import std.format;

import token;
import type;
import env;
import func;
import exception;


abstract class Node {
    public:
	Token tok;
	this(Token tok) { 
	    this.tok = tok;
	}
	abstract Type type(Env);
	Node asRvalue(Env) { return this; }
	void setValue(Env, Node) { throw new TopiException("this is not lvalue %s".format(tok.str), tok.loc); }
}
class NilNode : Node {
public:
	this(Token tok) {
		super(tok);
	}
	override Type type(Env) { return Type.Void; }
	override string toString() {
	    return "nil";
	}
}
class IntNode : Node {
    public:
	long v;
	this(Token tok, long v) {
	    super(tok);
	    this.v = v;
	}
	override Type type(Env) { return Type.Int; }
	override string toString() {
	    return v.to!string;
	}
} 
class RealNode : Node {
    public:
	double v;
	this(Token tok, double v) {
	    super(tok);
	    this.v = v;
	}
	override Type type(Env) { return Type.Real; }
	override string toString() {
	    return v.to!string;
	}
}

class SymbolNode : Node
{
public:
	string name;
	this(Token tok, string name) {
		super(tok);
		this.name = name;
	}

	override Type type(Env env) {
		return env.getVar(name).type(env).varType();
	}

	override string toString() {
		return this.name;
	}

	override Node asRvalue(Env env) { 
		return env.getVar(name).asRvalue(env);
	}
	override void setValue(Env env, Node node) {
		auto ltype = this.asRvalue(env).type(env);
		auto rtype = node.type(env);
		if (ltype != rtype) {
			throw new TopiException("cannot assign type for %s to %s".format(ltype.toString(), rtype.toString()),
					tok.loc);
		}
		env.setVar(this.name, node);
	}
}

// function call node
class FuncCallNode : Node {
    public:
	string name;
	Node[] args;
	this(Token tok, string name, Node[] args) {
	    super(tok);
	    this.name = name;
	    this.args = args;
	}
	override Type type(Env env) {
		throw new Exception("Unimplemented yet");
	}
	override string toString() {
	    return "(%s %s)".format(name, args.map!(to!string).join(" "));
	}
}

// variable declaration
class VarDeclNode : Node {
    public:
	string typename;
	string varname;
	this(Token tok, string typename, string varname) {
	    super(tok);
	    this.typename = typename;
	    this.varname = varname;
	}
	override Type type(Env) { throw new TopiException("VarDeclNode is not a Expression", tok.loc); }
	override string toString() {
	    return "(%s %s)".format(typename, varname);
	}
}

class VarDeclBlockNode : Node {
    public:
	VarDeclNode[] vardeclNodes;
	this(Token tok, VarDeclNode[] vardeclNodes) {
	    super(tok);
	    this.vardeclNodes = vardeclNodes;
	}
	override Type type(Env) { throw new TopiException("VarDeclBlockNode is not a Expression", tok.loc); }
	override string toString() {
	    return "[%s]".format(vardeclNodes.map!(to!string).join(" ").array);
	}
}

class BlockNode : Node {
    public:
	VarDeclBlockNode vardeclblockNode;
	Node[] nodes;
	this(Token tok, VarDeclBlockNode vardeclblockNode, Node[] nodes) {
	    super(tok);
	    this.vardeclblockNode = vardeclblockNode;
	    this.nodes = nodes;
	}
	override Type type(Env) { throw new TopiException("BlockNode is not a Expression", tok.loc); }
	override string toString() {
	    string declStr = "";
	    if (vardeclblockNode !is null) { declStr = vardeclblockNode.to!string; }

	    string nodesStr = "{%s}".format(nodes.map!(to!string).join(" ").array);
	    return declStr ~ nodesStr;
	}
}
