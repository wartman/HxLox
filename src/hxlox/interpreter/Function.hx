package hxlox.interpreter;

import hxlox.Stmt.Fun;

class Function implements Callable {

  private var declaration:Fun;
  private var closure:Environment;
  private var isInitializer:Bool;

  public function new(declaration:Fun, closure:Environment, isInitializer:Bool) {
    this.declaration = declaration;
    this.closure = closure;
    this.isInitializer = isInitializer;
  }

  public function bind(instance:Instance) {
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
      if (isInitializer) {
        return closure.getAt(0, "this");
      }
      return returnValue.value;
    }
    if (isInitializer) return closure.getAt(0, "this");
    return null;
  }

  public function toString() {
    return '<fun ${declaration.name.lexeme}>';
  }

}
