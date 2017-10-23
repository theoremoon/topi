// file name wants to be eval.d but it causes compile error


import std.algorithm;
import std.array;
import env, node, func, type;
import exception;

debug import std.stdio;

// call function
Node call(FuncCallNode funcCallNode, Env env) {
    // evaluate arguments
    Node[] args = [];
    foreach (arg; funcCallNode.args) {
	args ~= eval(arg, env);
    }

    // get argument types
    Type[] types = [];
    foreach (arg; args) {
	types ~= arg.type;
    }

    // get function signature and function object
    string signature = Func.signature(funcCallNode.name, types);
    debug writeln("calling:", signature);
    Func f = env.getFunc(signature);
    if (f is null) {
	throw new TopiException("undefined function:" ~ signature, funcCallNode.tok.loc);
    }

    // execute
    return f.proc(args);
}

// entry point of compile time evaluation 
Node eval(Node root) {
    // initialize type and environment
    Type.init();
    Env env = new Env();

    // register built-in compile-time function
    env.registerFunc(new Func("+", [Type.Int, Type.Int], Type.Int, function(Node[] args)
    {
	auto a = cast(IntNode)args[0];
	auto b = cast(IntNode)args[1];
	return new IntNode(a.tok, a.v+b.v);
    }));

    // evaluate program
    return eval(root, env);
}


// evaluate node
Node eval(Node node, Env env) {
    debug writeln("evaluating:", node);

    // funciton call
    if (auto funcCallNode = cast(FuncCallNode)node) {
	Node[] args = [];
	foreach (arg; funcCallNode.args) {
	    args ~= eval(arg, env);
	}

	// call function
	return call(funcCallNode, env);
    }

    // as-is node
    return node;
}
