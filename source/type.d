/// type
module type;

/// type
class Type
{
public:
	// bool is_array;
	// bool is_struct;
	// bool is_reftype;
	// bool is_func;
	uint size;   // size of variable on memory
	string name;  // type name
	bool is_int;

	this (string name, uint size)
	{
		this.name = name;
		this.size = size;
		this.is_int = false;
	}

	/// return primitive type int
	static Type Int()
	{
		auto t = new Type("int", 8);
		t.is_int = true;
		return t;
	}

	override string toString()
	{
		return this.name;
	}
}

/// predicate to check does given type fill interface?
alias TypeCheck = bool delegate(Type t);
