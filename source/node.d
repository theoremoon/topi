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

class CTVarNode : Node {
    public:
	string name;
	Node val;
	this(string name, Node val) {
	    super(null);
	    this.name = name;
	    this.val = val;
	}
	override Type type() { return val.type; }
	override string toString() { 
	    return "%s[=%s]".format(name, val.to!string);
	}
}

/// variable delcaration
class CTDeclNode : Node {
    public:
	string typename;
	string varname;

	this (Token typename, Token varname) {
	    super(varname);
	    this.typename = typename.str;
	    this.varname = varname.str;
	}
	override Type type() { return Type.Void; }
	override string toString() {
	    return "(decl %s %s)".format(typename, varname);
	}

}

class CTDeclBlock : Node {
    public:
	CTDeclNode[] decls;

        this(CTDeclNode[] decls) {
	    super(null);
            this.decls = decls;
        }
        this(CTDeclBlock[] decls) {
	    super(null);
            this.decls = [];
            foreach (decl; decls) {
                this.decls ~= decl.decls;
            }
        } 
	override Type type() { return Type.Void; }
	override string toString() {
	    return decls.map!(to!string).join(" ");
	}
}

class CTBlockNode : Node {
    public:
	CTDeclBlock declBlock;
	Node[] nodes;

        this(Node[] nodes, CTDeclBlock declBlock) {
	    super(null);
            this.declBlock = declBlock;
            this.nodes = nodes;
        }
	override Type type() { return Type.Void; }
	override string toString() {
	    return "(%s\n%s\n)".format(declBlock.to!string, nodes.map!(to!string).join("\n"));
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

	// allowing conversion rvalue -> lvalue 
	bool same_rvalue_signature(string name, Type[] argtypes) {
	    if (this.name != name) { return false; }
	    if (this.argtypes.length != argtypes.length) { return false; }
	    foreach (i; 0..(this.argtypes.length)) {
		if (!this.argtypes[i].same_rvalue(argtypes[i])) { return false; }
	    }
	    return true;
	}
	// ignoring is_lvalue
	bool same_signature(string name, Type[] argtypes) {
	    if (this.name != name) { return false; }
	    if (this.argtypes.length != argtypes.length) { return false; }
	    foreach (i; 0..(this.argtypes.length)) {
		if (!this.argtypes[i].same_signature(argtypes[i])) { return false; }
	    }
	    return true;
	}

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
	Func[] funcs;
	Node[string] vars;
	Type[string] types;

	// allowing conversion rvalue -> lvalue 
	Func getFunc(string fname, Type[] argtypes) {
	    foreach (f; funcs) {
		if (f.same_rvalue_signature(fname, argtypes))  { return f; }
	    }
	    return null;
	}
	// ignoring is_lvalue
	Func strictGetFunc(string fname, Type[] argtypes) {
	    foreach (f; funcs) {
		if (f.same_signature(fname, argtypes)) { return f; }
	    }
	    return null;
	}
	bool registerFunc(Func f) {
	    if (strictGetFunc(f.name, f.argtypes)) { return false; }
	    funcs ~= f;
	    return true;
	}

	Node getVar(string name) {
	    if (name in vars) { return vars[name]; }
	    return null;
	}
	bool registerVar(string name, Node var) {
	    if (name in vars) { return false; }
	    vars[name] = var;
	    return true;
	}

	Type getType(string name) {
	    if (name in types) { return types[name]; }
	    return null;
	}
	bool registerType(Type t) {
	    if (t.to!string in types) { return false; }
	    types[t.to!string] = t;
	    return true;
	}
}

FuncNode getFunc(Node node, Node[] args, Env env) {
    // args is already evaluated
    if (auto func = cast(FuncNode)node) { return func; }
    if (auto symbolNode = cast(SymbolNode)node) {
	Type[] argtypes = [];
	foreach (arg; args) { argtypes ~= arg.type; }
	Func func = env.getFunc(symbolNode.name, argtypes);
	if (func is null) { return null; }
	return new FuncNode(func);
    }
    return null;
}

Node call(Func func, Node[] args, Env env) {
    // func should be constexpr 
    // args is already evaluated
    if (auto builtin = cast(BuiltinFunc)func) {
	return builtin.constexprFunc(args, env);
    }
    throw new Exception("internal error: call for func is unimplemented");
}

Node defaultValue(Type t) {
    if (t == Type.Int) {
	return new IntNode(null, 0);
    }
    if (t == Type.Real) {
	return new RealNode(null, 0);
    }
    throw new Exception("defaultValue for %s is unimplemented".format(t.to!string));
}

/// variable declaration
void declVars(CTDeclBlock declBlock, Env env) {
    foreach (decl; declBlock.decls) {
	auto t = env.getType(decl.typename);
	if (t is null) {
	    throw new TopiException("Invalid type " ~ decl.typename, decl.loc);
	}
	// FIXME: defualt value
	env.registerVar(decl.varname, t.defaultValue);
    }
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
    env.registerFunc(new BuiltinFunc("=", [Type.Int, Type.Int], Type.Int, "", null, function(Node[] args, Env env) {
	if (auto intA = cast(IntNode)args[0]) {
	    if (auto intB = cast(IntNode)args[1]) {
	    return new IntNode(null, intA.v + intB.v);
	    }
	}
	throw new Exception("invalid arguments: "~args.to!string);
    }));

    env.registerType(Type.Int); 
    env.registerType(Type.Real); 
    env.registerType(Type.Void); 
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
    if (auto blockNode = cast(CTBlockNode)node) {
	blockNode.declBlock.declVars(env);

	// evaluate body
	Node[] evaledNodes = [];
	foreach (node2; blockNode.nodes) {
	    evaledNodes ~= node2.eval(env);
	}

	return new CTBlockNode(evaledNodes, blockNode.declBlock);
    }
    if (auto symbolNode = cast(SymbolNode)node) {
	auto var = env.getVar(symbolNode.name);
	if (var is null) {
	    throw new TopiException("unknown name %s".format(symbolNode.to!string), symbolNode.loc);
	}
	return var;
    }
    // primitive
    return node;
}
