package quirk.generator;

import quirk.Token;
import quirk.Stmt;
import quirk.Scanner;
import quirk.Parser;
import quirk.ErrorReporter;
import quirk.ModuleLoader;

using Lambda;

class BaseTarget implements Target {

  private var loader:ModuleLoader;
  private var writer:ModuleWriter;
  private var reporter:ErrorReporter;
  private var modules:Map<String, ModuleEntry> = new Map();
  private var main:String;

  public function new(
    main:String,
    loader:ModuleLoader,
    writer:ModuleWriter,
    reporter:ErrorReporter
  ) {
    this.loader = loader;
    this.writer = writer;
    this.main = main;
    this.reporter = reporter;
  }

  public function resolveModule(path:Array<Token>, ?currentModule:Array<Token>):String {
    return loader.find(path);
  }

  public function resolveFile(path:Array<Token>):String {
    return loader.find(path);
  }

  public function addModuleDependency(name:String, dep:String):Void {
    var mod = modules.get(name);
    if (mod == null) {
      throw 'Tried to add [$dep] for unregistered module [$name]';
    }
    if (mod.deps.exists(function (d) return d == dep)) {
      return;
    }
    mod.deps.push(dep);
  }

  public function addModule(name:String):Void {
    if (modules.exists(name)) {
      return;
    }
    var source = loader.load(name);
    var tokens = new Scanner(source, name, reporter).scanTokens();
    var stmts = new Parser(tokens, reporter).parse();
    modules.set(name, { generated: '', deps: [] });
    modules.get(name).generated = generate(name, stmts);
  }
  
  public function addBuiltinModule(name:String, ?moduleName:String):Void {
    if (moduleName == null) {
      moduleName = name;
    }
    var source = haxe.Resource.getString(name);
    var tokens = new Scanner(source, name, reporter).scanTokens();
    var stmts = new Parser(tokens, reporter).parse();
    modules.set(moduleName, { generated: '', deps: [] });
    modules.get(moduleName).generated = generate(moduleName, stmts); 
  }

  public function addResource(name:String, ?moduleName:String) {
    if (moduleName == null) {
      moduleName = name;
    }
    modules.set(moduleName, { generated: loader.load(name), deps: [] });
  }

  public function write():Void {
    throw 'Not implemented in BaseTarget.';
  }

  public function generate(name:String, stmts:Array<Stmt>):String {
    throw 'Not implemented in BaseTarget';
    return '';
  }

}
