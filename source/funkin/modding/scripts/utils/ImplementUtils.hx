package funkin.modding.scripts.utils;

import funkin.states.PlayState;

@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class ImplementUtils {
	public static inline function make(interpreter:Dynamic):(String, Dynamic) -> Null<Dynamic> {
		// can be one
		return function(name:String, value:Dynamic):Null<Dynamic> {
			interpreter.set(name, value);
			return null;
		};
	}

	public static function addTextToDebug(text:String, color:Int):Void {
		PlayState.instance.addTextToDebug(text, color);
	}
}
