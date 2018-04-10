package quirk.interpreter;

import quirk.Stmt.Fun;

class Function implements Callable {

  private var declaration:Fun;
  private var closure:Environment;
  private var isInitializer:Bool;
  @:isVar public var meta(default, null):Map<String, Array<Dynamic>>;

  public function new(
    declaration:Fun,
    closure:Environment,
    isInitializer:Bool,
    meta:Map<String, Array<Dynamic>>
  ) {
    this.declaration = declaration;
    this.closure = closure;
    this.isInitializer = isInitializer;
    this.meta = meta;
  }

  public function bind(instance:Object) {
    var environment = new Environment(closure);
    environment.define('this', instance);
    return new Function(declaration, environment, isInitializer, meta);
  }

  public function arity():Int {
    return declaration.params.length;
  }

  public function call(interpreter:Interpreter, args:Array<Dynamic>):Dynamic {
    var environment = new Environment(closure);
    for (i in 0...declaration.params.length) {
      // todo: handle argument defaults
      environment.define(declaration.params[i].name.lexeme, args[i]);
    }
    try {
      interpreter.executeBlock(declaration.body, environment);
    } catch (returnValue:Return) {
      return returnValue.value;
    }
    if (isInitializer) return closure.getAt(0, "this");
    return null;
  }

  public function toString() {
    return '<fun ${declaration.name.lexeme}>';
  }

}
