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

}
