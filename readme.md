HxLox
=====

Haxe implementation of the [Lox language](http://www.craftinginterpreters.com/the-lox-language.html).

Still a few rough edges, but this was mostly done for fun/education.

Usage
-----

Compile:
```
> haxe build.hxml
```

Run the REPL:
```
> neko bin/hxlox.n
```

Interpret a file:
```
> neko bin/hxlox.n example/test.lox
```

You could also compile the code with any other Haxe target that supports the `sys` package.

Notes
-----

This branch extends Lox a bit to add the following features:

- Imports
- Static methods
- `print` is no longer built-in -- use `System.print` instead.