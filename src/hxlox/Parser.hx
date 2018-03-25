package hxlox;

import hxlox.Expr;
import hxlox.Stmt;
import hxlox.TokenType;

class Parser {

  private var tokens:Array<Token>;
  private var current:Int = 0;

  public function new(tokens:Array<Token>) {
    this.tokens = tokens;
  }

  public function parse():Array<Stmt> {
    var stmts:Array<Stmt> = [];
    while (!isAtEnd()) {
      stmts.push(declaration());
    }
    return stmts;
  }

  private function declaration():Stmt {
    try {
      if (match([ TokVar ])) return varDeclaration();
      if (match([ TokFun ])) return functionDeclaration('function');
      if (match([ TokClass ])) return classDeclaration();
      if (match([ TokImport ])) return importDeclaration();
      if (match([ TokModule ])) return moduleDeclaration();
      return statement();
    } catch (error:ParserError) {
      synchronize();
      return null;
    }
  }

  private function varDeclaration():Stmt {
    var name:Token = consume(TokIdentifier, "Expect variable name.");
    var initializer:Expr = null;
    if (match([ TokEqual ])) {
      initializer = expression();
    }
    consume(TokSemicolon, "Expect ';' after value.");
    return new Stmt.Var(name, initializer);
  }

  private function functionDeclaration(kind:String):Stmt {
    var name:Token = consume(TokIdentifier, 'Expect ${kind} name.');
    consume(TokLeftParen, 'Expect \'(\' after ${kind} name.');
    var params:Array<Token> = [];
    if (!check(TokRightParen)) {
      do {
        if (params.length >= 8) {
          error(peek(), "Cannot have more than 8 parameters.");
        }

        params.push(consume(TokIdentifier, 'Expect parameter name'));
      } while(match([ TokComma ]));
    }
    consume(TokRightParen, 'Expect \')\' after parameters');
    consume(TokLeftBrace, 'Expect \'{\' before ${kind} body');
    var body:Array<Stmt> = block();

    return new Stmt.Fun(name, params, body);
  }

  private function classDeclaration():Stmt {
    var name = consume(TokIdentifier, "Expect a class name.");
    var superclass:Expr = null;

    if (match([ TokLess ])) {
      consume(TokIdentifier, "Expect superclass name.");
      superclass = new Expr.Variable(previous());
    }

    consume(TokLeftBrace, "Expect '{' before class body.");

    var methods:Array<Stmt.Fun> = [];
    var staticMethods:Array<Stmt.Fun> = [];
    while(!check(TokRightBrace) && !isAtEnd()) {
      if (match([ TokStatic ])) {
        staticMethods.push(cast functionDeclaration('method'));
      } else {
        methods.push(cast functionDeclaration('method'));
      }
    }
    consume(TokRightBrace, "Expect '}' after class body.");

    return new Stmt.Class(name, superclass, methods, staticMethods);
  }

  private function importDeclaration():Stmt {
    var path = parseList(TokDot, TokFor, function ():Token {
      return consume(TokIdentifier, "Expect dot-seperated identifiers for 'import'");
    });
    consume(TokFor, "Expect a 'for' after an import path");
    var items:Array<Token> = parseList(TokComma, TokSemicolon, function () {
      return consume(TokIdentifier, "Expect an identifier");
    });
    consume(TokSemicolon, "Expect a semicolon after import list");
    return cast new Stmt.Import(path, items);
  }

  private function moduleDeclaration():Stmt {
    // todo: allow `import foo.bar as foo;` syntax too.

    var path = parseList(TokDot, TokFor, function ():Token {
      return consume(TokIdentifier, "Expect dot-seperated identifiers for 'module'");
    });
    consume(TokFor, "Expect a 'for' after a module path");
    var items:Array<Token> = parseList(TokComma, TokSemicolon, function () {
      return consume(TokIdentifier, "Expect an identifier");
    });

    // if (check(TokLeftBrace)) {
    //   // inline module stuff here
    // } else {
      consume(TokSemicolon, "Expect a semicolon after import list");
    // }

    return cast new Stmt.Module(path, items);
  }

  private function statement():Stmt {
    if (match([ TokIf ])) return ifStatement();
    if (match([ TokWhile ])) return whileStatement();
    if (match([ TokFor ])) return forStatement();
    if (match([ TokReturn ])) return returnStatement();
    if (match([ TokLeftBrace ])) return new Stmt.Block(block());
    return expressionStatement();
  }

  private function ifStatement():Stmt {
    consume(TokLeftParen, "Expect '(' after 'if'.");
    var condition:Expr = expression();
    consume(TokRightParen, "Expect ')' after if condition.");

    var thenBranch = statement();
    var elseBranch:Stmt = null;
    if (match([ TokElse ])) {
      elseBranch = statement();
    }

    return new Stmt.If(condition, thenBranch, elseBranch);
  }

  private function whileStatement():Stmt {
    consume(TokLeftParen, "Expect '(' after 'while'.");
    var condition = expression();
    consume(TokRightParen, "Expect ')' after 'while' condition.");
    var body = statement();

    return new Stmt.While(condition, body);
  }

  private function forStatement():Stmt {
    consume(TokLeftParen, "Expect '(' after 'for'.");

    var initializer:Stmt;
    if (match([ TokSemicolon ])) {
      initializer = null;
    } else if (match([ TokVar ])) {
      initializer = varDeclaration();
    } else {
      initializer = expressionStatement();
    }

    var condition:Expr = null;
    if (!check(TokSemicolon)) {
      condition = expression();
    }
    consume(TokSemicolon, "Expect ';' after loop condition.");

    var increment:Expr = null;
    if (!check(TokRightParen)) {
      increment = expression();
    }
    consume(TokRightParen, "Expect ')' after loop condition.");

    var body = statement();

    if (increment != null) {
      body = new Stmt.Block([
        body,
        new Stmt.Expression(increment)
      ]);
    }

    if (condition == null) {
      condition = new Expr.Literal(true);
    }
    body = new Stmt.While(condition, body);

    if (initializer != null) {
      body = new Stmt.Block([
        initializer,
        body
      ]);
    }

    return body;
  }

  private function returnStatement():Stmt {
    var keyword = previous();
    var value:Expr = null;
    if (!check(TokSemicolon)) {
      value = expression();
    }
    consume(TokSemicolon, "Expect ';' after return value.");
    return new Stmt.Return(keyword, value);
  }

  private function expressionStatement():Stmt {
    var expr = expression();
    consume(TokSemicolon, "Expect ';' after expression.");
    return new Stmt.Expression(expr);
  }

  private function block() {
    var statements:Array<Stmt> = [];
    while (!check(TokRightBrace) && !isAtEnd()) {
      statements.push(declaration());
    }
    consume(TokRightBrace, "Expect '}' after block.");
    return statements;
  }

  private function expression() {
    return assignment();
  }

  private function assignment() {
    var expr:Expr = or();

    if (match([ TokEqual ])) {
      var equals = previous();
      var value = assignment();

      if (Std.is(expr, Expr.Variable)) {
        var name = (cast expr).name;
        return new Expr.Assign(name, value);
      } else if (Std.is(expr, Expr.Get)) {
        var get:Expr.Get = cast expr;
        return new Expr.Set(get.object, get.name, value);
      }

      error(equals, "Invalid assignment target.");
    }

    return expr;
  }

  private function or() {
    var expr:Expr = and();

    while (match([ TokOr ])) {
      var operator = previous();
      var right = and();
      expr = new Expr.Logical(expr, operator, right);
    }

    return expr;
  }

  private function and() {
    var expr:Expr = equality();

    while (match([ TokAnd ])) {
      var operator = previous();
      var right = equality();
      expr = new Expr.Logical(expr, operator, right);
    }

    return expr;
  }

  private function equality() {
    var expr:Expr = comparison();

    while(match([TokBangEqual, TokEqualEqual])) {
      var op = previous();
      var right = comparison();
      expr = new Expr.Binary(expr, op, right);
    }

    return expr;
  }

  private function comparison() {
    var expr = addition();

    while (match([ TokGreater, TokGreaterEqual, TokLess, TokLessEqual ])) {
      var op = previous();
      var right = addition();
      expr = new Expr.Binary(expr, op, right);
    }

    return expr;
  }

  private function addition() {
    var expr = multiplication();

    while (match([ TokMinus, TokPlus ])) {
      var op = previous();
      var right = multiplication();
      expr = new Expr.Binary(expr, op, right);
    }

    return expr;
  }

  private function multiplication() {
    var expr = unary();

    while (match([ TokSlash, TokStar ])) {
      var op = previous();
      var right = unary();
      expr = new Expr.Binary(expr, op, right);
    }

    return expr;
  }

  private function unary() {
    if (match([ TokBang, TokMinus ])) {
      var op = previous();
      var right = unary();
      return new Expr.Unary(op, right);
    }

    return call();
  }

  private function call():Expr {
    var expr:Expr = primary();

    while(true) {
      if (match([ TokLeftParen ])) {
        expr = finishCall(expr);
      } else if (match([ TokDot ])) {
        var name = consume(TokIdentifier, "Expect property name after '.'.");
        expr = new Expr.Get(expr, name); 
      } else {
        break;
      }
    }

    return expr;
  }

  private function finishCall(callee:Expr):Expr {
    var arguments:Array<Expr> = [];

    if (!check(TokRightParen)) {
      do {
        if (arguments.length >= 8) { // limit of 8 for now
          error(peek(), "Cannot have more than 8 arguments.");
        }
        arguments.push(expression());
      } while (match([ TokComma ]));
    }

    var paren = consume(TokRightParen, "Expect ')' after arguments.");

    return new Expr.Call(callee, paren, arguments);
  }

  private function primary():Expr {
    if (match([ TokFalse ])) return new Expr.Literal(false);
    if (match([ TokTrue ])) return new Expr.Literal(true);
    if (match([ TokNull ])) return new Expr.Literal(null);

    if (match([ TokNumber, TokString ])) {
      return new Expr.Literal(previous().literal);
    }

    if (match([ TokSuper ])) {
      var keyword = previous();
      consume(TokDot, "Expect '.' after 'super'.");
      var method = consume(TokIdentifier, "Expect superclass method name.");
      return new Expr.Super(keyword, method); 
    }

    if (match([ TokThis ])) {
      return new Expr.This(previous());
    }

    if (match([ TokIdentifier ])) {
      return new Expr.Variable(previous());
    }

    if (match([ TokLeftParen ])) {
      var expr = expression();
      consume(TokRightParen, "Expect ')' after expression.");
      return new Expr.Grouping(expr);
    }

    if (match([ TokLeftBracket ])) {
      return arrayLiteral();
    }

    if (match([ TokLeftBrace ])) {
      return blockOrObjectLiteral();
    }

    throw error(peek(), 'Expect expression');
  }

  private function arrayLiteral():Expr {
    var values:Array<Expr> = parseList(TokComma, TokRightBracket, expression);
    var end = consume(TokRightBracket, "Expect ']' after values.");
    return new Expr.ArrayLiteral(end, values);
  }

  private function blockOrObjectLiteral():Expr {
    // For now, always assume object literal.
    var keys:Array<Token> = [];
    var values:Array<Expr> = [];

    if (!check(TokRightBrace)) {
      do {
        keys.push(consume(TokIdentifier, "Expect identifiers for object keys"));
        consume(TokColon, "Expect colons after object keys");
        values.push(expression()); 
      } while (match([ TokComma ]));
    }

    var end = consume(TokRightBrace, "Expect '}' at the end of an object literal");

    return new Expr.ObjectLiteral(end, keys, values);
  }

  private function match(types:Array<TokenType>):Bool {
    for (type in types) {
      if (check(type)) {
        advance();
        return true;
      }
    }
    return false;
  }

  private function consume(type:TokenType, message:String) {
    if (check(type)) return advance();
    throw error(peek(), message);
  } 

  private function check(type:TokenType):Bool {
    if (isAtEnd()) return false;
    return peek().type.equals(type);
  }

  private function advance():Token {
    if (!isAtEnd()) current++;
    return previous();
  }

  private function isAtEnd() {
    return peek().type.equals(TokEof);
  }

  private function peek():Token {
    return tokens[current];
  }

  private function previous():Token {
    return tokens[current - 1];
  }

  private function error(token:Token, message:String) {
    HxLox.error(token, message);
    return new ParserError();
  }

  private function synchronize() {
    advance();
    while (!isAtEnd()) {
      if (previous().type.equals(TokSemicolon)) return;

      switch (peek().type) {
        case TokClass | TokFun | TokVar | TokFor | TokIf |
             TokWhile | TokReturn: return;
        default: advance();
      }
    }
  }

  private function parseList<T>(sep:TokenType, end:TokenType, parser:Void->T):Array<T> {
    var items:Array<T> = [];
    if (!check(end)) {
      do {
        items.push(parser());
      } while (match([ sep ]));
    }
    return items;
  }

}

class ParserError {

  // todo

  public function new() {}

}
