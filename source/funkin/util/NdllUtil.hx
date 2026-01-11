package funkin.util;

#if sys
import sys.FileSystem;
#end
import lime.app.Application;
import funkin.psychlua.LuaUtils;

@:keep
class NdllUtil
{
	public static var os(get, never):String;

	inline public static function get_os():String
	{
		return LuaUtils.getBuildTarget();
	}

	public static function getFunction(ndllPath:String, name:String, args:Int):Dynamic
	{
		#if NDLL_ALLOWED
		var func:Dynamic = _getNdllFunc(ndllPath, name, args);
		CoolLog.info('Loading ndll function "${name}" from "${ndllPath}".');

		return Reflect.makeVarArgs(function(a:Array<Dynamic>)
		{
			return backend.macros.MacroUtil.generateReflectionLike(25, "func", "a");
		});
		#else
		CoolLog.warning("Ndlls are not supported on this platform!");
		return noop;
		#end
	}

	#if NDLL_ALLOWED
	public static function _getNdllFunc(ndll:String, name:String, args:Int):Dynamic
	{
		if (!FileSystem.exists(ndll))
		{
			CoolLog.warning('getFunction: ndll "${ndll}" doesn\'t exist!');
			return noop;
		}
		var func = lime.system.CFFI.load('./${ndll}', name, args);
		if (func != null)
			return func;

		CoolLog.warning('getFunction: There was an error getting the ndll\'s functions! {ndll: ${ndll}, function: ${name}, argument count: ${args}}');
		return noop;
	}
	#end

	@:dox(hide) @:noCompletion static function noop()
	{
	}
}
