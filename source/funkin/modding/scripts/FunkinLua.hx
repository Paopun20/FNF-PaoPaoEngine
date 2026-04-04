#if LUA_ALLOWED
package funkin.modding.scripts;

class FunkinLua extends LuaScript
{
	public var lua:Dynamic = null;
	public var camTarget:Dynamic = null;
	public var modFolder:String = null;

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static var lastCalledScript:FunkinLua = null;

	public function new(scriptName:String)
	{
		super(scriptName);
	}

	public function addLocalCallback(name:String, func:Dynamic)
	{
		callbacks.set(name, func);
	}

	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();
}
#end
