package quirk;

@:autoBuild(quirk.tools.AstBuilder.buildNode())
interface Expr {
  public function accept<T>(visitor:ExprVisitor<T>):T;
}

class Metadata implements Expr {
  var name:Token;
  var args:Array<Expr>;
  var expr:Expr;
}

class Assign implements Expr {
  var name:Token;
  var value:Expr;
}

class Binary implements Expr {
  var left:Expr;
  var op:Token;
  var right:Expr;
}

class Logical implements Expr {
  var left:Expr;
  var op:Token;
  var right:Expr;
}

class Call implements Expr {
  var callee:Expr;
  var paren:Token;
  var args:Array<Expr>;
}

class Get implements Expr {
  var object:Expr;
  var name:Token;
}

class Set implements Expr {
  var object:Expr;
  var name:Token;
  var value:Expr;
}

class SubscriptGet implements Expr {
  var end:Token;
  var object:Expr;
  var index:Expr;
}

class SubscriptSet implements Expr {
  var end:Token;
  var object:Expr;
  var index:Expr;
  var value:Expr;
}

class Super implements Expr {
  var keyword:Token;
  var method:Token;
}

class This implements Expr {
  var keyword:Token;
}

class Grouping implements Expr {
  var expression:Expr;
}

class Literal implements Expr {
  var value:Dynamic;
}

class ArrayLiteral implements Expr {
  var end:Token;
  var values:Array<Expr>;
}

class ObjectLiteral implements Expr {
  var end:Token;
  var keys:Array<Token>;
  var values:Array<Expr>;
}

class Lambda implements Expr {
  var fun:Stmt;
}

class Unary implements Expr {
  var op:Token;
  var right:Expr;
}

class Variable implements Expr {
  var name:Token;
}
