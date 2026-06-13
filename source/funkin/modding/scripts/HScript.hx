package funkin.modding.scripts;

import funkin.modding.scripts.components.*;
import funkin.modding.scripts.utils.LuaUtils;
import funkin.objects.Character;
import funkin.backend.utils.PlatformDex;
#if LUA_ALLOWED
import funkin.modding.scripts.LuaScript;
#end
#if PYTHON_ALLOWED
import funkin.modding.scripts.Python;
#end
#if HSCRIPT_ALLOWED
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import funkin.modding.scripts.compatibility.StructureCompatibility;
import funkin.objects.NoteSplash;
import funkin.objects.StrumNote;
import funkin.backend.utils.NdllUtil;
import hscript.SScript;
import flixel.FlxBasic;
import funkin.modding.scripts.ScriptPack;

using StringTools;

typedef StringMap<T> = Map<String, T>;

class HScript extends Script implements IScriptExecutor {
	/**
	 * Variables that survive a full `reset()` call and are propagated into every
	 * new script instance on construction.  These are distinct from
	 * `SScript.globalVariables`, which is the built-in cross-instance shared map
	 * (our former `publicVariables`).
	 */
	public static var staticVariables:StringMap<Dynamic> = new StringMap<Dynamic>();

	public var script:SScript;
	public var returnValue:Dynamic;

	public var variables(get, never):StringMap<Dynamic>;

	public function get_variables()
		return script.variables;

	#if MODS_ALLOWED
	public var modFolder:String = null;
	public var modName:String = null;
	#end

	public static function reset(clearCache:Bool = false) {
		CoolLog.info('Resetting HScript');
		staticVariables = new StringMap<Dynamic>();
		SScript.globalVariables.clear();
	}

	// Construction

	public override function new(?file:String = '', ?varsToBring:Any = null, ?parentInstance:Dynamic = null) {
		super(file);

		// Create an empty SScript; the file/code is loaded later in execute() / codeExecute()
		// so that all variable presets are applied before the script body runs.
		script = new SScript();

		this.scriptName = this.fileName;
		if (this.scriptName != null && this.scriptName.length > 0)
			this.scriptName = "HxVM:" + this.scriptName;
		else
			this.scriptName = "HxVM:<inline>";
		this.origin = file;

		#if MODS_ALLOWED
		resolveModFolder(file);
		#end

		// Propagate truly-static values into this instance.
		for (key => value in staticVariables)
			script.set(key, value);

		Script.preset(this);
		preset(varsToBring);
	}

	#if MODS_ALLOWED
	private function resolveModFolder(file:String):Void {
		if (file == null || file.length == 0)
			return;

		var parts = file.split('/');
		var isModFile = parts[0] + '/' == Paths.mods()
			&& (Mods.currentModDirectory == parts[1] || Mods.getGlobalMods().contains(parts[1]));

		if (isModFile)
			this.modFolder = parts[1];
	}
	#end

	// Execution

	public override function execute() {
		if (origin == null || origin.length == 0)
			return;

		var scriptContent = loadScriptContent(origin);
		if (scriptContent == null)
			return;

		codeExecute(scriptContent);
		call('onCreate', []);
	}

	private function loadScriptContent(path:String):Null<String> {
		// If the string already contains a newline it is raw code, not a file path.
		if (path.contains('\n'))
			return path;

		try {
			return File.getContent(path);
		} catch (e:Dynamic) {
			CoolLog.error('Failed to load script file: "$path"');
			return null;
		}
	}

	public function codeExecute(code:String):Dynamic {
		if (closed)
			return null;

		try {
			script.doString(code);
		} catch (e:Dynamic) {
			CoolLog.error('HScript execute error in "$scriptName": $e');
			return null;
		}

		if (script.parsingException != null)
			CoolLog.error('HScript parse/execute error in "$scriptName": ${Std.string(script.parsingException)}');
		returnValue = null;
		return returnValue;
	}

	// Parent binding
	override function set_parent(parent:Dynamic):Dynamic {
		script.setSpecialObject(parent);
		return this;
	}

	override function get_parent():Dynamic
		return parent;

	// Preset

	public function preset(?varsToBring:Any):Void {
		if (varsToBring != null) {
			for (fieldName in Reflect.fields(varsToBring))
				set(fieldName, Reflect.field(varsToBring, fieldName));
		}

		Script.preset(this);

		if (PlayState.instance != null) {
			set("game", PlayState.instance);
			set("add", PlayState.instance.add);
			set('insert', PlayState.instance.insert);
			set('remove', PlayState.instance.remove);
			set('addBehindGF', PlayState.instance.addBehindGF);
			set('addBehindDad', PlayState.instance.addBehindDad);
			set('addBehindBF', PlayState.instance.addBehindBF);
		} else {
			var ps = FlxG.state;

			set("game", ps);
			set("add", ps.add);
			set('insert', ps.insert);
			set('remove', ps.remove);
		}

		set('setVar', function(name:String, value:Dynamic) {
			MusicBeatState.getVariables().set(name, value);
			return value;
		});

		set('getVar', function(name:String) return MusicBeatState.getVariables().exists(name) ? MusicBeatState.getVariables().get(name) : null);
		set('removeVar', function(name:String):Bool {
			if (MusicBeatState.getVariables().get(name) == null)
				return false;
			MusicBeatState.getVariables().remove(name);
			return true;
		});

		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('version', funkin.states.MainMenuState.psychEngineVersion.trim());
		set('buildTarget', LuaUtils.getBuildTarget());
		set("PlatformDex", PlatformDex);
		set("NdllUtil", NdllUtil);
		set('debugPrint', function(text:String, ?color:FlxColor = null) CoolLog.info(text));

		registerVarBindings();
		registerKeyboardBindings();
		registerGamepadBindings();
		registerModSettingBinding();
	}

	private function registerVarBindings():Void {
		set('setVar', function(name:String, value:Dynamic) {
			MusicBeatState.getVariables().set(name, value);
			return value;
		});
		set('getVar', function(name:String) return MusicBeatState.getVariables().exists(name) ? MusicBeatState.getVariables().get(name) : null);
	}

	private function registerKeyboardBindings():Void {
		set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		set('keyJustPressed', function(name:String = '') return resolveNoteKey(name, 'justPressed'));
		set('keyPressed', function(name:String = '') return resolveNoteKey(name, 'pressed'));
		set('keyReleased', function(name:String = '') return resolveNoteKey(name, 'released'));
	}

	/**
	 * Maps arrow-key names to their Controls counterparts, falling back to
	 * the generic Controls query for anything else.
	 */
	private function resolveNoteKey(name:String, eventType:String):Bool {
		var controls = Controls.instance;
		name = name.toLowerCase();

		return switch ([name, eventType]) {
			case ['left', 'justPressed']: controls.NOTE_LEFT_P;
			case ['down', 'justPressed']: controls.NOTE_DOWN_P;
			case ['up', 'justPressed']: controls.NOTE_UP_P;
			case ['right', 'justPressed']: controls.NOTE_RIGHT_P;
			case ['left', 'pressed']: controls.NOTE_LEFT;
			case ['down', 'pressed']: controls.NOTE_DOWN;
			case ['up', 'pressed']: controls.NOTE_UP;
			case ['right', 'pressed']: controls.NOTE_RIGHT;
			case ['left', 'released']: controls.NOTE_LEFT_R;
			case ['down', 'released']: controls.NOTE_DOWN_R;
			case ['up', 'released']: controls.NOTE_UP_R;
			case ['right', 'released']: controls.NOTE_RIGHT_R;
			case [_, 'justPressed']: controls.justPressed(name);
			case [_, 'pressed']: controls.pressed(name);
			case [_, 'released']: controls.justReleased(name);
			default: false;
		}
	}

	private function registerGamepadBindings():Void {
		set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		set('anyGamepadPressed', function(name:String) return FlxG.gamepads.anyPressed(name));
		set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

		set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true) {
			var controller = FlxG.gamepads.getByID(id);
			return controller != null ? controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK) : 0.0;
		});
		set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true) {
			var controller = FlxG.gamepads.getByID(id);
			return controller != null ? controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK) : 0.0;
		});
		set('gamepadJustPressed', function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			return controller != null && Reflect.getProperty(controller.justPressed, name) == true;
		});
		set('gamepadPressed', function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			return controller != null && Reflect.getProperty(controller.pressed, name) == true;
		});
		set('gamepadReleased', function(id:Int, name:String) {
			var controller = FlxG.gamepads.getByID(id);
			return controller != null && Reflect.getProperty(controller.justReleased, name) == true;
		});
	}

	private function registerGlobalCallback() {
		if (scriptPack != null) {
			// Register every script except this one.
			set("createGlobalCallback", function(name:String, func:String) {
				scriptPack.set(name, Reflect.makeVarArgs(function(args:Array<Dynamic>) {
					if (!hasFunction(func))
						return LuaUtils.Function_Continue;
					// Use SScript's call() so errors are caught and surfaced cleanly.
					var callResult = script.call(func, args);
					return callResult.returnValue ?? LuaUtils.Function_Continue;
				}), [this]);
			});
		}
	}

	private function registerModSettingBinding():Void {
		set('getModSetting', function(saveTag:String, ?modName:String = null) {
			if (modName == null) {
				if (this.modFolder == null) {
					CoolLog.error('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!');
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
		});
	}

	// Variable access

	public override function set(variable:String, data:Dynamic):Void {
		if (script == null || closed)
			return;
		script.set(variable, data);
	}

	public override function get(variable:String):Dynamic {
		if (script == null || closed)
			return null;
		return script.variables.get(variable);
	}

	public override function hasFunction(funcName:String):Bool {
		if (script == null || closed)
			return false;
		return script.variables.exists(funcName) && Reflect.isFunction(script.variables.get(funcName));
	}

	public override function call(func:String, ?args:Array<Dynamic>):Dynamic {
		if (closed)
			return LuaUtils.Function_Continue;

		if (args == null)
			args = [];

		if (!hasFunction(func))
			return LuaUtils.Function_Continue;

		try {
			var callResult = script.call(func, args);

			if (callResult.exceptions != null && callResult.exceptions.length > 0) {
				var stack = haxe.CallStack.toString(haxe.CallStack.exceptionStack(true));
				CoolLog.error('HScript call error in $func: ${callResult.exceptions[0]}\n$stack');
			}

			returnValue = callResult.returnValue;
			return returnValue ?? LuaUtils.Function_Continue;
		} catch (e:Dynamic) {
			var stack = haxe.CallStack.toString(haxe.CallStack.exceptionStack(true));
			CoolLog.error('HScript call error in $func: $e\n$stack');
		}

		return LuaUtils.Function_Continue;
	}

	// Lifecycle

	public override function destroy():Void {
		if (closed)
			return;
		closed = true;
		script = null;
		origin = null;
		super.destroy();
	}
}
#else
class HScript {}
#end
