package quirk.generator;

import quirk.Token;
import quirk.ModuleLoader;
import sys.io.File;

using haxe.io.Path;

class JsModuleLoader implements ModuleLoader {

  private static var builtins:Array<String> = [ 'Std' ];
  private var root:String;
  private var extension:String = 'qrk';

  public function new(root:String) {
    this.root = root;
  }

  public function find(tokens:Array<Token>):String {
    var first = tokens[0].lexeme;
    var parts = tokens.map(function (t) return t.lexeme);
    if (first.toLowerCase() == 'npm') {
      return parts.splice(0, 1).join('/');
    }
    // if (builtins.indexOf(first) >= 0) {
    //   return [ 'quirk', 'bin' ].concat(parts).join('/');
    // }
    return parts.join('/');
  }

  public function load(path:String):String {
    if (path.extension() == '') {
      path = path.withExtension(extension);
    }
    // trace(Path.join([ root, path ]));
    return File.getBytes(Path.join([ root, path ])).toString();
  }

}