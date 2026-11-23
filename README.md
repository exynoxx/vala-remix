## vala-remix fork

Performance-oriented fork of upstream `main` (branch `vala-remix`). Goal: faster, leaner generated C (CPU first, memory second) through small, targeted codegen changes — no large refactors — plus parser-only syntax sugar (below). Full test suite passes. Timings: `-O2`, median of 3, valac 0.56 vs fork.

| Change | Effect | Benchmark |
|---|---|---|
| String `switch` compares with `g_strcmp0` + C `switch` instead of `g_quark_from_string` | No global lock, no permanent interning of every input (was an unbounded leak) | 2M distinct strings: 10.68 s / 7.7 GB → 1.22 s / 3 MB |
| `s.length` hoisted out of `for`/`while` conditions (`i < s.length`, `s` an owned local or `in` param not assigned/captured/address-taken in the loop) | strlen once instead of per iteration; gcc can't hoist past external calls | 200k-char loop: 0.93 s → 0.01 s |
| valac invoking cc: honours `$CFLAGS`, adds `-O2` unless `--debug`, `-X -O*` or `-O` in `$CFLAGS` | Plain `valac foo.vala` builds were `-O0`; build systems passing flags unaffected | 2.79 s → 0.23 s (loop), 1.63 s → 0.95 s (mixed) |
| Signal emits from other files / external packages: cached id (`g_signal_lookup` once, `g_signal_emit`) instead of `g_signal_emit_by_name`; dynamic signals unchanged | No name parse + locked lookup per emit | with casts below: 6.67 s → 5.79 s |
| Plain C casts instead of `G_TYPE_CHECK_INSTANCE_CAST` for provable upcasts, `base.` calls, equality upcasts and `self` in `get_property`/`set_property`/`constructor`/`finalize`; downcasts stay checked | Removes out-of-line type-check calls on hot paths | (see above) |
| Closures capture and ref `self` only when the lambda uses `this` (explicit, implicit member, `base`, nested); generic classes, interfaces and structs always capture | Saves an atomic ref/unref and 8 bytes per block; avoids ref cycles | 20M closures: 1.99 s → 0.73 s |

Syntax additions (parser desugarings: no new AST nodes, codegen or runtime; test `tests/parser/remix-syntax.vala`):

| Syntax | Desugars to | Notes |
|---|---|---|
| `int area () => w * h;` · `void f () => g ();` | `{ return w * h; }` · `{ g (); }` | Methods incl. `async`; not constructors |
| `get => e;` · `set => _x = value;` · `int area => w * h;` | accessor block; last form = get-only property | Getters unowned as usual; `{ owned get => @"..."; }` for computed strings |
| `if (o is Foo f)` | hidden `Foo? f = null;` before the statement + `(f = o as Foo) != null` | C# scope: `f` lives in the enclosing block (`if (o is not Foo f) return; f.x ();` works), so reusing a name in one block is a redeclaration error; fine in `&&`, `while`, `else if`; rejected in expression lambdas/initializers (no statement to host it); reference types only (`as`) |
| `o is not Foo` · `o is not Foo f` | `!(o is Foo)` · negated binding | `not` contextual (only before a type name); a type named `not` still parses |
| `foreach (var i in a..b)` | `{ var end = b; for (var i = a; i < end; i++) body }` | Half-open, `b` evaluated once, explicit element type honoured; new `..` token; no `..=`, step or range values |

Unboxing (merged): (A) owned `T?` locals of simple/enum types and heap-free structs that don't escape (not captured, no `ref`/`out`/`(owned)`/`&`, not async) live in a stack slot (`gint slot; gint* x = &slot;`) instead of `g_new0`+`memcpy` boxes; (B) private/internal non-virtual, non-async methods not used as delegates return `T?` as `struct { T value; gboolean has_value; }` by value — public API, headers, vapi and GIR stay boxed (kept boxed under `--use-fast-vapi`/`--internal-header`); (C) `int64`/`uint64`/`float`/`double` accepted as unboxed generic type arguments (`GenericArray<double>`), bit-cast into the pointer, no dup/free; files using it carry `G_STATIC_ASSERT (sizeof (gpointer) >= 8)` so 32-bit fails at C compile time. `T?` keeps null semantics. Applies cleanly on upstream `main` without the rest of the fork (measured there, results identical):

| Unboxing benchmark (upstream `main` vs `main` + unboxing, `-O2`, median of 3) | `main` | `main` + unboxing | Gain |
|---|---|---|---|
| A: `int?`/`Point?` assignment loops (2×100M) | 3.05 s | 0.48 s | 6.4× |
| A+B: `int? x = maybe (i); if (x != null)` and `Point?` returns (2×100M) | 5.11 s | 0.38 s | 13× |
| C: `GenericArray<double?>` → `<double>`, 10M add + 10 reads, 2M HashTable ops | 1.23 s / 505 MB | 0.38 s / 147 MB | 3.2×, 3.4× less memory |
| C: `GenericArray<int64?>` → `<int64>`, same workload | 1.22 s / 505 MB | 0.28 s / 114 MB | 4.4×, 4.4× less memory |

Original benchmark table — every change attempted, valac 0.56 vs fork, with compiler lines added/removed (`codegen/` + `vala/`, tests excluded):

| Change | Benchmark | Gain | Lines | Status |
|---|---|---|---|---|
| String `switch` via `g_strcmp0` | 2M distinct strings: 10.68 s / 7.7 GB → 1.22 s / 3 MB | ~9×, ~2500× less memory | +39 / −94 | merged |
| `s.length` hoisting | 200k-char loop: 0.93 s → 0.01 s | ~90× (one loop shape) | +101 / −2 | merged |
| Default `-O2` + `$CFLAGS` | plain `valac`: 1.63 s → 0.95 s (2.79 → 0.23 s loop) | 1.7–12× (plain `valac` only) | +12 / 0 | merged |
| Cached signal ids | with casts: 6.67 s → 5.79 s | 1.15× | +49 / −5 | merged |
| Unchecked provable upcasts | (with signal ids) | — | +19 / −11 | merged |
| Closures capture `self` only when used | 20M closures: 1.99 s → 0.73 s | 2.7× | +63 / −7 | merged |
| Unboxed 64-bit generic args (C) | 0.89 s / 394 MB → 0.24 s / 81 MB | 3.7×, 4.9× less memory | +83 / −2 | merged |
| Nullable stack slots + unboxed returns (A+B) | see table above | 6–13× | +352 / −12 | merged |
| String `+` chain flattening | 9 operands ×10M: 8.09 s → 2.99 s | 2.7× | +150 / −2 (with `+=`) | reverted |
| In-place `+=` append | 1M appends: 2.53 s → 0.55 s | 4.6× | (with `+` chains) | reverted |
| Enum `to_string` switch, drop empty `priv`, setter field read, `g_new` | mixed: 1.31 s → 1.04 s | 1.25× | +79 / −10 | reverted |
| Async temporaries as C locals | 4.19 s → 4.04 s; data struct 288 → 120 B | ~1× (memory only) | +55 / −2 | reverted |

Tried and reverted: flattening string `+` chains / in-place `+=`, switch-based enum `to_string`, dropping empty `priv`, setter field reads, `g_new` for struct dup, async temporaries as C locals (gain did not justify the added code or behaviour change). Not attempted: making `foreach` loop variables unowned (risks use-after-free).

Behaviour notes: string-switch labels are evaluated once before matching; hoisted `s.length` for `in` params assumes the caller doesn't mutate the buffer behind Vala's back; cached signal ids go stale if a dynamic (plugin) type is unloaded and re-registered; interface upcasts are unchecked; plain `valac` now optimizes by default (also affects test binaries); internal methods returning `T?` use a by-value struct ABI, so hand-written C prototypes for them break; an unowned alias of a stack-slot local sees later reassignments.

Build from this shallow clone: `autoreconf -fi && ./configure --disable-valadoc && make` (`m4/ax_check_compile_flag.m4` replaces autoconf-archive; `.tarball-version` pins `0.57.0.remix` since there are no tags).

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
