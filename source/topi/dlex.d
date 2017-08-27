module topi.dlex;

import topi;
import dlex;
import std.stdio;
import std.uni;

enum TokenType {
    STRING,
    IDENT,
    INT,
    SYMBOL,
    SPACE,
}

alias Token = DLex!TokenType.LexResult;
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

    auto dlex = new DLex!(TokenType);
    dlex.Rules([
            dlex.RuleT(TokenType.IDENT, Pred(&isAlpha) + Pred(&isAlphaNum).Repeat),
            dlex.RuleT(TokenType.INT, Pred(&isNumber).Repeat),
            dlex.RuleT(TokenType.SPACE, Pred(&isSpace).Skip),
	    dlex.RuleT(TokenType.STRING,
                Between(Char('"'), Char('"'),
                    String(`\"`).As((dstring s) => `"`d)| 
                    Any
                ).As((dstring s) => s[1..$-1])
            ),
	    dlex.RuleT(TokenType.SYMBOL, Char('(')),
	    dlex.RuleT(TokenType.SYMBOL, Char(')')),
	    dlex.RuleT(TokenType.SYMBOL, Char('{')),
	    dlex.RuleT(TokenType.SYMBOL, Char('}')),
	    dlex.RuleT(TokenType.SYMBOL, Char(',')),
	    dlex.RuleT(TokenType.SYMBOL, Char(';')),
	    dlex.RuleT(TokenType.SYMBOL, String("==")),
	    dlex.RuleT(TokenType.SYMBOL, Char('=')),
	    dlex.RuleT(TokenType.SYMBOL, Char('+')),
	    dlex.RuleT(TokenType.SYMBOL, Char('-')),
	    dlex.RuleT(TokenType.SYMBOL, Char('*')),
	    dlex.RuleT(TokenType.SYMBOL, Char('/')),
    ]);

    return new Source(dlex.Lex(src));
}
