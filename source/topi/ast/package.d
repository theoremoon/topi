module topi.ast;

import topi;
import std.outbuffer;

abstract class Ast {
       public:
              void emit(ref OutBuffer o); 
}

abstract class ValueAst : Ast {
       public:
              abstract Type rtype();
}

public import topi.ast.integerast,
       topi.ast.funccallast;
