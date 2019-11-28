package hxlox;

enum TokenType {

  // Single-character tokens
  TokLeftParen;
  TokRightParen;
  TokLeftBrace;
  TokRightBrace;
  TokComma;
  TokDot;
  TokMinus;
  TokPlus;
  TokSemicolon;
  TokNewline;
  TokSlash;
  TokStar;

  // Keywords
  TokAnd;
  TokClass;
  TokElse;
  TokFalse;
  TokFun;
  TokFor;
  TokIf;
  TokNil;
  TokOr;
  TokPrint;
  TokReturn;
  TokSuper;
  TokThis;
  TokTrue;
  TokVar;
  TokWhile;

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
