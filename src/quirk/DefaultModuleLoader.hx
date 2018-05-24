package quirk;

import sys.io.File;
import sys.FileSystem;

using haxe.io.Path;

class DefaultModuleLoader implements ModuleLoader {

  private var root:String;
  private var extension:String = 'qrk';
  private var mappings:Map<String, String>;

  public function new(?root:String, ?mappings:Map<String, String>) {
    this.root = root != null ? root : Sys.getCwd();
    this.mappings = mappings != null? mappings : new Map();
  }

  public function find(tokens:Array<Token>):String {
    return tokens.map(function (p) return p.lexeme).join('/');
  }

  public function load(path:String):String {
    for (pattern in mappings.keys()) {
      var re = new EReg('^' + pattern, 'i');
      if (re.match(path)) {
        path = re
          .replace(path, mappings.get(pattern))
          .normalize()
          .withExtension(extension);
        if (!FileSystem.exists(path)) {
          throw 'The file [${path}] does not exist';
        }
        return File.getBytes(path).toString();
      }
    }
    path = Path.join([ root, path ]).normalize().withExtension(extension);
    if (!FileSystem.exists(path)) {
      throw 'The file [${path}] does not exist';
    }
    return File.getBytes(path).toString();
  }

}
