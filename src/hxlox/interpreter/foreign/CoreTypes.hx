package hxlox.interpreter.foreign;

import hxlox.Parser;
import hxlox.Scanner;
import hxlox.interpreter.Callable;
import hxlox.interpreter.Class;
import hxlox.interpreter.Instance;
import hxlox.interpreter.Environment;
import hxlox.interpreter.Interpreter;
import hxlox.interpreter.Resolver;

using StringTools;

class CoreTypes {

  public static function addCoreTypes(interpreter:Interpreter) {
    var globals = interpreter.globals;

    // System hooks
    globals.define('__SYSTEM_PRINT', new ExternCallable(function (args) {
      var value = Std.string(args[0]);
      value = value.replace("\\n", '\n'); // handle this issue better :P
      Sys.print(value);
      return null;
    }, 1));
    globals.define('__SYSTEM_PRINT_LN', new ExternCallable(function (args) {
      Sys.println(Std.string(args[0]));
      return null;
    }, 1));
    globals.define('__SYSTEM_GET_MODULE', new ExternCallable(function (args) {
      return interpreter.currentModule;
    }, 0));
    globals.define('__SYSTEM_GET_CWD', new ExternCallable(function (args) {
      return Sys.getCwd();
    }, 0));

    // Reflection hooks
    globals.define('__REFLECT_TYPE', new ExternCallable(function (args) {
      var target = args[0];
      if (Std.is(target, Instance)) {
        var inst:Instance = cast target;
        return inst.getClass().name;
      }
      if (Std.is(target, Class)) {
        var cls:Class = cast target;
        return cls.name;
      }
      if (Std.is(target, Callable)) {
        return '<callable>';
      }
      return '<object>';
    }, 1));
    globals.define('__REFLECT_GET_FIELD', new ExternCallable(function (args) {
      var obj:Instance = args[0];
      var name:String = Std.string(args[1]);
      return obj.fields.get(name);
    }, 2));
    globals.define('__REFLECT_GET_METHOD', new ExternCallable(function (args) {
      var inst:Instance = cast args[0];
      return inst.getClass().findMethod(inst, Std.string(args[1]));
    }, 2));
    globals.define('__REFLECT_GET_METHOD_NAMES', new ExternCallable(function (args) {
      var target:Class;
      var inst = args[0];
      if (Std.is(inst, Instance)) {
        target = inst.getClass();
      } else {
        target = cast inst;
      }
      var arrCls:Class = globals.values.get('Array');
      var names:Array<String> = [];
      for (name in target.methods.keys()) {
        names.push(name);
      }
      var arr:Instance = arrCls.call(interpreter, [ names ]);
      return arr;
    }, 1));

    // Array hooks
    globals.define('__ARRAY_GET', new ExternCallable(function (args) {
      var values:Array<Dynamic> = args[0];
      var index:Int = Std.int(args[1]);
      return values[index];
    }, 2));
    globals.define('__ARRAY_SET', new ExternCallable(function (args) {
      var values:Array<Dynamic> = args[0];
      var index:Int = Std.int(args[1]);
      values[index] = args[2];
      return null;
    }, 3));
    globals.define('__ARRAY_LENGTH', new ExternCallable(function (args) {
      var values:Array<Dynamic> = args[0];
      return values.length;
    }, 1));
    globals.define('__ARRAY_PUSH', new ExternCallable(function (args) {
      var values:Array<Dynamic> = args[0];
      values.push(args[1]);
      return null;
    }, 2));
    globals.define('__ARRAY_POP', new ExternCallable(function (args) {
      var values:Array<Dynamic> = args[0];
      return values.pop();
    }, 1));

    // Generic literal hooks
    globals.define('__LITERAL_ADD', new ExternCallable(function (args) {
      var value = Std.string(args[0]);
      var combine = Std.string(args[1]);
      return value + combine;
    }, 2));

    // String hooks
    globals.define('__STRING_SPLIT', new ExternCallable(function (args) {
      var value:String = Std.string(args[0]);
      var array:Class = globals.values.get('Array');
      return array.call(interpreter, [ value.split(Std.string(args[1])) ]);
    }, 2));
    globals.define('__STRING_SUBSTRING', new ExternCallable(function (args) {
      var value:String = Std.string(args[0]);
      return value.substring(
        Std.int(args[1]), 
        Std.int(args[2])
      );
    }, 3));
    globals.define('__STRING_INDEX_OF', new ExternCallable(function (args) {
      var value:String = Std.string(args[0]);
      return value.indexOf(Std.string(args[1]));
    }, 2));

    var scanner = new Scanner("

      class System {

        static print(s) {
          __SYSTEM_PRINT(s);
        }

        static println(s) {
          __SYSTEM_PRINT_LN(s);
        }

        static getModule() {
          return __SYSTEM_GET_MODULE();
        }

        static getCwd() {
          return __SYSTEM_GET_CWD();
        }

      }

      class Reflect {

        static getType(cls) {
          return __REFLECT_TYPE(cls);
        }

        static is(a, b) {
          // Todo: need to be able to check superclasses.
          return this.getType(a) == this.getType(b);
        }

        static getMethod(obj, name) {
          return __REFLECT_GET_METHOD(obj, name);
        }

        static getMethodNames(cls) {
          return __REFLECT_GET_METHOD_NAMES(cls);
        }

        static getField(cls, name) {
          return __REFLECT_GET_FIELD(cls, name);
        }

      }

      class Exception {

        init(message) {
          this.message = message;
        }

      }

      class Array {

        init(values) {
          this.values = values;
        }

        __offsetGet(i) {
          return __ARRAY_GET(this.values, i);
        }

        __offsetSet(i, value) {
          __ARRAY_SET(this.values, i, value);
        }

        length() {
          return __ARRAY_LENGTH(this.values);
        }

        push(value) {
          __ARRAY_PUSH(this.values, value);
          return this.length();
        }

        pop() {
          return __ARRAY_POP(this.values);
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

        __offsetGet(key) {
          return Reflect.getField(this, key);
        }

      }

      class String {

        init(value) {
          this.value = value;
        }

        indexOf(find) {
          return __STRING_INDEX_OF(this.value, find);
        }

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
