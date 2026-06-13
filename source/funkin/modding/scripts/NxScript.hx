package funkin.modding.scripts;

/*
	NxScript - https://github.com/Kitsumizy/NxScript/

	NxScript is a bytecode-compiled scripting language that runs inside Haxe. You write .nx files, the library compiles them to bytecode at runtime, and a stack-based VM executes them. Hot-reloadable logic, no recompile, no nonsense.

	Built for games. Works for anything.
 */
#if NXSCRIPT_ALLOWED
import nx.script.Interpreter;
import funkin.modding.scripts.components.*;
import funkin.modding.scripts.bridge.HxRuner;
#end

class NxScript extends Script implements IScriptExecutor {
	#if NXSCRIPT_ALLOWED
	public var interp:Interpreter;
	#end

	override function set_parent(value:Dynamic):Dynamic
		#if NXSCRIPT_ALLOWED
		return interp.parent = value;
		#else
		return null;
		#end

	override function get_parent():Dynamic
		#if NXSCRIPT_ALLOWED
		return interp.parent;
		#else
		return null;
		#end

	public function new(path:String) {
		super(path);

		#if NXSCRIPT_ALLOWED
		interp = new Interpreter();
		this.origin = path;
		#if DISCORD_ALLOWED DiscordClient.addCallbacks(this); #end
		#if ACHIEVEMENTS_ALLOWED Achievements.addCallbacks(this); #end
		#if TRANSLATIONS_ALLOWED Language.addCallbacks(this); #end
		HxRuner.implement(this);
		ReflectionFunctions.implement(this);
		TextFunctions.implement(this);
		ExtraFunctions.implement(this);
		CustomSubstate.implement(this);
		ShaderFunctions.implement(this);
		Script.preset(this);
		#end
	}

	override function execute() {
		#if NXSCRIPT_ALLOWED
		interp.run(scriptCode);
		#end
		call('onCreate', []);
	}

	override function call(funcName:String, ?args:Array<Dynamic>):Dynamic {
		#if NXSCRIPT_ALLOWED
		var nxArgs = [];
		var arr = args ?? [];
		for (i in 0...arr.length)
			nxArgs[i] = interp.vm.haxeToValue(arr[i]);
		return interp.vm.valueToHaxe(interp.safeCall(funcName, nxArgs));
		#else
		return null;
		#end
	}

	override function set(variable:String, value:Dynamic) {
		#if NXSCRIPT_ALLOWED
		interp.globals.set(variable, interp.vm.haxeToValue(value));
		#else
		return null;
		#end
	}

	override function get(variable:String):Dynamic {
		#if NXSCRIPT_ALLOWED
		return interp.vm.valueToHaxe(interp.globals.get(variable));
		#else
		return null;
		#end
	}

	override function hasFunction(funcName:String):Bool {
		#if NXSCRIPT_ALLOWED
		return interp.vm.resolveCallable(funcName) != null;
		#else
		return false;
		#end
	}
}
