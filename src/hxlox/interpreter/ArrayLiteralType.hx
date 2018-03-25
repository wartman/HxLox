package hxlox.interpreter;

class ArrayLiteralType extends CoreType {

  public var name:String = 'ArrayLiteral';
  public var values:Array<Dynamic>;

  public function new(values:Array<Dynamic>) {
    this.values = values;

    methods.set('map', new ArrayLiteralMapMethod(this));

    // todo: think of a better way of adding these statically?
    addField('length', function () return values.length);
    addMethod('push', function (args:Array<Dynamic>) {
      values.push(args[0]);
      return values.length;
    }, 1);
    // Todo: need to add subscript operators :P. For now,
    // `get` works.
    addMethod('get', function (args:Array<Dynamic>) {
      return values[Std.int(args[0])];
    }, 1);
  }

  override public function toString() {
    return 'Array';
  }

}

// Not working yet -- we can't pass functions as arguments :P.
class ArrayLiteralMapMethod implements Callable {

  private var instance:ArrayLiteralType;

  public function new(instance:ArrayLiteralType) {
    this.instance = instance;
  }

  public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic {
    var fn = arguments[0];
    var out:Array<Dynamic> = [];
    
    if (Std.is(fn, Function)) {
      for (index in 0...instance.values.length) {
        var value = instance.values[index];
        out[index] = (fn:Function).call(interpreter, [ value, index ]);
      }
    }

    return new ArrayLiteralType(out);
  }

  public function arity():Int {
    return 1;
  }

}