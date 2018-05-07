package quirk.core;

import quirk.Token;

class Environment<T> {

  @:isVar public var values(default, null):Map<String, T> = new Map();
  @:isVar public var enclosing(default, null):Environment<T>;

  public function new(?enclosing:Environment<T>) {
    this.enclosing = enclosing;
  }

  public function define(name:String, value:T):Void {
    values.set(name, value);
  }

  public function assign(name:Token, value:T):Void {
    if (values.exists(name.lexeme)) {
      values.set(name.lexeme, value);
      return;
    }
    if (enclosing != null) {
      enclosing.assign(name, value);
      return;
    }
    throwError(name, 'Undefined variable: ${name.lexeme}.');
    return null;
  }

  public function assignAt(distance:Int, name:Token, value:T) {
    ancestor(distance).values.set(name.lexeme, value);
  }

  public function get(name:Token):T {
    if (values.exists(name.lexeme)) {
      return values.get(name.lexeme);
    }
    if (enclosing != null) {
      return enclosing.get(name);
    }
    throwError(name, 'Undefined variable: ${name.lexeme}.');
    return null;
  }

  public function getAt(distance:Int, name:String) {
    return ancestor(distance).values.get(name);
  }

  public function ancestor(distance:Int):Environment<T> {
    var env = this;
    for (i in 0...distance) {
      env = env.enclosing;
    }
    return env;
  }

  private function throwError(token:Token, message:String) {
    throw new RuntimeError(token, message);
  }

}