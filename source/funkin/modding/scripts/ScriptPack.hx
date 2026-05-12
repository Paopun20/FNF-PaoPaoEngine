package funkin.modding.scripts;

import funkin.modding.scripts.utils.LuaUtils;

enum ScriptType {
	LUA;
	PYTHON;
	HSCRIPT;
	NXSCRIPT;
}

class ScriptPack {
	public var scripts:Array<Script> = [];
	public var name:String;
	public var path:String;
	public var variables = {};

	public function new(?name:String = "ScriptPack", ?path:String = "") {
		this.name = name;
		this.path = path;
		this.variables = {
			get: function(name:String):Dynamic return this.get(name),
			set: function(name:String, value:Dynamic):Void this.set(name, value),
			has: function(name:String):Bool return this.get(name) != null
		};
	}

	private inline function matchesType(script:Script, type:ScriptType):Bool {
		return switch (type) {
			case LUA: Std.isOfType(script, LuaScript);
			case HSCRIPT: Std.isOfType(script, HScript);
			case PYTHON: Std.isOfType(script, Python);
			case NXSCRIPT: Std.isOfType(script, NxScript);
		};
	}

	private inline function validScript(script:Script, exclusions:Array<Script>):Bool {
		return script != null && !script.closed && !exclusions.contains(script);
	}

	private function forEachScript(?type:ScriptType, exclusions:Array<Script>, fn:Script->Void):Void {
		for (script in scripts) {
			if (!validScript(script, exclusions))
				continue;

			if (type != null && !matchesType(script, type))
				continue;

			fn(script);
		}
	}

	private function getFromScripts(?type:ScriptType, variable:String, exclusions:Array<Script>):Dynamic {
		for (script in scripts) {
			if (!validScript(script, exclusions))
				continue;

			if (type != null && !matchesType(script, type))
				continue;

			var result = script.get(variable);
			if (result != null)
				return result;
		}
		return null;
	}

	public function load(onlyName:String = null):Void {
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED || PYTHON_ALLOWED || NXSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), path))
			for (file in sys.FileSystem.readDirectory(folder)) {
				if (onlyName != null && !file.toLowerCase().startsWith(onlyName.toLowerCase()))
					continue;

				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua'))
					add(new LuaScript(folder + file));
				#end

				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx'))
					add(new HScript(folder + file));
				#end

				#if PYTHON_ALLOWED
				if (file.toLowerCase().endsWith('.py'))
					add(new Python(folder + file));
				#end

				#if NXSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('nx'))
					add(new NxScript(folder + file));
				#end
			}
		#end
	}

	public function getScriptsByName(names:Array<String>):Array<Script> {
		var result:Array<Script> = [];

		for (script in scripts) {
			if (script == null)
				continue;

			#if LUA_ALLOWED
			if (Std.isOfType(script, LuaScript)) {
				var s:LuaScript = cast script;
				if (names.contains(s.scriptName))
					result.push(script);
			}
			#end

			#if HSCRIPT_ALLOWED
			if (Std.isOfType(script, HScript)) {
				var s:HScript = cast script;
				if (names.contains(s.origin))
					result.push(script);
			}
			#end

			#if PYTHON_ALLOWED
			if (Std.isOfType(script, Python)) {
				var s:Python = cast script;
				if (names.contains(s.origin))
					result.push(script);
			}
			#end

			#if PYTHON_ALLOWED
			if (Std.isOfType(script, NxScript)) {
				var s:NxScript = cast script;
				if (names.contains(s.origin))
					result.push(script);
			}
			#end
		}

		return result;
	}

	public function add(script:Script):Void {
		if (script != null && !scripts.contains(script)) {
			scripts.push(script);
			script.scriptPack = this;
			#if LUA_ALLOWED
			if (Std.isOfType(script, LuaScript))
				(cast script : LuaScript).implementPackCallbacks(this);
			#end
		}
	}

	public function remove(script:Script):Void {
		if (script == null)
			return;

		scripts.remove(script);
		if (!script.closed)
			script.destroy();

		script.scriptPack = null;
	}

	public function set(variable:String, data:Dynamic, ?exclusions:Array<Script>):Void {
		if (exclusions == null)
			exclusions = [];
		forEachScript(null, exclusions, s -> s.set(variable, data));
	}

	public function setOnly(type:ScriptType, variable:String, data:Dynamic, ?exclusions:Array<Script>):Void {
		if (exclusions == null)
			exclusions = [];
		forEachScript(type, exclusions, s -> s.set(variable, data));
	}

	public function get(variable:String, ?exclusions:Array<Script>):Dynamic {
		if (exclusions == null)
			exclusions = [];
		return getFromScripts(null, variable, exclusions);
	}

	public function getOnly(type:ScriptType, variable:String, ?exclusions:Array<Script>):Dynamic {
		if (exclusions == null)
			exclusions = [];
		return getFromScripts(type, variable, exclusions);
	}

	private static function getResult(result:Dynamic):Null<String> {
		if (result == LuaUtils.Function_Stop
			|| result == LuaUtils.Function_StopLua
			|| result == LuaUtils.Function_StopHScript
			|| result == LuaUtils.Function_StopPython
			|| result == LuaUtils.Function_StopNxScript
			|| result == LuaUtils.Function_StopAll)
			return result;
		return null;
	}

	private function callInternal(type:ScriptType, func:String, args:Array<Dynamic>, ignoreStops:Bool, exclusions:Array<Script>,
			excludeValues:Array<Dynamic>):Dynamic {
		var result:Dynamic = LuaUtils.Function_Continue;

		for (script in scripts) {
			if (!validScript(script, exclusions))
				continue;

			if (type != null && !matchesType(script, type))
				continue;

			var scriptResult = script.call(func, args);

			if (!ignoreStops && getResult(scriptResult) != null)
				return scriptResult;

			if (scriptResult != null && scriptResult != LuaUtils.Function_Continue && !excludeValues.contains(scriptResult))
				result = scriptResult;
		}

		return result;
	}

	public function call(func:String, ?args:Array<Dynamic>, ?ignoreStops:Bool = false, ?exclusions:Array<Script>, ?excludeValues:Array<Dynamic>):Dynamic {
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [];

		return callInternal(null, func, args, ignoreStops, exclusions, excludeValues);
	}

	public function callOnly(type:ScriptType, func:String, ?args:Array<Dynamic>, ?ignoreStops:Bool = false, ?exclusions:Array<Script>,
			?excludeValues:Array<Dynamic>):Dynamic {
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [];

		return callInternal(type, func, args, ignoreStops, exclusions, excludeValues);
	}

	public function hasFunction(func:String):Bool {
		for (script in scripts)
			if (script != null && !script.closed && script.hasFunction(func))
				return true;

		return false;
	}

	public function destroy():Void {
		forEachScript(null, [], s -> s.destroy());
		scripts = [];
	}

	public function toArray():Array<Script>
		return scripts.copy();

	public var length(get, never):Int;

	private function get_length():Int
		return scripts.length;
}
