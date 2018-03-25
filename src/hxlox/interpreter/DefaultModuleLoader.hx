package hxlox.interpreter;

import sys.io.File;

using haxe.io.Path;

class DefaultModuleLoader implements ModuleLoader {

  private var root:String;
  private var extension:String = 'lox';

  public function new(?root:String) {
    if (root == null) {
      root = Sys.getCwd();
    }
    this.root = root;
  }

  public function find(name:String):String {
    var path = Path.join([root, name]).normalize();
    if (path.extension() != 'lox') {
      // throw error??
      path = path.withExtension(extension);
    }
    return path;
  }

  public function load(path:String):String {
    return File.getBytes(path).toString();
  }

}