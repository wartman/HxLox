package quirk.generator;

import sys.io.File;

using sys.FileSystem;
using haxe.io.Path;

class JsBundleWriter implements Writer {

  private var root:String;

  public function new(root:String) {
    this.root = root;
  }

  public function write(modules:Map<String, String>) {
    var path = root.withExtension('js');
    var dir = path.directory();
    if (!dir.exists()) {
      dir.createDirectory();
    }
    var output:Array<String> = [];
    output.push(modules.get('_prelude'));
    for (name in modules.keys()) {
      if (name != '_prelude' && name != '_init') {
        output.push(modules.get(name));
      }
    }
    output.push(modules.get('_init'));
    File.saveContent(path, output.join('\n'));
  }

}