// Closure block data only holds a reference to self if a lambda uses `this'

delegate void Func ();

class Foo : Object {
	public int field;
	public signal void sig ();

	public int prop {
		get {
			int i = 1;
			Func f = () => { i += field; };
			f ();
			return i;
		}
	}

	construct {
		int i = 0;
		Func f = () => { i++; field = i; };
		f ();
	}

	public Foo () {
		int i = 0;
		Func f = () => { i++; };
		f ();
		assert (ref_count == 1);
	}

	public Foo.with_this () {
		int i = 0;
		Func f = () => { field = ++i; };
		assert (ref_count == 2);
		f ();
	}

	public Func no_this () {
		int i = 0;
		Func f = () => { i++; };
		assert (ref_count == 1);
		return (owned) f;
	}

	public Func implicit_field () {
		int i = 1;
		Func f = () => { field += i; };
		assert (ref_count == 2);
		return (owned) f;
	}

	public Func explicit_this () {
		int i = 1;
		Func f = () => { Foo self_ref = this; self_ref.field += i; };
		assert (ref_count == 2);
		return (owned) f;
	}

	public Func nested_inner_this () {
		int i = 1;
		Func f = () => {
			int j = i;
			Func g = () => { field += j; };
			g ();
		};
		assert (ref_count == 2);
		return (owned) f;
	}

	public Func nested_inner_instance_lambda () {
		int i = 1;
		Func f = () => {
			i++;
			Func g = () => { field++; };
			g ();
		};
		assert (ref_count == 2);
		return (owned) f;
	}

	public Func nested_no_this () {
		int i = 1;
		Func f = () => {
			int j = i;
			Func g = () => { j++; };
			g ();
		};
		assert (ref_count == 1);
		return (owned) f;
	}

	public virtual int virt () {
		return 10;
	}

	public void connect_no_this () {
		int i = 0;
		sig.connect (() => { i++; });
		assert (ref_count == 1);
		sig ();
		assert (i == 1);
	}

	public void connect_this () {
		int i = 1;
		sig.connect (() => { field += i; });
		assert (ref_count == 2);
	}

	public async void run_async () {
		var rc = ref_count;
		{
			int i = 0;
			Func f = () => { i++; };
			assert (ref_count == rc);
			f ();
		}
		{
			int i = 1;
			Func g = () => { field += i; };
			assert (ref_count == rc + 1);
			g ();
		}
		Idle.add (run_async.callback);
		yield;
	}
}

class Bar : Foo {
	public override int virt () {
		int i = 1;
		int r = 0;
		Func f = () => { r = base.virt () + i; };
		f ();
		return r;
	}
}

class Baz : Foo {
	public Baz () {
		base ();
		int i = 0;
		Func f = () => { field = ++i; };
		assert (ref_count == 2);
		f ();
	}

	public Baz.no_this () {
		base ();
		int i = 0;
		Func f = () => { i++; };
		assert (ref_count == 1);
		f ();
	}
}

class Gen<G> : Object {
	public G val;

	public Func capture (G v) {
		G local = v;
		Func f = () => { local = null; };
		return (owned) f;
	}

	public void typed (G v) {
		G local = v;
		Func f = () => { val = local; assert (typeof (G) == typeof (string)); };
		f ();
	}
}

void main () {
	var foo = new Foo ();
	assert (foo.field == 1);
	assert (foo.prop == 2);

	var foo2 = new Foo.with_this ();
	assert (foo2.ref_count == 1);
	assert (foo2.field == 1);

	foo.field = 0;
	Func f = foo.no_this ();
	assert (foo.ref_count == 1);
	f ();
	f = () => {};
	f = foo.implicit_field ();
	assert (foo.ref_count == 2);
	f ();
	assert (foo.field == 1);
	f = () => {};
	f = foo.explicit_this ();
	f ();
	assert (foo.field == 2);
	foo.field = 1;
	f = () => {};
	f = foo.nested_inner_this ();
	f ();
	assert (foo.field == 2);
	f = () => {};
	f = foo.nested_inner_instance_lambda ();
	f ();
	assert (foo.field == 3);
	f = () => {};
	f = foo.nested_no_this ();
	assert (foo.ref_count == 1);
	f ();
	f = () => {};
	assert (foo.ref_count == 1);

	assert (new Bar ().virt () == 11);

	var gen = new Gen<string> ();
	f = gen.capture ("foo");
	f ();
	f = () => {};
	assert (gen.ref_count == 1);
	gen.typed ("bar");
	assert (gen.val == "bar");
	assert (gen.ref_count == 1);

	var baz = new Baz ();
	assert (baz.ref_count == 1);
	assert (baz.field == 1);
	baz = new Baz.no_this ();
	assert (baz.ref_count == 1);

	var foo3 = new Foo ();
	foo3.connect_no_this ();
	foo3.connect_this ();
	foo3.field = 0;
	foo3.sig ();
	assert (foo3.field == 1);

	var loop = new MainLoop ();
	foo.field = 0;
	foo.run_async.begin ((o, r) => {
		((Foo) o).run_async.end (r);
		loop.quit ();
	});
	loop.run ();
	assert (foo.field == 1);
	assert (foo.ref_count == 1);
}
