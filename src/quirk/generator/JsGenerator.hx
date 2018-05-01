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

  private static var reserved:Array<String> = [
    'new', 'default'
  ];

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
    return getIndent() + 'var ' + safeVar(stmt.name) + ' = '
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
    return 'this.__super.' + expr.method.lexeme + '.bind(this)'; // maybe???
  }

  public function visitThisExpr(expr:Expr.This):String {
    return 'this';
  }

  public function visitUnaryExpr(expr:Expr.Unary):String {
    return expr.op.lexeme + generateExpr(expr.right);
  }

  public function visitFunStmt(stmt:Stmt.Fun):String {
    return 'function ' + safeVar(stmt.name) + genParams(stmt.params) + ' ' 
      + genBlock(stmt.body);
  }

  public function visitClassStmt(stmt:Stmt.Class):String {
    var name = stmt.name.lexeme;
    var fullName = moduleName.replace('/', '.') + '.' + name;
    var out = '';
    var metaList:Map<String, Array<Expr>> = new Map();
    var propertyList:Map<String, { 
      name:String,
      target:String,
      ?getter:String,
      ?setter:String 
    }> = new Map();

    if (stmt.meta.length > 0) {
      metaList.set('__TYPE__', stmt.meta);
    }
    
    out += getIndent() + 'function ' + name + '() {};\n';

    if (stmt.superclass != null) {
      out += '__quirk.extend(' + name + ', ' + generateExpr(stmt.superclass) + ');\n';
      out += name + '.prototype.__super = ' + generateExpr(stmt.superclass) + '.prototype;\n'; 
    }

    out += name + '.__name = "' + fullName + '";\n';
    out += name + '.prototype.__name = "' + fullName + '";\n';
    out += '__quirk.addClass("' + fullName + '", ' + name + ');\n';

    out += stmt.staticMethods.map(function (method) {
      return visitFieldStmt(name, method, propertyList, metaList);
    }).concat(stmt.methods.map(function (method) {
      return visitFieldStmt(name + '.prototype', method, propertyList, metaList);
    })).filter(function (v) return v != null).concat([ for (key in propertyList.keys()) {
      var prop = propertyList.get(key);
      var outProps = [];
      indent();
      if (prop.setter != null) {
        outProps.push(getIndent() + 'set: ' + prop.setter);
      }
      if (prop.getter != null){
        outProps.push(getIndent() + 'get: ' + prop.getter);
      }
      outdent();
      'Object.defineProperty(' + prop.target + ', "' + prop.name + '", {\n' 
        + outProps.join(',\n') + '\n' + getIndent() + '})';
    } ]).join(';\n') + ';';

    addMeta(name, metaList);

    return out;
  }

  private function visitFieldStmt(
    target:String,
    method:Stmt.Fun,
    propertyList:Map<String, {
      target:String,
      name:String,
      ?getter:String,
      ?setter:String 
    }>,
    metaList:Map<String, Array<Expr>>
  ):String {
    if (method.meta.length > 0) {
      metaList.set(method.name.lexeme, method.meta);
    }
    var ident = target + '::' + method.name.lexeme;
    var initProp = function () {
      if (!propertyList.exists(ident)) {
        propertyList.set(ident, { 
          target: target,
          name: method.name.lexeme,
          setter: null, 
          getter: null 
        });
      }
    };
    // todo: maybe be a bit more explicit about properties.
    return switch method.kind {
      case Stmt.FunKind.FunGetter:
        initProp();
        indent();
        propertyList.get(ident).getter = visitFunStmt(method);
        outdent();
        null;
      case Stmt.FunKind.FunSetter:
        initProp();
        indent();
        propertyList.get(ident).setter = visitFunStmt(method);
        outdent();
        null;
      case Stmt.FunKind.FunConstructor:
        target + '.' + method.name.lexeme + ' = function ' + genParams(method.params) + '{\n' 
          + indent().getIndent() + 'var instance = new ' + target + '();\n'
          + getIndent() + 'instance.' + method.name.lexeme + genParams(method.params) + ';\n'
          + getIndent() + 'return instance;\n'
          + outdent().getIndent() + '}\n'
        + getIndent() + target + '.prototype.' + method.name.lexeme + ' = ' + visitFunStmt(method);

        // // probably won't handle super calls tho
        // target + '.' + method.name.lexeme + ' = function ' + genParams(method.params)
        //   + ' {\n' + [
        //     indent().getIndent() + 'var instance = new ' + target + '();',
        //     getIndent() + '(function () ' + genBlock(method.body) + ').call(instance);',
        //     getIndent() +'return instance;'
        //   ].join('\n') + '\n' + outdent().getIndent() + '}';
      default: target + '.' + method.name.lexeme + ' = ' + visitFunStmt(method);
    }
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
    return safeVar(expr.name);
  }

  public function visitMetadataExpr(expr:Expr.Metadata):String {
    // capture meta?
    return '{ name: "' + expr.name.lexeme + '", values: [' + expr.args.map(generateExpr).join(',') + '] }';
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

  private function genBlock(stmts:Array<Stmt>) {
    var out = '{\n';
    indent();
    out += stmts.map(generateStmt).join('\n'); 
    outdent();
    return out + '\n' + getIndent() + '}';
  }

  private function genParams(params:Array<Token>) {
    return '(' + params.map(function (t) return t.lexeme).join(', ') + ')';
  }

  private function safeVar(tok:Token) {
    var name = tok.lexeme;
    if (reserved.indexOf(name) >= 0) {
      return '_' + name;
    }
    return name;
  }

  private function addMeta(target:String, data:Map<String, Array<Expr>>) {
    var out = '__quirk.addMeta(' + target + ', {\n';
    indent();
    out += [ 
      for (key in data.keys()) 
        getIndent() + '"' + key + '": [' + data.get(key).map(generateExpr).join(', ') + ']' 
    ].join(',\n');
    outdent();
    out += '\n' + getIndent() + '});';
    append.push(out);
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
