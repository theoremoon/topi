import std.algorithm;
import std.outbuffer;
import std.conv;
import std.array;

import type;
import node;

class Func {
    public:
	alias EmitT = void function(OutBuffer);
	static Func[dstring] funcs;

	dstring name;
	Type[] argtypes;
	Type rettype;
	EmitT emitfunc;

	static bool register(Func f) {
	    if (f.signature in funcs) {
		return false;
	    }
	    funcs[f.signature] = f;
	    return true;
	}
	static dstring signature(dstring name, Node[] args) {
	    Type[] argtypes = args.map!(a => a.type).array;
	    return signature(name, argtypes);
	}
	static dstring signature(dstring name, Type[] argtypes) {
	    return name~"("~argtypes.map!(to!dstring).join(",")~")";
	}
	static Func get(dstring name, Node[] args) {
	    Type[] argtypes = args.map!(a => a.type).array;
	    return get(name, argtypes);
	}
	static Func get(dstring name, Type[] argtypes) {
	    auto sign = signature(name, argtypes);
	    if (sign !in funcs) {
		return null;
	    }
	    return funcs[sign];
	}

	this(dstring name, Type[] argtypes, Type rettype, EmitT emitfunc) {
	    this.name = name;
	    this.argtypes = argtypes;
	    this.rettype = rettype;
	    this.emitfunc = emitfunc;
	}

	dstring signature() {
	    return Func.signature(name, argtypes);
	}
	void emit(OutBuffer o) {
	    // emitfunc may be null
	    if (emitfunc !is null) {
		emitfunc(o);
	    }
	}
	void call(Node[] args, OutBuffer o) {
	    // o.write("\tcall %s\n", signature);
	}

	Type type() {
	    return rettype;
	}
}

class BuiltinFunc : Func {
    public:
	alias CallT = void function(Node[], OutBuffer);
	CallT callfunc;

	this(dstring name, Type[] argtypes, Type rettype, EmitT emitfunc, CallT callfunc) {
	    super(name, argtypes, rettype, emitfunc);
	    this.callfunc = callfunc;
	}
	override void call(Node[] args, OutBuffer o) {
	    if (callfunc is null) {
		super.call(args, o);
	    }
	    else {
		callfunc(args, o);
	    }
	}
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
    succeeded = Func.register(new BuiltinFunc("+", [Type.Int, Type.Int], Type.Int, null, int_add));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("+", [Type.Int, Type.Real], Type.Real, null, real_add));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("+", [Type.Real, Type.Int], Type.Real, null, real_add));
    if (!succeeded) {
	throw new Exception("Internal Error");
    }
    succeeded = Func.register(new BuiltinFunc("+", [Type.Real, Type.Real], Type.Real, null, real_add));
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
}
