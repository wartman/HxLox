package hxlox;

interface ErrorReporter {
  public function report(pos:Position, where:String, message:String, ?isRuntime:Bool):Void;
}
