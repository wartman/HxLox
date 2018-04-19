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

Grammar
-------

(note: `;` also indicates a newline, not just a semicolon)

```
expression     → equality ;
equality       → comparison ( ( "!=" | "==" ) comparison )* ;
comparison     → addition ( ( ">" | ">=" | "<" | "<=" ) addition )* ;
addition       → multiplication ( ( "-" | "+" ) multiplication )* ;
multiplication → unary ( ( "/" | "*" ) unary )* ;
unary          → ( "!" | "-" ) unary
               | primary ;
primary        → NUMBER | STRING | "false" | "true" | "null"
               | "(" expression ")" | ( interpolation )* ;
```