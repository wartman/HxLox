package hxlox.interpreter;

class StringLiteral extends CoreType {

  var value:String;

  public function new(value:String) {
    this.value = value;
    addField('length', function () return this.value.length);
    addMethod('substring', function (args:Array<Dynamic>) {
      return new StringLiteral(this.value.substring(args[0], args[1]));
    }, 2);
  }

  override public function toString() {
    return this.value;
  }

}