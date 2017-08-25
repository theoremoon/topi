module topi.dlex;

import topi;
import dlex;
import std.stdio;
import std.uni;

alias Token = DLex!Type.LexResult;
class Source {
    public {
	Token[] results;
	uint p = 0;
    }
    this(Token[] results) {
	this.results = results;
    }
    Token get() {
	if (results.length <= p) {
	    return null;
	}
	return results[p++];
    }
    void unget(Token tok) {
	if (p == 0) {
	    throw new Exception("invalid unget. p=0");
	}
	p--;
	if (results[p] != tok) {
	    throw new Exception("invalid unget. expected:" ~ results[p].toString ~", got: " ~ tok.toString);
	}
    }
}

auto Lex(dstring src) {

    auto dlex = new DLex!(Type);
    dlex.Rules([
            dlex.RuleT(Type.IDENT, Pred(&isAlpha) + Pred(&isAlphaNum).Repeat),
            dlex.RuleT(Type.INT, Pred(&isNumber).Repeat),
            dlex.RuleT(Type.SPACE, Pred(&isSpace).Skip),
	    dlex.RuleT(Type.STRING,
                Between(Char('"'), Char('"'),
                    String(`\"`).As((dstring s) => `"`d)| 
                    Any
                ).As((dstring s) => s[1..$-1])
            ),
	    dlex.RuleT(Type.SYMBOL, Char('(')),
	    dlex.RuleT(Type.SYMBOL, Char(')')),
	    dlex.RuleT(Type.SYMBOL, Char('{')),
	    dlex.RuleT(Type.SYMBOL, Char('}')),
	    dlex.RuleT(Type.SYMBOL, Char(',')),
	    dlex.RuleT(Type.SYMBOL, Char(';')),
	    dlex.RuleT(Type.SYMBOL, String("==")),
	    dlex.RuleT(Type.SYMBOL, Char('=')),
	    dlex.RuleT(Type.SYMBOL, Char('+')),
	    dlex.RuleT(Type.SYMBOL, Char('-')),
	    dlex.RuleT(Type.SYMBOL, Char('*')),
	    dlex.RuleT(Type.SYMBOL, Char('/')),
    ]);

    return new Source(dlex.Lex(src));
}
