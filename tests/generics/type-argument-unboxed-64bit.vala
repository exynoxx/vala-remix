class Box<T> {
	public T val;
	public Box (T v) {
		val = v;
	}
	public T get_val () {
		return val;
	}
}

delegate T Producer<T> (T x);

T id<T> (T x) {
	return x;
}

T apply<T> (Producer<T> f, T x) {
	return f (x);
}

bool same_bits (double a, double b) {
	return Memory.cmp (&a, &b, sizeof (double)) == 0;
}

void main () {
	int64[] i64s = { int64.MAX, int64.MIN, 0, -1 };
	uint64[] u64s = { uint64.MAX, 0, 1ULL << 63 };
	double[] ds = { double.NAN, -0.0, double.INFINITY, -double.INFINITY, 4.9e-324, double.MAX, double.MIN, 3.14159 };

	// GenericArray
	var ai = new GenericArray<int64> ();
	foreach (var v in i64s) ai.add (v);
	for (int i = 0; i < i64s.length; i++) assert (ai[i] == i64s[i]);
	int n = 0;
	foreach (var v in ai) assert (v == i64s[n++]);

	var au = new GenericArray<uint64> ();
	foreach (var v in u64s) au.add (v);
	for (int i = 0; i < u64s.length; i++) assert (au[i] == u64s[i]);

	var ad = new GenericArray<double> ();
	foreach (var v in ds) ad.add (v);
	for (int i = 0; i < ds.length; i++) assert (same_bits (ad[i], ds[i]));
	assert (ad[0].is_nan ());
	assert (ad[1] == 0.0 && same_bits (ad[1], -0.0));
	n = 0;
	foreach (var v in ad) assert (same_bits (v, ds[n++]));

	// HashTable values and int64 keys
	var h = new HashTable<string,double> (str_hash, str_equal);
	h["nan"] = double.NAN;
	h["negzero"] = -0.0;
	h["inf"] = double.INFINITY;
	h["denorm"] = 4.9e-324;
	assert (h["nan"].is_nan ());
	assert (same_bits (h["negzero"], -0.0));
	assert (h["inf"] == double.INFINITY);
	assert (h["denorm"] == 4.9e-324);
	var hu = new HashTable<string,uint64> (str_hash, str_equal);
	hu["max"] = uint64.MAX;
	assert (hu["max"] == uint64.MAX);

	// List
	var l = new List<int64> ();
	foreach (var v in i64s) l.append (v);
	n = 0;
	foreach (var v in l) assert (v == i64s[n++]);
	var ld = new List<double> ();
	foreach (var v in ds) ld.append (v);
	n = 0;
	foreach (var v in ld) assert (same_bits (v, ds[n++]));

	// Queue
	var q = new Queue<double?> ();
	q.push_tail (2.5);
	assert (q.pop_head () == 2.5);
	var qd = new Queue<double> ();
	qd.push_tail (-0.0);
	assert (same_bits (qd.pop_head (), -0.0));

	// generic method, delegate, generic class field
	assert (id<int64> (int64.MIN) == int64.MIN);
	assert (id<uint64> (uint64.MAX) == uint64.MAX);
	assert (same_bits (id<double> (-0.0), -0.0));
	assert (apply<double> ((x) => x * 2, 1.5) == 3.0);
	assert (apply<int64> ((x) => x - 1, int64.MIN + 1) == int64.MIN);
	var b = new Box<double> (double.MAX);
	assert (b.val == double.MAX);
	assert (b.get_val () == double.MAX);
	b.val = double.NAN;
	assert (b.get_val ().is_nan ());
	var bi = new Box<int64> (int64.MAX);
	assert (bi.get_val () == int64.MAX);

	// float
	var af = new GenericArray<float> ();
	af.add (1.5f);
	af.add (float.NAN);
	assert (af[0] == 1.5f);
	assert (af[1].is_nan ());

	// double? stays boxed: null distinguishable from 0.0
	var an = new GenericArray<double?> ();
	an.add (null);
	an.add (0.0);
	assert (an[0] == null);
	assert (an[1] != null && an[1] == 0.0);
}
