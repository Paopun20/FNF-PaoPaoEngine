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
import funkin.modding.scripts.utils.CacheScript.CacheParser;
import funkin.modding.scripts.utils.CacheScript.CacheType;
import funkin.modding.scripts.utils.CacheScript;
import funkin.modding.scripts.compatibility.StructureCompatibility;
import funkin.objects.NoteSplash;
import funkin.objects.StrumNote;
import funkin.backend.utils.NdllUtil;
import hscript.Expr.Error as HscriptError;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import hscript.Printer;
import hscript.Tools;
import flixel.FlxBasic;
import funkin.modding.scripts.ScriptPack;

using StringTools;

typedef StringMap<T> = Map<String, T>;

class HScript extends Script
{
	public static var printer:Printer = new Printer();
	public static var staticVariables:StringMap<Dynamic> = new StringMap<Dynamic>();
	public static var publicVariables:StringMap<Dynamic> = new StringMap<Dynamic>();

	public var interp:Interp;
	public var origin:Null<String>;
	public var returnValue:Dynamic;

	public var variables(get, never):StringMap<Dynamic>;

	public function get_variables()
		return interp.variables;

	#if MODS_ALLOWED
	public var modFolder:String = null;
	public var modName:String = null;
	#end

	public static function reset(clearCache:Bool = false)
	{
		CoolLog.info('Resetting HScript');
		staticVariables = new StringMap<Dynamic>();
		publicVariables = new StringMap<Dynamic>();

		if (clearCache)
			CacheScript.clear(CacheType.HSCRIPT);
	}

	// Error handlers

	private final function onError(e:HscriptError)
	{
		if (Std.isOfType(e, HscriptError))
		{
			CoolLog.error(Printer.errorToString(e), this.interp.posInfos());
		}
	}

	private final function onWarning(e:HscriptError)
	{
		if (Std.isOfType(e, HscriptError))
		{
			CoolLog.warning(Printer.errorToString(e), this.interp.posInfos());
		}
	}

	private final function onImportFailed(classPath:Array<String>, classAlias:Null<String>):Bool
	{
		var varName = (classAlias != null) ? classAlias : classPath[classPath.length - 1];
		var fullPath = classPath.join(".");
		var classObj = LuaUtils.resolveClass(fullPath);

		if (classObj != null)
		{
			set(varName, classObj);
			return true;
		}

		// hscriptDebugMode suppresses errors in favour of warnings during development
		if (get("hscriptDebugMode"))
		{
			CoolLog.warning('Import failed: $fullPath (alias: ${classAlias != null ? classAlias : "none"})', this.interp.posInfos());
			return true;
		}

		CoolLog.error('Import failed: $fullPath (alias: ${classAlias != null ? classAlias : "none"})', this.interp.posInfos());
		return false;
	}

	// Construction

	public override function new(?file:String = '', ?varsToBring:Any = null, ?parentInstance:Dynamic = null)
	{
		super(file);

		interp = new Interp();
		interp.allowStaticVariables = interp.allowPublicVariables = true;
		interp.errorHandler = onError;
		interp.importFailedCallback = onImportFailed;
		interp.publicVariables = publicVariables;
		interp.staticVariables = staticVariables;

		var activeState = FlxG.state.subState ?? FlxG.state;
		addExHScript(this.interp, LuaUtils.isPlayStateScript(activeState));

		this.scriptName = this.fileName;
		this.scriptName = "HxVM:" + this.scriptName;
		this.origin = file;

		#if MODS_ALLOWED
		resolveModFolder(file);
		#end

		Script.preset(this);
		preset(varsToBring);
	}

	#if MODS_ALLOWED
	private function resolveModFolder(file:String):Void
	{
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

	public override function execute()
	{
		if (origin == null || origin.length == 0)
			return;

		var scriptContent = loadScriptContent(origin);
		if (scriptContent == null)
			return;

		codeExecute(scriptContent);
		call('onCreate', []);
	}

	private function loadScriptContent(path:String):Null<String>
	{
		// If origin contains a newline it is already raw code, not a file path
		if (path.contains('\n'))
			return path;

		try
		{
			return File.getContent(path);
		}
		catch (e:Dynamic)
		{
			CoolLog.error('Failed to load script file: "$path"');
			return null;
		}
	}

	public function codeExecute(code:String):Dynamic
	{
		if (closed)
			return null;

		var cachedExpr = getOrParseExpr(code);
		returnValue = interp.execute(cachedExpr);
		return returnValue;
	}

	private function getOrParseExpr(code:String):Dynamic
	{
		var cacheKey = CacheScript.hashCode(#if MODS_ALLOWED modFolder + #end scriptName + code);

		if (CacheScript.exists(cacheKey, CacheType.HSCRIPT))
		{
			CoolLog.info('HScript reused AST for "$scriptName" ($cacheKey)');
			return CacheScript.get(cacheKey, CacheType.HSCRIPT);
		}

		var expr = CacheParser.parse(code, CacheType.HSCRIPT, this.scriptName);
		CacheScript.set(cacheKey, expr, CacheType.HSCRIPT);
		CoolLog.info('HScript parsed AST for "$scriptName" ($cacheKey)');
		return expr;
	}

	// Parent binding

	override function set_parent(parent:Dynamic):Dynamic
	{
		if (interp == null)
			return this;

		interp.scriptObject = parent;

		if (parent.variables != null)
			interp.publicVariables = parent.variables;

		for (fieldName in Reflect.fields(parent))
			this.set(fieldName, Reflect.field(parent, fieldName));

		// Re-apply object-dependent bindings now that scriptObject is set
		addExHScript(this.interp, LuaUtils.isPlayStateScript(FlxG.state.subState ?? FlxG.state));

		return this;
	}

	override function get_parent():Dynamic
		return interp.scriptObject;

	// PlayState and generic interp bindings

	public static function addExHScript(targetInterp:Interp, isPlayState:Bool = false)
	{
		if (targetInterp == null)
			return;

		if (isPlayState)
			registerPlayStateBindings(targetInterp);
		else
			registerGenericBindings(targetInterp);
	}

	private static function registerPlayStateBindings(targetInterp:Interp):Void
	{
		var ps = PlayState.instance;
		targetInterp.variables.set("game", ps);
		targetInterp.variables.set("add", buildPlayStateAddFn(ps));
		targetInterp.variables.set('insert', ps.insert);
		targetInterp.variables.set('remove', ps.remove);
		targetInterp.variables.set('addBehindGF', ps.addBehindGF);
		targetInterp.variables.set('addBehindDad', ps.addBehindDad);
		targetInterp.variables.set('addBehindBF', ps.addBehindBF);

		targetInterp.variables.set('setVar', function(name:String, value:Dynamic)
		{
			ps.variables.set(name, value);
			return value;
		});
		targetInterp.variables.set('getVar', function(name:String) return ps.variables.exists(name) ? ps.variables.get(name) : null);
		targetInterp.variables.set('removeVar', function(name:String):Bool
		{
			if (!ps.variables.exists(name))
				return false;
			ps.variables.remove(name);
			return true;
		});

		targetInterp.variables.set('customSubstate', CustomSubstate.instance);
		targetInterp.variables.set('customSubstateName', CustomSubstate.name);

		/* 
			for (field in Type.getInstanceFields(Type.getClass(ps)))
			{
				try
				{
					var obj = Reflect.getProperty(ps, field);
					if (Reflect.isObject(obj)){
						targetInterp.variables.set(field, obj);
					} else if (Reflect.isFunction(obj)) {
						if (!targetInterp.variables.exists(field)) {
							targetInterp.variables.set(field, obj);
						}
					}
				}
				catch (e:Dynamic)
				{
				}
		}*/
	}

	/**
	 * Inserts a display object below the topmost character group so that
	 * it renders behind characters by default.
	 */
	private static function buildPlayStateAddFn(ps:PlayState):(FlxBasic, ?Bool) -> Void
	{
		return function(basic:FlxBasic, ?frontOfChars:Bool = false)
		{
			if (frontOfChars)
			{
				ps.add(basic);
				return;
			}

			// Insert behind the frontmost character group
			var position = ps.members.indexOf(ps.gfGroup);
			if (ps.members.indexOf(ps.boyfriendGroup) < position)
				position = ps.members.indexOf(ps.boyfriendGroup);
			else if (ps.members.indexOf(ps.dadGroup) < position)
				position = ps.members.indexOf(ps.dadGroup);

			ps.insert(position, basic);
		};
	}

	private static function registerGenericBindings(targetInterp:Interp):Void
	{
		var scriptObj = targetInterp.scriptObject;

		// Guard: if the parent object isn't set yet, skip object-dependent bindings.
		// set_parent() will call this again once scriptObject is available.
		if (scriptObj == null)
			return;

		targetInterp.variables.set("game", scriptObj);
		targetInterp.variables.set('add', scriptObj.add);
		targetInterp.variables.set('insert', scriptObj.insert);
		targetInterp.variables.set('remove', scriptObj.remove);

		var vars:Dynamic = scriptObj.variables;
		if (vars == null)
			return;

		targetInterp.variables.set('setVar', function(name:String, value:Dynamic)
		{
			vars.set(name, value);
			return value;
		});
		targetInterp.variables.set('getVar', function(name:String) return vars.get(name));
		targetInterp.variables.set('removeVar', function(name:String):Bool
		{
			if (vars.get(name) == null)
				return false;
			vars.remove(name);
			return true;
		});
	}

	// Preset

	public function preset(?varsToBring:Any):Void
	{
		if (varsToBring != null)
		{
			for (fieldName in Reflect.fields(varsToBring))
				set(fieldName, Reflect.field(varsToBring, fieldName));
		}

		Script.preset(this);

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

	private function registerVarBindings():Void
	{
		set('setVar', function(name:String, value:Dynamic)
		{
			MusicBeatState.getVariables().set(name, value);
			return value;
		});
		set('getVar', function(name:String) return MusicBeatState.getVariables().exists(name) ? MusicBeatState.getVariables().get(name) : null);
	}

	private function registerKeyboardBindings():Void
	{
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
	private function resolveNoteKey(name:String, eventType:String):Bool
	{
		var controls = Controls.instance;
		name = name.toLowerCase();

		return switch ([name, eventType])
		{
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

	private function registerGamepadBindings():Void
	{
		set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		set('anyGamepadPressed', function(name:String) return FlxG.gamepads.anyPressed(name));
		set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

		set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			return controller != null ? controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK) : 0.0;
		});
		set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			return controller != null ? controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK) : 0.0;
		});
		set('gamepadJustPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			return controller != null && Reflect.getProperty(controller.justPressed, name) == true;
		});
		set('gamepadPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			return controller != null && Reflect.getProperty(controller.pressed, name) == true;
		});
		set('gamepadReleased', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			return controller != null && Reflect.getProperty(controller.justReleased, name) == true;
		});
	}

	private function registerGlobalCallback()
	{
		if (scriptPack != null)
		{
			// Register every scripts except this
			set("createGlobalCallback", function(name:String, func:Dynamic)
			{
				scriptPack.set(name, Reflect.makeVarArgs(function(args:Array<Dynamic>)
				{
					var functionRef = interp.variables.get(func);
					var result = Reflect.callMethod(null, functionRef, args);
					return result ?? LuaUtils.Function_Continue;
				}), [this]);
			});
		}
	}

	private function registerModSettingBinding():Void
	{
		set('getModSetting', function(saveTag:String, ?modName:String = null)
		{
			if (modName == null)
			{
				if (this.modFolder == null)
				{
					CoolLog.error('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', this.interp.posInfos());
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
		});
	}

	// Variable access

	public override function set(variable:String, data:Dynamic):Void
	{
		if (interp == null || closed)
			return;
		interp.variables.set(variable, data);
	}

	public override function get(variable:String):Dynamic
	{
		if (interp == null || closed)
			return null;
		return interp.variables.get(variable);
	}

	public override function hasFunction(funcName:String):Bool
	{
		if (interp == null || closed)
			return false;
		return interp.variables.exists(funcName) && Reflect.isFunction(interp.variables.get(funcName));
	}

	public override function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		if (closed)
			return LuaUtils.Function_Continue;

		if (args == null)
			args = [];

		try
		{
			var functionRef = interp.variables.get(func);
			if (functionRef == null || !Reflect.isFunction(functionRef))
				return LuaUtils.Function_Continue;

			var result = Reflect.callMethod(null, functionRef, args);
			return result ?? LuaUtils.Function_Continue;
		}
		catch (e:Dynamic)
		{
			var stack = haxe.CallStack.toString(haxe.CallStack.exceptionStack(true));
			CoolLog.error('HScript call error in $func: $e\n$stack');
		}

		return LuaUtils.Function_Continue;
	}

	// Lifecycle

	public override function stop():Void
	{
		if (closed)
			return;
		closed = true;
		interp = null;
		origin = null;
		super.stop();
	}

	public override function destroy():Void
	{
		stop();
		super.destroy();
	}
}

// FlxColor / FlxAxes / FlxText wrappers
// These thin wrappers expose Flixel's abstract types as plain Int/enum values
// so HScript can use them without needing access to Haxe abstract magic.

class CustomFlxColor
{
	public static var TRANSPARENT(default, null):Int = FlxColor.TRANSPARENT;
	public static var BLACK(default, null):Int = FlxColor.BLACK;
	public static var WHITE(default, null):Int = FlxColor.WHITE;
	public static var GRAY(default, null):Int = FlxColor.GRAY;
	public static var GREEN(default, null):Int = FlxColor.GREEN;
	public static var LIME(default, null):Int = FlxColor.LIME;
	public static var YELLOW(default, null):Int = FlxColor.YELLOW;
	public static var ORANGE(default, null):Int = FlxColor.ORANGE;
	public static var RED(default, null):Int = FlxColor.RED;
	public static var PURPLE(default, null):Int = FlxColor.PURPLE;
	public static var BLUE(default, null):Int = FlxColor.BLUE;
	public static var BROWN(default, null):Int = FlxColor.BROWN;
	public static var PINK(default, null):Int = FlxColor.PINK;
	public static var MAGENTA(default, null):Int = FlxColor.MAGENTA;
	public static var CYAN(default, null):Int = FlxColor.CYAN;

	public static function fromInt(value:Int):Int
		return cast FlxColor.fromInt(value);

	public static function fromRGB(r:Int, g:Int, b:Int, a:Int = 255):Int
		return cast FlxColor.fromRGB(r, g, b, a);

	public static function fromRGBFloat(r:Float, g:Float, b:Float, a:Float = 1):Int
		return cast FlxColor.fromRGBFloat(r, g, b, a);

	public static inline function fromCMYK(c:Float, m:Float, y:Float, k:Float, a:Float = 1):Int
		return cast FlxColor.fromCMYK(c, m, y, k, a);

	public static function fromHSB(hue:Float, sat:Float, brt:Float, alpha:Float = 1):Int
		return cast FlxColor.fromHSB(hue, sat, brt, alpha);

	public static function fromHSL(hue:Float, sat:Float, light:Float, alpha:Float = 1):Int
		return cast FlxColor.fromHSL(hue, sat, light, alpha);

	public static function fromString(str:String):Int
		return cast FlxColor.fromString(str);
}

class CustomFlxAxes
{
	public static var X(default, null):flixel.util.FlxAxes = flixel.util.FlxAxes.X;
	public static var Y(default, null):flixel.util.FlxAxes = flixel.util.FlxAxes.Y;
	public static var XY(default, null):flixel.util.FlxAxes = flixel.util.FlxAxes.XY;
}

class CustomFlxTextAlign
{
	public static var LEFT(default, null):flixel.text.FlxText.FlxTextAlign = flixel.text.FlxText.FlxTextAlign.LEFT;
	public static var CENTER(default, null):flixel.text.FlxText.FlxTextAlign = flixel.text.FlxText.FlxTextAlign.CENTER;
	public static var RIGHT(default, null):flixel.text.FlxText.FlxTextAlign = flixel.text.FlxText.FlxTextAlign.RIGHT;
	public static var JUSTIFY(default, null):flixel.text.FlxText.FlxTextAlign = flixel.text.FlxText.FlxTextAlign.JUSTIFY;
}

class CustomFlxTextBorderStyle
{
	public static var NONE(default, null):flixel.text.FlxText.FlxTextBorderStyle = flixel.text.FlxText.FlxTextBorderStyle.NONE;
	public static var SHADOW(default, null):flixel.text.FlxText.FlxTextBorderStyle = flixel.text.FlxText.FlxTextBorderStyle.SHADOW;
	public static var OUTLINE(default, null):flixel.text.FlxText.FlxTextBorderStyle = flixel.text.FlxText.FlxTextBorderStyle.OUTLINE;
	public static var OUTLINE_FAST(default, null):flixel.text.FlxText.FlxTextBorderStyle = flixel.text.FlxText.FlxTextBorderStyle.OUTLINE_FAST;
}

class CustomFlxPoint
{
	public static inline function get(x:Float = 0, y:Float = 0):flixel.math.FlxBasePoint
		return flixel.math.FlxPoint.get(x, y);

	public static inline function weak(x:Float = 0, y:Float = 0):flixel.math.FlxBasePoint
		return flixel.math.FlxPoint.weak(x, y);
}

// Bitmap cache wrappers

@:privateAccess(flixel.system.frontEnds.BitmapFrontEnd)
class BitmapFrontEndWrapper
{
	public static var instance(get, never):BitmapFrontEndWrapper;
	private static var _instance:BitmapFrontEndWrapper;

	static function get_instance():BitmapFrontEndWrapper
	{
		if (_instance == null)
			_instance = new BitmapFrontEndWrapper();
		return _instance;
	}

	public var _cache(get, never):CacheWrapper;

	private function new()
	{
	}

	function get__cache():CacheWrapper
		return new CacheWrapper(@:privateAccess FlxG.bitmap._cache);

	public function add(graphic:flixel.graphics.FlxGraphic, ?persistent:Bool = false, ?key:String):flixel.graphics.FlxGraphic
		return FlxG.bitmap.add(graphic, persistent, key);

	public function removeByKey(key:String):Void
		FlxG.bitmap.removeByKey(key);

	public function remove(graphic:flixel.graphics.FlxGraphic):Void
		FlxG.bitmap.remove(graphic);

	public function get(key:String):flixel.graphics.FlxGraphic
		return FlxG.bitmap.get(key);

	public function checkCache(key:String):Bool
		return FlxG.bitmap.checkCache(key);

	public function create(w:Int, h:Int, color:Int, ?unique:Bool = false, ?key:String):flixel.graphics.FlxGraphic
		return FlxG.bitmap.create(w, h, color, unique, key);

	public function reset():Void
		FlxG.bitmap.reset();

	public function clearCache():Void
		FlxG.bitmap.clearCache();

	public function clearUnused():Void
		FlxG.bitmap.clearUnused();
}

class CacheWrapper
{
	private var cache:Map<String, flixel.graphics.FlxGraphic>;

	public function new(cache:Map<String, flixel.graphics.FlxGraphic>)
		this.cache = cache;

	public function exists(key:String):Bool
		return cache.exists(key);

	public function get(key:String):flixel.graphics.FlxGraphic
		return cache.get(key);

	public function remove(key:String):Bool
		return cache.remove(key);

	public function set(key:String, value:flixel.graphics.FlxGraphic):Void
		cache.set(key, value);

	public function keys():Iterator<String>
		return cache.keys();

	public function count():Int
	{
		var total = 0;
		for (_ in cache.keys())
			total++;
		return total;
	}
}
#else
class HScript
{
}
#end

// HaxeBridge — shared runHaxeCode/runHaxeFunction/addHaxeLibrary logic
// Both HxLua and HxPy were identical bridges. This class holds the shared
// HScript instance and exposes the three callable functions so each binding
// only needs to wire them up.
#if HSCRIPT_ALLOWED
class HaxeBridge
{
	private var hscript:HScript = null;

	public function new()
	{
	}

	/**
	 * Executes raw Haxe code, optionally bringing in variables from the
	 * calling script's scope and then calling a named function.
	 */
	public function runHaxeCode(scriptPath:String, codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic
	{
		if (hscript == null)
			initializeHScript(scriptPath, codeToRun, varsToBring)
		else
			executeInExistingHScript(codeToRun);

		if (funcToRun == null)
			return hscript?.returnValue;

		var result = hscript?.call(funcToRun, funcArgs);
		return (result != null && result != LuaUtils.Function_Continue) ? result : hscript?.returnValue;
	}

	private function initializeHScript(scriptPath:String, code:String, varsToBring:Any):Void
	{
		CoolLog.info('Initializing Haxe interp for: "$scriptPath"');
		try
		{
			hscript = new HScript();
			hscript.scriptName = 'HxVM:${scriptPath}';
			if (varsToBring != null)
				for (fieldName in Reflect.fields(varsToBring))
					hscript.set(fieldName, Reflect.field(varsToBring, fieldName));
			hscript.returnValue = hscript.codeExecute(code);
		}
		catch (e:Dynamic)
		{
			CoolLog.error('HScript Error in $scriptPath: $e');
			hscript = null;
		}
	}

	private function executeInExistingHScript(code:String):Void
	{
		try
		{
			hscript.returnValue = hscript.codeExecute(code);
		}
		catch (e:Dynamic)
		{
			CoolLog.error('HScript Error: $e');
			hscript.returnValue = null;
		}
	}

	/** Calls a function that was defined in a previous runHaxeCode call. */
	public function runHaxeFunction(funcToRun:String, ?funcArgs:Array<Dynamic> = null):Dynamic
	{
		if (hscript == null)
		{
			CoolLog.error('runHaxeFunction: HScript is not initialized. Call runHaxeCode first.');
			return null;
		}
		return hscript.call(funcToRun, funcArgs);
	}

	/** Imports a Haxe class/enum into the HScript interpreter by its package path. */
	public function addHaxeLibrary(libName:String, ?libPackage:Null<String> = ''):Void
	{
		if (libName == null)
			libName = '';

		var prefix = (libPackage != null && libPackage.length > 0) ? libPackage + '.' : '';
		// resolveClass and resolveEnum return incompatible types (Class vs Enum),
		// so ?? cannot unify them — fall back with an explicit null check instead.
		var resolved:Dynamic = LuaUtils.resolveClass(prefix + libName);
		if (resolved == null)
			resolved = Type.resolveEnum(prefix + libName);

		if (hscript == null)
			hscript = new HScript();

		try
		{
			hscript.set(libName, resolved);
		}
		catch (e:Dynamic)
		{
			CoolLog.error('addHaxeLibrary error: $e');
		}
	}
}
#end

// Script-language bridges
#if (LUA_ALLOWED && HSCRIPT_ALLOWED)
class HxLua
{
	public static function implement(script:LuaScript):Void
	{
		var bridge = new HaxeBridge();
		script.set("runHaxeCode", function(code, ?vars, ?func, ?args) return bridge.runHaxeCode(script.scriptPath, code, vars, func, args));
		script.set("runHaxeFunction", function(func, ?args) return bridge.runHaxeFunction(func, args));
		script.set("addHaxeLibrary", function(lib, ?pkg) bridge.addHaxeLibrary(lib, pkg));
	}
}
#else
class HxLua
{
	public static function implement(?_:Dynamic):Void
	{
	}
}
#end

#if (PYTHON_ALLOWED && HSCRIPT_ALLOWED)
class HxPy
{
	public static function implement(script:Python):Void
	{
		var bridge = new HaxeBridge();
		script.set("runHaxeCode", function(code, ?vars, ?func, ?args) return bridge.runHaxeCode(script.scriptPath, code, vars, func, args));
		script.set("runHaxeFunction", function(func, ?args) return bridge.runHaxeFunction(func, args));
		script.set("addHaxeLibrary", function(lib, ?pkg) bridge.addHaxeLibrary(lib, pkg));
	}
}
#else
class HxPy
{
	public static function implement(?_:Dynamic):Void
	{
	}
}
#end
