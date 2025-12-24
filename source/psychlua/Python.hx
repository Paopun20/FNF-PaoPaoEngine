package psychlua;

#if PYTHON_ALLOWED
import objects.Character;
import paopao.hython.Interp as PyInterp;
import paopao.hython.Parser as PyParser;
import psychlua.CustomSubstate;
#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

class Python
{
	public var parser:PyParser;
	public var interp:PyInterp;

	public var origin:String;
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
		    }
		}
	}

	// Execute python-like code
	public function execute(code:String):Dynamic
	{   
		var expr = parser.parseString(code);
		returnValue = interp.execute(expr);
		return returnValue;
	}

	// Call python function
	public function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		if (args == null)
			args = [];
		if (exists(func))
		{
			return interp.calldef(func, args);
		}
		return null;
	}

	public function exists(func:String):Bool // it have is be true // if not exists be false
	{
		return interp.getdef(func);
	}

	public function set(variable:String, arg:Dynamic)
	{
		interp.setVar(variable, arg);
	}

	// Inject variables / API
	function preset(varsToBring:Any)
	{
		// bring variables from Lua / Haxe
		if (varsToBring != null)
		{
			for (k in Reflect.fields(varsToBring))
			{
				set(k, Reflect.field(varsToBring, k));
			}
		}

		#if LUA_ALLOWED
		set("parentLua", parentLua);
		#end

		set('Type', Type);
		#if sys
		set('File', File);
		set('FileSystem', FileSystem);
		#end
		set('FlxG', flixel.FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxText', flixel.text.FlxText);
		set('FlxCamera', flixel.FlxCamera);
		set('PsychCamera', backend.PsychCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('Countdown', backend.BaseStage.Countdown);
		set('PlayState', PlayState);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		#if ACHIEVEMENTS_ALLOWED
		set('Achievements', Achievements);
		#end
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Note', objects.Note);
		set('CustomSubstate', CustomSubstate);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		set('ErrorHandledRuntimeShader', shaders.ErrorHandledShader.ErrorHandledRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('StringTools', StringTools);
		#if flxanimate
		set('FlxAnimate', FlxAnimate);
		#end

		// Functions & Variables
		set('setVar', function(name:String, value:Dynamic)
		{
			MusicBeatState.getVariables().set(name, value);
			return value;
		});
		set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if (MusicBeatState.getVariables().exists(name))
				result = MusicBeatState.getVariables().get(name);
			return result;
		});
		set('removeVar', function(name:String)
		{
			if (MusicBeatState.getVariables().exists(name))
			{
				MusicBeatState.getVariables().remove(name);
				return true;
			}
			return false;
		});
		set('debugPrint', function(text:String, ?color:FlxColor = null)
		{
			if (color == null)
				color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});
	}

	public function stop()
	{
		if (interp != null)
		{
			interp.stop();
			interp = null;
		}
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
		PlayState.instance.addTextToDebug("Python: Python is not allowed on this platform!", FlxColor.RED);
	}

	public function execute(code:String):Dynamic
	{
		trace("[Python] Python is not allowed on this platform!");
		PlayState.instance.addTextToDebug("Python: Python is not allowed on this platform!", FlxColor.RED);
		return null;
	}

	public function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		trace("[Python] Python is not allowed on this platform!");
		return null;
	}

	public function destroy()
	{
		PlayState.instance.addTextToDebug("Python: Python is not allowed on this platform!", FlxColor.RED);
		trace("[Python] Python is not allowed on this platform!");
	}
}
#end
