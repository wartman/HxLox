package quirk.generator;

import sys.io.File;

using StringTools;
using sys.FileSystem;
using haxe.io.Path;

class PhpWriter implements Writer {

  private var root:String;

  public function new(root:String) {
    this.root = root;
  }

  public function write(modules:Map<String, String>) {
    for (name in modules.keys()) {
      // trace(name);
      writeModule(name, modules.get(name));
    }
  }

  public function writeModule(path:String, output:String) {
    var path = ensureDir(path).withExtension('php');
    File.saveContent(path, output);
  }

  private function ensureDir(name:String) {
    name = name.replace('.', '/');
    var dir = Path.join([ root, name ]);
    if (!dir.exists()) {
      dir.createDirectory();
    }
    return dir;
  }

}