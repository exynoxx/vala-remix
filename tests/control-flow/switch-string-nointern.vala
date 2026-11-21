const string DYN = "dyn";

int classify (string? s) {
	switch (s) {
	case "a":
	case "b":
		return 1;
	case null:
		return 2;
	case DYN:
		return 3;
	case "x":
	default:
		return 4;
	case "c":
		return 5;
	}
}

int classify_owned (int i) {
	int r = 0;
	// owned temporary input, freed before the section bodies run
	switch (i.to_string ()) {
	case "1":
		r = 1;
		break;
	case "2":
		r = 2;
		break;
	}
	return r;
}

int in_loop () {
	int sum = 0;
	foreach (unowned string s in new string[] { "a", "skip", "b", "end", "a" }) {
		switch (s) {
		case "a":
			sum += 1;
			break;
		case "skip":
			continue;
		case "end":
			return sum + 100;
		default:
			sum += 10;
			break;
		}
		sum += 1000;
	}
	return sum;
}

void main () {
	assert (classify ("a") == 1);
	assert (classify ("b") == 1);
	assert (classify (null) == 2);
	assert (classify ("dyn") == 3);
	assert (classify ("x") == 4);
	assert (classify ("zzz") == 4);
	assert (classify ("") == 4);
	assert (classify ("c") == 5);
	assert (classify_owned (1) == 1);
	assert (classify_owned (2) == 2);
	assert (classify_owned (3) == 0);
	assert (in_loop () == 2111);

	// non-matching inputs must not be interned
	switch ("switch-string-nointern-unique") {
	case "foo":
		assert_not_reached ();
	default:
		break;
	}
	assert (Quark.try_string ("switch-string-nointern-unique") == 0);
}
