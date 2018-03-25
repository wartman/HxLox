package;

import sys.io.File;
import hxlox.Token;
import hxlox.Parser;
import hxlox.Scanner;
import hxlox.interpreter.DefaultModuleLoader;
import hxlox.interpreter.RuntimeError;
import hxlox.interpreter.Resolver;
import hxlox.interpreter.Interpreter;

using haxe.io.Path;

class HxLox {

  public static var hadError:Bool = false;
  public static var hadRuntimeError:Bool = false;

  public static function main() {
    var args = Sys.args();
    if (args.length > 1) {
      Sys.print('Usage: hxlox [script]');
    } else if (args.length == 1) {
      runFile(args[0]);  
    } else {
      runPrompt();
    }
  }

  private static function runFile(path:String) {
    var path = Path.join([ Sys.getCwd(), path ]).normalize();
    if (path.extension() == '') {
      path = path.withExtension('lox');
    }
    var root = path.directory().addTrailingSlash();
    var bytes = File.getBytes(path);

    Sys.println('Running: ${path}');
    Sys.println('Program root: ${root}');
    Sys.println('---');

    run(bytes.toString(), root);
    
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

  private static function run(source:String, root:String) {
    var loader = new DefaultModuleLoader(root);
    var scanner = new Scanner(source);
    var tokens = scanner.scanTokens();
    var parser = new Parser(tokens);
    var stmts = parser.parse();
    var interpreter = new Interpreter(loader);
    var resolver = new Resolver(interpreter);

    resolver.resolve(stmts);
    if (hadError) return;
    interpreter.interpret(stmts);
  }

  public static function runtimeError(error:RuntimeError) {
    Sys.println(error.message + "\n[line " + error.token.line + ']');
    hadRuntimeError = true;
  }

  public static function error(token:{
    line:Int,
    ?lexeme:String,
    ?type:hxlox.TokenType
  }, message:String) {
    if (token.type == null) {
      report(token.line, '', message);
    } else if (token.type.equals(hxlox.TokenType.TokEof)) {
      report(token.line, " at end", message);
    } else {
      report(token.line, " at '" + token.lexeme + "'", message);
    }
  }

  private static function report(line:Int, where:String, message:String) {
    Sys.println('[line $line] Error${where}: ${message}');
    hadError = true;
  }

}