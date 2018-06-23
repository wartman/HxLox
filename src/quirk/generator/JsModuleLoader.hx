package quirk.generator;

import sys.io.File;
import sys.FileSystem;
import quirk.Token;

using haxe.io.Path;

class JsModuleLoader implements ModuleLoader {

  // Resolve js implementation paths. These refer to the actual locations
  // of the files, NOT the module name.
  private static var implementations:Map<String, String> = [ 
    'Std/Core' => 'Std/Js/Core',
    'Std/Mirror' => 'Std/Js/Mirror',
    'Std/RegExp' => 'Std/Js/RegExp'
  ];
  private var mappings:Map<String, String>;
  private var root:String;
  private var extension:String = 'qrk';

  public function new(root:String, ?mappings:Map<String, String>) {
    this.root = root;
    this.mappings = mappings != null? mappings : new Map();
  }

  public function find(tokens:Array<Token>):String {
    var parts = tokens.map(function (t) return t.lexeme);
    return parts.join('/');
  }

  public function findRelative(tokens:Array<Token>, relative:Array<Token>):String {
    var parts = tokens.map(function (t) return t.lexeme);
    var walkBack:Array<String> = [];
    var relativePos = 0;
    for (i in 0...relative.length - 1) {
      if (tokens.length >= i) {
        if (relative[i].lexeme != tokens[relativePos].lexeme) {
          walkBack.push('..');
        } else {
          parts.shift();
          relativePos++;
        }
      } else {
        break;
      }
    }
    if (walkBack.length == 0) {
      return './' + parts.join('/');
    }
    return walkBack.concat(parts).join('/');
  }

  public function load(path:String):String {
    if (implementations.exists(path)) {
      path = implementations.get(path);
    }
    for (pattern in mappings.keys()) {
      var re = new EReg('^' + pattern, 'i');
      if (re.match(path)) {
        path = re.replace(path, mappings.get(pattern)).normalize();
        if (path.extension() == '') {
          path = path.withExtension(extension);
        }
        if (!FileSystem.exists(path)) {
          throw 'The file [${path}] does not exist';
        }
        return File.getBytes(path).toString();
      }
    }
    path = Path.join([ root, path ]).withExtension(extension);
    if (!FileSystem.exists(path)) {
      throw 'The file [${path}] does not exist';
    }
    return File.getBytes(path).toString();
  }

}
