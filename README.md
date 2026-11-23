# vala-remix

## Fork changes

### New Syntax

```vala
int area () => w * h;            // expression-bodied method
int area => w * h;               // expression-bodied get-only property
int x { get => _x; set => _x = value; }  // expression-bodied accessors
if (o is Foo f) f.bar ();        // type test with binding (f usable in the block)
if (o is not Foo) return;        // negated type test (also: o is not Foo f)
foreach (var i in 0..n) { }      // half-open range loop, n evaluated once
```

All are parser desugarings (no runtime cost);

### Performance Optimizations

| Optimization | Gain (`-O2`) |
|---|---|
| String `switch` via `g_strcmp0` (no quark interning) | 9×, 7.7 GB → 3 MB |
| `s.length` hoisted out of loop conditions | up to 90× |
| Nullable locals on the stack, unboxed `T?` returns (internal methods) | 6–13× |
| Unboxed `int64`/`double` generic args (`GenericArray<double>`) | 3–4×, 3–4× less memory |
| Closures capture `self` only when used | 2.7× |
| Default `-O2` / `$CFLAGS` when valac runs cc | 1.7–12× |
| Cached signal ids, unchecked provable upcasts | 1.15× |

plain `valac` now builds with `-O2`; 64-bit generic args need a 64-bit target; internal `T?` methods return a struct by value.
Build: `autoreconf -fi && ./configure --disable-valadoc && make`.

## What is Vala?
Vala is a programming language that aims to bring modern programming
language features to GNOME developers without imposing any additional
runtime requirements and without using a different ABI compared to
applications and libraries written in C.

`valac`, the Vala compiler, is a self-hosting compiler that translates
Vala source code into C source and header files. It uses the GObject
type system to create classes and interfaces declared in the Vala source
code.

The syntax of Vala is similar to C#, modified to better fit the GObject
type system. Vala supports modern language features as the following:

 * Interfaces
 * Properties
 * Signals
 * Foreach
 * Lambda expressions
 * Type inference for local variables
 * Generics
 * Non-null types
 * Assisted memory management
 * Exception handling

Vala is designed to allow access to existing C libraries, especially
GObject-based libraries, without the need for runtime bindings. All that
is needed to use a library with Vala is an API file, containing the class
and method declarations in Vala syntax. Vala currently comes with
bindings for GLib and GTK+.

Using classes and methods written in Vala from an application written in
C is not difficult. The Vala library only has to install the generated
header files and C applications may then access the GObject-based API of
the Vala library as usual. It should also be easily possible to write a
bindings generator for access to Vala libraries from applications
written in e.g. C# as the Vala parser is written as a library, so that
all compile-time information is available when generating a binding.

More information about Vala is available at [https://vala.dev](https://vala.dev)


## Building Vala
Instructions on how to build the latest version of Vala.
These can be modified to build a specific release.

### Step One:
Install the following packages:

 * a C compiler, e.g. GCC
 * a C library, e.g. glibc
 * glib (>= 2.56)
 * gobject-introspection
 * flex
 * bison
 * Graphviz (libgvc) (>= 2.16) to build valadoc
 * make
 * autoconf
 * autoconf-archive
 * automake
 * libtool

These additional packages are needed to generate the documentation:

 * help2man when updating the man pages
 * sphinx, python-furo
 * latexmk, texlive for PDF generation

### Step Two:
Decide where the Vala compiler is to be found.

Vala is self-hosting so it needs another Vala compiler to compile
itself.  `valac` is the name of the executable and can be:

 * installed from an existing package
 * built from a source tarball
 * built from the [Vala bootstrap module](https://gitlab.gnome.org/Archive/vala-bootstrap)

If you have an existing `valac` installed then move on to step three.

If you don't have an existing version of Vala installed (i.e. because you're
bootstrapping or cross-compiling) then a source tarball or the vala-bootstrap
module contain pre-compiled C files from the Vala sources. These can be used
to bootstrap `valac`.

Current releases of source tarballs can be downloaded via:

https://download.gnome.org/sources/vala/

or the vala-bootstrap module is available at:

https://gitlab.gnome.org/Archive/vala-bootstrap


Here is an example on how to download and compile from a Vala release tarball.
In this example it is release version 0.48.25:

```sh
curl --silent --show-error --location https://download.gnome.org/sources/vala/0.48/vala-0.48.25.tar.xz --output vala-bootstrap.tar.xz
tar --extract --file vala-bootstrap.tar.xz
cd vala-bootstrap
./configure --prefix=/opt/vala-bootstrap
make && sudo make install
```

The configure script will check if `valac` can be found in PATH. If not then
`valac` is bootstrapped from the C source files in the tarball.
If you do not wish to install the bootstrapped version of `valac` it can be
found in `vala-bootstrap/compiler/valac` This is a libtool wrapper script
that makes the libraries in the build directory work together.


An example of downloading and compiling from the bootstrap module:

```sh
git clone https://gitlab.gnome.org/Archive/vala-bootstrap
cd vala-bootstrap
touch */*.stamp
VALAC=/no-valac ./configure --prefix=/opt/vala-bootstrap
make && sudo make install
```

### Step Three:
Compiling the newest Vala from the repository using a pre-installed `valac`:

```sh
git clone https://gitlab.gnome.org/GNOME/vala
cd vala
./autogen.sh
make && sudo make install
```

To use `valac` from a bootstrapped build detailed in step two use:

```sh
git clone https://gitlab.gnome.org/GNOME/vala
cd vala
VALAC=/opt/vala-bootstrap/bin/valac ./autogen.sh
make && sudo make install
```

### Compiling Different Vala Versions
Maybe you now want to compile Vala with the new version you have just installed.
Then you simply clean the version files and start the build. Be warned that
`git clean -dfx` **will remove all untracked files** from the source tree:

```sh
git clean -dfx
./autogen.sh
make && sudo make install
```

If you wish to build a specific release, for example 0.56.17:

```sh
git checkout 0.56.17
git clean -dfx
./autogen.sh
make && sudo make install
```
