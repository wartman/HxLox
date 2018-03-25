package hxlox.interpreter;

import hxlox.Token;

// Not quite there, but you get the idea.
class Module extends CoreType {

  private var name:String;
  // private var children:Map<String, Module> = new Map();
  private var env:Environment;
  private var exports:Array<String>;

  public function new(name:String, env:Environment, exports:Array<String>) {
    this.name = name;
    this.env = env;
    this.exports = exports;
  }

  // public function addChild(name:String, module:Module) {
  //   children.set(name, module);
  // }

  override public function get(name:Token):Dynamic {
    // if (children.exists(name.lexeme)) {
    //   return children.get(name.lexeme);
    // }
    if (exports.indexOf(name.lexeme) < 0) {
      throw new RuntimeError(name, 'The module ${this.name} does not export: ${name.lexeme}');
    }
    return env.get(name);
  }

  override public function toString() {
    return this.name;
  }

}