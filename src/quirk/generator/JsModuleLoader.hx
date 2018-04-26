package quirk.generator;

import quirk.Token;
import quirk.ModuleLoader;
import sys.io.File;

using haxe.io.Path;

class JsModuleLoader implements ModuleLoader {

  // Resolve js implementation paths. These refer to the actual locations
  // of the files, NOT the module name.
  private static var implementations:Map<String, String> = [ 
    'Std/Core' => 'Std/Js/Core'
  ];
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
    return parts.join('/');
  }

  public function load(path:String):String {
    if (implementations.exists(path)) {
      path = implementations.get(path);
    }
    if (path.extension() == '') {
      path = path.withExtension(extension);
    }
    return File.getBytes(Path.join([ root, path ])).toString();
  }

}
