package quirk.generator;

import quirk.Stmt;

class PhpTarget extends BaseTarget {

  override public function generate(name:String, stmts:Array<Stmt>):String {
    return new PhpGenerator(this, name).generate(stmts);
  }

}