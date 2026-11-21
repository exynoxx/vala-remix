class PrivParent : Object {
	int secret = 1;
	public int get_secret () { return secret; }
}

class PlainChild : PrivParent {
	public int pub = 2;
}

class PlainParent : Object {
	public int pub = 3;
}

class PrivChild : PlainParent {
	string secret = "four";
	public string get_secret () { return secret; }
}

class PrivGrandChild : PrivChild {
	int more = 5;
	public int get_more () { return more; }
}

class GenericChild<G> : PlainParent {
	public G val;
}

class Locked : Object {
	public int counter;
	public void inc () {
		lock (counter) {
			counter++;
		}
	}
}

class Empty : Object {
}

class Fundamental {
	public int pub = 6;
}

class FundamentalPriv : Fundamental {
	int secret = 7;
	public int get_secret () { return secret; }
}

void main () {
	var a = new PlainChild ();
	assert (a.get_secret () == 1 && a.pub == 2);
	var b = new PrivChild ();
	assert (b.get_secret () == "four" && b.pub == 3);
	var c = new PrivGrandChild ();
	assert (c.get_secret () == "four" && c.get_more () == 5 && c.pub == 3);
	var g = new GenericChild<string> ();
	g.val = "x";
	assert (g.val == "x");
	var l = new Locked ();
	l.inc ();
	assert (l.counter == 1);
	assert (new Empty () is Object);
	var f = new FundamentalPriv ();
	assert (f.pub == 6 && f.get_secret () == 7);
}
