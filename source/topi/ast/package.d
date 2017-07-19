module topi.ast;

import topi;
import std.outbuffer;

abstract class Ast {
       public:
              void analyze();
              void emit(ref OutBuffer o); 
}

abstract class ValueAst : Ast {
       public:
              Type type();
}

public import topi.ast.integerast,
       topi.ast.operatorast,
       topi.ast.declast,
       topi.ast.returnast;
