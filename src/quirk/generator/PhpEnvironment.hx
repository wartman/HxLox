package quirk.generator;

import quirk.core.Environment;

enum PhpKind {
  PhpType;
  PhpFun;
  PhpVar;
}

typedef PhpEnvironment = Environment<PhpKind>;
