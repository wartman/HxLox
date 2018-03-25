package hxlox.interpreter;

import hxlox.Token;

class ObjectLiteralType extends CoreType {

  private var keys:Array<String> = [];
  private var values:Array<Dynamic> = [];

  public function new(keys:Array<String>, values:Array<Dynamic>) {
    this.keys = keys;
    this.values = values;

    addMethod('keys', function (args:Array<Dynamic>) {
      return new ArrayLiteralType(this.keys);
    }, 0);
    addMethod('values', function (args:Array<Dynamic>) {
      return  new ArrayLiteralType(this.values);
    }, 0);
  }

  override public function get(name:Token):Dynamic {
    var index = keys.indexOf(name.lexeme);
    if (index >= 0) {
      return values[index];
    }
    return super.get(name);
  }

  override public function set(name:Token, value:Dynamic):Void {
    var index = keys.indexOf(name.lexeme);
    if (index >= 0) {
      values[index] = value;
    } else {
      keys.push(name.lexeme);
      values.push(value);
    }
  }
  
  override public function toString():String {
    return 'ObjectLiteral';
  }

}