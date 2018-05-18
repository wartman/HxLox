package quirk.generator;

import quirk.Expr;
import quirk.Stmt;
import quirk.ExprVisitor;
import quirk.StmtVisitor;
import quirk.generator.PhpEnvironment.PhpKind;

using Lambda;

// Note: this is just a resolver to figure out
// php types for now (so we know when we need
// `static::method` or `$variable->property`, etc).
// May be a real typer later.
class PhpResolver
  implements ExprVisitor<Void>
  implements StmtVisitor<Void>
{

  private var generator:PhpGenerator;

  public function new(generator:PhpGenerator) {
    this.generator = generator;
  }

  public function resolve(stmts:Array<Stmt>):Void {
    for (stmt in stmts) {
      resolveStmt(stmt);
    } 
  }

  private function resolveStmt(stmt:Stmt) {
    stmt.accept(this);
  }

  private function resolveExpr(expr:Expr) {
    expr.accept(this);
  }

  private function resolveFunction(fun:Stmt.Fun) {
    // need scopes :P
    for (param in fun.params) {
      generator.define(param, PhpVar);
    }
    resolve(fun.body);
  }

  public function visitBlockStmt(stmt:Stmt.Block):Void {
    resolve(stmt.statements);
  }

  public function visitExpressionStmt(stmt:Stmt.Expression):Void {
    resolveExpr(stmt.expression);
  }

  public function visitIfStmt(stmt:Stmt.If):Void {
    resolveExpr(stmt.condition);
    resolveStmt(stmt.thenBranch);
    if (stmt.elseBranch != null) resolveStmt(stmt.elseBranch);
  }

  public function visitReturnStmt(stmt:Stmt.Return):Void {
    // if (currentFunction.equals(FunNone)) {
    //   error(stmt.keyword, "Cannot return from top-level code.");
    // }
    // if (currentFunction.equals(FunConstructor)) {
    //   error(stmt.keyword, "Cannot return a value from an initializer");
    // }
    if (stmt.value != null) {
      resolveExpr(stmt.value);
    }
  }

  public function visitThrowStmt(stmt:Stmt.Throw):Void {
    resolveExpr(stmt.expr);
  }

  public function visitTryStmt(stmt:Stmt.Try):Void {
    resolveStmt(stmt.body);
    resolveStmt(stmt.caught);
    // declare(stmt.exception);
    // define(stmt.exception);
  }

  public function visitWhileStmt(stmt:Stmt.While):Void {
    resolveExpr(stmt.condition);
    resolveStmt(stmt.body);
  }

  public function visitVarStmt(stmt:Stmt.Var):Void {
    generator.define(stmt.name, PhpVar);
    if (stmt.initializer != null) {
      resolveExpr(stmt.initializer);
    }
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
    // if (currentClass.equals(ClsNone)) {
    //   error(expr.keyword, "Cannot use 'super' outside of a class.");
    // } else if (!currentClass.equals(ClsSubClass)) {
    //   error(expr.keyword, "Cannot use 'super' in a class with no superclass.");
    // }
    // resolveLocal(expr, expr.keyword);
  }

  public function visitThisExpr(expr:Expr.This):Void {
    // if (currentClass.equals(ClsNone)) {
    //   error(expr.keyword, "Cannot use 'this' outside of a class.");
    //   return;
    // }
    // resolveLocal(expr, expr.keyword);
  }

  public function visitUnaryExpr(expr:Expr.Unary):Void {
    resolveExpr(expr.right);
  }

  public function visitFunStmt(stmt:Stmt.Fun):Void {
    generator.define(stmt.name, PhpFun);
    resolveFunction(stmt);
  }

  public function visitClassStmt(stmt:Stmt.Class):Void {
    generator.define(stmt.name, PhpType);
    if (stmt.superclass != null) {
      resolveExpr(stmt.superclass);
    }
    for (method in stmt.methods) {
      resolveFunction(method);
    }
    for (method in stmt.staticMethods) {
      resolveFunction(method);
    }

    // declare(stmt.name);
    // define(stmt.name);

    // var enclosingClass = currentClass;
    // currentClass = ClsClass;

    // if (stmt.superclass != null) {
    //   currentClass = ClsSubClass;
    //   resolveExpr(stmt.superclass);
    //   beginScope();
    //   scopes[scopes.length - 1].set('super', true);
    // }

    // beginScope();
    // scopes[scopes.length - 1].set('this', true);
    // for (method in stmt.methods) {
    //   var type = FunMethod;
    //   if (method.kind.equals(quirk.Stmt.FunKind.FunConstructor)) {
    //     type = FunConstructor;
    //   }
    //   resolveFunction(method, type);
    // }
    // endScope();

    // beginScope();
    // scopes[scopes.length - 1].set('this', true);
    // for (method in stmt.staticMethods) {
    //   var type = FunMethod;
    //   if (method.kind.equals(quirk.Stmt.FunKind.FunConstructor)) {
    //     type = FunConstructor;
    //   }
    //   resolveFunction(method, type);
    // }
    // endScope();

    // if (stmt.superclass != null) {
    //   endScope();
    // }

    // currentClass = enclosingClass;
  }

  public function visitImportStmt(stmt:Stmt.Import):Void {
    if (stmt.alias != null) {
      generator.define(stmt.alias, PhpVar);
    }
    for (name in stmt.imports) {
      generator.define(name, PhpType);
      // define(name);
      // declare(name);
    }
  }

  public function visitModuleStmt(stmt:Stmt.Module):Void {
    // noop
  }

  public function visitLambdaExpr(expr:Expr.Lambda):Void {
    // noop
  }

  public function visitVariableExpr(expr:Expr.Variable):Void {
  }

  public function visitMetadataExpr(expr:Expr.Metadata):Void {
    // noop
  }

  public function visitAssignExpr(expr:Expr.Assign):Void {
    resolveExpr(expr.value);
    // resolveLocal(expr, expr.name);
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

}