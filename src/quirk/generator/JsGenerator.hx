package quirk.generator;

import quirk.Expr;
import quirk.Stmt;
import quirk.ExprVisitor;
import quirk.StmtVisitor;
import quirk.ErrorReporter;
import quirk.ModuleLoader;

using Lambda;

class JsGenerator
  implements ExprVisitor<String>
  implements StmtVisitor<String>
{

  private var reporter:ErrorReporter;
  private var loader:ModuleLoader;
  private var indentLevel:Int = 0;

  public function new(loader:ModuleLoader, reporter:ErrorReporter) {
    this.loader = loader;
    this.reporter = reporter;
  }

  public function generate(stmts:Array<Stmt>):String {
    return stmts.map(generateStmt).join('');
  }

  private function generateStmt(stmt:Stmt):String {
    return stmt.accept(this);
  }

  private function generateExpr(expr:Null<Expr>):String {
    if (expr == null) return '';
    return expr.accept(this);
  }

  public function visitBlockStmt(stmt:Stmt.Block):String {
    return '{\n' + stmt.statements.map(generateStmt).join('\n') + '\n}';
  }

  public function visitExpressionStmt(stmt:Stmt.Expression):String {
    return generateExpr(stmt.expression);
  }

  public function visitIfStmt(stmt:Stmt.If):String {
    return '';
  }

  public function visitReturnStmt(stmt:Stmt.Return):String {
    return stmt.value == null
      ? 'return'
      : 'return ' + generateExpr(stmt.value);
  }

  public function visitThrowStmt(stmt:Stmt.Throw):String {
    return 'throw ' + generateExpr(stmt.expr);
  }

  public function visitTryStmt(stmt:Stmt.Try):String {
    return '';
  }

  public function visitWhileStmt(stmt:Stmt.While):String {
    return '';
  }

  public function visitVarStmt(stmt:Stmt.Var):String {
    return 'var ' + stmt.name.lexeme + ' = '
      + stmt.initializer != null ? generateExpr(stmt.initializer) : 'null';
  }

  public function visitBinaryExpr(expr:Expr.Binary):String {
    return generateExpr(expr.left) + ' ' + expr.op.lexeme + ' ' + generateExpr(expr.right);
  }

  public function visitCallExpr(expr:Expr.Call):String {
    return generateExpr(expr.callee) + '(' + expr.args.map(generateExpr).join(', ')  + ')';
  }

  public function visitGetExpr(expr:Expr.Get):String {
    return generateExpr(expr.object) + '.' + expr.name.lexeme;
  }

  public function visitGroupingExpr(expr:Expr.Grouping):String {
    return '(' + generateExpr(expr.expression) + ')';
  }

  public function visitLiteralExpr(expr:Expr.Literal):String {
    return Std.is(expr.value, String)
      ? '"' + expr.value + '"' // todo: handle escaping
      : expr.value;
  }

  public function visitLogicalExpr(expr:Expr.Logical):String {
    return generateExpr(expr.left) + expr.op.lexeme + generateExpr(expr.right);
  }

  public function visitSetExpr(expr:Expr.Set):String {
    return generateExpr(expr.object) + '.' + expr.name.lexeme + '=' + generateExpr(expr.value);
  }

  public function visitSubscriptGetExpr(expr:Expr.SubscriptGet):String {
    return generateExpr(expr.object) + '[' + generateExpr(expr.index) + ']';
  }

  public function visitSubscriptSetExpr(expr:Expr.SubscriptSet):String {
    return generateExpr(expr.object) + '[' + generateExpr(expr.index) + ']'
      + '=' + generateExpr(expr.value);
  }

  public function visitSuperExpr(expr:Expr.Super):String {
    return 'super.' + expr.method.lexeme;
  }

  public function visitThisExpr(expr:Expr.This):String {
    return 'this';
  }

  public function visitUnaryExpr(expr:Expr.Unary):String {
    return expr.op.lexeme + generateExpr(expr.right);
  }

  public function visitFunStmt(stmt:Stmt.Fun):String {
    return 'function ' + stmt.name.lexeme + '('
      + stmt.params.map(function (t) return t.lexeme).join(', ') + ') '
      + '{\n' + stmt.body.map(generateStmt).join('\n') + '\n};\n';
  }

  public function visitClassStmt(stmt:Stmt.Class):String {
    var name = stmt.name.lexeme;
    var out = 'var ' + name + '=';
    var init = stmt.methods.find(function (m) {
      return m.name.lexeme == 'new';
    });
    if (init != null) {
      init.name = stmt.name;
      out += visitFunStmt(init);
    } else {
      out += 'function ' + name + '() {};\n';
    }
    if (stmt.superclass != null) {
      out += '__quirk_extend(' + name + ', ' + generateExpr(stmt.superclass) + ');\n';
    }
    for (method in stmt.methods) {
      out += name + '.prototype.' + method.name.lexeme + ' = ' + visitFunStmt(method);
    }
    return out;
  }

  public function visitImportStmt(stmt:Stmt.Import):String {
    return '';
  }

  public function visitModuleStmt(stmt:Stmt.Module):String {
    return '';
  }

  public function visitLambdaExpr(expr:Expr.Lambda):String {
    var fun:Stmt.Fun = cast expr.fun;
    return 'function (' + fun.params.map(function (p) return p.lexeme).join(', ') + ')'
      + '{\n' + fun.body.map(generateStmt).join('\n') + '\n}';
  }

  public function visitVariableExpr(expr:Expr.Variable):String {
    return expr.name.lexeme;
  }

  public function visitMetadataExpr(expr:Expr.Metadata):String {
    return '';
  }

  public function visitAssignExpr(expr:Expr.Assign):String {
    return expr.name.lexeme + ' = ' + generateExpr(expr.value);
  }

  public function visitArrayLiteralExpr(expr:Expr.ArrayLiteral):String {
    return '[' + expr.values.map(generateExpr).join(', ') + ']';
  }

  public function visitObjectLiteralExpr(expr:Expr.ObjectLiteral):String {
    var out = '{';
    for (i in 0...expr.values.length) {
      out += expr.keys[i].lexeme + ': ' + generateExpr(expr.values[i]) + ',';
    }
    return out + '}';
  }

}