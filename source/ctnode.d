import std.conv;
import std.array;
import std.algorithm;

import node;

/// compile-time type
enum CTType {
    INT,
    REAL,
    SYMBOL,
    FUNC,
    LIST,
}
/// compile-time node
class CTNode {
    public:
	CTType type = CTType.LIST;
	CTNode[] elements = []; 
	this(CTNode[] elements = []) {
	    this.elements = elements;
	}
}

class CTInt : CTNode {
    public:
	long v;
	this(long v) {
	    type = CTType.INT;
	    this.v = v;
	}
}
class CTReal : CTNode {
    public:
	double v;
	this(double v) {
	    type = CTType.REAL;
	    this.v = v;
	}
}

class CTSymbol : CTNode {
    public:
	string name;
	this(string name) {
	    type = CTType.SYMBOL;
	    this.name = name;
	}
}

class CTFunc : CTNode {
    public:
	string[] params;
	CTNode proc;

	this(string[] params, CTNode proc) {
	    type = CTType.FUNC;
	    this.params = params;
	    this.proc = proc;
	}
}

alias CTEnv = CTNode[string];
alias CTBuiltinFunc = CTNode function(CTNode[], CTEnv);
class CTBuiltin : CTFunc {
    public:
	CTBuiltinFunc func;
	this (CTBuiltinFunc func) {
	    super([], null);
	    this.func = func;
	}
}

CTNode ct_funccall(string fname, CTNode[] args) {
    CTNode fsymbol = new CTSymbol(fname);
    return new CTNode([fsymbol] ~ args);
}

string ctbuiltin_binop(string op) {
    return `
    if (args.length != 2) { throw new Exception("internal error"); }
    auto a = args[0].eval(env);
    auto b = args[1].eval(env);
    auto intA = cast(CTInt)a;
    auto intB = cast(CTInt)b;
    auto realA = cast(CTReal)a;
    auto realB = cast(CTReal)b;

    if (intA !is null && intB !is null) {
	return new CTInt(intA.v` ~ op ~ `intB.v);
    }
    if (realA !is null && intB !is null) {
	return new CTReal(realA.v` ~ op ~ `cast(double)intB.v);
    }
    if (intA !is null && realB !is null) {
	return new CTReal(cast(double)(intA.v)` ~ op ~ `realB.v);
    }
    if (realA !is null && realB !is null) {
	return new CTReal(realA.v` ~ op ~ `realB.v);
    }
    throw new Exception("invalid arguments: ", args.to!string);
`;
}
CTNode ctbuiltin_add(CTNode[] args, CTEnv env) {
    mixin(ctbuiltin_binop("+"));
}
CTNode ctbuiltin_sub(CTNode[] args, CTEnv env) {
    if (args.length == 1) {
	auto a = args[0].eval(env);
	if (auto intA = cast(CTInt)a) {
	    return new CTInt(-intA.v);
	}
	else if (auto realA = cast(CTReal)a) {
	    return new CTReal(-realA.v);
	}
	throw new Exception("invalid arguments: ", args.to!string);
    }
    mixin(ctbuiltin_binop("-"));
}
CTNode ctbuiltin_mul(CTNode[] args, CTEnv env) {
    mixin(ctbuiltin_binop("*"));
}
CTNode ctbuiltin_div(CTNode[] args, CTEnv env) {
    mixin(ctbuiltin_binop("/"));
}

CTEnv ct_init() {
    CTEnv env;
    env["+"] = new CTBuiltin(&ctbuiltin_add);
    env["-"] = new CTBuiltin(&ctbuiltin_sub);
    env["*"] = new CTBuiltin(&ctbuiltin_mul);
    env["/"] = new CTBuiltin(&ctbuiltin_div);
    env["print"] = new CTSymbol("print");
    
    return env;
}

/// call function in compile-time
CTNode call(CTFunc func, CTNode[] args, CTEnv env) {
    if (auto builtin = cast(CTBuiltin)func) {
	return builtin.func(args, env);
    }
    throw new Exception("unimplemented non builtin function");
}

/// evaluate compile-time node
CTNode eval(CTNode node, CTEnv env) {
    if (node.type == CTType.LIST) {
	if (node.elements.length == 0) { 
	    throw new Exception("nil is unimplemented");
	}
	CTNode val = node.elements[0].eval(env);
	if (auto func = cast(CTFunc)val) {
	    return func.call(node.elements[1..$], env);
	}
	// non-constexpr function call
	if (auto symbol = cast(CTSymbol)val) {
	    return ct_funccall(symbol.name, node.elements[1..$].map!(e => e.eval(env)));
	}

	throw new Exception("unimplemented eval for list");
    }
    else if (node.type == CTType.INT) {
	return node;
    }
    else if (node.type == CTType.REAL) {
	return node;
    }
    else if (auto symbol = cast(CTSymbol)node) {
	if (symbol.name in env) { return env[symbol.name]; }
    }
    throw new Exception("unknow node type: " ~ node.type.to!string);
}

/// convert to node
Node toNode(CTNode node) {
    if (node.type == CTType.LIST) {
	if (node.elements.length == 0) { 
	    throw new Exception("nil is unimplemented");
	}
	// non-constexpr function call
	if (auto symbol = cast(CTSymbol)(node.elements[0])) {
	    return new FuncCallNode(symbol.name, node.elements[1..$].map!(e => e.toNode));
	}
    }
    else if (auto intNode = cast(CTInt)node) {
	return new IntNode(intNode.v);
    }
    else if (auto realNode = cast(CTReal)node) {
	return new RealNode(realNode.v);
    }
    throw new Exception("unknow node type: " ~ node.type.to!string);
}
