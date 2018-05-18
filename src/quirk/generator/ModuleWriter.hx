package quirk.generator;

using sys.io.File;
using sys.FileSystem;
using haxe.io.Path;
using Lambda;

class ModuleWriter {

  private var root:String;

  public function new(root:String) {
    this.root = root;
  }

  public function writeToRoot(content:String) {
    ensureDir(root);
    root.saveContent(content);
    logSuccess(root);
  }

  public function writeToFile(path:String, content:String) {
    var path = Path.join([ root, path ]);
    ensureDir(path);
    path.saveContent(content);
    logSuccess(path);
  }

  private function ensureDir(path:String) {
    var dir = path.directory();
    if (!dir.exists()) {
      dir.createDirectory();
    }
  }

  private function logSuccess(path) {
    Sys.println('Saved to: $path');
  }

}