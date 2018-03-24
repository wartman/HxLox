package hxlox.interpreter;

import hxlox.Token;
import hxlox.Expr;
import hxlox.Stmt;
import hxlox.ExprVisitor;
import hxlox.StmtVisitor;
import hxlox.interpreter.FunctionType;
import hxlox.interpreter.ClassType;

using Lambda;

class Resolver 
  implements ExprVisitor<Void> 
  implements StmtVisitor<Void> 
{

  private var interpreter:Interpreter;
  // As far as I can tell Haxe stacks don't have enough functionality, so we're using Arrays
  // for the moment.
  private var scopes:Array<Map<String, Bool>> = [];
  private var currentFunction = FunNone;
  private var currentClass = ClsNone;

  public function new(interpreter:Interpreter) {
    this.interpreter = interpreter;
  }

  public function resolve(statements:Array<Stmt>) {
    for (stmt in statements) {
      resolveStatement(stmt);
    }
  }

  public function visitBlockStmt(stmt:Stmt.Block):Void {
    beginScope();
    resolve(stmt.statements);
    endScope();
  }

  public function visitExpressionStmt(stmt:Stmt.Expression):Void {
    resolveExpr(stmt.expression);
  }

  public function visitIfStmt(stmt:Stmt.If):Void {
    resolveExpr(stmt.condition);
    resolveStatement(stmt.thenBranch);
    if (stmt.elseBranch != null) resolveStatement(stmt.elseBranch);
  }

  public function visitReturnStmt(stmt:Stmt.Return):Void {
    if (currentFunction.equals(FunNone)) {
      HxLox.error(stmt.keyword, "Cannot return from top-level code.");
    }
    if (currentFunction.equals(FunInitializer)) {
      HxLox.error(stmt.keyword, "Cannot return a value from an initializer");
    }
    if (stmt.value != null) {
      resolveExpr(stmt.value);
    }
  }

  public function visitWhileStmt(stmt:Stmt.While):Void {
    resolveExpr(stmt.condition);
    resolveStatement(stmt.body);
  }

  public function visitVarStmt(stmt:Stmt.Var):Void {
    declare(stmt.name);
    if (stmt.initializer != null) {
      resolveExpr(stmt.initializer);
    }
    define(stmt.name);
  }

  public function visitBinaryExpr(expr:Expr.Binary):Void {
    resolveExpr(expr.left);
    resolveExpr(expr.right);
  }

  public function visitCallExpr(expr:Expr.Call):Void {
    resolveExpr(expr.callee);
    expr.args.foreach(function (expr) {
      resolveExpr(expr);
      return true; 
    });
  }

  public function visitGetExpr(expr:Expr.Get):Void {
    resolveExpr(expr.object);
  }

  public function visitGroupingExpr(expr:Expr.Grouping):Void {
    resolveExpr(expr.expression);
  }

  public function visitLiteralExpr(expr:Expr.Literal):Void {
    // noop
  }

  public function visitLogicalExpr(expr:Expr.Logical):Void {
    resolveExpr(expr.left);
    resolveExpr(expr.right);
  }

  public function visitSetExpr(expr:Expr.Set):Void {
    resolveExpr(expr.value);
    resolveExpr(expr.object);
  }

  public function visitSuperExpr(expr:Expr.Super):Void {
    if (currentClass.equals(ClsNone)) {
      HxLox.error(expr.keyword,  "Cannot use 'super' outside of a class.");
    } else if (!currentClass.equals(ClsSubClass)) {
      HxLox.error(expr.keyword, "Cannot use 'super' in a class with no superclass.");
    }
    resolveLocal(expr, expr.keyword);
  }

  public function visitThisExpr(expr:Expr.This):Void {
    if (currentClass.equals(ClsNone)) {
      HxLox.error(expr.keyword, "Cannot use 'this' outside of a class.");
      return;
    }
    resolveLocal(expr, expr.keyword);
  }

  public function visitUnaryExpr(expr:Expr.Unary):Void {
    resolveExpr(expr.right);
  }

  public function visitFunStmt(stmt:Stmt.Fun):Void {
    declare(stmt.name);
    define(stmt.name);
    resolveFunction(stmt, FunFunction);
  }

  public function visitClassStmt(stmt:Stmt.Class):Void {
    declare(stmt.name);
    define(stmt.name);

    var enclosingClass = currentClass;
    currentClass = ClsClass;

    if (stmt.superclass != null) {
      currentClass = ClsSubClass;
      resolveExpr(stmt.superclass);
      beginScope();
      scopes[scopes.length - 1].set('super', true);
    }

    beginScope();
    scopes[scopes.length - 1].set('this', true);
    for (method in stmt.methods) {
      var type = FunMethod;
      if (method.name.lexeme == 'init') {
        type = FunInitializer;
      }
      resolveFunction(method, type);
    }
    endScope();
    
    if (stmt.superclass != null) { 
      endScope();
    }

    currentClass = enclosingClass;
  }

  public function visitImportStmt(stmt:Stmt.Import):Void {
    for (name in stmt.imports) {
      define(name);
      declare(name);
    }
  }

  public function visitVariableExpr(expr:Expr.Variable):Void {
    if (!scopes.empty() && scopes[scopes.length - 1].get(expr.name.lexeme) == false) {
      HxLox.error(expr.name, "Cannot read local variable in its own initializer.");
    }
    resolveLocal(expr, expr.name);
  }

  public function visitAssignExpr(expr:Expr.Assign):Void {
    resolveExpr(expr.value);
    resolveLocal(expr, expr.name);
  }

  private function resolveStatement(stmt:Stmt) {
    stmt.accept(this);
  }

  private function resolveFunction(fun:Stmt.Fun, type:FunctionType) {
    var enclosingFunction = currentFunction;
    currentFunction = type;

    beginScope();
    for (param in fun.params) {
      declare(param);
      define(param);
    }
    resolve(fun.body);
    endScope();

    currentFunction = enclosingFunction;
  }

  private function resolveExpr(expr:Expr) {
    expr.accept(this);
  }

  private function beginScope() {
    scopes.push(new Map());
  }

  private function endScope() {
    scopes.pop();
  }

  private function declare(name:Token) {
    if (scopes.length == 0) {
      return;
    }
    var scope = scopes[scopes.length - 1];
    if (scope.exists(name.lexeme)) {
      HxLox.error(name, "Variable with this name already declared in this scope.");
    }
    scope.set(name.lexeme, false);
  }

  private function define(name:Token) {
    if (scopes.length == 0) {
      return;
    }
    scopes[scopes.length - 1].set(name.lexeme, true);
  }

  private function resolveLocal(expr:Expr, name:Token) {
    var i = scopes.length -1;
    while (i >= 0) {
      var scope = scopes[i];
      if (scope.exists(name.lexeme)) {
        interpreter.resolve(expr, scopes.length - 1 - i);
        return;
      }
      i--;
    }
  }

}
