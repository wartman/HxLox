package quirk.interpreter;

interface Callable {
  public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic;
  public function arity():Int;
  public function isDynamic():Bool;
}