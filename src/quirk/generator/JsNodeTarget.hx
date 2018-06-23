package quirk.generator;

using Lambda;

class JsNodeTarget extends JsTarget {

  override private function writeModules() {
    for (name in modules.keys()) {
      var entry = modules.get(name);
      var deps = entry.deps;
      var body = entry.generated;
      // Add prelude deps to file
      if (name != '_prelude' && name != '_primitives') {
        var primitives = loader.findRelative(stringToTokens('_primitives'), stringToTokens(name));
        var prelude = loader.findRelative(stringToTokens('_prelude'), stringToTokens(name));
        body = [
          'require("$prelude");', 
          'var __quirk = global.__quirk;',
          'require("$primitives");',
          'var Int = global.Int;',
          'var Bool = global.Bool;'
        ].join('\n') + '\n' + body;
      }
      writer.writeToFile(name, body, 'js');
    }
  }

  override public function resolveModule(path:Array<Token>, ?currentModule:Array<Token>):String {
    return currentModule != null ? loader.findRelative(path, currentModule) : loader.find(path);
  }

  private function stringToTokens(lexeme:String):Array<quirk.Token> {
    return lexeme.split('/').map(function (l) return new quirk.Token(quirk.TokenType.TokIdentifier, l, l, { line:0, offset:0, file:l }));
  }

}
