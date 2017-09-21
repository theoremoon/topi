import std.outbuffer;

import func;
import node;
import type;

Node add_constexpr(T1, T2, T3)(Node[] args) {
    if (auto arg1 = cast(T1)(args[0].eval)) {
	if (auto arg2 = cast(T2)(args[1].eval)) {
	    return new T3(arg1.v + arg2.v);
	} 
    }
    throw new Exception("Internal Error");
}


void register_builtin() {
    bool succeeded;
    //add
    
    auto int_add = function(Node[] args, OutBuffer o) {
	args[0].emit_int(o);
	o.write("\tpush rax\n");
	args[1].emit_int(o);
	o.write("\tmov rcx,rax\n");
	o.write("\tpop rax\n");
	o.write("\tadd rax,rcx\n");
    };
    auto real_add = function(Node[] args, OutBuffer o) {
	args[0].emit_real(o);
	o.write("\tsub rsp,0x8\n");
	o.write("\tmovsd [rsp],xmm0\n");
	args[1].emit_real(o);
	o.write("\tmovsd xmm1,xmm0\n");
	o.write("\tmovsd xmm0,[rsp]\n");
	o.write("\tadd rsp,0x8\n");
	o.write("\taddsd xmm0,xmm1\n");
    };
    succeeded = Func.register(new BuiltinFunc("+", [Type.Int, Type.Int], Type.Int, null, int_add, &add_constexpr!(IntNode, IntNode, IntNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("+", [Type.Int, Type.Real], Type.Real, null, real_add, &add_constexpr!(IntNode, RealNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("+", [Type.Real, Type.Int], Type.Real, null, real_add, &add_constexpr!(RealNode, IntNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("+", [Type.Real, Type.Real], Type.Real, null, real_add, &add_constexpr!(RealNode, RealNode, RealNode)));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }

    // sub
    auto int_sub = function(Node[] args, OutBuffer o) {
	args[0].emit_int(o);
	o.write("\tpush rax\n");
	args[1].emit_int(o);
	o.write("\tmov rcx,rax\n");
	o.write("\tpop rax\n");
	o.write("\tsub rax,rcx\n");
    };
    auto real_sub = function(Node[] args, OutBuffer o) {
	args[0].emit_real(o);
	o.write("\tsub rsp,0x8\n");
	o.write("\tmovsd [rsp],xmm0\n");
	args[1].emit_real(o);
	o.write("\tmovsd xmm1,xmm0\n");
	o.write("\tmovsd xmm0,[rsp]\n");
	o.write("\tadd rsp,0x8\n");
	o.write("\tsubsd xmm0,xmm1\n");
    };
    succeeded = Func.register(new BuiltinFunc("-", [Type.Int, Type.Int], Type.Int, null, int_sub));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("-", [Type.Real, Type.Int], Type.Real, null, real_sub));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("-", [Type.Int, Type.Real], Type.Real, null, real_sub));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("-", [Type.Real, Type.Real], Type.Real, null, real_sub));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }

    // imul
    auto int_imul = function(Node[] args, OutBuffer o) {
	args[0].emit_int(o);
	o.write("\tpush rax\n");
	args[1].emit_int(o);
	o.write("\tmov rcx,rax\n");
	o.write("\tpop rax\n");
	o.write("\timul rcx\n");
    };
    auto real_imul = function(Node[] args, OutBuffer o) {
	args[0].emit_real(o);
	o.write("\tsub rsp,0x8\n");
	o.write("\tmovsd [rsp],xmm0\n");
	args[1].emit_real(o);
	o.write("\tmovsd xmm1,xmm0\n");
	o.write("\tmovsd xmm0,[rsp]\n");
	o.write("\tadd rsp,0x8\n");
	o.write("\tmulsd xmm0,xmm1\n");
    };
    succeeded = Func.register(new BuiltinFunc("*", [Type.Int, Type.Int], Type.Int, null, int_imul));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("*", [Type.Real, Type.Int], Type.Real, null, real_imul));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("*", [Type.Int, Type.Real], Type.Real, null, real_imul));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("*", [Type.Real, Type.Real], Type.Real, null, real_imul));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }

    // idiv
    auto int_idiv = function(Node[] args, OutBuffer o) {
	args[0].emit_int(o);
	o.write("\tpush rax\n");
	args[1].emit_int(o);
	o.write("\tmov rbx,rax\n");
	o.write("\tpop rax\n");
	o.write("\txor rdx,rdx\n");
	o.write("\tidiv rbx\n");
    };
    auto real_idiv = function(Node[] args, OutBuffer o) {
	args[0].emit_real(o);
	o.write("\tsub rsp,0x8\n");
	o.write("\tmovsd [rsp],xmm0\n");
	args[1].emit_real(o);
	o.write("\tmovsd xmm1,xmm0\n");
	o.write("\tmovsd xmm0,[rsp]\n");
	o.write("\tadd rsp,0x8\n");
	o.write("\tdivsd xmm0,xmm1\n");
    };
    succeeded = Func.register(new BuiltinFunc("/", [Type.Int, Type.Int], Type.Int, null, int_idiv));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("/", [Type.Real, Type.Int], Type.Real, null, real_idiv));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("/", [Type.Int, Type.Real], Type.Real, null, real_idiv));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("/", [Type.Real, Type.Real], Type.Real, null, real_idiv));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }

    // neg
    auto int_neg = function(Node[] args, OutBuffer o) {
	args[0].emit_int(o);
	o.write("\tneg rax\n");
    };
    auto real_neg = function(Node[] args, OutBuffer o) {
	args[0].emit_real(o);
	o.write("\tmovsd xmm1,xmm0\n");
	o.write("\txorps xmm0,xmm0\n");
	o.write("\tsubsd xmm0,xmm1\n");
    };
    succeeded = Func.register(new BuiltinFunc("-", [Type.Int], Type.Int, null, int_neg));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("-", [Type.Real], Type.Real, null, real_neg));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
}
