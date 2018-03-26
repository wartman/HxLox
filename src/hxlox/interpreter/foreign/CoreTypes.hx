package hxlox.interpreter.foreign;

import hxlox.Parser;
import hxlox.Scanner;
import hxlox.interpreter.Callable;
import hxlox.interpreter.Environment;
import hxlox.interpreter.Interpreter;
import hxlox.interpreter.Resolver;
import hxlox.interpreter.Instance;

class CoreTypes {

  public static function addCoreTypes(interpreter:Interpreter) {
    var globals = interpreter.globals;

    globals.define('__SYSTEM_PRINT', new ExternCallable(function (args) {
      Sys.println(Std.string(args[0]));
      return null;
    }, 1));
    globals.define('__SYSTEM_GET_MODULE', new ExternCallable(function (args) {
      return interpreter.currentModule;
    }, 0));
    globals.define('__SYSTEM_GET_CWD', new ExternCallable(function (args) {
      return Sys.getCwd();
    }, 0));

    globals.define('__ARRAY_GET', new ExternCallable(function (args) {
      var values:Array<Dynamic> = args[0];
      var index:Int = Std.int(args[1]);
      return values[index];
    }, 2));
    globals.define('__ARRAY_LENGTH', new ExternCallable(function (args) {
      var values:Array<Dynamic> = args[0];
      return values.length;
    }, 1));
    globals.define('__ARRAY_PUSH', new ExternCallable(function (args) {
      var values:Array<Dynamic> = args[0];
      values.push(args[1]);
      return null;
    }, 2));

    globals.define('__LITERAL_ADD', new ExternCallable(function (args) {
      var value = Std.string(args[0]);
      var combine = Std.string(args[1]);
      return value + combine;
    }, 2));

    globals.define('__STRING_SPLIT', new ExternCallable(function (args) {
      var value:String = Std.string(args[0]);
      var array:Class = globals.values.get('Array');
      return array.call(interpreter, [ value.split(Std.string(args[1])) ]);
    }, 2));
    globals.define('__STRING_SUBSTRING', new ExternCallable(function (args) {
      var value:String = Std.string(args[0]);
      var string:Class = globals.values.get('String');
      return string.call(interpreter, [ value.substring(
        Std.int(args[1]), 
        Std.int(args[2])
      ) ]);
    }, 3));

    var scanner = new Scanner("

      class System {

        static print(s) {
          __SYSTEM_PRINT(s);
        }

        static getModule() {
          return __SYSTEM_GET_MODULE();
        }

        static getCwd() {
          return __SYSTEM_GET_CWD();
        }

      }

      class Array {

        init(values) {
          this.values = values;
        }

        get(i) {
          return __ARRAY_GET(this.values, i);
        }

        length() {
          return __ARRAY_LENGTH(this.values);
        }

        push(value) {
          __ARRAY_PUSH(this.values, value);
          return this.length();
        }

        map(cb) {
          var out = [];
          for (var i = 0; i < this.length(); i = i + 1) {
            var value = __ARRAY_GET(this.values, i);
            out.push(cb(value, i));
          }
          return out;
        }

      }

      class Object {

        // Noop for now.

      }

      class Literal {

        init(value) {
          this.value = value;
        }

        add(b) {
          return __LITERAL_ADD(this.value, b);
        }

      }

      class String : Literal {

        split(sep) {
          return __STRING_SPLIT(this.value, sep);
        }

        substring(start, end) {
          return __STRING_SUBSTRING(this.value, start, end);
        }

        toString() {
          return this.value;
        }

      }

    ");
    
    var tokens = scanner.scanTokens();
    var parser = new Parser(tokens);
    var stmts = parser.parse();
    var resolver = new Resolver(interpreter);

    resolver.resolve(stmts);
    interpreter.interpret(stmts);
  }

}

class ExternCallable implements Callable {

  private var fn:Array<Dynamic>->Dynamic;
  private var arity_:Int;

  public function new(fn:Array<Dynamic>->Dynamic, arity:Int) {
    this.fn = fn;
    this.arity_ = arity;
  }

  public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic {
    return fn(arguments);
  }

  public function arity():Int {
    return this.arity_;
  }

} 
