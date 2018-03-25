package hxlox.interpreter;

import hxlox.Token;

class CoreType implements Object {

  private var fields:Map<String, Void->Dynamic> = new Map();
  private var methods:Map<String, Callable> = new Map();

  public function addMethod(name:String, fn:Array<Dynamic>->Dynamic, artity:Int) {
    methods.set(name, new CoreTypeMethod(fn, artity));
    return this;
  }

  public function addField(name:String, resolver:Void->Dynamic) {
    fields.set(name, resolver);
  }

  public function get(name:Token):Dynamic {
    if (fields.exists(name.lexeme)) {
      return fields.get(name.lexeme)();
    }
    if (methods.exists(name.lexeme)) {
      return methods.get(name.lexeme);
    }
    throw new RuntimeError(name, "Undefined property '" + name.lexeme + "'.");
  }

  public function set(name:Token, value:Dynamic):Void {
    throw new RuntimeError(name, "Cannot set properties on builtin objects");
  }

  public function toString() {
    var cls = Type.getClass(this);
    return Type.getClassName(cls);
  }

}

class CoreTypeMethod implements Callable {

  private var fn:Array<Dynamic>->Dynamic;
  private var arity_:Int;

  public function new(fn:Array<Dynamic>->Dynamic, arity:Int) {
    this.fn = fn;
    this.arity_ = arity;
  }

  public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic {
    return fn(arguments);
  }

  public function arity():Int {
    return this.arity_;
  }

}