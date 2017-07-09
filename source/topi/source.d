module topi.source;

import core.stdc.stdio : getc;
import std.stdio;
import std.uni;

/// Source: management source string
class Source {
	public:
		dchar[] buf;
		File f;

		alias f this;
		this(File f) {
			this.f = f;
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
			foreach_reverse (dchar c; s) {
				unget(c);
			}
		}
		bool expect(dchar c) {
			dchar d;
			if (!get(d)) {
				return false;
			}
			return c == d;
		}
		bool expect_with_skip(dchar[] cs) {
			dchar d;
			while (get(d)) {
				foreach (c; cs) {
				if (c == d) {
					return true;
				}
				}
				if (!d.isWhite) {
					unget(d);
					return false;
				}
			}
			return false;
		}
}

