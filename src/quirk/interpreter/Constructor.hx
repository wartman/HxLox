package quirk.interpreter;

import quirk.Stmt.Fun;

class Constructor extends Function {

  public function new(declaration:Fun, closure:Environment, meta:Map<String, Array<Dynamic>>) {
    super(declaration, closure, true, meta, false);
  }

  override public function bind(instance:Object) {
    if (!Std.is(instance, Class)) {
      throw 'Constructors must receive a class, not an instance';
    }
    var cls:Class = cast instance;
    return super.bind(new Instance(cls)); 
  }

}