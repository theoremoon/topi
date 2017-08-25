module topi.ast;

import topi;
import std.outbuffer;

abstract class Ast {
       public:
              void emit(ref OutBuffer o); 
}

abstract class ValueAst : Ast {
       public:
}

public import topi.ast.integerast,
       topi.ast.operatorast;
