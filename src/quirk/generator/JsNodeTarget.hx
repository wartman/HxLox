package quirk.generator;

using sys.io.File;
using sys.FileSystem;
using haxe.io.Path;
using Lambda;

class JsNodeTarget extends JsTarget {

  override private function writeModules() {
    var root = dest;
    for (name in modules.keys()) {
      var path = Path.join([ root, name ]).withExtension('js');
      var dir = path.directory();
      if (!dir.exists()) {
        dir.createDirectory();
      }
      var entry = modules.get(name);
      var deps = entry.deps;
      var body = entry.generated;
      // Add prelude deps to file
      if (name != '_prelude') {
        body = 'var __quirk = require("_prelude").__quirk;\n' + body;
      }
      path.saveContent(body);
      Sys.println('Saved to :' + path);
    }
  }

}
