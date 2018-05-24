package;

import sys.io.File;
import quirk.Token;
import quirk.Parser;
import quirk.Scanner;
import quirk.DefaultErrorReporter;
import quirk.DefaultModuleLoader;
import quirk.core.RuntimeError;
import quirk.interpreter.Resolver;
import quirk.interpreter.Interpreter;
import quirk.generator.ModuleWriter;
import quirk.generator.JsModuleLoader;
import quirk.generator.JsTarget;
import quirk.generator.JsNodeTarget;

using haxe.io.Path;

enum GenKind {
  GenJs;
  GenJsNode;
  GenPhp;
}

class Quirk {

  public static var hadError:Bool = false;
  public static var hadRuntimeError:Bool = false;
  public static var corePaths = [
    'Std' => Path.join([ Sys.programPath(), '../../std' ]).normalize()
  ];

  public static function main() {
    var args = Sys.args();
    if (args.length > 1) {
      if (args[0] == 'gen') {
        if (args.length != 4) {
          throw 'Usage: gen [kind] [src] [dst]';
        }
        switch (args[1]) {
          case '--js': genFile(args[2], args[3], GenJs);
          case '--node': genFile(args[2], args[3], GenJsNode);
          case '--php': genFile(args[2], args[3], GenPhp);
          default: throw 'Invalid generator type';
        }
        return;
      }
      Sys.print('Usage: quirk [script]');
    } else if (args.length == 1) {
      runFile(args[0]);
    } else {
      runPrompt();
    }
  }

  private static function genFile(main:String, dest:String, kind:GenKind) {
    var reporter = new DefaultErrorReporter();
    var writer = new ModuleWriter(Path.join([ Sys.getCwd(), dest ]));

    switch (kind) {
      case GenJs:
        var loader = new JsModuleLoader(Sys.getCwd(), corePaths);
        var target = new JsTarget(main, loader, writer, reporter);
        target.write();
      case GenJsNode:
        var loader = new JsModuleLoader(Sys.getCwd(), corePaths);
        var target = new JsNodeTarget(main, loader, writer, reporter);
        target.write();
      case GenPhp:
        throw 'Not implemented yet';
    }
  }

  private static function runFile(path:String) {
    run(Sys.getCwd(), path);
    if (hadError) Sys.exit(65);
    if (hadRuntimeError) Sys.exit(70);
  }

  private static function runPrompt() {
    var input = Sys.stdin();
    Sys.println('Starting REPL. `Ctrl C` to exit.');
    while (true) {
      Sys.print('> ');
      run(input.readLine(), Sys.getCwd());
      hadError = false;
    }
  }

  public static function run(root:String, path:String = '<unknown>') {
    var reporter = new DefaultErrorReporter();
    var loader = new DefaultModuleLoader(root, corePaths);
    var source = loader.load(path);
    var scanner = new Scanner(source, path, reporter);
    var tokens = scanner.scanTokens();
    var parser = new Parser(tokens, reporter);
    var stmts = parser.parse();
    var interpreter = new Interpreter(loader, reporter);
    var resolver = new Resolver(interpreter);

    resolver.resolve(stmts);
    if (hadError) return;
    interpreter.interpret(stmts);
  }

}
