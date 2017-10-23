import env, node, type, func;
 
// register compile-time built-in function
void registerCompileTimeBuiltin(Env env)
{
    env.registerFunc(new Func("+", [Type.Int, Type.Int], Type.Int, function(Node[] args)
    {
	auto a = cast(IntNode)args[0];
	auto b = cast(IntNode)args[1];
	return new IntNode(a.tok, a.v+b.v);
    }));
    env.registerFunc(new Func("+", [Type.Int, Type.Real], Type.Real, function(Node[] args)
    {
	auto a = cast(IntNode)args[0];
	auto b = cast(RealNode)args[1];
	return new RealNode(a.tok, a.v+b.v);
    }));
    env.registerFunc(new Func("+", [Type.Real, Type.Int], Type.Real, function(Node[] args)
    {
	auto a = cast(RealNode)args[0];
	auto b = cast(IntNode)args[1];
	return new RealNode(a.tok, a.v+b.v);
    }));
    env.registerFunc(new Func("+", [Type.Real, Type.Real], Type.Real, function(Node[] args)
    {
	auto a = cast(RealNode)args[0];
	auto b = cast(RealNode)args[1];
	return new RealNode(a.tok, a.v+b.v);
    }));

    env.registerFunc(new Func("*", [Type.Int, Type.Int], Type.Int, function(Node[] args)
    {
	auto a = cast(IntNode)args[0];
	auto b = cast(IntNode)args[1];
	return new IntNode(a.tok, a.v*b.v);
    }));
}
