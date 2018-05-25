package quirk.interpreter.foreign;

import haxe.io.Path;
import quirk.VisualErrorReporter;
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
        var corePaths = Quirk.corePaths;
        var libs:Map<String, String> = settings.fields.get('libs').fields;
        for (key in corePaths.keys()) {
          if (!libs.exists(key)) {
            libs.set(key, corePaths.get(key));
          }
        }
        var loader = new JsModuleLoader(
          Path.join([Sys.getCwd(),Std.string(settings.fields.get('src'))]),
          libs
        );
        var reporter = new VisualErrorReporter(loader);
        new JsTarget(
          Std.string(settings.fields.get('main')),
          loader,
          new ModuleWriter(Path.join([Sys.getCwd(), Std.string(settings.fields.get('dst'))])),
          reporter
        ).write();
        return null;
      })
      .addForeign('Std.Build.Project.buildNode(_)', function (args, f) {
        throw 'not ready yet';

        // var settings:Instance = cast(args[0]);
        // new JsNodeTarget(
        //   Std.string(settings.fields.get('main')),
        //   new JsModuleLoader(
        //     Path.join([Sys.getCwd(), Std.string(settings.fields.get('src'))]),
        //     settings.fields.get('libs').fields
        //   ),
        //   new ModuleWriter(Path.join([Sys.getCwd(), Std.string(settings.fields.get('dst'))])),
        //   interpreter.reporter
        // ).write();
        return null;
      })
      .addForeign('Std.Build.Project.buildPhp(_)', function (args, f) {
        return null;
      })
      .addForeign('Std.Build.Project.interpret(_)', function (args, f) {
        var settings:Instance = cast(args[0]);
        var root = Path.join([ Sys.getCwd(), settings.fields.get('src') ]);
        var path = settings.fields.get('main');
        Quirk.run(root, path);
        return null;
      });
  }

}
