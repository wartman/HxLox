package quirk;

@:build(quirk.tools.AstBuilder.buildVisitor('quirk.Expr'))
interface ExprVisitor<T> {}
