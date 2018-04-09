package quirk;

class Token {

  public var type:TokenType;
  public var lexeme:String;
  public var literal:Dynamic;
  public var pos:Position;

  public function new(type:TokenType, lexeme:String, literal:Dynamic, pos:Position) {
    this.type = type;
    this.lexeme = lexeme;
    this.literal = literal;
    this.pos = pos;
  }

  public function toString():String {
    return '${Std.string(type)} ${this.lexeme} ${Std.string(this.literal)}';
  }

}
