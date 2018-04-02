package hxlox;

using haxe.io.Path;

class DefaultErrorReporter implements ErrorReporter {

  public static var hadError:Bool = false;
  public static var hadRuntimeError:Bool = false;

  public var file:String;

  public function new(file:String) {
    this.file = file;
  }

  public function report(line:Int, where:String, message:String) {
    Sys.println('${this.file} [line ${line}] Error${where}:');
    Sys.println('   ${message}');
  }

}
