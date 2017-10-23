import std.algorithm;
import std.array;
import env, node, func, type;
import exception;

debug import std.stdio;

Node call(FuncCallNode funcCallNode, Env env) {
    Node[] args = [];
    foreach (arg; funcCallNode.args) {
	args ~= eval(arg, env);
    }
    Type[] types = [];
    foreach (arg; args) {
	types ~= arg.type;
    }
    string signature = Func.signature(funcCallNode.name, types);
    debug writeln("calling:", signature);
    Func f = env.getFunc(signature);
    if (f is null) {
	throw new TopiException("undefined function:" ~ signature, funcCallNode.tok.loc);
    }
    return f.proc(args);
}

Node eval(Node root) {
    Type.init();
    Env env = new Env();
    env.registerFunc(new Func("+", [Type.Int, Type.Int], Type.Int, function(Node[] args)
    {
	auto a = cast(IntNode)args[0];
	auto b = cast(IntNode)args[1];
	return new IntNode(a.tok, a.v+b.v);
    }));
    return eval(root, env);
}


Node eval(Node node, Env env) {
    debug writeln("evaluating:", node);
    if (auto funcCallNode = cast(FuncCallNode)node) {
	Node[] args = [];
	foreach (arg; funcCallNode.args) {
	    args ~= eval(arg, env);
	}
	return eval(call(funcCallNode, env), env);
    }
    return node;
}
