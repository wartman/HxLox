package quirk;

import quirk.TokenType;

class Scanner {

  private static var keywords:Map<String, TokenType> = [
    "class" => TokClass,
    "else" => TokElse,
    "false" => TokFalse,
    "fun" => TokFun,
    "for" => TokFor,
    "if" => TokIf,
    "null" => TokNull,
    "return" => TokReturn,
    "super" => TokSuper,
    "this" => TokThis,
    "true" => TokTrue,
    "var" => TokVar,
    "while" => TokWhile,
    "import" => TokImport,
    "in" => TokIn,
    "as" => TokAs,
    "module" => TokModule,
    "static" => TokStatic,
    "throw" => TokThrow,
    "try" => TokTry,
    "catch" => TokCatch
  ];

  private var source:String;
  private var tokens:Array<Token> = [];
  private var start:Int = 0;
  private var current:Int = 0;
  private var line:Int = 1;
  private var reporter:ErrorReporter;
  private var file:String;

  public function new(source:String, file:String, reporter:ErrorReporter) {
    this.source = source;
    this.file = file;
    this.reporter = reporter;
  }

  public function scanTokens():Array<Token> {
    while (!isAtEnd()) {
      start = current;
      scanToken();
    }
    tokens.push(new Token(TokEof, '', null, {line: line, offset: current, file: file}));
    return tokens;
  }

  private function isAtEnd():Bool {
    return current >= source.length;
  }

  private function scanToken() {
    var c = advance();
    switch (c) {
      case '(': addToken(TokLeftParen);
      case ')': addToken(TokRightParen);
      case '{': addToken(TokLeftBrace);
      case '}': addToken(TokRightBrace);
      case '[': addToken(TokLeftBracket);
      case ']': addToken(TokRightBracket);
      case '|': addToken(match('|') ? TokBoolOr : TokPipe);
      case '&': addToken(match('&') ? TokBoolAnd : TokAnd);
      case ',': addToken(TokComma);
      case '.': addToken(TokDot);
      case '-': addToken(match('>') ? TokArrow : TokMinus);
      case '+': addToken(TokPlus);
      case ';': addToken(TokSemicolon);
      case ':': addToken(TokColon);
      case '*': addToken(TokStar);
      case '@': addToken(TokAt);
      case '?': addToken(TokQuestion);
      case '!': addToken(match('=') ? TokBangEqual : TokBang);
      case '=': addToken(match('=') ? TokEqualEqual : TokEqual);
      case '<': addToken(match('=') ? TokLessEqual : TokLess);
      case '>': addToken(match('=') ? TokGreaterEqual : TokGreater);
      case '/':
        if (match('/')) {
          while (peek() != '\n' && !isAtEnd()) advance();
          if (peek() == '\n') advance(); // Consume the newline too.
        } else {
          addToken(TokSlash);
        }
      case '"': string();
      case "'": string("'");
      case ' ' | '\r' | '\t': null; // ignore
      case '\n': newline(); // Might be a valid statement end -- checked by the parser.
      default:
        if (isDigit(c)) {
          number();
        } else if (isAlpha(c)) {
          identifier();
        } else {
          reporter.report({
            line: line,
            offset: current,
            file: file
          }, c, 'Unexpected character: $c');
          // HxLox.error({ line: line }, 'Unexpected character: $c');
        }
    }
  }

  private function identifier() {
    while (isAlphaNumeric(peek())) advance();

    var text = source.substring(start, current);
    var type = keywords.get(text);

    if (type != null) {
      addToken(type);
    } else {
      addToken(TokIdentifier);
    }
  }

  private function newline() {
    line++;
    // todo: may need to handle windows newline too :P
    while (peek() == '\n' && !isAtEnd()) {
      line++;
      advance();
    }
    // For now, until we implement things (the parser chokes otherwise)
    addToken(TokNewline);
  }

  private function string(quote:String = '"') {
    while (peek() != quote && !isAtEnd()) {
      if (peek() == '\n') {
        line++;
      }
      advance();
    }
    if (isAtEnd()) {
      reporter.report({
        line: line,
        offset: current,
        file: file
      }, '<EOF>', 'Unterminated string.');
      // HxLox.error({ line: line }, 'Unterminated string.');
      return;
    }

    // The closing "
    advance();

    var value = source.substring(start + 1, current - 1);
    addToken(TokString, value);
  }

  private function number() {
    while(isDigit(peek())) advance();
    if (peek() == '.' && isDigit(peekAt(current + 1))) {
      advance();
      while (isDigit(peek())) advance();
    }
    addToken(TokNumber, Std.parseFloat(source.substring(start, current)));
  }

  private function isDigit(c:String):Bool {
    return c >= '0' && c <= '9';
  }

  private function isAlpha(c:String):Bool {
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') ||
            c == '_';
  }

  private function isAlphaNumeric(c:String) {
    return isAlpha(c) || isDigit(c);
  }

  private function match(expected:String):Bool {
    if (isAtEnd()) {
      return false;
    }
    if (source.charAt(current) != expected) {
      return false;
    }
    current++;
    return true;
  }

  private function peek():String {
    if (isAtEnd()) {
      return '';
    }
    return source.charAt(current);
  }

  private function peekAt(i) {
    if (i >= source.length) {
      return '';
    }
    return source.charAt(i);
  }

  private function advance() {
    current++;
    return source.charAt(current - 1);
  }

  private function addToken(type:TokenType, ?literal:Dynamic) {
    var text = source.substring(start, current);
    var pos:Position = {
      line: line,
      offset: current,
      file: file
    };
    tokens.push(new Token(type, text, literal, pos));
  }

}
