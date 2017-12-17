import func;
import type;
import node;

import std.format;

class Env {
public:
	Env par;
	Func[string] funcs;
	Type[string] types;
	Node[string] vars;

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

	bool registerType(Type type) {
		if (type.toString() in types) {
			return false;
		}
		types[type.toString()] = type;
		return true;
	}
	Type getType(string name) {
		if (name in types) {
			return types[name];
		}
		return null;
	}

	bool registerVar(string name, Node node) {
		if (name in vars) {
			return false;
		}
		vars[name] = node;
		return true;
	}
	void setVar(string name, Node node) {
		if (name !in vars) {
			throw new Exception("variable %s is not exist in env".format(name));
		}
		vars[name] = node;
	}
	Node getVar(string name) {
		if (name in vars) {
			return vars[name];
		}
		return null;
	}
}
