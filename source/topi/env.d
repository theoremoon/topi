module topi.env;

import topi;

class Env {
    public:
	// 現在の環境をstaticに持つ
	static Env cur;
	Env prev; // 昔の環境

	// 関数とか型（変数も持ちたい）
	Func[string] funcs;
	Type[string] types;

	this() {
	    this.prev = null;
	}
	this(Env prev) {
	    this.prev = prev;
	}
	static this() {
	    cur = new Env();
	}

	// 型の登録
	bool registerType(Type t) {
	    if (getType(t.name) !is null) {
		return false;
	    }
	    types[t.name] = t;
	    return true;
	}
	// 型の取得
	Type getType (string name) {
	    if (name in types)  {
		return types[name];
	    }
	    if (prev is null)  {
		return null;
	    }
	    return prev.getType(name);
	}

	// 関数の登録 
	// TODO:（shadowingしたいのでスコープ内でかぶらなければよしとしたい）
	bool registerFunc(Func f) {
	    if (getFunc(f) !is null) {
		return false;
	    }
	    funcs[f.signature] = f;
	    return true;
	}
	// 関数の取得
	Func getFunc (Func f) {
	    string sign = f.signature;
	    if (sign in funcs)  {
		return funcs[sign];
	    }
	    if (prev is null)  {
		return null;
	    }
	    return prev.getFunc(f);
	}
	Func getFunc (string fname, ValueAst[] args) {
	    string sign = Func.signature(fname, args);
	    if (sign in funcs)  {
		return funcs[sign];
	    }
	    if (prev is null)  {
		return null;
	    }
	    return prev.getFunc(fname, args);
	}
}
