struct Point {
	public int x;
	public int y;
}

struct Named {
	public string name;
	public int v;
}

enum Color {
	RED,
	GREEN
}

class Holder {
	public int? f;
	public Point? p;
}

int? boxed (int i) {
	if (i < 0) {
		return null;
	}
	return i;
}

int? ret_local (int i) {
	int? r = i * 2;
	return r;
}

void set_out (out int? o) {
	o = 42;
}

void set_ref (ref int? o) {
	o = o + 1;
}

int deref (int? v) {
	return v ?? -1;
}

int? take_owned (owned int? v) {
	return v;
}

void main () {
	// assign / reassign / null
	int? a = 1;
	assert (a == 1);
	a = 2;
	assert (a == 2);
	a = null;
	assert (a == null);
	a = boxed (5);
	assert (a == 5);
	a = boxed (-1);
	assert (a == null);
	a = a ?? 7;
	assert (a == 7);
	a += 3;
	assert (a == 10);
	a = a;
	assert (a == 10);

	// uninitialized declaration
	int? u;
	u = 3;
	assert (u == 3);

	// loops: running best
	int? best = null;
	for (int i = 0; i < 100; i++) {
		int v = (i * 37) % 101;
		if (best == null || v > best) {
			best = v;
		}
	}
	assert (best == 100);

	int? last = null;
	for (int i = 0; i < 10; i++) {
		int? cur = boxed (i % 3 == 0 ? -1 : i);
		if (cur != null) {
			last = cur;
		}
	}
	assert (last == 8);

	// struct nullable
	Point? p = { 1, 2 };
	assert (p.x == 1 && p.y == 2);
	p.x = 5;
	assert (p.x == 5);
	Point? q = p;
	q.y = 9;
	assert (p.y == 2 && q.y == 9);
	p = null;
	assert (p == null && q != null);

	// enum nullable
	Color? c = Color.GREEN;
	assert (c == Color.GREEN);
	c = null;
	assert (c == null);

	// struct with heap fields stays boxed
	Named? n = { "a", 1 };
	assert (n.name == "a");
	n = { "b", 2 };
	assert (n.name == "b");

	// unowned alias observes the slot
	int? s = 1;
	unowned int? alias = s;
	assert (alias == 1);
	s = 2;
	assert (s == 2);

	// owned copies into other storage stay independent
	var h = new Holder ();
	int? fv = 11;
	h.f = fv;
	fv = 12;
	assert (h.f == 11 && fv == 12);
	Point? pv = { 3, 4 };
	h.p = pv;
	pv.x = 0;
	assert (h.p.x == 3);

	int?[] arr = new int?[2];
	int? av = 21;
	arr[0] = av;
	av = 22;
	assert (arr[0] == 21);

	var list = new List<int?> ();
	int? lv = 31;
	list.append (lv);
	lv = 32;
	assert (list.data == 31);

	var ga = new GenericArray<int?> ();
	int? gv = 41;
	ga.add (gv);
	gv = null;
	assert (ga[0] == 41);

	// returned local
	assert (ret_local (4) == 8);

	// passed to unowned / owned params
	int? pp = 51;
	assert (deref (pp) == 51);
	assert (take_owned (pp) == 51);
	assert (pp == 51);

	// locals that must stay boxed
	int? o;
	set_out (out o);
	assert (o == 42);
	int? r = 1;
	set_ref (ref r);
	assert (r == 2);
	int? t = 61;
	int? t2 = (owned) t;
	assert (t == null && t2 == 61);
	int? cap = 71;
	SourceFunc f = () => {
		cap = cap + 1;
		return false;
	};
	f ();
	assert (cap == 72);
	int? ad = 81;
	int** adp = (int**) (&ad);
	assert (**adp == 81);

	// nested blocks and early exit
	for (int i = 0; i < 5; i++) {
		int? x = i;
		if (x == 3) {
			break;
		}
		if (x == 1) {
			continue;
		}
	}

	// while condition assignment
	int k = 0;
	int? w;
	while ((w = boxed (k < 3 ? k : -1)) != null) {
		k++;
	}
	assert (k == 3 && w == null);
}
