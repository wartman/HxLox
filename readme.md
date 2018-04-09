Quirk
=====

Initially started as a haxe impelementation of the [Lox language](http://www.craftinginterpreters.com/the-lox-language.html).

Still a few rough edges, but this was mostly done for fun/education.

Usage
-----

Compile:
```
> haxe build.hxml
```

Run the REPL:
```
> neko bin/quirk.n
```

Interpret a file:
```
> neko bin/quirk.n example/test.qrk
```

You could also compile the code with any other Haxe target that supports the `sys` package.

Notes
-----

Basically this branch has left Lox behind and is doing its own thing.

Its own, poorly tested thing.
