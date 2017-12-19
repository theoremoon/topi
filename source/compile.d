/* compile.d
 *
 *  for compilation process
 */

import node;

// Register, Memory, Variable...
class CompileContext {
public:
	void write() {
		// do nothing
	}
}

CompileContext compile(Node root) {
	auto ctx =  new CompileContext();
	return ctx;
}
