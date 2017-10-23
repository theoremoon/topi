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
	abstract Type type();
}
class IntNode : Node {
    public:
	long v;
	this(Token tok, long v) {
	    super(tok);
	    this.v = v;
	}
	override Type type() { return Type.Int; }
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
	override Type type() { return Type.Real; }
	override string toString() {
	    return v.to!string;
	}
}
class FuncCallNode : Node {
    public:
	string name;
	Node[] args;
	this(Token tok, string name, Node[] args) {
	    super(tok);
	    this.name = name;
	    this.args = args;
	}
	override Type type() { return Type.Void; }
	override string toString() {
	    return "(%s %s)".format(name, args.map!(to!string).join(" "));
	}
}
