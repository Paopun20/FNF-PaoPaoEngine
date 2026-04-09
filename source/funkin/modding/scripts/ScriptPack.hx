package funkin.modding.scripts;

import funkin.modding.scripts.utils.LuaUtils;

class ScriptPack
{
	public var scripts:Array<Script> = [];
	public var name:String;
	public var path:String;
	public var legacyMode:Bool;

	public function new(?name:String = "ScriptPack", ?path:String = "", ?legacyMode:Bool = false)
	{
		this.name = name;
		this.path = path;
		this.legacyMode = legacyMode;
	}

	public function load(onlyName:String = null):Void
	{
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED || PYTHON_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), path))
			for (file in sys.FileSystem.readDirectory(folder))
			{
				if (onlyName != null && !file.toLowerCase().startsWith(onlyName.toLowerCase()))
					continue;

				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua')) {
					add(new LuaScript(folder + file));
				}
				#end
				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx'))
					add(new HScript(folder + file));
				#end
				#if PYTHON_ALLOWED
				if (file.toLowerCase().endsWith('.py'))
					add(new Python(folder + file));
				#end
			}
		#end
	}

	public function add(script:Script):Void
	{
		if (script != null && !scripts.contains(script))
			scripts.push(script);
	}

	public function setParent(parent:Dynamic):Void
	{
		for (script in scripts)
		{
			if (script != null && !script.closed)
				script.set("parent", parent);
		}
	}

	public function remove(script:Script):Void
	{
		scripts.remove(script);
	}

	public function clear():Void
	{
		for (script in scripts)
		{
			if (script != null && !script.closed)
				script.destroy();
		}
		scripts = [];
	}

	public function set(variable:String, data:Dynamic, ?exclusions:Array<Script>):Void
	{
		if (exclusions == null)
			exclusions = [];

		for (script in scripts)
		{
			if (script != null && !script.closed && !exclusions.contains(script))
				script.set(variable, data);
		}
	}

	public function get(variable:String, ?exclusions:Array<Script>):Dynamic
	{
		if (exclusions == null)
			exclusions = [];

		for (script in scripts)
		{
			if (script != null && !script.closed && !exclusions.contains(script))
			{
				var result = script.get(variable);
				if (result != null)
					return result;
			}
		}
		return null;
	}

	public function call(func:String, ?args:Array<Dynamic>, ?ignoreStops:Bool = false, ?exclusions:Array<Script>, ?excludeValues:Array<Dynamic>):Dynamic
	{
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [];

		var result:Dynamic = LuaUtils.Function_Continue;
		for (script in scripts)
		{
			if (script == null || script.closed || exclusions.contains(script))
				continue;

			var scriptResult = script.call(func, args);
			if (!ignoreStops)
			{
				if (scriptResult == LuaUtils.Function_Stop || scriptResult == LuaUtils.Function_StopLua || scriptResult == LuaUtils.Function_StopHScript || scriptResult == LuaUtils.Function_StopPython || scriptResult == LuaUtils.Function_StopAll)
					return scriptResult;
			}
			if (scriptResult != null && scriptResult != LuaUtils.Function_Continue && !excludeValues.contains(scriptResult))
				result = scriptResult;
		}
		return result;
	}

	public function hasFunction(func:String):Bool
	{
		for (script in scripts)
		{
			if (script != null && !script.closed)
			{
				if (script.hasFunction(func))
					return true;
			}
		}
		return false;
	}

	public function stop():Void
	{
		for (script in scripts)
		{
			if (script != null && !script.closed)
				script.stop();
		}
	}

	public function destroy():Void
	{
		for (script in scripts)
		{
			if (script != null && !script.closed)
				script.destroy();
		}
		scripts = [];
	}

	public function toArray():Array<Script>
		return scripts.copy();

	public var length(get, never):Int;
	private function get_length():Int return scripts.length;
}
