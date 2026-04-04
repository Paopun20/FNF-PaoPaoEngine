package funkin.modding.scripts.utils;

#if (LUA_ALLOWED || PYTHON_ALLOWED)
#if LUA_ALLOWED
import funkin.modding.scripts.LuaScript;
#end
#if PYTHON_ALLOWED
import funkin.modding.scripts.Python;
#end
#end
import funkin.states.PlayState;

class ImplementUtils
{
	public static function make(interpreter:Dynamic):(String, Dynamic) -> Null<Dynamic>
	{
		#if LUA_ALLOWED
		if (Std.isOfType(interpreter, LuaScript))
		{
			var ls = cast(interpreter, LuaScript);
			return function(name:String, value:Dynamic):Null<Dynamic>
			{
				ls.set(name, value);
				return null;
			};
		}
		#if (!PYTHON_ALLOWED)
		else
		#end
		#end
		#if (PYTHON_ALLOWED)
		if (Std.isOfType(interpreter, Python))
		{
			var py = cast(interpreter, Python);
			return function(name:String, value:Dynamic):Null<Dynamic>
			{
				py.set(name, value);
				return null;
			};
		}
		#end

		return function(name:String, value:Dynamic):Null<Dynamic>
		{
			return null;
		};
	}

	public static function addTextToDebug(text:String, color:Int):Void
	{
		PlayState.instance.addTextToDebug(text, color);
	}
}
