package hxlox.interpreter;

import sys.io.File;
import hxlox.Expr;
import hxlox.TokenType;
import hxlox.ExprVisitor;
import hxlox.StmtVisitor;
import hxlox.Scanner;
import hxlox.Parser;

using haxe.io.Path;

class Interpreter 
  implements ExprVisitor<Dynamic> 
  implements StmtVisitor<Dynamic> 
{

  public var globals:Environment = new Environment();
  private var environment:Environment;
  private var modules:Map<String, Environment> = new Map();
  private var loader:ModuleLoader;
  private var locals:Map<Expr, Int> = new Map();

  public function new(?loader:ModuleLoader) {
    if (loader == null) {
      loader = new DefaultModuleLoader(Sys.getCwd());
    }
    this.loader = loader;

    // Setup default libraries
    globals.define('System', new hxlox.interpreter.foreign.System());
    
    environment = globals;
  }

  public function interpret(stmts:Array<Stmt>) {
    try {
      for (stmt in stmts) {
        execute(stmt);
      }
    } catch (error:RuntimeError) {
      HxLox.runtimeError(error);
    }
  }

  public function resolve(expr:Expr, depth:Int) {
    locals.set(expr, depth);
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
      throw e; // not the best option, but eh.
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
    var fun:Function = new Function(stmt, environment, false);
    environment.define(stmt.name.lexeme, fun);
    return null;
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

    var methods:Map<String, Function> = new Map();
    var staticMethods:Map<String, Function> = new Map();
    for (method in stmt.methods) {
      var fun = new Function(method, environment, method.name.lexeme == 'init');
      methods.set(method.name.lexeme, fun);
    }
    for (method in stmt.staticMethods) {
      var fun = new Function(method, environment, method.name.lexeme == 'init');
      staticMethods.set(method.name.lexeme, fun);
    }
    var cls = new Class(stmt.name.lexeme, (cast superclass), methods, staticMethods);

    if (superclass != null) {
      environment = environment.enclosing;
    }

    environment.assign(stmt.name, cls);
    return null;
  }

  public function visitImportStmt(stmt:Stmt.Import):Dynamic {
    var module = getModule(stmt.path.literal);
    for (name in stmt.imports) {
      try {
        var value = module.get(name);
        environment.define(name.lexeme, value);
      } catch (e:RuntimeError) {
        throw new RuntimeError(name, 'The module [${stmt.path.literal}] does not export: ${name.lexeme}');
      }
    }
    return null;
  }

  public function visitReturnStmt(stmt:Stmt.Return):Dynamic {
    var value = null;
    if (stmt.value != null) value = evaluate(stmt.value);
    throw new Return(value);
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
    return expr.value;
  }

  public function visitLogicalExpr(expr:Expr.Logical):Dynamic {
    var left = evaluate(expr.left);
    if (expr.op.type.equals(TokOr)) {
      if (isTruthy(left)) return left;
    } else {
      if (!isTruthy(left)) return left;
    }
    return evaluate(expr.right);
  }

  public function visitSetExpr(expr:Expr.Set):Dynamic {
    var object = evaluate(expr.object);
    if (!Std.is(object, Instance)) {
      throw new RuntimeError(expr.name, "Only instances have fields.");
    }
    var value = evaluate(expr.value);
    (cast object).set(expr.name, value);
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
      default: null;
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

    if (arguments.length != callable.arity()) {
      throw new RuntimeError(expr.paren, 'Expected ${callable.arity()} arguments but got ${arguments.length}.');
    }

    return callable.call(this, arguments); 
  }

  public function visitGetExpr(expr:Expr.Get):Dynamic {
    var object = evaluate(expr.object);
    if (Std.is(object, Object)) {
      return (cast object).get(expr.name);
    }
    throw new RuntimeError(expr.name, "Only objects have properties.");
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

  private function getModule(name:String) {
    if (!modules.exists(name)) {
      loadModule(name);
    }
    return modules.get(name);
  }

  private function loadModule(name:String) {
    var path = loader.find(name);
    var source = loader.load(path);
    var previous = environment;

    var scanner = new Scanner(source);
    var tokens = scanner.scanTokens();
    var parser = new Parser(tokens);
    var stmts = parser.parse();
    var resolver = new Resolver(this);

    resolver.resolve(stmts);
    environment = new Environment(globals);
    interpret(stmts);
    modules.set(name, environment);

    environment = previous;
  }

}
