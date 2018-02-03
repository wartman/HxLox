package hxlox;

@:build(hxlox.tools.AstBuilder.buildVisitor('hxlox.Expr'))
interface ExprVisitor<T> {}
