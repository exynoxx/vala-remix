// external class signal (emitted via cached g_signal_lookup id)
class Monitor : FileMonitor {
	public override bool cancel () {
		return true;
	}
	public void fire (File f) {
		changed (f, null, FileMonitorEvent.CREATED);
	}
}

// external interface signal
class Obj : Object, DBusObject {
	public DBusInterface? get_interface (string name) {
		return null;
	}
	public List<DBusInterface> get_interfaces () {
		return new List<DBusInterface> ();
	}
	public unowned string get_object_path () {
		return "/";
	}
	public void fire () {
		interface_added (null);
		((DBusObject) this).interface_removed (null);
	}
}

class Foo : Object {
	[Signal (detailed = true)]
	public signal void bar (int i);
}

int count;

void main () {
	var m = new Monitor ();
	var f = File.new_for_path ("/");
	m.changed.connect ((file, other, ev) => {
		assert (file == f && other == null && ev == FileMonitorEvent.CREATED);
		count++;
	});
	m.fire (f);
	m.fire (f);
	assert (count == 2);

	count = 0;
	var o = new Obj ();
	o.interface_added.connect (() => count++);
	o.interface_removed.connect (() => count += 10);
	o.fire ();
	o.fire ();
	assert (count == 22);

	count = 0;
	var foo = new Foo ();
	foo.bar["a"].connect ((i) => count += i);
	foo.bar["b-c"].connect ((i) => count += 100 * i);
	foo.bar["a"] (1);
	foo.bar["b-c"] (2);
	foo.bar["b_c"] (4);
	string d = "a";
	foo.bar[d] (3);
	foo.bar (5);
	assert (count == 204);
}
