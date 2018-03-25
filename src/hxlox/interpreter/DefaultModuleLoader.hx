package hxlox.interpreter;

import sys.io.File;
import hxlox.Token;

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

  public function find(tokens:Array<Token>):String {
    var path = tokens.map(function (p) return p.lexeme).join('/');
    return Path.join([ root, path ]).normalize().withExtension(extension);
  }

  public function load(path:String):String {
    return File.getBytes(path).toString();
  }

}