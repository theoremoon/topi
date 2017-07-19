module topi.env;

import topi;
debug import std.stdio;

class Env {
	public:
		Type[string] vars;
		Env pre;
		this() {
			this.pre = null;
		}
		this(Env pre) {
			this.pre = pre;
		}
		int getScope(string name) {
			if (name in vars) {
				return 0;
			}
			if (! pre) {
				return -1;
			}
			return pre.getScope(name);
		}
		void add(string name, Type type) {
			vars[name] = type;
		}
}

Env env;
