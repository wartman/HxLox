package quirk.interpreter.foreign;

import quirk.interpreter.Instance;
import quirk.interpreter.Interpreter;

class Build {

  public static function register(interpreter:Interpreter) {

  }

  private static function project(interpreter:Interpreter) {
    interpreter
      .addForeign('Std.Build.Project.buildJs(_)', function (args, f) {
        var settings:Instance = cast(args[0]);

        // todo

        return null;
      })
      .addForeign('Std.Build.Project.buildPhp(_)', function (args, f) {
        return null;
      })
      .addForeign('Std.Build.Project.interpret(_)', function (args, f) {
        return null;
      });
  }

}
