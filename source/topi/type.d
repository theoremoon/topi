module topi.type;

import topi;

class Type {
   public:
      static Type Int;
      static Type Void;
      static this() {
	 Int = new Type("Int", []);
	 Void = new Type("Void", []);
      }

      bool isfunc;
      Type[] types;
      string name;
      static makeFunc(string name, Type[] argtypes, Type rtype) {
	 auto t = new Type();
	 t.name = name;
	 t.isfunc = true;
	 t.types = argtypes ~ rtype;
      }
      this(string name, Type[] types) {
	 this.name = name;
	 this.isfunc = false;
	 this.types = types;
      }
      override string toString() {
	 return this.name;
      }
   private:
      this() {}
}
