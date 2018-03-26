package hxlox.interpreter;

import hxlox.Stmt.Fun;

class Function extends CoreType implements Callable {

  private var declaration:Fun;
  private var closure:Environment;
  private var isInitializer:Bool;

  public function new(declaration:Fun, closure:Environment, isInitializer:Bool) {
    this.declaration = declaration;
    this.closure = closure;
    this.isInitializer = isInitializer;

    methods.set('call', new FunctionCallMethod(this));
    methods.set('bind', new FunctionBindMethod(this));
  }

  public function bind(instance:Object) {
    var environment = new Environment(closure);
    environment.define('this', instance);
    return new Function(declaration, environment, isInitializer);
  }

  public function arity():Int {
    return declaration.params.length;
  }

  public function call(interpreter:Interpreter, args:Array<Dynamic>):Dynamic {
    var environment = new Environment(closure);
    for (i in 0...declaration.params.length) {
      environment.define(declaration.params[i].lexeme, args[i]);
    }
    try {
      interpreter.executeBlock(declaration.body, environment);
    } catch (returnValue:Return) {
      return returnValue.value;
    }
    if (isInitializer) return closure.getAt(0, "this");
    return null;
  }

 override public function toString() {
    return '<fun ${declaration.name.lexeme}>';
  }

}

class FunctionCallMethod implements Callable {

  private var instance:Function;

  public function new(instance:Function) {
    this.instance = instance;
  }

  public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic {
    return instance.call(interpreter, arguments);
  }

  public function arity():Int {
    return instance.arity();
  }

}

class FunctionBindMethod implements Callable {

  private var instance:Function;

  public function new(instance:Function) {
    this.instance = instance;
  }

  public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic {
    return instance.bind(arguments[0]);
  }

  public function arity():Int {
    return 1;
  }

}
