import func;
import type;

class Env {
    public:
	Env par;
	Func[string] funcs;

	this (Env par = null) {
	    this.par = par;
	}
	bool registerFunc(Func func) {
	    if (func.signature in funcs) {
		return false;
	    }
	    funcs[func.signature] = func;
	    return true;
	}
	Func getFunc(string signature) {
	    if (signature in funcs) {
		return funcs[signature];
	    }
	    return null;
	}
}
