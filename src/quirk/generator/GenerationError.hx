package quirk.generator;

import quirk.Token;

class GeneratorError {

  public var token:Token;
  public var message:String;

  public function new(token:Token, message:String) {
    this.token = token;
    this.message = message;
  }

  public function toString() {
    return this.message;
  }

}