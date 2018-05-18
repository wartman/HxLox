package quirk.generator;

import quirk.Stmt;

interface Generator {
  public function generate(stmts:Array<Stmt>):String;
}
