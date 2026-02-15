package funkin.backend;

import haxe.ds.StringMap;
#if HSCRIPT_ALLOWED
import funkin.modding.scripts.HScript;
#end
#if PYTHON_ALLOWED
import funkin.modding.scripts.Python;
#end
#if LUA_ALLOWED
import funkin.modding.scripts.FunkinLua as Lua;
#end

class EditableState extends MusicBeatState
{
	private var stateName:String;

	#if LUA_ALLOWED
	private var luaArray:Array<Lua> = [];
	#end
	#if HSCRIPT_ALLOWED
	private var hscriptArray:Array<HScript> = [];
	#end
	#if PYTHON_ALLOWED
	private var pythonArray:Array<Python> = [];
	#end

	function preset(script:Dynamic)
	{
		if (script != null && Reflect.hasField(script, 'set'))
		{
			script.set("stateName", stateName);
		}
	}

	#if HSCRIPT_ALLOWED
	private inline function initHScript(file:String)
	{
		var newScript:HScript = null;
		try
		{
			newScript = new HScript(null, file);
			preset(newScript);
			if (newScript.exists('onCreate'))
				newScript.call('onCreate');
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
	private inline function initLua(file:String)
	{
		var newScript:Lua = null;
		try
		{
			newScript = new Lua(file);
			preset(newScript);
			if (newScript.existsFunc('onCreate'))
				newScript.call('onCreate');
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
	private inline function initPython(file:String)
	{
		var newScript:Python = null;
		try
		{
			newScript = new Python(null, file);
			preset(newScript);
			if (newScript.existsFunc('onCreate'))
				newScript.call('onCreate');
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

	private function initScriptFromDirectory(directory:String, name:String)
	{
		CoolLog.info('EditableState: Scanning for scripts in: $directory');
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED || PYTHON_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), directory))
			for (file in FileSystem.readDirectory(folder))
			{
				if (file.toLowerCase() == name.toLowerCase())
				{
					if (file.toLowerCase().endsWith('.lua'))
						initLua(folder + file);
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
	}

	private function callScripts(funcname:String, args:Array<Dynamic>)
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			if (luaArray[i].existsFunc(funcname))
				luaArray[i].call(funcname, args);
		}
		#end
		#if HSCRIPT_ALLOWED
		for (i in 0...hscriptArray.length)
		{
			if (hscriptArray[i].exists(funcname))
				hscriptArray[i].call(funcname, args);
		}
		#end
		#if PYTHON_ALLOWED
		for (i in 0...pythonArray.length)
		{
			if (pythonArray[i].exists(funcname))
				pythonArray[i].call(funcname, args);
		}
		#end
	}

	override public function create():Void
	{
		stateName = Type.getClassName(Type.getClass(this)).split('.').pop();
		initScriptFromDirectory("scripts/states/", stateName); // load from scripts/states/[state_name].[lua, hx, py]
		callScripts("onCreatePost", []);
		super.create();
		callScripts("onCreate", []);
	}

	override public function update(elapsed:Float):Void
	{
		callScripts("onUpdatePost", [elapsed]);
		super.update(elapsed);
		callScripts("onUpdate", [elapsed]);
	}

	override public function beatHit():Void
	{
		super.beatHit();
		callScripts("onBeatHit", []);
	}

	override public function stepHit():Void
	{
		super.stepHit();
		callScripts("onStepHit", []);
	}

	override public function sectionHit():Void
	{
		super.sectionHit();
		callScripts("onSectionHit", []);
	}

	override public function onFocus():Void
	{
		super.onFocus();
		callScripts("onFocus", []);
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
		callScripts("onFocusLost", []);
	}

	override public function destroy():Void
	{
		super.destroy();
		callScripts("onDestroy", []);
	}
}
