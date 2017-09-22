import std.outbuffer;

import asmstate;
import env;
import func;
import node;
import type;

string bin_constexpr(string name, string op) {
    return "Node " ~ name ~ `(T1, T2, T3)(Node[] args) {
		if (auto arg1 = cast(T1)(args[0].eval)) {
		    if (auto arg2 = cast(T2)(args[1].eval)) {
			return new T3(arg1.v ` ~ op ~` arg2.v);
		    } 
		}
		throw new Exception("Internal Error");
	    }`;
}

mixin (bin_constexpr("add_constexpr", "+"));
mixin (bin_constexpr("sub_constexpr", "-"));
mixin (bin_constexpr("imul_constexpr", "*"));
mixin (bin_constexpr("idiv_constexpr", "/"));

Node neg_constexpr(T1)(Node[] args) {
    if (auto arg1 = cast(T1)(args[0].eval)) {
	return new T1(-arg1.v);
    }
    throw new Exception("Internal Error");
}



void register_builtin(Env env) {
    bool succeeded;

    //add
    auto int_add = function(Node[] args, AsmState state) {
	args[0].emit_int;
	state.write("push rax");
	args[1].emit_int;
	state.write("mov rcx,rax");
	state.write("pop rax");
	state.write("add rax,rcx");
    };
    auto real_add = function(Node[] args, AsmState state) {
	args[0].emit_real;
	state.write("sub rsp,0x8");
	state.write("movsd [rsp],xmm0");
	args[1].emit_real;
	state.write("movsd xmm1,xmm0");
	state.write("movsd xmm0,[rsp]");
	state.write("add rsp,0x8");
	state.write("addsd xmm0,xmm1");
    };
    succeeded = env.registerFunc(new BuiltinFunc("+", [Type.Int, Type.Int], Type.Int, null, int_add, &add_constexpr!(IntNode, IntNode, IntNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("+", [Type.Int, Type.Real], Type.Real, null, real_add, &add_constexpr!(IntNode, RealNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("+", [Type.Real, Type.Int], Type.Real, null, real_add, &add_constexpr!(RealNode, IntNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("+", [Type.Real, Type.Real], Type.Real, null, real_add, &add_constexpr!(RealNode, RealNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }

    // sub
    auto int_sub = function(Node[] args, AsmState state) {
	args[0].emit_int;
	state.write("push rax");
	args[1].emit_int;
	state.write("mov rcx,rax");
	state.write("pop rax");
	state.write("sub rax,rcx");
    };
    auto real_sub = function(Node[] args, AsmState state) {
	args[0].emit_real;
	state.write("sub rsp,0x8");
	state.write("movsd [rsp],xmm0");
	args[1].emit_real;
	state.write("movsd xmm1,xmm0");
	state.write("movsd xmm0,[rsp]");
	state.write("add rsp,0x8");
	state.write("subsd xmm0,xmm1");
    };
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Int, Type.Int], Type.Int, null, int_sub, &sub_constexpr!(IntNode, IntNode, IntNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Real, Type.Int], Type.Real, null, real_sub, &sub_constexpr!(RealNode, IntNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Int, Type.Real], Type.Real, null, real_sub, &sub_constexpr!(IntNode, RealNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Real, Type.Real], Type.Real, null, real_sub, &sub_constexpr!(RealNode, RealNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }

    // imul
    auto int_imul = function(Node[] args, AsmState state) {
	args[0].emit_int;
	state.write("push rax");
	args[1].emit_int;
	state.write("mov rcx,rax");
	state.write("pop rax");
	state.write("imul rcx");
    };
    auto real_imul = function(Node[] args, AsmState state) {
	args[0].emit_real;
	state.write("sub rsp,0x8");
	state.write("movsd [rsp],xmm0");
	args[1].emit_real;
	state.write("movsd xmm1,xmm0");
	state.write("movsd xmm0,[rsp]");
	state.write("add rsp,0x8");
	state.write("mulsd xmm0,xmm1");
    };
    succeeded = env.registerFunc(new BuiltinFunc("*", [Type.Int, Type.Int], Type.Int, null, int_imul, &imul_constexpr!(IntNode, IntNode, IntNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("*", [Type.Real, Type.Int], Type.Real, null, real_imul, &imul_constexpr!(RealNode, IntNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("*", [Type.Int, Type.Real], Type.Real, null, real_imul, &imul_constexpr!(IntNode, RealNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("*", [Type.Real, Type.Real], Type.Real, null, real_imul, &imul_constexpr!(RealNode, RealNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }

    // idiv
    auto int_idiv = function(Node[] args, AsmState state) {
	args[0].emit_int;
	state.write("push rax");
	args[1].emit_int;
	state.write("mov rbx,rax");
	state.write("pop rax");
	state.write("xor rdx,rdx");
	state.write("idiv rbx");
    };
    auto real_idiv = function(Node[] args, AsmState state) {
	args[0].emit_real;
	state.write("sub rsp,0x8");
	state.write("movsd [rsp],xmm0");
	args[1].emit_real;
	state.write("movsd xmm1,xmm0");
	state.write("movsd xmm0,[rsp]");
	state.write("add rsp,0x8");
	state.write("divsd xmm0,xmm1");
    };
    succeeded = env.registerFunc(new BuiltinFunc("/", [Type.Int, Type.Int], Type.Int, null, int_idiv, &idiv_constexpr!(IntNode, IntNode, IntNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("/", [Type.Real, Type.Int], Type.Real, null, real_idiv, &idiv_constexpr!(RealNode, IntNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("/", [Type.Int, Type.Real], Type.Real, null, real_idiv, &idiv_constexpr!(IntNode, RealNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("/", [Type.Real, Type.Real], Type.Real, null, real_idiv, &idiv_constexpr!(RealNode, RealNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }

    // neg
    auto int_neg = function(Node[] args, AsmState state) {
	args[0].emit_int;
	state.write("neg rax");
    };
    auto real_neg = function(Node[] args, AsmState state) {
	args[0].emit_real;
	state.write("movsd xmm1,xmm0");
	state.write("xorps xmm0,xmm0");
	state.write("subsd xmm0,xmm1");
    };
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Int], Type.Int, null, int_neg, &neg_constexpr!(IntNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Real], Type.Real, null, real_neg, &neg_constexpr!(RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }

    // print
    succeeded = env.registerFunc(new BuiltinFunc("print", [Type.Int], Type.Void, null, function(Node[] args, AsmState state) {
	args[0].emit_int;
	state.write("mov rdi,rax");
	state.write("call print_int");
    }));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("print", [Type.Real], Type.Void, null, function(Node[] args, AsmState state) {
	args[0].emit_real;
	state.write("call print_real");
    }));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
}
