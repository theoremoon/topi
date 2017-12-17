import node;
import token;

class Type {
private:
	this() @safe pure {
	    name = "";
		defaultExpr = null;
		isvar = false;
	};
	this(const Type t) @safe pure {
		this.name = t.name;
		this.defaultExpr = t.defaultExpr;
		this.isvar = t.isvar;
	}
public:
	alias defaultT = Node function();
	string name;
	defaultT defaultExpr;
	bool isvar;

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

	Type varType() {
		Type t = new Type(this);
		t.isvar = true;
		return t;
	}
	
	override string toString() {
	    string s = name;
		if (this.isvar) {
			return "&"~s;
		}
	    return s;
	}
}
