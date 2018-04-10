package quirk.generator;

import quirk.ExprVisitor;
import quirk.StmtVisitor;
import quirk.ModuleLoader;

class JavaScriptGenerator
  implements ExprVisitor<String>
  implements StmtVisitor<String>
{

  private var loader:ModuleLoader;

  public function new(loader:ModuleLoader) {
    this.loader = loader;
  }

  

}
