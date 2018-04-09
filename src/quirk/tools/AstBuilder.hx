package quirk.tools;

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;

class AstBuilder {

  // Build a visitor for all Stmt or Expr nodes.
  public static function buildVisitor(targetPath:String) {
    var fields = Context.getBuildFields();
    var root = targetPath.split('.').pop();
    var exprs = Context.getModule(targetPath).map(function (type) {
      var name = type.getClass().name;
      if (name == root) return null;
      return name;
    }).filter(function (name) return name != null);

    for (name in exprs) {
      var method:Field = {
        name: 'visit${name}${root}',
        access: [ APublic ],
        pos: Context.currentPos(),
        kind: FFun({
          params: [],
          args: [ {
            name: root.toLowerCase(),
            opt: false,
            type: Context.getType('${targetPath}.${name}').toComplexType(),
            value: null
          } ],
          expr: null,
          ret: macro:T
        })
      };
      fields.push(method);
    }

    return fields;
  }

  // Turn a class into an Expr or Stmt node.
  public static function buildNode() {
    var fields = Context.getBuildFields();
    var cls = Context.getLocalClass().get();
    var args = [];
    var states = [];

    for (f in fields) {
      switch (f.kind) {
        case FVar(t, e):
          args.push({name:f.name, type:t, opt:false, value:null});
          states.push(macro $p{["this", f.name]} = $i{f.name});
          f.access.push(APublic);
        default:
      }
    }

    fields.push({
      name: "new",
      access: [ APublic ],
      pos: Context.currentPos(),
      kind: FFun({
        args: args,
        expr: macro $b{states},
        params: [],
        ret: null
      })
    });

    var suffix = cls.interfaces[0].t.get().name; // a bit messy, but eh. will work for what we're doing.
    var name = 'visit' + cls.name + suffix;
    var type = Context.getType('quirk.${suffix}Visitor').toComplexType();

    fields.push({
      name: "accept",
      access: [ APublic ],
      pos: Context.currentPos(),
      kind: FFun({
        args: [ { name: 'visitor', type:type, opt:false, value:null } ],
        params: [ { name: 'T' } ],
        expr: macro { return visitor.$name(this); },
        ret: macro:T
      })
    });

    return fields;
  }

}