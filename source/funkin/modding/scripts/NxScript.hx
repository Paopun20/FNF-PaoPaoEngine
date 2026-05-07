package funkin.modding.scripts;

/*
	NxScript - https://github.com/Kitsumizy/NxScript/

	NxScript is a bytecode-compiled scripting language that runs inside Haxe. You write .nx files, the library compiles them to bytecode at runtime, and a stack-based VM executes them. Hot-reloadable logic, no recompile, no nonsense.

	Built for games. Works for anything.
 */
import nx.script.Interpreter;

class NxScript extends Script {
	public var interp:Interpreter;

	override function set_parent(value:Dynamic):Dynamic {
		return null;
	}

	override function get_parent():Dynamic {
		return null;
	}

	public function new(path:String) {
		super(path);

		interp = new Interpreter();
		this.origin = path;
		Script.preset(this);
	}

	override function execute() {
		interp.run(scriptCode);
		call('onCreate', []);
	}

	override function call(funcName:String, ?args:Array<Dynamic>):Dynamic {
		var nxArgs = [];
		var arr = args ?? [];
		for (i in 0...arr.length)
			nxArgs[i] = interp.vm.haxeToValue(arr[i]);
		return interp.vm.valueToHaxe(interp.safeCall(funcName, nxArgs));
	}

	override function set(variable:String, value:Dynamic) {
		interp.globals.set(variable, interp.vm.haxeToValue(value));
	}

	override function get(variable:String):Dynamic {
		return interp.vm.valueToHaxe(interp.globals.get(variable));
	}

	override function hasFunction(funcName:String):Bool {
		return interp.vm.resolveCallable(funcName) != null;
	}
}
