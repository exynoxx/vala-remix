interface IFoo : Object {
	public abstract int val ();
}

class Base : Object {
	public int prop { get; set; default = 1; }
	public string name { get; construct; }
	construct {
		prop += 10;
	}
	public virtual int get_val () {
		return 1;
	}
}

class Derived : Base, IFoo {
	public int dprop { get; set; }
	public Derived () {
		Object (name: "d");
	}
	public override int get_val () {
		return base.get_val () + 1;
	}
	public int val () {
		return ((Base) this).get_val () * 10;
	}
}

void main () {
	var d = new Derived ();
	assert (d.get_val () == 2);
	assert (d.val () == 20);
	assert (d.prop == 11);
	assert (d.name == "d");

	d.set ("prop", 5, "dprop", 7);
	int p, dp;
	d.get ("prop", out p, "dprop", out dp);
	assert (p == 5 && dp == 7);

	Object o = (Object) d;
	IFoo i = (IFoo) d;
	Base b = d;
	assert (o == d && d == o && b == d && i == d);
	assert (((Object) i) == o);
	Derived? other = new Derived ();
	assert (b != other);
}
