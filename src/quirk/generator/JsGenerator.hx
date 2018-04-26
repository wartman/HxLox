package quirk.generator;

import quirk.Expr;
import quirk.Stmt;
import quirk.ErrorReporter;
import quirk.ModuleLoader;
import quirk.ExprVisitor;
import quirk.StmtVisitor;

using Lambda;
using StringTools;

typedef JsGeneratorOptions = {
  bundle:Bool,
  isMain:Bool
};

class JsGenerator 
  implements Generator
  implements ExprVisitor<String> 
  implements StmtVisitor<String>
{

  private var reporter:ErrorReporter;
  private var loader:ModuleLoader;
  private var uid:Int = 0;
  private var indentLevel:Int = 0;
  private var append:Array<String> = [];
  private var options:JsGeneratorOptions;
  private var moduleName:String = null;
  private var deps:Array<String> = [];
  private var modules:Map<String, String>;

  public function new(
    loader:ModuleLoader,
    reporter:ErrorReporter,
    ?options:JsGeneratorOptions,
    ?modules:Map<String, String>
  ) {
    this.loader = loader;
    this.reporter = reporter;
    this.options = options != null 
      ? options
      : { bundle: true, isMain: true };
    this.modules = modules != null ? modules : new Map();
  }

  public function generate(stmts:Array<Stmt>):String {
    var out = stmts.map(generateStmt).filter(function (s) {
      return s != null;
    }).concat(this.append).join('\n');
    
    if (options.bundle) {
      if (moduleName == null) {
        if (options.isMain) {
          moduleName = 'main';
        } else {
          throw 'Expected a module declaration';
        }
      }
      out = '__quirk_env.define("' + moduleName + '", [' +
        deps.join(',') + '], function (require, module) {\n'
        + out + '\n});\n';
    }

    if (options.bundle == false || options.isMain == true) {
      out = bundlePrelude() + '\n' + out + '__quirk_init("' + moduleName + '");\n';
    }

    return out;
  }

  private function bundlePrelude() {
    return [
      ';(function (global) {',
      haxe.Resource.getString('lib:js-cjs'),
      haxe.Resource.getString('lib:js'),
      '})(global != null ? global : window);'
    ].concat([ for (key in modules.keys()) modules.get(key) ]).join('\n');
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
    var out = getIndent() + 'if (' + generateExpr(stmt.condition) + ')' + generateStmt(stmt.thenBranch);
    if (stmt.elseBranch != null) {
      out += ' else ' + generateStmt(stmt.elseBranch);
    }
    return out;
  }

  public function visitReturnStmt(stmt:Stmt.Return):String {
    return getIndent() + (stmt.value == null
      ? 'return;'
      : 'return ' + generateExpr(stmt.value) + ';');
  }

  public function visitThrowStmt(stmt:Stmt.Throw):String {
    return getIndent() + 'throw ' + generateExpr(stmt.expr) + ';';
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
    return getIndent() + 'var ' + stmt.name.lexeme + ' = '
      + (stmt.initializer != null ? generateExpr(stmt.initializer) : 'null')
      + ';';
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
      ? '"' + Std.string(expr.value).replace('"', '\\"') + '"'
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
    return 'this.__super__.' + expr.method.lexeme + '.bind(this)'; // maybe???
  }

  public function visitThisExpr(expr:Expr.This):String {
    return 'this';
  }

  public function visitUnaryExpr(expr:Expr.Unary):String {
    return expr.op.lexeme + generateExpr(expr.right);
  }

  public function visitFunStmt(stmt:Stmt.Fun):String {
    var out = 'function ' + stmt.name.lexeme + '('
      + stmt.params.map(function (t) return t.lexeme).join(', ') + ') '
      + '{\n';
    indent(); 
    out += stmt.body.map(generateStmt).join('\n'); 
    outdent();
    return out + '\n' + getIndent() + '}';
  }

  public function visitClassStmt(stmt:Stmt.Class):String {
    var name = stmt.name.lexeme;
    var fullName = moduleName.replace('/', '.') + '.' + name;
    var out = '';
    var init = stmt.methods.find(function (m) {
      return m.name.lexeme == 'init';
    });

    if (stmt.meta.length > 0) {
      addMeta(name, stmt.meta);
    }
    
    // Getting around the fact that we don't use the `new` keyword.
    // Feels like this could be a bit of an issue, so... I dunno. might
    // come back later and make real JS constructors.
    var initParams = init != null 
      ? init.params.map(function (t) return t.lexeme).join(', ')
      : '';  
    out += getIndent() + 'function ' + name + '(' + initParams + ') {\n';
    indent();
    var inst = tempVar('obj');
    out += getIndent() + 'var ' + inst + ' = Object.create(' + name + '.prototype);\n';
    if (init != null) {
      out += getIndent() + inst + '.' + init.name.lexeme + '(' + initParams + ');\n';
    }
    out += getIndent() + 'return ' + inst + ';\n';
    outdent();
    out += getIndent() + '};\n';

    // if (init != null) {
    //   init.name = stmt.name;
    //   out += visitFunStmt(init) + ';\n';
    // } else {
    //   out += 'function ' + name + '() {};\n';
    // }

    if (stmt.superclass != null) {
      out += '__quirk.extend(' + name + ', ' + generateExpr(stmt.superclass) + ');\n';
      out += name + '.prototype.__super = ' + generateExpr(stmt.superclass) + ';\n'; 
    }

    out += name + '.__name = "' + fullName + '";\n';
    out += name + '.prototype.__name = "' + fullName + '";\n';
    out += '__quirk.addClass("' + fullName + '", ' + name + ');\n';

    out += stmt.staticMethods.map(function (method) {
      return name + '.' + method.name.lexeme + ' = ' + visitFunStmt(method);
    }).join(';\n');
    
    out += stmt.methods.map(function (method) {
      if (method.meta.length > 0) {
        addMeta('${name}.prototype.${method.name.lexeme}', method.meta);
      }
      return name + '.prototype.' + method.name.lexeme + ' = ' + visitFunStmt(method);
    }).join(';\n') + ';';

    return out;
  }

  public function visitImportStmt(stmt:Stmt.Import):String {
    // Allow `@require` to override default paths
    var metaReq:Null<Expr.Metadata> = cast stmt.meta.find(function (m) {
      var meta:Expr.Metadata = cast m;
      return meta.name.lexeme == 'require';
    });
    var target:String = metaReq != null
      ? generateExpr(metaReq.args[0])
      : '"' + loader.find(stmt.path) + '"';

    if (options.bundle) {
      this.deps.push(target);
      var loadName = loader.find(stmt.path);
      if (!this.modules.exists(loadName)) {
        this.modules.set(loadName, bundleModule(loadName));
      }
    }

    var tmp = tempVar('req');
    var out = [ 'var ${tmp} = require(${target})' ];
    if (stmt.alias != null) {
      out.push('var ' + stmt.alias.lexeme + ' = ' + tmp);
    }
    // todo: actually load requirements
    return out.concat(stmt.imports.map(function (t) {
      return 'var ' + t.lexeme + ' = ${tmp}.' + t.lexeme;
    })).join(';\n') + ';';
  }

  public function visitModuleStmt(stmt:Stmt.Module):String {
    if (options.bundle == true) {
      moduleName = loader.find(stmt.path);
    }
    append.push('module.exports = {' + stmt.exports.map(function (t) {
      return t.lexeme + ': ' + t.lexeme;
    }).join(', ') + '};');
    return null;
  }

  public function visitLambdaExpr(expr:Expr.Lambda):String {
    return visitFunStmt(cast expr.fun) + '.bind(this)';
  }

  public function visitVariableExpr(expr:Expr.Variable):String {
    return expr.name.lexeme;
  }

  public function visitMetadataExpr(expr:Expr.Metadata):String {
    // capture meta?
    return '{ name: "${ expr.name.lexeme }", values: [' + expr.args.map(generateExpr).join(',') + '] }';
  }

  public function visitAssignExpr(expr:Expr.Assign):String {
    return expr.name.lexeme + ' = ' + generateExpr(expr.value);
  }

  public function visitArrayLiteralExpr(expr:Expr.ArrayLiteral):String {
    return '[' + expr.values.map(generateExpr).join(', ') + ']';
  }

  public function visitObjectLiteralExpr(expr:Expr.ObjectLiteral):String {
    if (expr.values.length == 0) {
      return '{}';
    }
    var out = '{\n';
    var pairs = [];
    indent();
    for (i in 0...expr.values.length) {
      pairs.push( getIndent() + expr.keys[i].lexeme + ': ' + generateExpr(expr.values[i]));
    }
    out += pairs.join(',\n') + '\n';
    outdent();
    return out + getIndent() + '}';
  }

  private function addMeta(target:String, data:Array<Expr>) {
    append.push('__quirk.addMeta(' + target + ', [' + data.map(generateExpr).join(', ') + ']);');
  }

  private function parseModule(path:String) {
    var source = loader.load(path);
    var scanner = new quirk.Scanner(source, path, reporter);
    var tokens = scanner.scanTokens();
    var parser = new quirk.Parser(tokens, reporter);
    var stmts = parser.parse();
    return stmts;
  }

  private function bundleModule(path:String) {
    var stmts = parseModule(path);
    var generator = new JsGenerator(loader, reporter, {
      bundle: true,
      isMain: false
    }, modules);
    return generator.generate(stmts);
  }

  // private function standaloneModule(path:String) {
  //   var stmts = parseModule(path);
  //   var generator = new JsGenerator(loader, reporter, {
  //     bundle: false,
  //     isMain: false
  //   });
  //   return generator.generate(stmts);
  // }

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
