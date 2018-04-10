package quirk;

typedef Ref<T> = {
  get: Void -> T
};

enum Type {
  TAny; // Dynamic type
  TDef(t:Type);
  TInst(t:Ref<ClassType>, params:Array<Type>);
  TFun(args:Array<Argument>, ret:Type);
}

typedef TypeParam = {
  name:String,
  ?type:Type
};

typedef Argument = {
  name:String,
  type:Type,
  optional:Bool
};

typedef BaseType = {
  module:Array<String>,
  name:String,
  pos:Position,
  // isExtern:Bool,
  params:Array<TypeParam>
};

typedef ClassField = {
  name:String,
  type:Type,
  params:Array<TypeParam>,
  kind:FieldKind,
  pos:Position
};

enum FieldKind {
  FVar;
  FMethod;
}

typedef ClassType = {
  > BaseType,
  ?superclass:{ t:Ref<ClassType>, params:Array<TypeParam> },
  interfaces:Array<{ t:Ref<ClassType>, params:Array<TypeParam> }>,
  staticFields:Array<ClassField>,
  fields:Array<ClassField>
}
