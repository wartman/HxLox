package hxlox.interpreter;

import hxlox.Token;

interface Object {
  public function get(name:Token):Dynamic;
  public function set(name:Token, value:Dynamic):Void;
}