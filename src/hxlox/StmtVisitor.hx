package hxlox;

@:build(hxlox.tools.AstBuilder.buildVisitor('hxlox.Stmt'))
interface StmtVisitor<T> {}
