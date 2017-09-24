import std.conv;
import std.array;
import std.format;
import std.algorithm;

import type;
import token;
import input : Location;
import exception;

abstract class Node {
    public:
	Token tok;
	this(Token tok) {
	    this.tok = tok;
	}
	abstract Type type();
	Location loc() { return tok.loc; }
}

class IntNode : Node {
    public:
	long v;
	this(Token tok, long v) {
	    super(tok);
	    this.v = v;
	}
	override Type type() { return Type.Int; }
	override string toString() { return v.to!string; }
}

class RealNode : Node {
    public:
	double v;
	this(Token tok, double v) {
	    super(tok);
	    this.v = v;
	}
	override Type type() { return Type.Real; }
	override string toString() { return v.to!string; }
}

class SymbolNode : Node {
    public:
	string name;
	this(Token tok) {
	    super(tok);
	    name = tok.str;
	}
	// FIXME
	override Type type() { return Type.Void; }
	override string toString() { return name; }
}


/// function object node. 
class FuncNode : Node {
    public:
	Func func;
	this(Func func) {
	    // funcnode will not appear in compile-time
	    super(null);
	    this.func = func;
	}
	bool is_constexpr() { return func.is_constexpr; } 
    
	override Type type(){ throw new Exception("functype is unimplemented"); }
	override string toString() { return func.signature; }
}

/// compile-time function call 
class CTFuncCallNode : Node {
    public:
	static fromToken(Token tok, Node[] args) {
	    auto symbol = new SymbolNode(tok);
	    return new CTFuncCallNode(symbol, args);
	}
	Node func;
	Node[] args;
	this(Node func, Node[] args) {
	    super(func.tok);
	    this.func = func;
	    this.args = args;
	}
	string signature() {
	    return "%s(%s)".format(func.to!string, args.map!(a => a.type.to!string).join(","));
	}
	/// REVIEW
	override Type type() {
	    if (auto funcNode = cast(FuncNode)func) {
		return funcNode.func.rettype;
	    }
	    throw new Exception("internal error: func is not FuncNode");
	}
	override string toString() { 
	    return "(%s %s)".format(func.to!string, args.map!(to!string).join(" "));
	}
}

/// function
class Func {
    public:
	string name;
	Type[] argtypes;
	Type rettype;
	bool isconstexpr;

	this(string name, Type[] argtypes, Type rettype, bool isconstexpr = false) {
	    if (name.length == 0) { throw new Exception("function name is required"); }
	    if (argtypes is null) { throw new Exception("argtypes is null"); }
	    if (rettype is null) { throw new Exception("rettype is null"); }

	    this.name = name;
	    this.argtypes = argtypes;
	    this.rettype = rettype;
	    this.isconstexpr = isconstexpr;
	}
	static string signature(string name, Node[] args) {
	    Type[] argtypes = [];
	    foreach (arg; args) { argtypes ~= arg.type; }
	    return signature(name, argtypes);
	}
	static string signature(string name, Type[] argtypes) {
	    return name~"("~argtypes.map!(to!string).join(",")~")";
	}
	string signature() { return Func.signature(name, argtypes); }
	bool is_constexpr() { return isconstexpr; }
}

/// built-in function
class BuiltinFunc : Func {
    public:
	/// return assembly which calling function
	alias CallT = string function(Node[]);
	/// function body
	alias ConstexprT = Node function(Node[], Env); 

	string emitstr;
	CallT callfunc;
	ConstexprT constexprFunc;

	this(string name, Type[] argtypes, Type rettype, string emitstr, CallT callfunc, ConstexprT constexprFunc) {
	    super(name, argtypes, rettype, constexprFunc !is null); 
	    this.emitstr = emitstr;
	    this.callfunc = callfunc;
	    this.constexprFunc = constexprFunc;
	}
}
class Env {
    public:
	Func[string] funcs;

	Func getFunc(string sign) {
	    if (sign in funcs) { return funcs[sign]; }
	    return null;
	}
	bool registerFunc(Func f) {
	    if (getFunc(f.signature) !is null) { return false; }
	    funcs[f.signature] = f;
	    return true;
	}
}

FuncNode getFunc(Node node, Node[] args, Env env) {
    // args is already evaluated
    if (auto func = cast(FuncNode)node) { return func; }
    if (auto symbolNode = cast(SymbolNode)node) {
	Func func = env.getFunc(Func.signature(symbolNode.name, args));
	if (func is null) { return null; }
	return new FuncNode(func);
    }
    return null;
}

Node call(Func func, Node[] args, Env env) {
    // func should be constexpr 
    // args is already evaluated
    import std.stdio;
    writeln("[*]func is ", typeid(func));
    if (auto builtin = cast(BuiltinFunc)func) {
	return builtin.constexprFunc(args, env);
    }
    throw new Exception("internal error: call for func is unimplemented");
}

Node eval(Node node) {
    Env env = new Env();
    env.registerFunc(new BuiltinFunc("print", [Type.Int], Type.Void, "", null, null));
    env.registerFunc(new BuiltinFunc("+", [Type.Int, Type.Int], Type.Int, "", null, function(Node[] args, Env env) {
	if (auto intA = cast(IntNode)args[0]) {
	    if (auto intB = cast(IntNode)args[1]) {
	    return new IntNode(null, intA.v + intB.v);
	    }
	}
	throw new Exception("invalid arguments: "~args.to!string);
    }));
    return node.eval(env);
}
Node eval(Node node, Env env) {
    if (auto funcCallNode = cast(CTFuncCallNode)node) {
	// evaluate arguments
	Node[] evaledArgs = [];
	foreach (arg; funcCallNode.args) {
	    evaledArgs ~= arg.eval(env);
	}

	// get function object from funcCallNode.func
	auto funcNode = getFunc(funcCallNode.func, evaledArgs, env);
	if (funcNode is null) {
	    throw new TopiException("%s is not a function".format(funcNode.to!string), funcCallNode.loc); 
	}
	if (funcNode.is_constexpr) {
	    return funcNode.func.call(evaledArgs, env);
	}
	return new CTFuncCallNode(funcNode, evaledArgs);
    }
    if (auto symbolNode = cast(SymbolNode)node) {
	throw new TopiException("unknown name %s".format(symbolNode.to!string), symbolNode.loc);
    }
    // primitive
    return node;
}
