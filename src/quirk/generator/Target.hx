package quirk.generator;

import quirk.Token;

interface Target {
  public function resolveModule(path:Array<Token>):String;
  public function addModuleDependency(name:String, dep:String):Void;
  public function addModule(name:String):Void;
  public function addBuiltinModule(name:String, ?moduleName:String):Void;
  public function addResource(name:String, ?moduleName:String):Void;
  public function write():Void;
}