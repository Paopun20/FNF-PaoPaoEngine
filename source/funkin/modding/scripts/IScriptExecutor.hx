package funkin.modding.scripts;

interface IScriptExecutor {
	function call(funcName:String, ?args:Array<Dynamic>):Dynamic;
	function execute():Void;
	function set(variable:String, value:Dynamic):Void;
	function get(variable:String):Dynamic;
	function hasFunction(funcName:String):Bool;
}