// file name wants to be eval.d but it causes compile error


import std.algorithm;
import std.array;
import env, node, func, type;
import exception;
import builtin;

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
    return f.proc(env, args);
}

// entry point of compile time evaluation 
Node eval(Node root) {
    // initialize type and environment
    Type.init();
    Env env = new Env();
	env.registerType(Type.Int);
	env.registerType(Type.Real);
	env.registerType(Type.Void);

    registerCompileTimeBuiltin(env);

    // evaluate program
    return eval(root, env);
}


// evaulate variable declaration
void evalDecl(VarDeclBlockNode node, Env env)
{
	if (node is null) { return; }

	foreach (vardeclNode; node.vardeclNodes) {
		// get type from string
		auto t = env.getType(vardeclNode.typename);

		// unknown type
		if (t is null) {
			throw new TopiException("unknown type " ~ vardeclNode.typename, vardeclNode.tok.loc);
		}
		
		// registration
		env.registerVar(vardeclNode.varname, t.defaultValue());
	}
}

// evaluate node
Node eval(Node node, Env env) {
    debug writeln("evaluating:", node);

    // funciton call
    if (auto funcCallNode = cast(FuncCallNode)node) {
		// call function
		return call(funcCallNode, env);
    }

	// block node
	if (auto blockNode = cast(BlockNode)node) {
		// variable declaration
		evalDecl(blockNode.vardeclblockNode, env);

		// evaluating each exprs
		Node[] newNodes = [];
		foreach (n; blockNode.nodes) {
			newNodes ~= eval(n, env);
		}

		// replace old nodes to new nodes
		blockNode.nodes = newNodes;
	}

    // as-is node
    return node;
}
