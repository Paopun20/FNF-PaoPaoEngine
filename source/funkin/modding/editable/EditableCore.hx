package funkin.modding.editable;

#if HSCRIPT_ALLOWED
import funkin.modding.scripts.HScript;
#end
#if PYTHON_ALLOWED
import funkin.modding.scripts.Python;
#end
#if LUA_ALLOWED
import funkin.modding.scripts.FunkinLua;
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
	}

	#if HSCRIPT_ALLOWED
	public function initHScript(file:String):Void
	{
		var newScript:HScript = null;
		try
		{
			newScript = new HScript(null, file);
			preset(newScript);
			if (newScript.exists('onCreate'))
				newScript.call('onCreate', []);
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
			if (newScript.existsFunc('onCreate'))
				newScript.call('onCreate', []);
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
			if (newScript.exists('onCreate'))
				newScript.call('onCreate', []);
			CoolLog.info('initialized python interp successfully: $file');
			pythonArray.push(newScript);
		}
		catch (e:Dynamic)
		{
			CoolLog.info('[Python] Runtime error: "' + e + '" at ' + file);
			if (newScript != null)
				newScript.destroy();
		}
	}
	#end

	private function getScriptCount():Int
	{
		var count = 0;
		#if LUA_ALLOWED count += luaArray.length; #end
		#if HSCRIPT_ALLOWED count += hscriptArray.length; #end
		#if PYTHON_ALLOWED count += pythonArray.length; #end
		return count;
	}

	public function initScriptFromDirectory(directory:String, name:String):Void
	{
		CoolLog.info('Loading scripts for state "$stateName" from scripts/states/');
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
	}

	public function callScripts(funcname:String, args:Array<Dynamic>):Void
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
			if (luaArray[i].existsFunc(funcname))
				luaArray[i].call(funcname, args);
		#end
		#if HSCRIPT_ALLOWED
		for (i in 0...hscriptArray.length)
			if (hscriptArray[i].exists(funcname))
				hscriptArray[i].call(funcname, args);
		#end
		#if PYTHON_ALLOWED
		for (i in 0...pythonArray.length)
			if (pythonArray[i].exists(funcname))
				pythonArray[i].call(funcname, args);
		#end
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
