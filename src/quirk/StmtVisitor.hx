package quirk;

@:build(quirk.tools.AstBuilder.buildVisitor('quirk.Stmt'))
interface StmtVisitor<T> {}
