package quirk.interpreter;

import quirk.Stmt.Fun;

typedef ForeignMethod = Array<Dynamic>->Null<Function>->Dynamic;

class Foreign extends Function {

  private var foreignFun:ForeignMethod;

  public function new(
    declaration:Fun,
    closure:Environment,
    meta:Map<String, Array<Dynamic>>,
    foreignFun:ForeignMethod
  ) {
    super(declaration, closure, false, meta, false);
    this.foreignFun = foreignFun;
  }

  override public function bind(instance:Object) {
    var environment = new Environment(closure);
    environment.define('this', instance);
    return new Foreign(declaration, environment, meta, foreignFun);
  }

  override public function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic {
    return foreignFun(arguments, this);
  }

  override public function toString() {
    return 'foreign ' + super.toString();
  }

}
