errordomain E { X }
int? f (int i) throws E { if (i == 3) throw new E.X ("x"); return i; }
void main () {
	bool c = true;
	int? a = 5, b = null;
	int? x = c ? a : b;
	assert (x == 5);
	x = !c ? a : b;
	assert (x == null);
	var l = new List<int?> ();
	l.append (1); l.append (null); l.append (3);
	int n = 0;
	foreach (int? e in l) { int? cp = e; if (cp != null) n += cp; }
	assert (n == 4);
	int s = 0;
	for (int i = 0; i < 5; i++) {
		try { int? v = f (i); s += v; } catch (E e) { s += 100; }
	}
	assert (s == 107);
	switch (s) {
	case 107:
		int? q = s;
		q += 1;
		assert (q == 108);
		break;
	default:
		assert_not_reached ();
	}
	int? z = 1;
	z = z + z * 2;
	assert (z == 3);
	string str = z.to_string ();
	assert (str == "3");
}
