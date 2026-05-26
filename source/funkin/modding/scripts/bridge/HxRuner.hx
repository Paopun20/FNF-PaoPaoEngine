package funkin.modding.scripts.bridge;

import funkin.modding.scripts.Script;

class HxRuner {
	public static function implement(script:Script):Void {
        #if HSCRIPT_ALLOWED
		var bridge = new HaxeBridge();
		script.set("runHaxeCode", function(code, ?vars, ?func, ?args) return bridge.runHaxeCode(script.scriptPath, code, vars, func, args));
		script.set("runHaxeFunction", function(func, ?args) return bridge.runHaxeFunction(func, args));
		script.set("addHaxeLibrary", function(lib, ?pkg) bridge.addHaxeLibrary(lib, pkg));
        #end
	}
}