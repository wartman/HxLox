package hxlox.interpreter;

import hxlox.Token;

class Instance {

  private var cls:Class;
  private var fields:Map<String, Dynamic> = new Map();

  public function new(cls:Class) {
    this.cls = cls;
  }

  public function get(name:Token) {
    if (fields.exists(name.lexeme)) {
      return fields.get(name.lexeme);
    }
    
    var method = cls.findMethod(this, name.lexeme);
    if (method != null) return method;

    throw new RuntimeError(name, "Undefined property '" + name.lexeme + "'.");
  }

  public function set(name:Token, value:Dynamic) {
    fields.set(name.lexeme, value);
  }

  public function toString() {
    return '${this.cls.name} instance';
  }

}