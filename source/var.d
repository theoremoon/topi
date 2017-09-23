import type;
import node;
import register;

class Var {
    Type type;
    string name;
    Register reg = null;
    Node constexprNode = null;

    this (Type type, string name) {
	this.type = type;
	this.name = name;
    }

    override string toString() { return name; }
}
