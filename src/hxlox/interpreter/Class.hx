package hxlox.interpreter;

class Class extends Instance implements Callable {

  public var name:String;
  public var superclass:Class;
  private var methods:Map<String, Function>;
  private var staticMethods:Map<String, Function>;

  public function new(name:String, superclass:Class, methods:Map<String, Function>, staticMethods:Map<String, Function>) {
    this.name = name;
    this.superclass = superclass;
    this.methods = methods;
    this.staticMethods = staticMethods;
    super(this);
  }

  public function arity():Int {
    var initializer = methods.get("init");
    if (initializer == null) return 0;
    return initializer.arity();
  }

  public function call(interpreter:Interpreter, args:Array<Dynamic>):Dynamic {
    var instance = new Instance(this);
    var initializer = methods.get('init');
    if (initializer != null) {
      initializer.bind(instance).call(interpreter, args);
    }
    return instance;
  }

  public function findMethod(instance:Instance, name:String) {
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