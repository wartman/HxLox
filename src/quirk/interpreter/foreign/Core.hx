package quirk.interpreter.foreign;

import quirk.interpreter.Interpreter;
import quirk.interpreter.Class;

using StringTools;
using quirk.interpreter.Helper;

class Core {

  public static function register(interpreter:Interpreter) {
    system(interpreter);
  }

  private static function system(interpreter:Interpreter) {
    interpreter
      .addForeign('Std.Core.System.args()', function (args, f) {
        var arrClass:Class = interpreter.globals.values.get('Array');
        return arrClass.construct('new', interpreter, [ Sys.args() ]);
      })
      .addForeign('Std.Core.System.command(_,_)', function (args, f) {
        return Sys.command(Std.string(args[0]), args[1]);
      })
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

}