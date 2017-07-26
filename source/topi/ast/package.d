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
       topi.ast.defast,
       topi.ast.returnast,
       topi.ast.blockast,
       topi.ast.variableast,
       topi.ast.functionast;
