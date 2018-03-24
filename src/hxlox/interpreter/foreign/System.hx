package hxlox.interpreter.foreign;

import hxlox.Token;
import hxlox.interpreter.Object;
import hxlox.interpreter.Callable;
import hxlox.interpreter.RuntimeError;

class System implements Object {

  private var methods:Map<String, Callable> = new Map();

  public function new() {
    methods.set('print', new Print());
    methods.set('getCwd', new GetCwd());
    methods.set('getTime', new GetTime());
  }

  public function get(name:Token):Dynamic {
    if (methods.exists(name.lexeme)) {
      return methods.get(name.lexeme);
    }
    throw new RuntimeError(name, "Undefined property '" + name.lexeme + "'.");
  }

  public function set(name:Token, value:Dynamic):Void {
    throw new RuntimeError(name, "Cannot set properties on builtin objects");
  }

}

private class Print implements Callable {

  public function new() {}

  public function arity():Int {
    return 1;
  }

  public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic {
    for (arg in arguments) {
      Sys.println(Std.string(arg));
    }
    return null;
  }
  
}

private class GetCwd implements Callable {

  public function new() {}

  public function arity():Int {
    return 0;
  }

  public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic {
    return Sys.getCwd();
  }

}

private class GetTime implements Callable {

  public function new() {}

  public function arity():Int {
    return 0;
  }

  public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic {
    return Sys.cpuTime() / 1000.0;
  }

}
