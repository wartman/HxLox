package quirk.interpreter.foreign;

import quirk.interpreter.Interpreter;

using StringTools;
using quirk.interpreter.Helper;

class Core {

  public static function register(interpreter:Interpreter) {
    system(interpreter);
    reflect(interpreter);
  }

  private static function system(interpreter:Interpreter) {
    interpreter
      .addForeign('Std.Core.System.print(_)', function (args, f) {
        var value = Std.string(args[0]);
        value = value.replace("\\n", '\n'); // handle this issue better :P
        Sys.print(value);
        return null;
      })
      .addForeign('Std.Core.System.getCwd()', function (args, f) {
        return Sys.getCwd();
      });
  }

  private static function reflect(interpreter:Interpreter) {
    var globals = interpreter.globals;
    function getClass(target) {
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
    }
    interpreter
      .addForeign('Std.Core.Reflect.getClass(_)', function (args, f) {
        return getClass(args[0]);
      })
      .addForeign('Std.Core.Reflect.getClassName(_)', function (args, f) {
        var cls = getClass(args[0]);
        if (cls != null) {
          return cls.name;
        }
        return '<object>';
      })
      .addForeign('Std.Core.Reflect.getSuperclass(_)', function (args, f) {
        var cls = getClass(args[0]);
        if (cls != null) {
          return cls.superclass;
        }
        return null;
      })
      .addForeign('Std.Core.Reflect.getField(_,_)', function (args, f) {
        var obj:Instance = args[0];
        var name:String = Std.string(args[1]);
        return obj.fields.get(name);
      })
      .addForeign('Std.Core.Reflect.setField(_,_,_)', function (args, f) {
        var target:Instance = cast args[0];
        var key:String = Std.string(args[1]);
        var value:Dynamic = args[2];
        target.fields.set(key, value);
        return null;
      })
      .addForeign('Std.Core.Reflect.getFieldNames(_)', function (args, f) {
        var target:Instance = cast args[0];
        var arrCls:Class = globals.values.get('Array');
        var names:Array<String> = [];
        for (name in target.fields.keys()) {
          names.push(name);
        }
        var arr:Instance = arrCls.construct('new', interpreter, [ names ]);
        return arr;
      })
      .addForeign('Std.Core.Reflect.getMethod(_,_)', function (args, f) {
        var inst:Instance = cast args[0];
        return inst.getClass().findMethod(inst, Std.string(args[1]));
      })
      .addForeign('Std.Core.Reflect.getMethodNames(_)', function (args, f) {
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
        var arr:Instance = arrCls.construct('new', interpreter, [ names ]);
        return arr;
      })
      .addForeign('Std.Core.Reflect.__getMetadata(_)', function (args, f) {
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
            inst.fields.set('values', arr.construct('new', interpreter, [ cls.meta.get(key) ]));
            out.push(inst);
          }
        } else if (Std.is(target, quirk.interpreter.Function)) {
          var f:quirk.interpreter.Function = cast target;
          for (key in f.meta.keys()) {
            var inst = new Instance(obj);
            inst.fields.set('name', key);
            inst.fields.set('values', arr.construct('new', interpreter, [ f.meta.get(key) ]));
            out.push(inst);
          }
        }
        return arr.construct('new', interpreter, [ out ]);
      });
  }

}