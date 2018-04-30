package quirk.interpreter.foreign;

import quirk.Parser;
import quirk.Scanner;
import quirk.interpreter.Callable;
import quirk.interpreter.Class;
import quirk.interpreter.Instance;
import quirk.interpreter.Environment;
import quirk.interpreter.Interpreter;
import quirk.interpreter.Resolver;

using StringTools;

class CoreTypes {

  public static function addCoreTypes(interpreter:Interpreter) {
    var globals = interpreter.globals;
    var reporter = interpreter.reporter;

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
        return inst.getClass();
      }
      if (Std.is(target, Class)) {
        var cls:Class = cast target;
        return cls;
      }
      // Todo: should have a Function class.
      // if (Std.is(target, Callable)) {
      //   return '<callable>';
      // }
      return null;
    }, 1));
    globals.define('__REFLECT_TYPE_NAME', new ExternCallable(function (args) {
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
    globals.define('__REFLECT_GET_SUPERCLASS', new ExternCallable(function (args) {
      var target:Dynamic = args[0];
      if (Std.is(target, String)) {
        target = globals.values.get(target);
        if (target == null) {
          return null;
        }
      }
      if (Std.is(target, Instance)) {
        var inst:Instance = cast target;
        return inst.getClass().superclass;
      }
      if (Std.is(target, Class)) {
        var cls:Class = cast target;
        return cls.superclass;
      }
      return null;
    }, 1));
    globals.define('__REFLECT_GET_FIELD', new ExternCallable(function (args) {
      var obj:Instance = args[0];
      var name:String = Std.string(args[1]);
      return obj.fields.get(name);
    }, 2));
    globals.define('__REFLECT_SET_FIELD', new ExternCallable(function (args) {
      var target:Instance = cast args[0];
      var key:String = Std.string(args[1]);
      var value:Dynamic = args[2];
      target.fields.set(key, value);
      return null;
    }, 3));
    globals.define('__REFLECT_GET_FIELD_NAMES', new ExternCallable(function (args) {
      var target:Instance = cast args[0];
      var arrCls:Class = globals.values.get('Array');
      var names:Array<String> = [];
      for (name in target.fields.keys()) {
        names.push(name);
      }
      var arr:Instance = arrCls.call(interpreter, [ names ]);
      return arr;
    }, 1));
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
    globals.define('__REFLECT_GET_METADATA', new ExternCallable(function (args) {
      var target = args[0];
      var arr:Class = globals.values.get('Array');
      var obj:Class = globals.values.get('Object');
      var name:String = null;
      var out = [];

      if (Std.is(target, quirk.interpreter.Class)) {
        var cls:quirk.interpreter.Class = cast target;
        for (key in cls.meta.keys()) {
          var inst = new Instance(obj);
          inst.fields.set('name', key);
          inst.fields.set('values', arr.call(interpreter, [ cls.meta.get(key) ]));
          out.push(inst);
        }
      } else if (Std.is(target, quirk.interpreter.Function)) {
        var f:quirk.interpreter.Function = cast target;
        for (key in f.meta.keys()) {
          var inst = new Instance(obj);
          inst.fields.set('name', key);
          inst.fields.set('values', arr.call(interpreter, [ f.meta.get(key) ]));
          out.push(inst);
        }
      }
      return arr.call(interpreter, [ out ]);
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
      return Std.int(values.length);
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
    globals.define('__ARRAY_JOIN', new ExternCallable(function (args) {
      var values:Array<Dynamic> = args[0];
      var glue:String = Std.string(args[1]);
      return values.join(glue);
    }, 2));

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

    // Handle primitives.
    var source = haxe.Resource.getString('primitives');
    var scanner = new Scanner(source, '<primitives>', reporter);
    var tokens = scanner.scanTokens();
    var parser = new Parser(tokens, reporter);
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

  public function isDynamic() return false;

  public function arity():Int {
    return this.arity_;
  }

}
