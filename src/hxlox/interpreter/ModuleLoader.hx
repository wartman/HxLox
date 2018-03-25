package hxlox.interpreter;

import hxlox.Token;

interface ModuleLoader {
  public function find(tokens:Array<Token>):String;
  public function load(path:String):String;
}
