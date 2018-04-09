package quirk.interpreter;

import quirk.Token;

class Module {

  @:isVar public var exports(default, null):Array<String>;
  private var name:String;
  private var env:Environment;

  public function new(name:String, env:Environment, exports:Array<String>) {
    this.name = name;
    this.env = env;
    this.exports = exports;
  }

  public function get(name:Token):Dynamic {
    if (exports.indexOf(name.lexeme) < 0) {
      throw new RuntimeError(name, 'The module ${this.name} does not export: ${name.lexeme}');
    }
    return env.get(name);
  }

  public function toString() {
    return this.name;
  }

}
