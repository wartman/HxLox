package;

import sys.io.File;
import quirk.Token;
import quirk.Parser;
import quirk.Scanner;
import quirk.DefaultErrorReporter;
import quirk.DefaultModuleLoader;
import quirk.interpreter.RuntimeError;
import quirk.interpreter.Resolver;
import quirk.interpreter.Interpreter;
import quirk.generator.Generator;
import quirk.generator.JsGenerator;
import quirk.generator.PhpGenerator;

using haxe.io.Path;

class Quirk {

  public static var hadError:Bool = false;
  public static var hadRuntimeError:Bool = false;

  public static function main() {
    var args = Sys.args();
    if (args.length > 1) {
      if (args[0] == 'gen') {
        switch (args[1]) {
          case '--js': genFile(args[2], 'js');
          case '--php': genFile(args[2], 'php');
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

  private static function genFile(path:String, kind:String) {
    var reporter = new DefaultErrorReporter();
    var loader = new DefaultModuleLoader(Sys.getCwd());
    var source = loader.load(path);
    var scanner = new Scanner(source, path, reporter);
    var tokens = scanner.scanTokens();
    var parser = new Parser(tokens, reporter);
    var stmts = parser.parse();
    var generator:Generator = kind == 'js'
      ? new JsGenerator(loader, reporter)
      : new PhpGenerator(loader, reporter);
    var js = generator.generate(stmts);

    trace(js);
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

  private static function run(root:String, path:String = '<unknown>') {
    var reporter = new DefaultErrorReporter();
    var loader = new DefaultModuleLoader(root);
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
