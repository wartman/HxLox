package hxlox.interpreter.foreign;

import hxlox.interpreter.Interpreter;
import hxlox.interpreter.Callable;

class Clock implements Callable {

  public function new() {}

  public function arity():Int {
    return 0;
  }

  public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic {
    return (Sys.cpuTime() * 1000.0);
  }

  public function toString():String {
    return "<native function>";
  }
}
