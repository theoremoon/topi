import type;

class Var {
    Type type;
    string name;
    this (Type type, string name) {
	this.type = type;
	this.name = name;
    }
    override string toString() { return name; }
}
