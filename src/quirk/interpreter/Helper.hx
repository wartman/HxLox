package quirk.interpreter;

import quirk.Token;
import quirk.Stmt;

class Helper {

  public static function getSetterName(name:Token) {
    return 'set_' + name.lexeme;
  }

  public static function getGetterName(name:Token) {
    return 'get_' + name.lexeme;
  }

  public static function getMethodName(method:Stmt.Fun) {
    return switch method.kind {
      case Stmt.FunKind.FunSetter: getSetterName(method.name);
      case Stmt.FunKind.FunGetter: getGetterName(method.name);
      default: method.name.lexeme;
    }
  }

  public static function signature(sig:Stmt.Fun) {
    var args = [ for (i in 0...sig.params.length) '_' ].join(',');
    return sig.name.lexeme + '(' + args + ')';
  }

  public static function construct(
    cls:quirk.interpreter.Class,
    constructor:String,
    interpreter:Interpreter,
    args:Array<Dynamic>
  ) {
    var method = cls.findMethod(cls, constructor);
    if (method == null) {
      throw 'No constructor found for ' + cls.name + '::' + constructor;
    }
    return method.call(interpreter, args);
  }

}
