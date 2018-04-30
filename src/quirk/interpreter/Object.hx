package quirk.interpreter;

import quirk.Token;

interface Object {
  public function get(interpreter:Interpreter, name:Token):Dynamic;
  public function set(interpreter:Interpreter, name:Token, value:Dynamic):Void;
  public function toString():String;
}