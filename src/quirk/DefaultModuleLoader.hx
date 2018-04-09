package quirk;

import sys.io.File;

using haxe.io.Path;

class DefaultModuleLoader implements ModuleLoader {

  private var root:String;
  private var extension:String = 'qrk';

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
    if (path.extension() == '') {
      path = path.withExtension(extension);
    }
    return File.getBytes(path).toString();
  }

}
