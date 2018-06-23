package quirk.interpreter.foreign;

import quirk.interpreter.Interpreter;
import quirk.interpreter.Class;

using StringTools;
using quirk.interpreter.Helper;

class Mirror {

  public static function register(interpreter:Interpreter) {
    reflect(interpreter);
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
      if (Std.is(target, Int)) {
        var cls:Class = globals.values.get('Int');
        return cls;
      }
      if (Std.is(target, Bool)) {
        var cls:Class = globals.values.get('Bool');
        return cls;
      }
      if (Std.is(target, String)) {
        var cls:Class = globals.values.get('String');
        return cls;
      }
      if (target == null) {
        var cls:Class = globals.values.get('Null');
        return cls;
      }
      return null;
    }
    interpreter
      .addForeign('Std.Mirror.Reflect.getClass(_)', function (args, f) {
        return getClass(args[0]);
      })
      .addForeign('Std.Mirror.Reflect.getClassName(_)', function (args, f) {
        var cls = getClass(args[0]);
        if (cls != null) {
          return cls.name;
        }
        return '<object>';
      })
      .addForeign('Std.Mirror.Reflect.getSuperclass(_)', function (args, f) {
        var cls = getClass(args[0]);
        if (cls != null) {
          return cls.superclass;
        }
        return null;
      })
      .addForeign('Std.Mirror.Reflect.getField(_,_)', function (args, f) {
        var obj:Instance = args[0];
        var name:String = Std.string(args[1]);
        return obj.fields.get(name);
      })
      .addForeign('Std.Mirror.Reflect.setField(_,_,_)', function (args, f) {
        var target:Instance = cast args[0];
        var key:String = Std.string(args[1]);
        var value:Dynamic = args[2];
        target.fields.set(key, value);
        return null;
      })
      .addForeign('Std.Mirror.Reflect.getFieldNames(_)', function (args, f) {
        var target:Instance = cast args[0];
        var arrCls:Class = globals.values.get('Array');
        var names:Array<String> = [];
        for (name in target.fields.keys()) {
          names.push(name);
        }
        var arr:Instance = arrCls.construct('new', interpreter, [ names ]);
        return arr;
      })
      .addForeign('Std.Mirror.Reflect.getMethod(_,_)', function (args, f) {
        var inst:Instance = cast args[0];
        return inst.getClass().findMethod(inst, Std.string(args[1]));
      })
      .addForeign('Std.Mirror.Reflect.getMethodNames(_)', function (args, f) {
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
      .addForeign('Std.Mirror.Reflect.getConstructor(_,_)', function (args, f) {
        var target:Class;
        var inst = args[0];
        if (Std.is(inst, Instance)) {
          target = inst.getClass();
        } else {
          target = cast inst;
        }
        // todo: ensure actually is constructor :P
        return target.findMethod(target, args[1]);
      })
      .addForeign('Std.Mirror.Reflect.getConstructorNames(_)', function (args, f) {
        var target:Class;
        var inst = args[0];
        var arrCls:Class = globals.values.get('Array');
        var names = [];
        if (Std.is(inst, Instance)) {
          target = inst.getClass();
        } else {
          target = cast inst;
        }
        for (name in target.staticMethods.keys()) {
          var method = target.staticMethods.get(name);
          if (method.declaration.kind.equals(quirk.Stmt.FunKind.FunConstructor)) {
            names.push(name);
          }
        }
        return arrCls.construct('new', interpreter, [ names ]);
      })
      .addForeign('Std.Mirror.Reflect.__getMetadata(_)', function (args, f) {
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