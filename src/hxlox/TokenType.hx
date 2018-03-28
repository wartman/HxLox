package hxlox;

enum TokenType {

  // Single-character tokens
  TokLeftParen;
  TokRightParen;
  TokLeftBrace;
  TokRightBrace;
  TokLeftBracket;
  TokRightBracket;
  TokComma;
  TokDot;
  TokMinus;
  TokPlus;
  TokColon;
  TokSemicolon;
  TokNewline;
  TokSlash;
  TokStar;

  // Keywords
  TokAnd;
  TokClass;
  TokStatic;
  TokFalse;
  TokElse;
  TokFun;
  TokFor;
  TokIf;
  TokNull;
  TokOr;
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
