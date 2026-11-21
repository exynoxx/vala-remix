enum Foo {
	ONE,
	TWO,
	THREE
}

enum Bar {
	A = 10,
	B = 0x20,
	C
}

// aliases can not be a switch, falls back to g_enum_to_string
enum Alias {
	X = 1,
	Y = 1,
	Z
}

[Flags]
enum Manam {
	FIRST,
	SECOND
}

void main () {
	assert (Foo.ONE.to_string () == "FOO_ONE");
	assert (Foo.THREE.to_string () == "FOO_THREE");
	assert (Bar.A.to_string () == "BAR_A");
	assert (Bar.B.to_string () == "BAR_B");
	assert (Bar.C.to_string () == "BAR_C");
	Foo f = Foo.TWO;
	string s = f.to_string ();
	assert (s == "FOO_TWO");
	unowned string u = Bar.C.to_string ();
	assert (u == "BAR_C");
	assert (((Foo) 42).to_string () == null);

	assert (Alias.Y.to_string () == "ALIAS_X");
	assert (Alias.Z.to_string () == "ALIAS_Z");

	assert ((Manam.FIRST | Manam.SECOND).to_string () == "MANAM_FIRST | MANAM_SECOND");
}
