package quirk.interpreter;

typedef Signature = {
  ?type:String,
  method:String,
  arity:Int
};

class Foreign implements Callable {

  public var signature(default, null):Signature;
  private var fn:Array<Dynamic>->Dynamic;

  public function new(signature:Signature, fn:Array<Dynamic>->Dynamic) {
    this.signature = signature;
    this.fn = fn;
  }

  public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic {
    return fn(arguments);
  }

  public function isDynamic() return false;

  public function arity():Int {
    return this.signature.arity;
  }

}
