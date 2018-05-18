package quirk.generator;

import quirk.Token;
import quirk.Scanner;
import quirk.Parser;
import quirk.ErrorReporter;

using sys.io.File;
using sys.FileSystem;
using haxe.io.Path;
using Lambda;

class PhpTarget implements Target {

  private var loader:JsModuleLoader;
  private var reporter:ErrorReporter;
  private var modules:Map<String, ModuleEntry> = new Map();
  private var dest:String;
  private var main:String;

  public function new(root:String, dest:String, main:String, reporter:ErrorReporter) {
    loader = new PhpModuleLoader(root);
    this.dest = dest;
    this.main = main;
    this.reporter = reporter;
  }

}