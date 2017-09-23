import std.outbuffer;

import asmstate;
import env;
import func;
import node;
import type;

void emit_int(Node node) {
    if (node.type is Type.Int) {
        node.emit;
    }
    else if (auto realNode = cast(RealNode)node) {
        auto intNode = new IntNode(cast(long)realNode.v);
        intNode.emit;
    }
    else if (node.type is Type.Real) {
        node.emit;
        Env.cur.state.write("cvtsd2si rax, xmm0");
    }
    else {
        throw new Exception("unimplemented");
    }
}
void emit_real(Node node) {
    if (node.type is Type.Real) {
        node.emit;
    }
    else if (auto intNode = cast(IntNode)node) {
        auto realNode = new RealNode(cast(double)intNode.v);
        realNode.emit;
    }
    else if (node.type is Type.Int) {
        node.emit;
        Env.cur.state.write("cvtsi2sd xmm0, rax");
    }
    else {
        throw new Exception("unimplemented");
    }
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
    succeeded = env.registerFunc(new BuiltinFunc("+", [Type.Int, Type.Int], Type.Int, null, int_add));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("+", [Type.Int, Type.Real], Type.Real, null, real_add));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("+", [Type.Real, Type.Int], Type.Real, null, real_add));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("+", [Type.Real, Type.Real], Type.Real, null, real_add));
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
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Int, Type.Int], Type.Int, null, int_sub));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Real, Type.Int], Type.Real, null, real_sub));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Int, Type.Real], Type.Real, null, real_sub));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Real, Type.Real], Type.Real, null, real_sub));
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
    succeeded = env.registerFunc(new BuiltinFunc("*", [Type.Int, Type.Int], Type.Int, null, int_imul));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("*", [Type.Real, Type.Int], Type.Real, null, real_imul));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("*", [Type.Int, Type.Real], Type.Real, null, real_imul));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("*", [Type.Real, Type.Real], Type.Real, null, real_imul));
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
    succeeded = env.registerFunc(new BuiltinFunc("/", [Type.Int, Type.Int], Type.Int, null, int_idiv));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("/", [Type.Real, Type.Int], Type.Real, null, real_idiv));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("/", [Type.Int, Type.Real], Type.Real, null, real_idiv));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("/", [Type.Real, Type.Real], Type.Real, null, real_idiv));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }

    // assign
    auto int_assign = function(Node[] args, AsmState state) {
	throw new Exception("unimplemented");
    };
    succeeded = env.registerFunc(new BuiltinFunc("=", [Type.Int, Type.Int], Type.Int, null, int_assign));
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
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Int], Type.Int, null, int_neg));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = env.registerFunc(new BuiltinFunc("-", [Type.Real], Type.Real, null, real_neg));
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
