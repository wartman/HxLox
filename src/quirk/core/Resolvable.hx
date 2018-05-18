package quirk.core;

import Expr;

interface Resolvable {
  public function resolve(expr:Expr, depth:Int):Void;
}