package hxlox.interpreter;

class Class implements Callable {

  public var name:String;
  private var methods:Map<String, Function>; 
  private var superclass:Class;

  public function new(name:String, superclass:Class, methods:Map<String, Function>) {
    this.name = name;
    this.superclass = superclass;
    this.methods = methods;
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
    if (methods.exists(name)) {
      return methods.get(name).bind(instance);
    }
    if (superclass != null) {
      return superclass.findMethod(instance, name);
    }
    return null;
  }

  public function toString() {
    return name;
  }

}
