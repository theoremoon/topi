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
			throw new Exception("the function %s is already defined in this scope".format(func.signature));
		}
		funcs[func.signature] = func;
		return true;
	}
	Func getFunc(string signature) {
		if (signature in funcs) {
			return funcs[signature];
		}
		if (par is null) {
			return null;
		}
		return par.getFunc(signature);
	}

	bool registerType(Type type) {
		if (type.toString() in types) {
			throw new Exception("the type %s is already defined in this scope".format(type.toString()));
		}
		types[type.toString()] = type;
		return true;
	}
	Type getType(string name) {
		if (name in types) {
			return types[name];
		}
		if (par is null) {
			return null;
		}
		return par.getType(name);
	}

	bool registerVar(string name, Node node) {
		if (name in vars) {
			throw new Exception("the variable %s is already defined in this scope".format(name));
		}
		vars[name] = node;
		return true;
	}
	void setVar(string name, Node node) {
		if (name in vars) {
			vars[name] = node;
			return;
		}
		if (par is null) {
			throw new Exception("the variable %s is not defined".format(name));
		}
		setVar(name, node);
	}
	Node getVar(string name) {
		if (name in vars) {
			return vars[name];
		}
		if (par is null) {
			throw new Exception("the variable %s isnot defined".format(name));
		}
		return par.getVar(name);
	}
}
