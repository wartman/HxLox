package quirk.interpreter.foreign;

import quirk.interpreter.Instance;
import quirk.interpreter.Interpreter;
import quirk.interpreter.Class;

using StringTools;
using quirk.interpreter.Helper;

class RegExp {

  public static function register(interpreter:Interpreter) {
    regExp(interpreter);
  }

  private static function regExp(interpreter:Interpreter) {
    interpreter
      .addForeign('Std.RegExp.RegExp#replace(_,_)', function (args, f) {
        var self:Instance = f.closure.values.get('this');
        var re:EReg = null;
        if (self.fields.exists('__proxy')) {
          re = self.fields.get('__proxy');
        } else {
          var pattern:String = self.fields.get('pattern');
          var flags:String = self.fields.get('flags');
          re = new EReg(pattern, flags);
          self.fields.set('__proxy', re);
        }
        return re.replace(Std.string(args[0]), Std.string(args[1]));
      });
  }

}
