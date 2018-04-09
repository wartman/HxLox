package quirk.interpreter;

import quirk.Token;

class Instance implements Object {

  @:isVar public var fields(default, never):Map<String, Dynamic> = new Map();
  private var cls:Class;

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

  public function getClass() {
    return cls;
  }

  public function toString() {
    return '${this.cls.name} instance';
  }

}