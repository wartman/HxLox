package;

import sys.io.File;
import quirk.Token;
import quirk.Compiler;
import quirk.DefaultErrorReporter;
import quirk.DefaultModuleLoader;
import quirk.interpreter.RuntimeError;
import quirk.interpreter.Resolver;
import quirk.interpreter.Interpreter;

using haxe.io.Path;

class Quirk {

  public static var hadError:Bool = false;
  public static var hadRuntimeError:Bool = false;

  public static function main() {
    var args = Sys.args();
    if (args.length > 1) {
      Sys.print('Usage: quirk [script]');
    } else if (args.length == 1) {
      runFile(args[0]);
    } else {
      runPrompt();
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

  private static function run(root:String, path:String = '<unknown>') {
    var loader = new DefaultModuleLoader(root);
    var reporter = new DefaultErrorReporter();
    var compiler = new Compiler(loader, reporter);
    var stmts = compiler.parseFile(path);
    var interpreter = new Interpreter(compiler, reporter);
    var resolver = new Resolver(interpreter);

    resolver.resolve(stmts);
    if (hadError) return;
    interpreter.interpret(stmts);

    // TEST
    Sys.println('');
    Sys.println('----');
    Sys.println('TEST - DEFINED TYPES:');
    for (key in compiler.types.keys()) {
      trace(key);
    }
    // TEST
    trace(compiler.types.get('test.core.ReflectTest'));
    trace(compiler.types.get('test.core.ReflectTest').superclass.t.get());
  }

}
