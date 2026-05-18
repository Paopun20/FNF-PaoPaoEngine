package funkin.backend.utils.tools;

import haxe.Json;

@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class JsonTools {
	public static function stringify(data:Dynamic, ?pretty:Bool = false):String {
		return pretty ? Json.stringify(data, null, "  ") : Json.stringify(data);
	}

	public static function parse(text:String):Dynamic {
		return Json.parse(text);
	}
}
