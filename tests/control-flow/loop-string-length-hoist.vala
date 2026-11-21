int count_for (string s) {
	int n = 0;
	for (int i = 0; i < s.length; i++) {
		n++;
	}
	return n;
}

int count_while (string s) {
	int i = 0;
	while (s.length > i) {
		i++;
	}
	return i;
}

int reassigned (string input) {
	// s changes inside the loop: must not be hoisted
	string s = input;
	int n = 0;
	for (int i = 0; i < s.length; i++) {
		if (n == 0) {
			s = s + "xx";
		}
		n++;
	}
	return n;
}

void shorten (ref string s) {
	s = s.substring (1);
}

int ref_arg (string input) {
	string s = input;
	int n = 0;
	while (n < s.length) {
		shorten (ref s);
		n++;
	}
	return n;
}

int captured (string input) {
	string s = input;
	SourceFunc f = () => { s = "a"; return false; };
	int n = 0;
	for (int i = 0; i < s.length; i++) {
		f ();
		n++;
	}
	return n;
}

void main () {
	assert (count_for ("hello") == 5);
	assert (count_for ("") == 0);
	assert (count_while ("abc") == 3);
	assert (reassigned ("abc") == 5);
	assert (ref_arg ("abcd") == 2);
	assert (captured ("abcd") == 1);
}
