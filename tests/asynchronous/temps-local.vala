// Temporaries of yield-free statements are C locals in the coroutine,
// temporaries live across a yield stay in the coroutine data.

async void tick () {
	Idle.add (tick.callback);
	yield;
}

async string id (string s) {
	yield tick ();
	return s;
}

async int twice (int i) {
	yield tick ();
	return 2 * i;
}

string concat (string a, string b) {
	return a + b;
}

async string loop (int n) {
	string acc = "";
	int sum = 0;
	for (int i = 0; i < n; i++) {
		string s = i.to_string () + "-" + (i * 2).to_string ();
		acc += s.up () + ";";
		sum += s.length + i * 3 % 5;
		if (i % 2 == 0) {
			yield tick ();
		}
	}
	return "%s%d".printf (acc, sum);
}

async string in_expressions () {
	// argument temps evaluated before the yield, result after it
	string a = concat ("x".up () + "1", yield id ("y".up () + "2"));
	// (several yields in one binary expression are not supported, see _res_)
	int b = "cd".length * 10 + (yield twice (3 + "ab".length)) + "efg".length;
	string c = a.down () + (yield id ("z".up () + a)) + b.to_string ();
	return c;
}

async string with_finally () throws Error {
	string log = "";
	try {
		log += "a".up () + (yield id ("b"));
		try {
			log += (yield id ("c".up ())) + "d".up ();
			throw new IOError.FAILED ("e".up () + "f");
		} finally {
			log += (yield id ("g")) + "h".up ();
		}
	} catch (IOError e) {
		log += e.message + (yield id ("i")).up ();
	} finally {
		log += "j".up () + (yield id ("k"));
	}
	return log;
}

async string nested () {
	return "o".up () + (yield id ("p".up () + (yield id ("q".up () + (yield id ("r")))))) + "s".up ();
}

async int closure (int n) {
	int total = 0;
	SourceFunc cb = () => {
		total += n.to_string ().length;
		return false;
	};
	for (int i = 0; i < n; i++) {
		cb ();
		total += (yield twice (i)) + i.to_string ().length;
	}
	return total;
}

MainLoop main_loop;
int pending;

void done () {
	if (--pending == 0) {
		main_loop.quit ();
	}
}

void main () {
	main_loop = new MainLoop ();
	pending = 5;
	loop.begin (5, (o, r) => {
		assert (loop.end (r) == "0-0;1-2;2-4;3-6;4-8;25");
		done ();
	});
	in_expressions.begin ((o, r) => {
		assert (in_expressions.end (r) == "x1y2ZX1Y233");
		done ();
	});
	with_finally.begin ((o, r) => {
		try {
			assert (with_finally.end (r) == "AbCDgHEfIJk");
		} catch {
			assert_not_reached ();
		}
		done ();
	});
	nested.begin ((o, r) => {
		assert (nested.end (r) == "OPQrS");
		done ();
	});
	closure.begin (4, (o, r) => {
		assert (closure.end (r) == 4 + 0 + 2 + 4 + 6 + 4);
		done ();
	});
	main_loop.run ();
}
