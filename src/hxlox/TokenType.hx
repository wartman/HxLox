package hxlox;

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

  TokIdentifier;
  TokString;
  TokNumber;

  TokEof;
}
