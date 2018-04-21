package quirk.generator;

import quirk.Expr;
import quirk.Stmt;
import quirk.ErrorReporter;
import quirk.ModuleLoader;

using Lambda;

class PhpGenerator
  implements Generator
  implements ExprVisitor<String> 
  implements StmtVisitor<String>
{

  private var reporter:ErrorReporter;
  private var loader:ModuleLoader;
  private var uid:Int = 0;
  private var indentLevel:Int = 0;
  private var types:Array<String> = [];
  private var append:Array<String> = [];

  public function new(loader:ModuleLoader, reporter:ErrorReporter) {
    this.loader = loader;
    this.reporter = reporter;
  }

  public function generate(stmts:Array<Stmt>):String {
    return stmts.map(generateStmt).filter(function (s) {
      return s != null;
    }).concat(this.append).join('\n');
  }

  private function generateStmt(stmt:Stmt):String {
    return stmt.accept(this);
  }
 
  private function generateExpr(expr:Null<Expr>):String {
    if (expr == null) return '';
    return expr.accept(this);
  }

  public function visitBlockStmt(stmt:Stmt.Block):String {
    var out = '{\n';
    indent(); 
    out += stmt.statements.map(generateStmt).join('\n') + '\n';
    outdent();
    out += getIndent() + '}';
    return out;
  }

  public function visitExpressionStmt(stmt:Stmt.Expression):String {
    return getIndent() + generateExpr(stmt.expression) + ';';
  }

  public function visitIfStmt(stmt:Stmt.If):String {
    var out = getIndent() + 'if (' + generateExpr(stmt.condition) + ') ' + generateStmt(stmt.thenBranch);
    if (stmt.thenBranch != null) {
      out += ' else ' + generateStmt(stmt.thenBranch);
    }
    return out;
  }

  public function visitReturnStmt(stmt:Stmt.Return):String {
    return stmt.value != null ? 'return ' + generateExpr(stmt.value) + ';' : 'return;';
  }

  public function visitThrowStmt(stmt:Stmt.Throw):String {
    return 'throw new \\Quirk\\Exception(' + generateExpr(stmt.expr) + ');';
  }

  public function visitTryStmt(stmt:Stmt.Try):String {
    return '// todo';
  }

  public function visitWhileStmt(stmt:Stmt.While):String {
    return '// todo';
  }

  public function visitVarStmt(stmt:Stmt.Var):String {
    return "$" + stmt.name.lexeme + ' = ' + (stmt.initializer != null 
      ? generateExpr(stmt.initializer)
      : 'null') + ';';
  }

  public function visitBinaryExpr(expr:Expr.Binary):String {
    return generateExpr(expr.left) + ' ' + expr.op.lexeme + ' ' + generateExpr(expr.right);
  }

  public function visitCallExpr(expr:Expr.Call):String {
    return '// todo';
  }

  public function visitGetExpr(expr:Expr.Get):String {
    return generateExpr(expr.object) + '->' + expr.name.lexeme;
  }

  public function visitGroupingExpr(expr:Expr.Grouping):String {
    return '(' + generateExpr(expr.expression) + ')';
  }

  public function visitLiteralExpr(expr:Expr.Literal):String {
    return expr.value;
  }

  public function visitLogicalExpr(expr:Expr.Logical):String {
    return generateExpr(expr.left) + expr.op.lexeme + generateExpr(expr.right);
  }

  public function visitSetExpr(expr:Expr.Set):String {
    return generateExpr(expr.object) + '->' + expr.name.lexeme + ' = ' + generateExpr(expr.value);
  }

  public function visitSubscriptGetExpr(expr:Expr.SubscriptGet):String {
    return generateExpr(expr.object) + '[' + generateExpr(expr.index) + ']';
  }

  public function visitSubscriptSetExpr(expr:Expr.SubscriptSet):String {
    return generateExpr(expr.object) + '[' + generateExpr(expr.index) + '] = ' + generateExpr(expr.value);
  }

  public function visitSuperExpr(expr:Expr.Super):String {
    return 'parent::' + expr.method.lexeme;
  }

  public function visitThisExpr(expr:Expr.This):String {
    return "$this";
  }

  public function visitUnaryExpr(expr:Expr.Unary):String {
    return expr.op.lexeme + generateExpr(expr.right);
  }

  public function visitFunStmt(stmt:Stmt.Fun):String {
    return '// todo';
  }

  public function visitClassStmt(stmt:Stmt.Class):String {
    var name = stmt.name.lexeme;
    var out = 'class ' + name;
    if (stmt.superclass != null) {
      out += ' extends ' + generateExpr(stmt.superclass);
    }
    out += ' {';

    // todo

    out += '}';
    return out;
  }

  public function visitImportStmt(stmt:Stmt.Import):String {
    var path = stmt.path.map(function (p) return p.lexeme);
    return stmt.imports.map(function (target) {
      types.push(target.lexeme);
      return 'use ' + path.concat([ target.lexeme ]).join('\\') + ';';
    }).join('\n');
  }

  public function visitModuleStmt(stmt:Stmt.Module):String {
    // todo: will need to split into seperate files for each export :P
    return 'namespace ' + stmt.path.map(function (p) return p.lexeme).join('\\') + ';';
  }

  public function visitLambdaExpr(expr:Expr.Lambda):String {
    return '// todo';
  }

  public function visitVariableExpr(expr:Expr.Variable):String {
    if (types.indexOf(expr.name.lexeme) >= 0) {
      return expr.name.lexeme;
    }
    return "$" + expr.name.lexeme;
  }

  public function visitMetadataExpr(expr:Expr.Metadata):String {
    return '// todo';
  }

  public function visitAssignExpr(expr:Expr.Assign):String {
    return '// todo';
  }

  public function visitArrayLiteralExpr(expr:Expr.ArrayLiteral):String {
    return '// todo';
  }

  public function visitObjectLiteralExpr(expr:Expr.ObjectLiteral):String {
    return '// todo';
  }

  private function getIndent() {
    var out = '';
    for (i in 0...this.indentLevel) {
      out += '  ';
    }
    return out;
  }

  private function indent() {
    indentLevel++;
  }

  private function outdent() {
    indentLevel--;
    if (indentLevel < 0) {
      indentLevel = 0;
    }
  }

  private function tempVar(prefix:String = 'tmp') {
    return '__quirk_' + prefix + (uid++);
  }

}
