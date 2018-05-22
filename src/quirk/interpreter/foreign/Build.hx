package quirk.interpreter.foreign;

import haxe.io.Path;
import quirk.interpreter.Instance;
import quirk.interpreter.Interpreter;
import quirk.generator.ModuleWriter;
import quirk.generator.JsModuleLoader;
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
        new JsTarget(
          Std.string(settings.fields.get('main')),
          new JsModuleLoader(
            Path.join([Sys.getCwd(),Std.string(settings.fields.get('src'))]),
            settings.fields.get('libs').fields
          ),
          new ModuleWriter(Path.join([Sys.getCwd(), Std.string(settings.fields.get('dst'))])),
          interpreter.reporter
        ).write();
        return null;
      })
      .addForeign('Std.Build.Project.buildNode(_)', function (args, f) {
        var settings:Instance = cast(args[0]);
        new JsNodeTarget(
          Std.string(settings.fields.get('main')),
          new JsModuleLoader(
            Path.join([Sys.getCwd(), Std.string(settings.fields.get('src'))]),
            settings.fields.get('libs').fields
          ),
          new ModuleWriter(Path.join([Sys.getCwd(), Std.string(settings.fields.get('dst'))])),
          interpreter.reporter
        ).write();
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
