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

  public function writeToRoot(content:String, ext:String) {
    var path = root.withExtension(ext);
    ensureDir(path);
    root.saveContent(content);
    logSuccess(root);
  }

  public function writeToFile(path:String, content:String, ?ext:String) {
    var path = Path.join([ root, path ]);
    if (ext != null) {
      path = path.withExtension(ext);
    }
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