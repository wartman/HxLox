package quirk.generator;

using Lambda;

class JsNodeTarget extends JsTarget {

  override private function writeModules() {
    for (name in modules.keys()) {
      var entry = modules.get(name);
      var deps = entry.deps;
      var body = entry.generated;
      // Add prelude deps to file
      if (name != '_prelude') {
        body = 'require("_prelude");\nvar __quirk = global.__quirk;\n' + body;
      }
      writer.writeToFile(name, body, 'js');
    }
  }

}
