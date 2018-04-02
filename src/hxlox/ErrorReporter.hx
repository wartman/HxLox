package hxlox;

interface ErrorReporter {
  public static var hadError:Bool;
  public static var hadRuntimeError:Bool;
  public var file:String;
  public function report(line:Int, where:String, message:String):Void;
}
