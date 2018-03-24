package hxlox.interpreter;

import HxLox;
import sys.io.File;

using haxe.io.Path;

typedef ModuleFinder = String -> String;

class Loader {

  private var interpreter:Interpreter;
  private var modules:Map<String, Environment> = new Map();
  private var moduleFinder:ModuleFinder;

  public function new(interpreter:Interpreter, ?moduleFinder:ModuleFinder) {
    if (moduleFinder == null) {
      this.moduleFinder = function (name:String):String {
        var path = Path.join([Sys.getCwd(), name]).normalize();
        var ext = '.lox';
        if (path.indexOf(ext) <= 0) {
          path += ext;
        }
        return path;
      }
    }
    this.interpreter = interpreter;
  }

  public function get(name:String):Environment {
    if (!modules.exists(name)) {
      load(name);
    }
    return modules.get(name); 
  }

  private function load(name:String) {
    var path = moduleFinder(name);
    var bytes = File.getBytes(path);
    var exports = parse(bytes.toString());
    modules.set(name, exports);
  }

  private function parse(source:String):Environment {
    var scanner = new Scanner(source);
    var tokens = scanner.scanTokens();
    var parser = new Parser(tokens);
    var stmts = parser.parse();
    var resolver = new Resolver(interpreter);

    resolver.resolve(stmts);
    if (HxLox.hadError) return new Environment();
    return interpreter.interpretModule(stmts);
  }

}