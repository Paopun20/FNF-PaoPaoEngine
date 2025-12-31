package psychlua;

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end
#if PYTHON_ALLOWED
import psychlua.Python;
#end

class ImplementUtils
{
	public static function make(interpreter:Dynamic):(String, Dynamic) -> Void
	{
		#if LUA_ALLOWED
		if (Std.isOfType(interpreter, FunkinLua))
		{
			var flua = cast(interpreter, FunkinLua);
			return function(name:String, value:Dynamic):Void
			{
				if (Reflect.isFunction(value))
				{
					Lua_helper.add_callback(flua.lua, name, value);
				}
				else
				{
					flua.set(name, value);
				}
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
			return function(name:String, value:Dynamic):Void
			{
				py.set(name, value);
			};
		}
		#end

		return function(name:String, value:Dynamic):Void
		{
		} // do nothing, yet
	}
}
