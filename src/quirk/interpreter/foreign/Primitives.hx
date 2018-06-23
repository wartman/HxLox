package quirk.interpreter.foreign;

import quirk.interpreter.Callable;
import quirk.interpreter.Class;
import quirk.interpreter.Instance;
import quirk.interpreter.Interpreter;
import quirk.interpreter.Resolver;
import quirk.interpreter.Function;

using StringTools;
using quirk.interpreter.Helper;

class Primitives {

  public static function register(interpreter:Interpreter) {
    arrayLiteral(interpreter);
    objectLiteral(interpreter);
    stringLiteral(interpreter);
    funLiteral(interpreter);
    addPrimitives(interpreter);
  }

  private static function funLiteral(interpreter:Interpreter) {
    interpreter
      .addForeign('Fun#call(_,_)', function (args, f) {
        var self:Instance = f.closure.values.get('this');
        var cb:Function = self.fields.get('wrapped');
        return cb.bind(args[0]).call(interpreter, args[1]);
      });
  }

  private static function arrayLiteral(interpreter:Interpreter) {
    interpreter
      .addForeign('Array#__offsetGet(_)', function (args, f) {
        var values:Array<Dynamic> = getValues(f);
        var index:Int = Std.int(args[0]);
        return values[index];
      })
      .addForeign('Array#__offsetSet(_,_)', function (args, f) {
        var values:Array<Dynamic> = getValues(f);
        var index:Int = Std.int(args[0]);
        values[index] = args[1];
        return null;
      })
      .addForeign('Array#push(_)', function (args, f) {
        var values = getValues(f);
        values.push(args[0]);
        return values.length;
      })
      .addForeign('Array#pop()', function (args, f) {
        return getValues(f).pop();
      })
      .addForeign('Array#join(_)', function (args, f) {
        return getValues(f).join(Std.string(args[0]));
      })
      .addForeign('Array#concat(_)', function (args, f) {
        var arr:Instance = args[0];
        var arrClass:Class = interpreter.globals.values.get('Array');
        var concated = getValues(f).concat(arr.fields.get('values'));
        return arrClass.construct('new', interpreter, [ concated ]);
      })
      .addForeign('Array#__length()', function (args, f) {
        return getValues(f).length;
      });
  }

  private static function stringLiteral(interpreter:Interpreter) {
    var globals = interpreter.globals;
    interpreter
      .addForeign('String#split(_)', function (args, f) {
        var value:String = Std.string(getThis(f).fields.get('value'));
        var array:Class = globals.values.get('Array');
        return array.construct('new', interpreter, [ value.split(Std.string(args[0])) ]);
      })
      .addForeign('String#substring(_,_)', function (args, f) {
        var value:String = Std.string(getThis(f).fields.get('value'));
        return value.substring(
          Std.int(args[0]),
          Std.int(args[1])
        );
      })
      .addForeign('String#indexOf(_)', function (args, f) {
        var value:String = Std.string(getThis(f).fields.get('value'));
        return value.indexOf(Std.string(args[0]));
      });
  }

  private static function objectLiteral(interpreter:Interpreter) {
    interpreter
      .addForeign('Object#__offsetGet(_)', function (args, f) {
        return getThis(f).fields.get(Std.string(args[0]));
      })
      .addForeign('Object#__offsetSet(_,_)', function (args, f) {
        getThis(f).fields.set(Std.string(args[0]), args[1]);
        return null;
      });
  }

  private static function getThis(f:Function):Instance {
    return cast f.closure.values.get('this');
  }

  private static function getValues(f:Function):Array<Dynamic> {
    return cast getThis(f).fields.get('values');
  }

  // Parse the primitives .qrk file.
  private static function addPrimitives(interpreter:Interpreter) {
    var source = haxe.Resource.getString('primitives');
    var scanner = new Scanner(source, '<primitives>', interpreter.reporter);
    var tokens = scanner.scanTokens();
    var parser = new Parser(tokens, interpreter.reporter);
    var stmts = parser.parse();
    var resolver = new Resolver(interpreter);
    resolver.resolve(stmts);
    interpreter.interpret(stmts);
  }

}