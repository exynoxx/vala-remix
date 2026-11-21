class Foo {
	public string? f;
	public string g = "g";
}

int counter;
string? order;

string? maybe (string? s) {
	return s;
}

unowned string side (string s) {
	counter++;
	order = "%s%s".printf (order ?? "", s);
	return s;
}

void main () {
	string? n = null;
	string? x = "x";
	string a = "a";
	string b = "b";

	// plain chains
	assert (a + b + "c" + a == "abca");
	assert ("<" + a + ">" + b + "<" + "/" + ">" == "<a>b</>");

	// NULL operands in the middle/end are skipped, like separate concats
	assert ("a" + n + "b" == "ab");
	assert ("a" + n + n + "b" + n == "ab");
	assert (a + maybe (null) + b == "ab");
	assert (a + maybe (null) + maybe (null) + b == "ab");
	assert (x + n + x == "xx");
	var foo = new Foo ();
	assert (a + foo.f + b + foo.g == "abg");
	// NULL first operand yields NULL
	assert (n + "a" + "b" == null);

	// side effects keep left-to-right order
	order = null;
	counter = 0;
	assert (side ("1") + side ("2") + a + side ("3") + side ("4") == "12a34");
	assert (order == "1234");
	assert (counter == 4);

	// an operand mutated by a later operand is read before the mutation
	string s = "s";
	string t = "t";
	assert (s + t + (t = "T") + t == "stTT");

	// +=
	string r = "r";
	r += "1";
	r += a + b;
	r += n;
	assert (r == "r1ab");
	for (int i = 0; i < 100; i++) {
		r += "x";
	}
	assert (r.length == 104);
	r = "self";
	r += r;
	assert (r == "selfself");
	unowned string tail = r.offset (4);
	r += tail;
	assert (r == "selfselfself");

	string? rn = null;
	rn += "a";
	assert (rn == null);

	foo.f = null;
	foo.f += "x";
	assert (foo.f == null);
	foo.g += "h" + foo.g;
	assert (foo.g == "ghg");
}
