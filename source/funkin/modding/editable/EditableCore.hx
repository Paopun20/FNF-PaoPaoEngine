package funkin.modding.editable;

#if MODS_ALLOWED
#if HSCRIPT_ALLOWED
import funkin.modding.scripts.HScript;
#end
#if PYTHON_ALLOWED
import funkin.modding.scripts.Python;
#end
#if LUA_ALLOWED
import funkin.modding.scripts.FunkinLua;
#end
import funkin.modding.scripts.utils.LuaUtils;
#end

enum EditableType
{
	State;
	Substate;
}

class EditableCore
{
	public var stateName:String;
	public var stateType:EditableType;

	#if LUA_ALLOWED
	private var luaArray:Array<FunkinLua> = [];
	#end
	#if HSCRIPT_ALLOWED
	private var hscriptArray:Array<HScript> = [];
	#end
	#if PYTHON_ALLOWED
	private var pythonArray:Array<Python> = [];
	#end

	public function new(stateName:String, stateType:EditableType):Void
	{
		this.stateName = stateName;
		this.stateType = stateType;
	}

	public function preset(script:Dynamic):Void
	{
		#if MODS_ALLOWED
		if (script != null && Reflect.hasField(script, 'set'))
		{
			script.set("stateName", stateName);
			switch (stateType)
			{
				case EditableType.State:
					script.set("stateType", "State");
					return;
				case EditableType.Substate:
					script.set("stateType", "Substate");
					return;
				default:
					script.set("stateType", "Unknown");
					return;
			}
		}
		#end
	}

	#if MODS_ALLOWED
	#if HSCRIPT_ALLOWED
	public function initHScript(file:String):Void
	{
		var newScript:HScript = null;
		try
		{
			newScript = new HScript(null, file);
			preset(newScript);
			CoolLog.info('initialized hscript interp successfully: $file');
			hscriptArray.push(newScript);
		}
		catch (e:Dynamic)
		{
			CoolLog.error('Error loading HScript from $file: $e');
			if (newScript != null)
				newScript.destroy();
		}
	}
	#end

	#if LUA_ALLOWED
	public function initLua(file:String):Void
	{
		var newScript:FunkinLua = null;
		try
		{
			newScript = new FunkinLua(file);
			preset(newScript);
			CoolLog.info('initialized lua interp successfully: $file');
			luaArray.push(newScript);
		}
		catch (e:Dynamic)
		{
			CoolLog.error('Error loading Lua from $file: $e');
			if (newScript != null)
				newScript.destroy();
		}
	}
	#end

	#if PYTHON_ALLOWED
	public function initPython(file:String):Void
	{
		var newScript:Python = null;
		try
		{
			newScript = new Python(null, file);
			preset(newScript);
			CoolLog.info('initialized python interp successfully: $file');
			pythonArray.push(newScript);
		}
		catch (e:Dynamic)
		{
			CoolLog.error('[Python] Runtime error: "' + e + '" at ' + file);
			if (newScript != null)
				newScript.destroy();
		}
	}
	#end
	#end
	private function getScriptCount():Int
	{
		var count = 0;
		#if MODS_ALLOWED
		#if LUA_ALLOWED count += luaArray.length; #end
		#if HSCRIPT_ALLOWED count += hscriptArray.length; #end
		#if PYTHON_ALLOWED count += pythonArray.length; #end
		#end
		return count;
	}

	public function initScriptFromDirectory(directory:String, name:String):Void
	{
		#if MODS_ALLOWED
		CoolLog.info('Loading scripts for state "$stateName" from ${directory}');
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED || PYTHON_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), directory))
			for (file in FileSystem.readDirectory(folder))
			{
				if (file.toLowerCase().split('.')[0] == name.toLowerCase())
				{
					#if LUA_ALLOWED
					if (file.toLowerCase().endsWith('.lua'))
						initLua(folder + file);
					#end
					#if HSCRIPT_ALLOWED
					if (file.toLowerCase().endsWith('.hx'))
						initHScript(folder + file);
					#end
					#if PYTHON_ALLOWED
					if (file.toLowerCase().endsWith('.py'))
						initPython(folder + file);
					#end
				}
			}
		#end

		CoolLog.info('Done - ${getScriptCount()} script(s) loaded for "$stateName"');
		#end
	}

	#if PYTHON_ALLOWED
	private function callOnPython(func:String, args:Array<Dynamic>, ignoreStops:Bool, exclusions:Array<String>, excludeValues:Array<Dynamic>):Dynamic
	{
		var returnVal:Dynamic = null;

		for (script in pythonArray)
		{
			if (script == null || exclusions.contains(script.origin))
				continue;

			if (!script.exists(func))
				continue;

			try
			{
				var value = script.call(func, args);

				if (value != null && !excludeValues.contains(value))
					returnVal = value;

				if (!shouldContinue(value, ignoreStops, excludeValues))
					break;
			}
			catch (e:Dynamic)
			{
				CoolLog.error('[Python] Runtime error in $func: $e');
			}
		}

		return returnVal;
	}
	#end

	#if HSCRIPT_ALLOWED
	private function callOnHScript(func:String, args:Array<Dynamic>, ignoreStops:Bool, exclusions:Array<String>, excludeValues:Array<Dynamic>):Dynamic
	{
		var returnVal:Dynamic = null;

		for (script in hscriptArray)
		{
			if (script == null || exclusions.contains(script.origin))
				continue;

			if (!script.exists(func))
				continue;

			try
			{
				var result = script.call(func, args);
				var value = result != null ? result.returnValue : null;

				if (value != null && !excludeValues.contains(value))
					returnVal = value;

				if (!shouldContinue(value, ignoreStops, excludeValues))
					break;
			}
			catch (e:Dynamic)
			{
				CoolLog.error('[HScript] Runtime error in $func: $e');
			}
		}

		return returnVal;
	}
	#end

	#if LUA_ALLOWED
	private function callOnLua(func:String, args:Array<Dynamic>, ignoreStops:Bool, exclusions:Array<String>, excludeValues:Array<Dynamic>):Dynamic
	{
		var returnVal:Dynamic = null;
		var toRemove:Array<FunkinLua> = [];

		for (script in luaArray)
		{
			if (script == null || script.closed)
			{
				toRemove.push(script);
				continue;
			}

			if (exclusions.contains(script.scriptName))
				continue;

			if (!script.existsFunc(func))
				continue;

			try
			{
				var value = script.call(func, args);

				if (value != null && !excludeValues.contains(value))
					returnVal = value;

				if (!shouldContinue(value, ignoreStops, excludeValues))
					break;
			}
			catch (e:Dynamic)
			{
				CoolLog.error('[Lua] Runtime error in $func: $e');
				toRemove.push(script);
			}
		}

		for (script in toRemove)
			luaArray.remove(script);

		return returnVal;
	}
	#end

	private function shouldContinue(value:Dynamic, ignoreStops:Bool, excludeValues:Array<Dynamic>):Bool
	{
		#if !MODS_ALLOWED
		return true;
		#else
		if (value == null || excludeValues.contains(value) || ignoreStops)
			return true;

		return switch (value)
		{
			case LuaUtils.Function_StopLua, LuaUtils.Function_StopHScript, LuaUtils.Function_StopPython, LuaUtils.Function_StopAll: false;
			default: true;
		};
		#end
	}

	public function callScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [];

		var returnVal:Dynamic = null;

		#if LUA_ALLOWED
		returnVal = callOnLua(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if (!shouldContinue(returnVal, ignoreStops, excludeValues))
			return returnVal;
		#end

		#if HSCRIPT_ALLOWED
		returnVal = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if (!shouldContinue(returnVal, ignoreStops, excludeValues))
			return returnVal;
		#end

		#if PYTHON_ALLOWED
		returnVal = callOnPython(funcToCall, args, ignoreStops, exclusions, excludeValues);
		#end

		return returnVal;
	}

	public function setScript(id:String, v:Dynamic):Void
	{
		#if LUA_ALLOWED
		for (luaScript in luaArray)
			luaScript.set(id, v);
		#end
		#if HSCRIPT_ALLOWED
		for (hscript in hscriptArray)
			hscript.set(id, v);
		#end
		#if PYTHON_ALLOWED
		for (pythonScript in pythonArray)
			pythonScript.set(id, v);
		#end
	}

	public function destroy():Void
	{
		#if LUA_ALLOWED
		for (lua in luaArray)
			lua.destroy();
		luaArray = [];
		#end
		#if HSCRIPT_ALLOWED
		for (hscript in hscriptArray)
			hscript.destroy();
		hscriptArray = [];
		#end
		#if PYTHON_ALLOWED
		for (python in pythonArray)
			python.destroy();
		pythonArray = [];
		#end
	}
}
