package hxlox.interpreter;

import hxlox.Token;

class Environment {

  public var values:Map<String, Dynamic> = new Map();
  public var enclosing:Environment;

  public function new(?enclosing:Environment) {
    this.enclosing = enclosing;
  }

  public function define(name:String, value:Dynamic):Void {
    values.set(name, value);
  }

  public function assign(name:Token, value:Dynamic):Void {
    if (values.exists(name.lexeme)) {
      values.set(name.lexeme, value);
      return;
    }
    if (enclosing != null) {
      enclosing.assign(name, value);
      return;
    }
    throw new RuntimeError(name, 'Undefined variable: ${name.lexeme}.');
  }

  public function assignAt(distance:Int, name:Token, value:Dynamic) {
    ancestor(distance).values.set(name.lexeme, value);
  }

  public function get(name:Token):Dynamic {
    if (values.exists(name.lexeme)) {
      return values.get(name.lexeme);
    }
    if (enclosing != null) {
      return enclosing.get(name);
    }
    throw new RuntimeError(name, 'Undefined variable: ${name.lexeme}.');
  }

  public function getAt(distance:Int, name:String) {
    return ancestor(distance).values.get(name);
  }

  public function ancestor(distance:Int):Environment {
    var env = this;
    for (i in 0...distance) {
      env = env.enclosing;
    }
    return env;
  }

}