struct Point {
	public int x;
	public int y;
}

class Foo : Object {
	public string str { get; set; }
	public int num { get; set; }
	public Point point { get; set; }
	[CCode (array_length = false, array_null_terminated = true)]
	public string[] arr { get; set; }
	public virtual int virt { get; set; }
}

class Bar : Foo {
	public override int virt { get; set; }
}

int counter;

void main () {
	var foo = new Bar ();
	foo.notify.connect (() => counter++);

	foo.str = "a";
	assert (counter == 1);
	foo.str = "a";
	assert (counter == 1);
	foo.str = "b";
	assert (counter == 2 && foo.str == "b");

	foo.num = 0;
	assert (counter == 2);
	foo.num = 5;
	assert (counter == 3 && foo.num == 5);

	foo.point = { 1, 2 };
	assert (counter == 4);
	foo.point = { 1, 2 };
	assert (counter == 4);

	foo.arr = { "x" };
	assert (counter == 5 && foo.arr[0] == "x");

	foo.virt = 1;
	assert (counter == 6);
	foo.virt = 1;
	assert (counter == 6 && foo.virt == 1);
}
