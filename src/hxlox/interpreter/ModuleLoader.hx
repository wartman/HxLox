package hxlox.interpreter;

interface ModuleLoader {
  public function find(name:String):String;
  public function load(path:String):String;
}
