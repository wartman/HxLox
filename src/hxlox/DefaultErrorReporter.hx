package hxlox;

using haxe.io.Path;

class DefaultErrorReporter implements ErrorReporter {

  public function new() {}

  public function report(pos:Position, where:String, message:String, ?isRuntime:Bool) {
    HxLox.hadError = true;
    if (isRuntime == true) HxLox.hadRuntimeError = true;
    Sys.println('${pos.file} [line ${pos.line}] Error ${where}:');
    Sys.println('   ${message}');
  }

}
