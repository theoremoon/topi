import std.conv;

import token;

abstract class Node {
    public:
	Token tok;
	this(Token tok) { 
	    this.tok = tok;
	}
}
class IntNode : Node {
    public:
	long v;
	this(Token tok, long v) {
	    super(tok);
	    this.v = v;
	}
	override string toString() {
	    return v.to!string;
	}
} 
