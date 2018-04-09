package quirk.interpreter;

import quirk.Token;

interface Object {
  public function get(name:Token):Dynamic;
  public function set(name:Token, value:Dynamic):Void;
  public function toString():String;
}