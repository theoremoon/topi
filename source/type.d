import node;
import token;

class Type {
private:
	this() {
	    name = "";
		defaultExpr = null;
	};
public:
	alias defaultT = Node function();
	string name;
	defaultT defaultExpr;

	static Type Int;
	static Type Real;
	static Type Void;
	
	static Type primitive(string name, defaultT defaultExpr) {
	    Type t = new Type();
	    t.name = name;
		t.defaultExpr = defaultExpr;
	    return t;
	}
	static void init() {
	    Int = primitive("Int", () => new IntNode(Token.Dummy(), cast(long)0));
	    Real = primitive("Real", () => new RealNode(Token.Dummy(), 0.0));
	    Void = primitive("Void", () => new NilNode(Token.Dummy()));
	}

	Node defaultValue() {
		return defaultExpr();
	}
	
	override string toString() {
	    string s = name;
	    return s;
	}
}
