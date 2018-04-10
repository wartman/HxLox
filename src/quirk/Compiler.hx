package quirk;

import quirk.Type;

class Compiler {

  public var loader(default, null):ModuleLoader;
  public var types(default, null):Map<String, ClassType> = new Map();
  private var reporter:ErrorReporter;
  private var parsed:Map<String, Array<Stmt>> = new Map();

  public function new(loader:ModuleLoader, reporter:ErrorReporter) {
    this.loader = loader;
    this.reporter = reporter;
  }

  public function addType(name:String, type:ClassType) {
    types.set(name, type);
  }

  public function getType(path:Array<Token>):ClassType {
    var name = path.map(function (t) return t.lexeme).join('.');
    if (types.exists(name)) {
      return types.get(name);
    }
    path.pop(); // Remove the last token to get the module path.
    parse(path);

    if (!types.exists(name)) {
      throw 'No type found for ${name}';
    }

    return types.get(name);
  }

  public function parse(path:Array<Token>):Array<Stmt> {
    var moduleName = path.map(function (t) return t.lexeme).join('.');

    if (parsed.exists(moduleName)) {
      return parsed.get(moduleName);
    }

    var file = loader.find(path);
    var stmts = parseFile(file);
    parsed.set(moduleName, stmts);

    return stmts;
  }

  public function parseFile(file:String):Array<Stmt> {
    var source = loader.load(file);
    var scanner = new Scanner(source, file, reporter);
    var tokens = scanner.scanTokens();
    var parser = new Parser(tokens, reporter, this);
    var stmts = parser.parse();

    return stmts;
  }

}
