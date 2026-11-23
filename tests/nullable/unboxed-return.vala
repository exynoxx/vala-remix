errordomain FooError {
	FAIL
}

struct Point {
	public int x;
	public int y;
}

enum Color {
	RED,
	GREEN
}

delegate int? MaybeFunc (int i);

int? maybe (int i) {
	if (i % 7 == 0) {
		return null;
	}
	return i;
}

Point? maybe_point (int i) {
	if (i % 7 == 0) {
		return null;
	}
	return { i, -i };
}

Color? maybe_color (bool b) {
	return b ? (Color?) Color.GREEN : null;
}

int? passthrough (int? v) {
	return v;
}

int? from_local (int i) {
	int? r = maybe (i);
	if (r != null) {
		r = r * 10;
	}
	return r;
}

int? from_boxed_call (int i) {
	// owned box from a boxed method
	return public_maybe (i);
}

int? throwing (int i) throws FooError {
	if (i < 0) {
		throw new FooError.FAIL ("negative");
	}
	return i == 0 ? null : (int?) i;
}

int? with_precondition (Object o, int i) requires (i >= 0) {
	return i;
}

int? captured_local (int i) {
	int? r = i;
	SourceFunc f = () => {
		r = r + 1;
		return false;
	};
	f ();
	return r;
}

// referenced as delegate, must stay boxed
int? as_delegate (int i) {
	return i + 1;
}

public int? public_maybe (int i) {
	if (i < 0) {
		return null;
	}
	return i;
}

class Foo : Object {
	int? field;

	int? get_field () {
		return field;
	}

	static int? twice (int? v) {
		return v == null ? null : (int?) (v * 2);
	}

	public int? run (int i) {
		field = maybe (i);
		return twice (get_field ());
	}
}

async int async_user (int i) {
	int? v = maybe (i);
	Idle.add (async_user.callback);
	yield;
	return v ?? -1;
}

void main () {
	long s = 0;
	for (int i = 0; i < 100; i++) {
		int? x = maybe (i);
		if (x != null) {
			s += x;
		}
	}
	assert (s == 4950 - 7 * (0 + 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11 + 12 + 13 + 14));

	// value and null, conditions
	assert (maybe (3) == 3);
	assert (maybe (7) == null);
	assert (maybe (3) != null);
	if (maybe (14) != null) {
		assert_not_reached ();
	}
	maybe (1);

	// chained and nested
	assert (passthrough (maybe (5)) == 5);
	assert (passthrough (maybe (7)) == null);
	assert (passthrough (passthrough (maybe (8))) == 8);
	assert (from_local (2) == 20);
	assert (from_local (7) == null);
	assert (from_boxed_call (4) == 4);
	assert (from_boxed_call (-4) == null);
	assert ((maybe (6) ?? 0) + (maybe (7) ?? 100) == 106);

	// casts to the non-nullable type
	int y = (int) maybe (3);
	int z = (!) maybe (4);
	int w = maybe (5);
	assert (y + z + w == 12);
	Point pc = (Point) maybe_point (2);
	assert (pc.x == 2);

	// struct and enum
	Point? p = maybe_point (3);
	assert (p != null && p.x == 3 && p.y == -3);
	assert (maybe_point (7) == null);
	assert (maybe_point (2).x == 2);
	assert (maybe_color (true) == Color.GREEN);
	assert (maybe_color (false) == null);

	// stored in owned storage
	var list = new List<int?> ();
	list.append (maybe (9));
	list.append (maybe (7));
	assert (list.nth_data (0) == 9 && list.nth_data (1) == null);
	int?[] arr = { maybe (10), maybe (14) };
	assert (arr[0] == 10 && arr[1] == null);

	// errors and preconditions
	try {
		assert (throwing (3) == 3);
		assert (throwing (0) == null);
		throwing (-1);
		assert_not_reached ();
	} catch (FooError e) {
	}
	assert (with_precondition (new Object (), 5) == 5);

	assert (captured_local (1) == 2);

	// delegate use
	MaybeFunc f = as_delegate;
	assert (f (1) == 2);
	assert (as_delegate (2) == 3);

	// public method keeps the boxed ABI
	int? pub = public_maybe (1);
	assert (pub == 1);

	// instance and static private methods
	var foo = new Foo ();
	assert (foo.run (4) == 8);
	assert (foo.run (7) == null);

	// called from a coroutine
	var loop = new MainLoop ();
	async_user.begin (3, (o, r) => {
		assert (async_user.end (r) == 3);
		loop.quit ();
	});
	loop.run ();
}
