package quirk.generator;

interface Writer {
  public function write(modules:Map<String, ModuleEntry>):Void;
}
