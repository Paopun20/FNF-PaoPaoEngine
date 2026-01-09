package funkin.psychlua;
#if (LUA_ALLOWED || PYTHON_ALLOWED)
#if LUA_ALLOWED
import funkin.psychlua.FunkinLua;
#end
#if PYTHON_ALLOWED
import funkin.psychlua.Python;
#end
#end
class ImplementUtils
{
    public static function make(interpreter:Dynamic): (String, Dynamic) -> Null<Dynamic>
	{
		#if LUA_ALLOWED
		if (Std.isOfType(interpreter, FunkinLua))
		{
			var flua = cast(interpreter, FunkinLua);
			return function(name:String, value:Dynamic):Null<Dynamic>
			{
				if (Reflect.isFunction(value))
				{
					Lua_helper.add_callback(flua.lua, name, value);
				}
				else
				{
					flua.set(name, value);
				}
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
}