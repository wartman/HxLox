package quirk;

enum TokenType {

  // Single-character tokens
  TokAt;
  TokLeftParen;
  TokRightParen;
  TokLeftBrace;
  TokRightBrace;
  TokLeftBracket;
  TokRightBracket;
  TokPipe;
  TokComma;
  TokDot;
  TokMinus;
  TokPlus;
  TokColon;
  TokSemicolon;
  TokNewline;
  TokSlash;
  TokStar;
  TokBoolAnd;
  TokAnd;
  TokBoolOr;

  // Keywords
  TokClass;
  TokStatic;
  TokFalse;
  TokElse;
  TokFun;
  TokFor;
  TokIf;
  TokNull;
  TokReturn;
  TokSuper;
  TokThis;
  TokTrue;
  TokVar;
  TokWhile;
  TokImport;
  TokModule;
  TokAs;
  TokIn;
  TokThrow;
  TokTry;
  TokCatch;

  // One or two character tokens
  TokBang;
  TokBangEqual;
  TokEqual;
  TokEqualEqual;
  TokGreater;
  TokGreaterEqual;
  TokLess;
  TokLessEqual;
  TokRange; // ..

  // Other
  TokIdentifier;
  TokString;
  TokNumber;

  // Interpolated strings, like `"foo ${bar}"`, are parsed
  // as if they were written `"foo" + bar`. For example, the
  // token stream for `"foo ${bar} bin"` would look like:
  // 
  //  TokInterpolation // -> "foo"
  //  TokIdentifier // -> bar
  //  TokString // -> "bin"
  //
  TokInterpolation;

  TokEof;
}
