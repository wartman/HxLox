package quirk.interpreter;

import quirk.Stmt.FunKind;

class Class extends Instance {

  public var name:String;
  public var superclass:Class;
  @:isVar public var meta(default, null):Map<String, Array<Dynamic>>;
  @:isVar public var methods(default, null):Map<String, Function>;
  @:isVar public var staticMethods(default, null):Map<String, Function>;

  public function new(
    name:String,
    superclass:Class,
    methods:Map<String, Function>,
    staticMethods:Map<String, Function>,
    meta:Map<String, Array<Dynamic>>
  ) {
    this.name = name;
    this.superclass = superclass;
    this.methods = methods;
    this.staticMethods = staticMethods;
    this.meta = meta;
    super(this);
  }

  public function findMethod(instance:Instance, name:String):Callable {
    var methods = instance == this ? this.staticMethods : this.methods;
    if (methods.exists(name)) {
      return methods.get(name).bind(instance);
    }
    if (superclass != null) {
      return superclass.findMethod(instance, name);
    }
    return null;
  }

  override public function toString() {
    return this.name;
  }

}
