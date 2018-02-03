package hxlox;

@:autoBuild(hxlox.tools.AstBuilder.buildNode())
interface Stmt {
  public function accept<T>(visitor:StmtVisitor<T>):T;
}

class Expression implements Stmt {
  var expression:Expr;
}

class Print implements Stmt {
  var expression:Expr;
}

class Var implements Stmt {
  var name:Token;
  var initializer:Expr;
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
  var params:Array<Token>;
  var body:Array<Stmt>;
}

class Return implements Stmt {
  var keyword:Token;
  var value:Expr;
}

class Class implements Stmt {
  var name:Token;
  var superclass:Expr;
  var methods:Array<Stmt.Fun>;
}
