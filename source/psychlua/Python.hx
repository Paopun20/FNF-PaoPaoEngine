package psychlua;

#if HYTHON_ALLOWED
import paopao.hython.Parser as PyParser;
import paopao.hython.Interp as PyInterp;
#if LUA_ALLOWED
import psychlua.FunkinLua;
#end
import flixel.FlxBasic;
import objects.Character;
import psychlua.LuaUtils;
import psychlua.CustomSubstate;
#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

class Python
{
	public var parser:PyParser;
	public var interp:PyInterp;

	public var filePath:String;
	public var returnValue:Dynamic;

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	#end

	public function new(?parent:Dynamic, ?code:String = '', ?varsToBring:Any = null, ?manualRun:Bool = false)
	{
		parser = new PyParser();
		interp = new PyInterp();

		#if LUA_ALLOWED
		parentLua = parent;
		#end

		preset(varsToBring);

		if (!manualRun && code != null && code.length > 0)
		{
			try
			{
				execute(code);
			}
			catch (e)
			{
				trace('[Python] Runtime error: ' + e);
				returnValue = null;
			}
		}
	}

	// Execute python-like code
	public function execute(code:String):Bool
	{
		var expr = parser.parseString(code);
		returnValue = interp.execute(expr);
		if (returnValue == null)
		{
			returnValue = false;
		}
		else
		{
			returnValue = true;
		}
		return returnValue;
	}

	// Call python function
	public function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		if (!exists(func))
		{
			PlayState.instance.addTextToDebug("Python: No function named: " + func, FlxColor.RED);
			return null;
		}
		return interp.calldef(func, args ?? []);
	}

	public function exists(func:String):Bool
	{
		return interp.getdef(func) != null;
	}

	// Inject variables / API
	function preset(varsToBring:Any)
	{
		// bring variables from Lua / Haxe
		if (varsToBring != null)
		{
			for (k in Reflect.fields(varsToBring))
			{
				interp.setVar(k, Reflect.field(varsToBring, k));
			}
		}

		#if LUA_ALLOWED
		interp.setVar("parentLua", parentLua);
		#end

		interp.setVar('Type', Type);
		#if sys
		interp.setVar('File', File);
		interp.setVar('FileSystem', FileSystem);
		#end
		interp.setVar('FlxG', flixel.FlxG);
		interp.setVar('FlxMath', flixel.math.FlxMath);
		interp.setVar('FlxSprite', flixel.FlxSprite);
		interp.setVar('FlxText', flixel.text.FlxText);
		interp.setVar('FlxCamera', flixel.FlxCamera);
		interp.setVar('PsychCamera', backend.PsychCamera);
		interp.setVar('FlxTimer', flixel.util.FlxTimer);
		interp.setVar('FlxTween', flixel.tweens.FlxTween);
		interp.setVar('FlxEase', flixel.tweens.FlxEase);
		interp.setVar('Countdown', backend.BaseStage.Countdown);
		interp.setVar('PlayState', PlayState);
		interp.setVar('Paths', Paths);
		interp.setVar('Conductor', Conductor);
		interp.setVar('ClientPrefs', ClientPrefs);
		#if ACHIEVEMENTS_ALLOWED
		interp.setVar('Achievements', Achievements);
		#end
		interp.setVar('Character', Character);
		interp.setVar('Alphabet', Alphabet);
		interp.setVar('Note', objects.Note);
		interp.setVar('CustomSubstate', CustomSubstate);
		#if (!flash && sys)
		interp.setVar('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		interp.setVar('ErrorHandledRuntimeShader', shaders.ErrorHandledShader.ErrorHandledRuntimeShader);
		#end
		interp.setVar('ShaderFilter', openfl.filters.ShaderFilter);
		interp.setVar('StringTools', StringTools);
		#if flxanimate
		interp.setVar('FlxAnimate', FlxAnimate);
		#end

		// Functions & Variables
		interp.setVar('setVar', function(name:String, value:Dynamic)
		{
			MusicBeatState.getVariables().set(name, value);
			return value;
		});
		interp.setVar('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if (MusicBeatState.getVariables().exists(name))
				result = MusicBeatState.getVariables().get(name);
			return result;
		});
		interp.setVar('removeVar', function(name:String)
		{
			if (MusicBeatState.getVariables().exists(name))
			{
				MusicBeatState.getVariables().remove(name);
				return true;
			}
			return false;
		});
		interp.setVar('debugPrint', function(text:String, ?color:FlxColor = null)
		{
			if (color == null)
				color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});
	}

	public function destroy()
	{
		parser = null;
		interp = null;
		returnValue = null;
		#if LUA_ALLOWED parentLua = null; #end
	}
}
#else
// Fallback version if Python is not allowed
class Python
{
	public function new()
	{
		trace("[Python] Python is not allowed on this platform!");
		PlayState.instance.addTextToDebug("Python: Python is not allowed on this platform!");
	}

	public function execute(code:String):Dynamic
	{
		trace("[Python] Python is not allowed on this platform!");
		PlayState.instance.addTextToDebug("Python: Python is not allowed on this platform!");
		return null;
	}

	public function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		trace("[Python] Python is not allowed on this platform!");
		return null;
	}

	public function destroy()
	{
		PlayState.instance.addTextToDebug("Python: Python is not allowed on this platform!");
		trace("[Python] Python is not allowed on this platform!");
	}
}
#end
