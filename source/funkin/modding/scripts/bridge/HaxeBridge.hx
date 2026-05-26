package funkin.modding.scripts.bridge;

import funkin.modding.scripts.HScript;
import funkin.modding.scripts.utils.LuaUtils;

#if HSCRIPT_ALLOWED
class HaxeBridge {
	private var hscript:HScript = null;

	public function new() {}

	/**
	 * Executes raw Haxe code, optionally bringing in variables from the
	 * calling script's scope and then calling a named function.
	 */
	public function runHaxeCode(scriptPath:String, codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null,
			?funcArgs:Array<Dynamic> = null):Dynamic {
		if (hscript == null)
			initializeHScript(scriptPath, codeToRun, varsToBring)
		else
			executeInExistingHScript(codeToRun);

		if (funcToRun == null)
			return hscript?.returnValue;

		var result = hscript?.call(funcToRun, funcArgs);
		return (result != null && result != LuaUtils.Function_Continue) ? result : hscript?.returnValue;
	}

	private function initializeHScript(scriptPath:String, code:String, varsToBring:Any):Void {
		CoolLog.info('Initializing Haxe interp for: "$scriptPath"');
		try {
			hscript = new HScript();
			hscript.scriptName = (scriptPath != null && scriptPath.length > 0) ? 'HxVM:${scriptPath}' : 'HxVM:<inline>';
			if (varsToBring != null)
				for (fieldName in Reflect.fields(varsToBring))
					hscript.set(fieldName, Reflect.field(varsToBring, fieldName));
			hscript.returnValue = hscript.codeExecute(code);
		} catch (e:Dynamic) {
			CoolLog.error('HScript Error in $scriptPath: $e');
			hscript = null;
		}
	}

	private function executeInExistingHScript(code:String):Void {
		try {
			hscript.returnValue = hscript.codeExecute(code);
		} catch (e:Dynamic) {
			CoolLog.error('HScript Error: $e');
			hscript.returnValue = null;
		}
	}

	/** Calls a function that was defined in a previous runHaxeCode call. */
	public function runHaxeFunction(funcToRun:String, ?funcArgs:Array<Dynamic> = null):Dynamic {
		if (hscript == null) {
			CoolLog.error('runHaxeFunction: HScript is not initialized. Call runHaxeCode first.');
			return null;
		}
		return hscript.call(funcToRun, funcArgs);
	}

	/** Imports a Haxe class/enum into the HScript interpreter by its package path. */
	public function addHaxeLibrary(libName:String, ?libPackage:Null<String> = ''):Void {
		if (libName == null)
			libName = '';

		var prefix = (libPackage != null && libPackage.length > 0) ? libPackage + '.' : '';
		// resolveClass and resolveEnum return incompatible types (Class vs Enum),
		// so ?? cannot unify them — fall back with an explicit null check instead.
		var resolved:Dynamic = LuaUtils.resolveClass(prefix + libName);
		if (resolved == null)
			resolved = Type.resolveEnum(prefix + libName);

		if (hscript == null)
			hscript = new HScript();

		try {
			hscript.set(libName, resolved);
		} catch (e:Dynamic) {
			CoolLog.error('addHaxeLibrary error: $e');
		}
	}
}
#end
