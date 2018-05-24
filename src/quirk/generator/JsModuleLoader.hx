package quirk.generator;

import quirk.Token;
import quirk.ModuleLoader;
import sys.io.File;

using haxe.io.Path;

class JsModuleLoader implements ModuleLoader {

  // Resolve js implementation paths. These refer to the actual locations
  // of the files, NOT the module name.
  private static var implementations:Map<String, String> = [ 
    'Std/Core' => 'Std/Js/Core',
    'Std/Mirror' => 'Std/Js/Mirror'
  ];
  private var mappings:Map<String, String>;
  private var root:String;
  private var extension:String = 'qrk';

  public function new(root:String, ?mappings:Map<String, String>) {
    this.root = root;
    this.mappings = mappings != null? mappings : new Map();
  }

  public function find(tokens:Array<Token>):String {
    var first = tokens[0].lexeme;
    var parts = tokens.map(function (t) return t.lexeme);
    return parts.join('/');
  }

  public function load(path:String):String {
    if (implementations.exists(path)) {
      path = implementations.get(path);
    }
    for (pattern in mappings.keys()) {
      var re = new EReg('^' + pattern, 'i');
      if (re.match(path)) {
        path = re
          .replace(path, mappings.get(pattern))
          .normalize()
          .withExtension(extension);
        return File.getBytes(path).toString();
      }
    }
    if (path.extension() == '') {
      path = path.withExtension(extension);
    }
    return File.getBytes(Path.join([ root, path ])).toString();
  }

}
