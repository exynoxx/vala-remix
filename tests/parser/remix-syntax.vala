class Shape : Object {
	public int w;
	public int h;
	public Shape (int w, int h) { this.w = w; this.h = h; }
	public int area () => w * h;
	public void grow () => w++;
	public int perimeter => 2 * (w + h);
	public string label { owned get => @"$(w)x$(h)"; }
	int _scale = 1;
	public int scale { get => _scale; set => _scale = value * 2; }
}

class Square : Shape {
	public Square (int s) { base (s, s); }
	public int side => w;
}

class not : Object {}

int side_or_zero (Object o) {
	if (o is not Square sq) {
		return 0;
	}
	return sq.side;
}

void main () {
	var s = new Shape (2, 3);
	assert (s.area () == 6);
	s.grow ();
	assert (s.area () == 9);
	assert (s.perimeter == 12);
	assert (s.label == "3x3");
	s.scale = 5;
	assert (s.scale == 10);

	Object o = new Square (4);
	if (o is Square sq) {
		assert (sq.side == 4);
	}
	assert (o is Shape && o is not Square == false);
	Object? n = null;
	assert (n is not Square);
	assert (side_or_zero (o) == 4);
	assert (side_or_zero (s) == 0);
	var x = new not ();
	assert (x is not);

	if (o != null && o is Square q) {
		assert (q.side == 4);
	} else if (o is Shape sh) {
		assert_not_reached ();
	}
	Object? cur = new Square (1);
	int hops = 0;
	while (cur is Square c) {
		hops += c.side;
		cur = null;
	}
	assert (hops == 1);

	int sum = 0;
	foreach (var i in 0..5) {
		sum += i;
	}
	assert (sum == 10);

	int calls = 0;
	int count = 0;
	foreach (int64 i in 2..(calls++ + 4)) {
		count++;
		if (i == 3) continue;
	}
	assert (calls == 1);
	assert (count == 2);

	foreach (var i in 3..3) {
		assert_not_reached ();
	}
}
