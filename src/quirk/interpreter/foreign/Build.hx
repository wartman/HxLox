package quirk.interpreter.foreign;

import haxe.io.Path;
import quirk.interpreter.Instance;
import quirk.interpreter.Interpreter;
import quirk.generator.JsTarget;
import quirk.generator.JsNodeTarget;

class Build {

  public static function register(interpreter:Interpreter) {
    project(interpreter);
  }

  private static function project(interpreter:Interpreter) {
    interpreter
      .addForeign('Std.Build.Project.buildJs(_)', function (args, f) {
        var settings:Instance = cast(args[0]);
        if (settings.fields.exists('type') && settings.fields.get('type') == 'bundle') {
          var target = new JsTarget(
            Path.join([Sys.getCwd(), Std.string(settings.fields.get('src'))]),
            Path.join([Sys.getCwd(), Std.string(settings.fields.get('dst'))]),
            settings.fields.get('main'),
            interpreter.reporter
          );
          target.write();
        } else {
          var target = new JsNodeTarget(
            Path.join([Sys.getCwd(), Std.string(settings.fields.get('src'))]),
            Path.join([Sys.getCwd(), Std.string(settings.fields.get('dst'))]),
            settings.fields.get('main'),
            interpreter.reporter
          );
          target.write();
        }
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
