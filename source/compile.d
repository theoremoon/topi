/// module for compilation
module compile;

import func;
import node;

import std.outbuffer;
import std.container;

/// Compile context
/// Scope and Memory management
class CompileContext
{
private:
	uint offset;  // offset from rbp
	DList!BuiltInFunc funcs;
public:
	static OutBuffer buf;
	static this()
	{
		this.buf = new OutBuffer();
	}

	this()
	{
		this.offset = 0;
		this.funcs  = DList!BuiltInFunc();
	}

	void add_func(BuiltInFunc f)
	{
		this.funcs.insertFront(f);
	}

	BuiltInFunc search_func(string name, Node[] args)
	{
		import std.algorithm;
		auto types = args.map!(a => a.type(this));
		BuiltInFunc func = null;
		foreach (f; this.funcs) {  // search by name and type
			if (f.name != name) { continue; }
			if (f.check_args(this, args)) {
				func = f;
				break;
			}
		}
		return func;
	}

	uint store_this(uint size)
	{
		auto ret = this.offset;
		this.offset += size;
		return ret;
	}
}

/// Memory or register
class Store
{
private:
	static Store[string] registers;  /// rax, rbx, rcx, rdx

public:
	static this() {
		this.registers = [
		"rax": null,
		"rbx": null,
		"rcx": null,
		"rdx": null,
		];
	}
	int offset;  /// this variable referenced by rbp-offset. -1 is invalid
	uint size;  /// size of this variable
	this(uint size)
	{
		this.size = size;
		this.offset = -1;
	}

	/// use register such as rax rbx rcx rdx
	void require_register(CompileContext cc, string regname)
	{
		if (regname !in this.registers) {
			throw new Exception("internal error: invalid register name "~regname);
		}

		if (this.registers[regname] is this) {
			return;
		}

		// another store object is using this register
		if (this.registers[regname] !is null && this.registers[regname] !is this) {
			this.registers[regname].save_to_memory(cc);
			cc.buf.writefln("\tmov %s, %s", regname, this.memory_str(cc));
		}
		this.registers[regname] = this;
	}

	/// save this value if in register
	void save_to_memory(CompileContext cc)
	{
		if (this.offset == -1) {
			this.offset = cast(int)cc.store_this(this.size);
		}

		foreach (name, reg; this.registers) {
			if (reg is this) {
				cc.buf.writefln("\tmov rbp-%d, %s", this.offset, name);
				break;
			}
		}
	}

	/// string of stored at. like rax rbp-10 ...
	string memory_str(CompileContext cc)
	{
		import std.format;
		foreach (name, reg; this.registers) {
			if (reg is this) {
				return name;
			}
		}
		if (this.offset == -1) {
			this.offset = cast(int)cc.store_this(this.size);
		}
		return "rbp-%d".format(this.offset);
	}

}
