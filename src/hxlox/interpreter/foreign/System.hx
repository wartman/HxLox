package hxlox.interpreter.foreign;

import hxlox.Token;
import hxlox.interpreter.CoreType;
import hxlox.interpreter.Callable;
import hxlox.interpreter.RuntimeError;

class System extends CoreType {

  public function new() {
    addMethod('print', function (arguments:Array<Dynamic>) {
      for (arg in arguments) {
        Sys.println(Std.string(arg));
      }
      return null;
    }, 1);
    addMethod('getCwd', function (arguments:Array<Dynamic>) {
      return Sys.getCwd();
    }, 0);
    addMethod('getTime', function (arguments:Array<Dynamic>) {
      return Sys.cpuTime() / 1000.0;
    }, 0);
  }

}
