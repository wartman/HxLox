package quirk.interpreter;

import sys.io.File;
import quirk.Expr;
import quirk.TokenType;
import quirk.ExprVisitor;
import quirk.StmtVisitor;
import quirk.Scanner;
import quirk.Parser;
import quirk.ErrorReporter;
import quirk.DefaultErrorReporter;
import quirk.ModuleLoader;
import quirk.DefaultModuleLoader;

using haxe.io.Path;
using quirk.interpreter.Helper;

class Interpreter
  implements ExprVisitor<Dynamic>
  implements StmtVisitor<Dynamic>
{

  public var globals:Environment = new Environment();
  public var currentModule:Module;
  public var reporter:ErrorReporter;
  private var environment:Environment;
  private var modules:Map<String, Module> = new Map();
  private var loader:ModuleLoader;
  private var locals:Map<Expr, Int> = new Map();
  private var foreigns:Map<String, Foreign.ForeignMethod> = new Map();
  private var objectMappings:Map<String, String> = [
    'String' => 'String'
  ];

  public function new(?loader:ModuleLoader, ?reporter:ErrorReporter) {
    if (loader == null) {
      loader = new DefaultModuleLoader(Sys.getCwd());
    }
    if (reporter == null) {
      reporter = new DefaultErrorReporter();
    }
    this.loader = loader;
    this.reporter = reporter;
    environment = globals;
    currentModule = new Module(null, globals, []);

    // Setup default types
    quirk.interpreter.foreign.Primitives.register(this);
    quirk.interpreter.foreign.Core.register(this);
  }

  public function interpret(stmts:Array<Stmt>) {
    try {
      for (stmt in stmts) {
        execute(stmt);
      }
    } catch (error:RuntimeError)  {
      reporter.report(error.token.pos, error.token.lexeme, error.message);
    }
  }

  public function resolve(expr:Expr, depth:Int) {
    locals.set(expr, depth);
  }

  /**
    Add a foreign method.

    Static methods: `Module.Path.ClassName.staticMethod(_, _)`
    Instance methods: `Module.Path.ClassName#instanceMethod(_, _)`
  **/
  public function addForeign(signature:String, foreign:Foreign.ForeignMethod) {
    foreigns.set(signature, foreign);
    return this;
  }

  public function getForeign(signature:String):Foreign.ForeignMethod {
    var f = foreigns.get(signature);
    if (f == null) {
      throw 'No foreign method registered for ' + signature;
    }
    return f;
  }

  private function execute(stmt:Stmt) {
    stmt.accept(this);
  }

  public function executeBlock(stmts:Array<Stmt>, environment:Environment) {
    var previous = this.environment;

    try {
      this.environment = environment;
      for (stmt in stmts) {
        execute(stmt);
      }
    } catch (e:Dynamic) {
      // No `finally` in haxe :P.
      this.environment = previous;
      #if neko
        neko.Lib.rethrow(e); // not the best option, but eh.
      #else
        throw e;
      #end
    }

    this.environment = previous;
  }

  private function evaluate(expr:Expr):Dynamic {
    return expr.accept(this);
  }

  public function visitBlockStmt(stmt:Stmt.Block):Dynamic {
    executeBlock(stmt.statements, new Environment(environment));
    return null;
  }

  public function visitExpressionStmt(stmt:Stmt.Expression):Dynamic {
    evaluate(stmt.expression);
    return null;
  }

  public function visitFunStmt(stmt:Stmt.Fun):Dynamic {
    var fun:Function = new Function(stmt, environment, false, new Map());
    environment.define(stmt.name.lexeme, fun);
    return null;
  }

  public function visitLambdaExpr(expr:Expr.Lambda):Dynamic {
    var fun:Function = new Function(cast expr.fun, environment, false, new Map(), true);
    return fun;
  }

  public function visitClassStmt(stmt:Stmt.Class):Dynamic {
    environment.define(stmt.name.lexeme, null);

    var superclass:Dynamic = null;
    if (stmt.superclass != null) {
      superclass = evaluate(stmt.superclass);
      if (!Std.is(superclass, Class)) {
        throw new RuntimeError(stmt.name, "Superclass must be a class.");
      }
      environment = new Environment(environment);
      environment.define('super', superclass);
    }

    var className:String = [ currentModule.toString(), stmt.name.lexeme ]
      .filter(function (name) return name != null)
      .join('.');
    var meta:Map<String, Array<Dynamic>> = intrepretMetadata(stmt.meta);
    var methods:Map<String, Function> = new Map();
    var staticMethods:Map<String, Function> = new Map();

    for (method in stmt.methods) {
      var funMeta = intrepretMetadata(method.meta);
      if (method.kind.equals(Stmt.FunKind.FunForeign)) {
        var sig = className + '#' + method.signature();
        methods.set(method.getMethodName(), new Foreign(method, environment, funMeta, getForeign(sig)));
        continue;
      }
      var fun = new Function(method, environment, method.name.lexeme == 'init', funMeta); 
      methods.set(method.getMethodName(), fun);
    }

    for (method in stmt.staticMethods) {
      var funMeta = intrepretMetadata(method.meta);
      if (method.kind.equals(Stmt.FunKind.FunForeign)) {
        var sig = className + '.' + method.signature();
        staticMethods.set(method.getMethodName(), new Foreign(method, environment, funMeta, getForeign(sig)));
        continue;
      }
      var fun = new Function(method, environment, method.name.lexeme == 'init', funMeta);
      staticMethods.set(method.getMethodName(), fun);
    }

    var cls = new Class(
      className,
      (cast superclass),
      methods,
      staticMethods,
      meta
    );

    if (superclass != null) {
      environment = environment.enclosing;
    }

    environment.assign(stmt.name, cls);
    return null;
  }

  public function visitImportStmt(stmt:Stmt.Import):Dynamic {
    var module = getModule(stmt.path);
    if (stmt.alias != null) {
      var obj:Class = globals.values.get('Object');
      var mod:Instance = obj.call(this, []);
      for (name in module.exports) {
        var tok:Token = new Token(TokIdentifier, name, '', stmt.alias.pos);
        mod.set(this, tok, module.get(tok));
      }
      environment.define(stmt.alias.lexeme, mod);
    } else {
      for (name in stmt.imports) {
        var value = module.get(name);
        environment.define(name.lexeme, value);
      }
    }
    return null;
  }

  public function visitModuleStmt(stmt:Stmt.Module):Dynamic {
    var path = loader.find(stmt.path);
    var name = stmt.path.map(function (p) return p.lexeme).join('.');
    var exports = stmt.exports.map(function (e) return e.lexeme);
    var module = new Module(name, environment, exports);

    modules.set(path, module);
    currentModule = module;

    return null;
  }

  public function visitReturnStmt(stmt:Stmt.Return):Dynamic {
    var value = null;
    if (stmt.value != null) value = evaluate(stmt.value);
    throw new Return(value);
  }

  public function visitThrowStmt(stmt:Stmt.Throw):Dynamic {
    var value = evaluate(stmt.expr);
    throw value; // temp
    return null;
  }

  public function visitTryStmt(stmt:Stmt.Try):Dynamic {
    try {
      execute(stmt.body);
    } catch (e:RuntimeError) {
      // Todo: actually handle the value
      var env = new Environment(environment);
      env.define(stmt.exception.lexeme, e.message);
      executeBlock((cast stmt.caught:Stmt.Block).statements, env);
    } catch (e:Dynamic) {
      var env = new Environment(environment);
      env.define(stmt.exception.lexeme, e);
      executeBlock((cast stmt.caught:Stmt.Block).statements, env);
    }
    return null;
  }

  public function visitIfStmt(stmt:Stmt.If):Dynamic {
    if (isTruthy(evaluate(stmt.condition))) {
      execute(stmt.thenBranch);
    } else if (stmt.elseBranch != null) {
      execute(stmt.elseBranch);
    }
    return null;
  }

  public function visitWhileStmt(stmt:Stmt.While):Dynamic {
    while(isTruthy(evaluate(stmt.condition))) {
      execute(stmt.body);
    }
    return null;
  }

  public function visitVarStmt(stmt:Stmt.Var):Dynamic {
    var value = null;
    if (stmt.initializer != null) {
      value = evaluate(stmt.initializer);
    }
    environment.define(stmt.name.lexeme, value);
    return null;
  }

  public function visitMetadataExpr(expr:Expr.Metadata) {
    // todo: handle metadata?
    return evaluate(expr.expr);
  }

  public function visitAssignExpr(expr:Expr.Assign) {
    var value = evaluate(expr.value);
    var distance = locals.get(expr);
    if (distance != null) {
      environment.assignAt(distance, expr.name, value);
    } else {
      environment.assign(expr.name, value);
    }
    return value;
  }

  public function visitLiteralExpr(expr:Expr.Literal):Dynamic {
    // if (Std.is(expr.value, String)) {
    //   var string:Class = globals.values.get('String');
    //   return string.call(this, [ expr.value ]);
    // }
    // else if (Std.is(expr.value, Int)) {
    //   var int:Class = globals.values.get('Int');
    //   return int.call(this, [ expr.value ]);
    // }
    return expr.value;
  }

  public function visitLogicalExpr(expr:Expr.Logical):Dynamic {
    var left = evaluate(expr.left);
    if (expr.op.type.equals(TokBoolOr)) {
      if (isTruthy(left)) return left;
    } else {
      if (!isTruthy(left)) return left;
    }
    return evaluate(expr.right);
  }

  public function visitSetExpr(expr:Expr.Set):Dynamic {
    var target = evaluate(expr.object);
    if (!Std.is(target, Instance)) {
      throw new RuntimeError(expr.name, "Only instances have fields.");
    }
    var value = evaluate(expr.value);
    var object:Instance = cast target;
    object.set(this, expr.name, value);
    return value;
  }

  public function visitSuperExpr(expr:Expr.Super):Dynamic {
    var distance = locals.get(expr);
    var superclass:Class = cast environment.getAt(distance, 'super');
    // "this" is always one level nearer than "super"'s environment.
    var instance:Instance = cast environment.getAt(distance - 1, 'this');
    var method:Function = superclass.findMethod(instance, expr.method.lexeme);

    if (method == null) {
      throw new RuntimeError(expr.method, "Undefined property '" + expr.method.lexeme + "'.");
    }

    return method;
  }

  public function visitThisExpr(expr:Expr.This):Dynamic {
    return lookUpVariable(expr.keyword, expr);
  }

  public function visitGroupingExpr(expr:Expr.Grouping):Dynamic {
    return evaluate(expr.expression);
  }

  public function visitUnaryExpr(expr:Expr.Unary):Dynamic {
    var right = evaluate(expr.right);

    return switch (expr.op.type) {
      case TokBang: !isTruthy(right);
      case TokMinus:
        checkNumberOperand(expr.op, right);
        -right;
      default: null;
    }
  }

  public function visitVariableExpr(expr:Expr.Variable) {
    return lookUpVariable(expr.name, expr);
  }

  public function visitBinaryExpr(expr:Expr.Binary):Dynamic {
    var left = evaluate(expr.left);
    var op = expr.op;
    var right = evaluate(expr.right);

    return switch(op.type) {
      case TokMinus:
        checkNumberOperands(op, left, right);
        left - right;
      case TokSlash:
        checkNumberOperands(op, left, right);
        left / right;
      case TokStar:
        checkNumberOperands(op, left, right);
        left * right;
      case TokPlus:
        if (Std.is(left, Int) && Std.is(right, Int)) {
          left + right;
        } else if (Std.is(left, String) && Std.is(right, String)) {
          left + right;
        } else if (Std.is(left, String) && Std.is(right, Int)) {
          left + Std.string(right);
        } else if (Std.is(left, Int) && Std.is(right, String)) {
          Std.string(left) + right;
        // } else if (Std.is(left, Instance)) {
        } else {
          throw new RuntimeError(op, 'Operands must be two numbers or two strings.');
        }
      case TokGreater:
        checkNumberOperands(op, left, right);
        left > right;
      case TokGreaterEqual:
        checkNumberOperands(op, left, right);
        left >= right;
      case TokLess:
        checkNumberOperands(op, left, right);
        left < right;
      case TokLessEqual:
        checkNumberOperands(op, left, right);
        left <= right;
      case TokBangEqual: return !isEqual(left, right);
      case TokEqualEqual: return isEqual(left, right);
      default:
        throw new RuntimeError(op, 'Invalid operator');
    }
  }

  public function visitCallExpr(expr:Expr.Call):Dynamic {
    var callee:Dynamic = evaluate(expr.callee);
    var arguments:Array<Dynamic> = [];

    for (arg in expr.args) {
      arguments.push(evaluate(arg));
    }

    if (!Std.is(callee, Callable)) {
      throw new RuntimeError(expr.paren, 'Can only call functions and classes.');
    }

    var callable:Callable = cast callee;

    if (!callable.isDynamic() && (arguments.length != callable.arity())) {
      throw new RuntimeError(expr.paren, 'Expected ${callable.arity()} arguments but got ${arguments.length}.');
    }

    return callable.call(this, arguments);
  }

  public function visitGetExpr(expr:Expr.Get):Dynamic {
    var target = evaluate(expr.object);
    if (Std.is(target, Object)) {
      var object:Instance = cast target;
      return object.get(this, expr.name);
    }

    // Sorta a hack :P
    var cls = getLiteralClass(target);
    if (cls != null) {
      var object:Instance = cls.call(this, [ target ]);
      return object.get(this, expr.name);
    }

    throw new RuntimeError(expr.name, "Only objects have properties.");
  }

  // Todo: probably a more elegant way to handle subscript operators.
  public function visitSubscriptGetExpr(expr:Expr.SubscriptGet):Dynamic {
    var object = evaluate(expr.object);
    var index = evaluate(expr.index);

    if (Std.is(object, Instance)) {
      var obj:Instance = cast object;
      var method:Function = obj.getClass().findMethod(object, '__offsetGet');
      if (method != null) {
        return method.call(this, [ index ]);
      }
      throw new RuntimeError(expr.end, "Subscripts can only be used on objects with an '__offsetGet' method");
    }

    throw new RuntimeError(expr.end, "Only objects have properties.");
  }

  public function visitSubscriptSetExpr(expr:Expr.SubscriptSet):Dynamic {
    var object = evaluate(expr.object);
    var index = evaluate(expr.index);
    var value = evaluate(expr.value);

    if (Std.is(object, Instance)) {
      var obj:Instance = cast object;
      var method:Function = obj.getClass().findMethod(object, '__offsetSet');
      if (method != null) {
        return method.call(this, [ index, value ]);
      }
      throw new RuntimeError(expr.end, "Subscripts can only be used on objects with an '__offsetSet' method");
    }

    throw new RuntimeError(expr.end, "Only objects have properties.");
  }

  public function visitArrayLiteralExpr(expr:Expr.ArrayLiteral):Dynamic {
    var values:Array<Dynamic> = [];
    for (value in expr.values) {
      values.push(evaluate(value));
    }
    var arrayClass:Class = globals.values.get('Array');
    return arrayClass.call(this, [ values ]);
  }

  public function visitObjectLiteralExpr(expr:Expr.ObjectLiteral):Dynamic {
    var keys:Array<String> = [];
    var values:Array<Dynamic> = [];
    var object:Class = globals.values.get('Object');
    var inst:Instance = object.call(this, []);
    for (i in 0...expr.keys.length) {
      inst.set(this, expr.keys[i], evaluate(expr.values[i]));
    }
    return inst;
  }

  private function intrepretMetadata(items:Array<Expr>):Map<String, Array<Dynamic>> {
    var meta:Map<String, Array<Dynamic>> = new Map();
    for (m in items) {
      var entry:Expr.Metadata = cast m;
      var name = entry.name.lexeme;
      var items:Array<Dynamic> = [];
      for (expr in entry.args) {
        items.push(evaluate(expr));
      }
      meta.set(name, items);
    }
    return meta;
  }

  private function isTruthy(obj:Dynamic):Bool {
    if (obj == null) return false;
    if (Std.is(obj, Bool)) return obj;
    return true;
  }

  private function isEqual(a:Dynamic, b:Dynamic):Bool {
    if (a == null && b == null) return true;
    if (a == null) return false;
    return a == b; // Java is doing some magic -- think it's basically this tho
  }

  private function stringify(obj:Dynamic) {
    if (obj == null) return 'null';
    return Std.string(obj);
  }

  private function checkNumberOperand(op:Token, operand:Dynamic) {
    if (Std.is(operand, Int)) return;
    throw new RuntimeError(op, 'Operand must be a number.');
  }

  private function checkNumberOperands(op:Token, left:Dynamic, right:Dynamic) {
    if (Std.is(left, Int) && Std.is(right, Int)) return;
    throw new RuntimeError(op, 'Operand must be a number.');
  }

  private function lookUpVariable(name:Token, expr:Expr) {
    var distance = locals.get(expr);
    if (distance != null) {
      return environment.getAt(distance, name.lexeme);
    } else {
      return environment.get(name);
    }
  }

  private function getLiteralClass(value:Dynamic):Null<Class> {
    var name = Type.getClassName(Type.getClass(value));
    if (objectMappings.exists(name)) {
      var loxName = objectMappings.get(name);
      var loxClass:Class = globals.values.get(loxName);
      return loxClass;
    }
    return null;
  }

  private function getModule(tokens:Array<Token>) {
    var path:String = loader.find(tokens);
    if (!modules.exists(path)) {
      loadModule(path);
    }
    if (!modules.exists(path)) {
      var name = tokens.map(function (t) return t.lexeme).join('.');
      throw new RuntimeError(tokens[tokens.length - 1], 'The module ${name} was not declared');
    }
    return modules.get(path);
  }

  private function loadModule(path:String) {
    var source = loader.load(path);
    var previousEnv = environment;
    var previousModule = currentModule;

    var scanner = new Scanner(source, path, reporter);
    var tokens = scanner.scanTokens();
    var parser = new Parser(tokens, reporter);
    var stmts = parser.parse();
    var resolver = new Resolver(this);

    resolver.resolve(stmts);
    environment = new Environment(globals);
    interpret(stmts);

    environment = previousEnv;
    currentModule = previousModule;
  }

}
