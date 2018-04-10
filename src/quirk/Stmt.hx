package quirk;

@:autoBuild(quirk.tools.AstBuilder.buildNode())
interface Stmt {
  public function accept<T>(visitor:StmtVisitor<T>):T;
}

class Expression implements Stmt {
  var expression:Expr;
}

class Import implements Stmt {
  var path:Array<Token>;
  var alias:Token;
  var imports:Array<Token>;
  var meta:Array<Expr>;
}

class Module implements Stmt {
  var path:Array<Token>;
  var exports:Array<Token>;
  var meta:Array<Expr>;
}

class Var implements Stmt {
  var name:Token;
  var initializer:Expr;
  var meta:Array<Expr>;
  var type:Type;
}

class Throw implements Stmt {
  var keyword:Token;
  var expr:Expr;
}

class Try implements Stmt {
  var body:Stmt;
  var caught:Stmt;
  var exception:Token;
}

class While implements Stmt {
  var condition:Expr;
  var body:Stmt;
}

class Block implements Stmt {
  var statements:Array<Stmt>;
}

class If implements Stmt {
  var condition:Expr;
  var thenBranch:Stmt;
  var elseBranch:Stmt;
}

class Fun implements Stmt {
  var name:Token;
  var params:Array<{
    name: Token,
    ?type: Type,
    ?value: Expr
  }>;
  var ret:Type;
  var body:Array<Stmt>;
  var meta:Array<Expr>;
}

class Return implements Stmt {
  var keyword:Token;
  var value:Expr;
}

class Class implements Stmt {
  var name:Token;
  var superclass:Expr;
  var methods:Array<Stmt.Fun>;
  var staticMethods:Array<Stmt.Fun>;
  var meta:Array<Expr>;
}
