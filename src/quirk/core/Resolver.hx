package quirk.core;

import quirk.Token;
import quirk.Expr;
import quirk.Stmt;
import quirk.ExprVisitor;
import quirk.StmtVisitor;
import quirk.ErrorReporter;
import quirk.core.FunctionType;
import quirk.core.ClassType;

using Lambda;

class Resolver
  implements ExprVisitor<Void>
  implements StmtVisitor<Void>
{

  private var resolvable:Resolvable;
  private var reporter:ErrorReporter;
  // As far as I can tell Haxe stacks don't have enough functionality, so we're using Arrays
  // for the moment.
  private var scopes:Array<Map<String, Bool>> = [];
  private var currentFunction = FunNone;
  private var currentClass = ClsNone;

  public function new(resolvable:Resolvable, reporter:ErrorReporter) {
    this.resolvable = resolvable;
    this.reporter = reporter;
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
      error(stmt.keyword, "Cannot return from top-level code.");
    }
    if (currentFunction.equals(FunConstructor)) {
      error(stmt.keyword, "Cannot return a value from an initializer");
    }
    if (stmt.value != null) {
      resolveExpr(stmt.value);
    }
  }

  public function visitThrowStmt(stmt:Stmt.Throw):Void {
    resolveExpr(stmt.expr);
  }

  public function visitTryStmt(stmt:Stmt.Try):Void {
    resolveStatement(stmt.body);
    resolveStatement(stmt.caught);
    declare(stmt.exception);
    define(stmt.exception);
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

  public function visitSubscriptGetExpr(expr:Expr.SubscriptGet):Void {
    resolveExpr(expr.object);
    resolveExpr(expr.index);
  }

  public function visitSubscriptSetExpr(expr:Expr.SubscriptSet):Void {
    resolveExpr(expr.object);
    resolveExpr(expr.index);
    resolveExpr(expr.value);
  }

  public function visitSuperExpr(expr:Expr.Super):Void {
    if (currentClass.equals(ClsNone)) {
      error(expr.keyword, "Cannot use 'super' outside of a class.");
    } else if (!currentClass.equals(ClsSubClass)) {
      error(expr.keyword, "Cannot use 'super' in a class with no superclass.");
    }
    resolveLocal(expr, expr.keyword);
  }

  public function visitThisExpr(expr:Expr.This):Void {
    if (currentClass.equals(ClsNone)) {
      error(expr.keyword, "Cannot use 'this' outside of a class.");
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
      if (method.kind.equals(quirk.Stmt.FunKind.FunConstructor)) {
        type = FunConstructor;
      }
      resolveFunction(method, type);
    }
    endScope();

    beginScope();
    scopes[scopes.length - 1].set('this', true);
    for (method in stmt.staticMethods) {
      var type = FunMethod;
      if (method.kind.equals(quirk.Stmt.FunKind.FunConstructor)) {
        type = FunConstructor;
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
    if (stmt.alias != null) {
      define(stmt.alias);
      declare(stmt.alias);
    }
    for (name in stmt.imports) {
      define(name);
      declare(name);
    }
  }

  public function visitModuleStmt(stmt:Stmt.Module):Void {
    // noop
  }

  public function visitLambdaExpr(expr:Expr.Lambda):Void {
    resolveFunction(cast expr.fun, FunLambda);
  }

  public function visitVariableExpr(expr:Expr.Variable):Void {
    if (!scopes.empty() && scopes[scopes.length - 1].get(expr.name.lexeme) == false) {
      error(expr.name, "Cannot read local variable in its own initializer.");
    }
    resolveLocal(expr, expr.name);
  }

  public function visitMetadataExpr(expr:Expr.Metadata):Void {
    // noop
  }

  public function visitAssignExpr(expr:Expr.Assign):Void {
    resolveExpr(expr.value);
    resolveLocal(expr, expr.name);
  }

  public function visitArrayLiteralExpr(expr:Expr.ArrayLiteral):Void {
    for (value in expr.values) {
      resolveExpr(value);
    }
  }

  public function visitObjectLiteralExpr(expr:Expr.ObjectLiteral):Void {
    for (value in expr.values) {
      resolveExpr(value);
    }
  }

  private function resolveExpr(expr:Expr) {
    expr.accept(this);
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
      error(name, "Variable with this name already declared in this scope.");
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
    var i = scopes.length - 1;
    while (i >= 0) {
      var scope = scopes[i];
      if (scope.exists(name.lexeme)) {
        resolvable.resolve(expr, scopes.length - 1 - i);
        return;
      }
      i--;
    }
  }

  private function error(token:Token, message:String) {
    reporter.report(token.pos, token.lexeme, message);
  }

}