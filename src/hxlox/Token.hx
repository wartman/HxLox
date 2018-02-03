package hxlox;

class Token {

  public var type:TokenType;
  public var lexeme:String;
  public var literal:Dynamic;
  public var line:Int;

  public function new(type:TokenType, lexeme:String, literal:Dynamic, line:Int) {
    this.type = type;
    this.lexeme = lexeme;
    this.literal = literal;
    this.line = line;
  }

  public function toString():String {
    return '${Std.string(type)} ${this.lexeme} ${Std.string(this.literal)}';
  }

}
