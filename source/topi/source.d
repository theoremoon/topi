module topi.source;

import topi;
import std.uni;
import std.conv;
import std.stdio;
import std.format;
import core.stdc.stdio : getc;

bool isFirstChar(dchar c) {
	return (c.isAlpha || c == '_');
}
bool isIdentChar(dchar c) {
	return c.isAlphaNum || c == '_';
}

/// Source: management source string
class Source {
	public:
		dchar[] buf;
		File f;

		alias f this;
		this(File f) {
			this.f = f;
			buf = [];
		}
		bool next(dchar c) {
			dchar c2;
			while (get(c2)) {
				if (c2 == c) {
					return true;
				}
				if (!c2.isWhite) {
					unget(c2);
					break;
				}
			}
			return false;
		}
		void unget(Token t) {
			if (t) {
				if (t.type == Token.Type.STRING) {
					unget('"');
					unget(t.str);
					unget('"');
				}
				else {
					unget(t.str);
				}
			}
		}
		Token get() {
			skip_space;
			auto tok = read_number;
			if (tok) {
				return tok;
			}
			tok = read_string;
			if (tok) {
				return tok;
			}
			tok = read_identifier;
			if (tok) {
				return tok;
			}
			tok = read_symbol;
			if (tok) {
				return tok;
			}
			return null;
		}

	private:
		/// read_number: read decimal number which begin from n
		Token read_number() {
			dchar c;
			dchar[] buf;
			while (get(c)) {
				if (! c.isNumber) {
					unget(c);
					break;
				}
				buf ~= c;
			}
			if (buf.length == 0) {
				return null;
			}
			return new Token(Token.Type.INT, buf.to!string);
		}
		/// read_string
		Token read_string() {
			dchar c;
			if (!get_with_skip(c)) {
				return null;
			}
			if (c != '"') {
				unget(c);
				return null;
			}
			dchar[] buf;
			while (true) {
				if (!get_with_skip(c)) {
					throw new Exception("unterminated string");
				}
				if (c == '"') {
					break;
				}
				if (c == '\\') {
					if (!get_with_skip(c)) {
						throw new Exception("unterminated \\");
					}
				}
				buf ~= c;
			}
			return new Token(Token.Type.STRING, buf.to!string);
		}
		/// read_identifier: read identifier or return null with read nothing
		Token read_identifier() {
			dchar c;
			if (!get_with_skip(c)) {
String:		return null;
			}
			if (c.isFirstChar) {
				dchar[] buf;
				buf ~= c;
				while (get(c)) {
					if (! c.isIdentChar) {
						unget(c);
						break;
					}
					buf ~= c;
				}
				return new Token(Token.Type.IDENT, buf.to!string);
			}
			unget(c);
			return null;
		}
		Token read_symbol() {
			dchar c;
			if (!get_with_skip(c)) {
				return null;
			}
			switch (c) {
				case '+': case '-':
				case '*':
				case '(': case ')':
				case '{': case '}':
				case ',':
					return new Token(Token.Type.SYMBOL, c.to!string);
				case '=':
					dchar c2;
					if (!get(c2)) {
						return new Token(Token.Type.SYMBOL, "=");
					}
					if (c2 == '=') {
						return new Token(Token.Type.SYMBOL, "==");
					}
					unget(c2);
					return new Token(Token.Type.SYMBOL, "=");
				default:
					break;
			}
			unget(c);
			return null;
		}
		/// get: get one character from source
		uint get(ref dchar c) {
			if (buf.length > 0) {
				c = buf[$-1];
				buf = buf[0..$-1];
				return 1;
			}
			int a = f.getFP.getc;
			if (a == EOF) {
				return 0;
			}
			c = a;
			return 1;
		}
		uint skip_space() {
			uint cnt = 0;
			dchar c;
			while (get(c)) {
				if (!c.isWhite) {
					unget(c);
					break;
				}
				cnt++;
			}
			return cnt;
		}
		uint get_with_skip(ref dchar c) {
			skip_space();
			return get(c);
		}
		void unget(dchar c) {
			buf ~= c;
		}
		void unget(string s) {
			foreach_reverse(c;s) {
				unget(c);
			}
		}
}

