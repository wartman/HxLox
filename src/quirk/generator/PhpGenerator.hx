package quirk.generator;

import quirk.Expr;
import quirk.Stmt;
import quirk.ErrorReporter;
import quirk.ModuleLoader;
import quirk.core.RuntimeError;
import quirk.generator.PhpEnvironment.PhpKind;

using StringTools;
using Lambda;

class PhpGenerator
  implements Generator
  implements ExprVisitor<String> 
  implements StmtVisitor<String>
{

  private var target:Target;
  private var uid:Int = 0;
  private var indentLevel:Int = 0;
  private var locals:Map<Expr, Int> = new Map();
  private var environment:PhpEnvironment = new PhpEnvironment();
  private var append:Array<String> = [];
  private var moduleName:String = null;
  
  public function new(target:Target, ?moduleName:String) {
    this.target = target;
    this.moduleName = moduleName;
  }

  public function resolve(expr:Expr, depth:Int) {
    locals.set(expr, depth);
  }

  public function define(name:Token, kind:PhpKind) {
    environment.define(name.lexeme, kind);
  }

  public function generate(stmts:Array<Stmt>):String {
    try {
      var out = '<?php\n' + stmts.map(generateStmt).filter(function (s) {
        return s != null;
      }).concat(this.append).join('\n');
      if (moduleName != null) modules.set(moduleName, out);
      return out;
    } catch (error:RuntimeError)  {
      reporter.report(error.token.pos, error.token.lexeme, error.message);
      return '';
    }
  }

  public function write() {
    this.writer.write(modules);
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
    if (stmt.elseBranch != null) {
      out += ' else ' + generateStmt(stmt.elseBranch);
    }
    return out;
  }

  public function visitReturnStmt(stmt:Stmt.Return):String {
    return getIndent() + (stmt.value != null 
      ? 'return ' + generateExpr(stmt.value) + ';' 
      : 'return;');
  }

  public function visitThrowStmt(stmt:Stmt.Throw):String {
    return getIndent() + 'throw new \\Quirk\\Exception(' + generateExpr(stmt.expr) + ');';
  }

  public function visitTryStmt(stmt:Stmt.Try):String {
    var out = getIndent() + 'try ' + generateStmt(stmt.body);
    if (stmt.caught != null) {
      out += ' catch (' + stmt.exception.lexeme + ') ' + generateStmt(stmt.caught);
    }
    return out;
  }

  public function visitWhileStmt(stmt:Stmt.While):String {
    return getIndent() + 'while (' + generateExpr(stmt.condition) + ') '
      + generateStmt(stmt.body);
  }

  public function visitVarStmt(stmt:Stmt.Var):String {
    return getIndent() + "$" + stmt.name.lexeme + ' = ' + (stmt.initializer != null 
      ? generateExpr(stmt.initializer)
      : 'null') + ';';
  }

  public function visitBinaryExpr(expr:Expr.Binary):String {
    return generateExpr(expr.left) + ' ' + expr.op.lexeme + ' ' + generateExpr(expr.right);
  }

  public function visitCallExpr(expr:Expr.Call):String {
    return generateExpr(expr.callee) + '(' + expr.args.map(generateExpr).join(', ')  + ')';
  }

  public function visitGetExpr(expr:Expr.Get):String {
    // this is temporary: will use the resolver soon.
    // Current issues: will NOT handle instances where, for example,
    // we have a `var ClassName` and a `class ClassName`. Also,
    // will NOT work for things defined later in the same file.
    var target = generateExpr(expr.object);
    var kind = environment.values.get(target);
    if (kind != null && kind.equals(PhpType)) {
      return target + '::' + expr.name.lexeme;
    }

    return target + '->' + expr.name.lexeme;
  }

  public function visitGroupingExpr(expr:Expr.Grouping):String {
    return '(' + generateExpr(expr.expression) + ')';
  }

  public function visitLiteralExpr(expr:Expr.Literal):String {
    return Std.is(expr.value, String)
      ? '"' + Std.string(expr.value).replace('"', '\\"') + '"'
      : expr.value;
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
    return 'function ' + stmt.name.lexeme + genParams(stmt.params) + ' '
      + genBlock(stmt.body);
  }

  public function visitClassStmt(stmt:Stmt.Class):String {
    var name = stmt.name.lexeme;
    var metaList:Map<String, Array<Expr>> = new Map();
    var constructors:Array<String> = [];
    // var fullName = moduleName == null
    //   ? name
    //   : moduleName.replace('/', '.') + '.' + name;

    if (stmt.meta.length > 0) {
      metaList.set('__TYPE__', stmt.meta);
    }

    var out = getIndent() + 'class ' + name;
    if (stmt.superclass != null) {
      out += ' extends ' + generateExpr(stmt.superclass);
    }
    out += ' {\n';
    indent();

    // All classes are initializeable
    out += getIndent() + 'public function __construct() {}\n';

    out += stmt.staticMethods.map(function (method) {
      if (method.kind.equals(Stmt.FunKind.FunConstructor)) {
        constructors.push(method.name.lexeme);
      }
      return getIndent() + 'static public ' + visitFieldStmt(method, metaList, name);
    }).concat(stmt.methods.map(function (method) {
      return getIndent() + 'public ' + visitFieldStmt(method, metaList, name);
    })).join('\n');

    // // todo: handle getters and setters
    // out += getIndent() + 'public function __get($name)'

    outdent();
    out += '\n' + getIndent() + '}';
    return out;
  }

  private function visitFieldStmt(method:Stmt.Fun, metaList:Map<String, Array<Expr>>, cls:String) {
    return switch method.kind {
      case Stmt.FunKind.FunGetter:
        method.name.lexeme = 'get_' + method.name.lexeme;
        visitFunStmt(method);
      case Stmt.FunKind.FunSetter:
        method.name.lexeme = 'set_' + method.name.lexeme;
        visitFunStmt(method);
      case Stmt.FunKind.FunConstructor:
        'function ' + method.name.lexeme + genParams(method.params) + ' {\n'
          + indent().getIndent() + "$instance = new " + cls + '();\n'
          + getIndent() + "$instance->" + method.name.lexeme + genParams(method.params) + ';\n'
          + getIndent() + "return $instance;\n"
          + outdent().getIndent() + '}\n'
        + getIndent() + 'public ' + visitFunStmt(method);
      default:
        visitFunStmt(method);
    }
  }

  public function visitImportStmt(stmt:Stmt.Import):String {
    var path = target.resolveModule(stmt.path);
    var phpPath = stmt.path.map(function (p) return p.lexeme).join('\\');
    target.addModuleDependency(moduleName, path);
    target.addModule(path);
    return stmt.imports.map(function (target) {
      return getIndent() + 'use ' + [ phpPath ].concat([ target.lexeme ]).join('\\') + ';';
    }).join('\n');
  }

  public function visitModuleStmt(stmt:Stmt.Module):String {
    moduleName = target.resolveModule(stmt.path);
    indent();
    return null;
    // todo: will need to split into seperate files for each export :P
    return 'namespace ' + stmt.path.map(function (p) return p.lexeme).join('\\') + ';';
  }

  public function visitLambdaExpr(expr:Expr.Lambda):String {
    return '// todo';
  }

  public function visitVariableExpr(expr:Expr.Variable):String {
    var kind = environment.values.get(expr.name.lexeme);
    if (kind != null) {
      return switch kind {
        case PhpType | PhpFun: expr.name.lexeme;
        default: "$" + expr.name.lexeme;
      }
    }
    return "$" + expr.name.lexeme;
  }

  public function visitMetadataExpr(expr:Expr.Metadata):String {
    return '// todo';
  }

  public function visitAssignExpr(expr:Expr.Assign):String {
    return expr.name.lexeme + ' = ' + generateExpr(expr.value);

    // var value = generateExpr(expr.value);
    // var distance = locals.get(expr);
    // if (distance != null) {

    // }
  }

  public function visitArrayLiteralExpr(expr:Expr.ArrayLiteral):String {
    return '[' + expr.values.map(generateExpr).join(', ') + ']';
  }

  public function visitObjectLiteralExpr(expr:Expr.ObjectLiteral):String {
    var out = 'new \\ArrayObject(';
    if (expr.values.length == 0) {
      return out + ')';
    }
    out += '[\n';
    var pairs = [];
    indent();
    for (i in 0...expr.values.length) {
      pairs.push( getIndent() + '"' + expr.keys[i].lexeme + '" => ' + generateExpr(expr.values[i]));
    }
    out += pairs.join(',\n') + '\n';
    outdent();
    return out + getIndent() + '])';
  }


  private function genParams(params:Array<Token>) {
    return '(' + params.map(function (t) return '$' + t.lexeme).join(', ') + ')';
  }

  private function genBlock(stmts:Array<Stmt>) {
    var out = '{\n';
    indent();
    out += stmts.map(generateStmt).join('\n'); 
    outdent();
    return out + '\n' + getIndent() + '}';
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
    return this;
  }

  private function outdent() {
    indentLevel--;
    if (indentLevel < 0) {
      indentLevel = 0;
    }
    return this;
  }

  private function tempVar(prefix:String = 'tmp') {
    return '__quirk_' + prefix + (uid++);
  }

}
