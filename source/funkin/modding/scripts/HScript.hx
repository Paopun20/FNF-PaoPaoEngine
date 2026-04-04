package funkin.modding.scripts;

import funkin.modding.scripts.components.*;
import funkin.modding.scripts.utils.LuaUtils;
import funkin.objects.Character;
import funkin.utils.PlatformDex;
#if LUA_ALLOWED
import funkin.modding.scripts.LuaScript;
#end
#if PYTHON_ALLOWED
import funkin.modding.scripts.Python;
#end
#if HSCRIPT_ALLOWED
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import funkin.modding.scripts.CacheScript.CacheParser;
import funkin.modding.scripts.CacheScript.CacheType;
import funkin.modding.scripts.CacheScript;
import funkin.modding.scripts.compatibility.StructureCompatibility;
import funkin.objects.NoteSplash;
import funkin.objects.StrumNote;
import funkin.utils.NdllUtil;
import hscript.Expr.Error as HscriptError;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import hscript.Printer;
import hscript.Tools;
import flixel.FlxBasic;

using StringTools;

typedef StringMap<T> = Map<String, T>; // for this file only

interface IHscriptInterface
{
	public var scriptName:String;
	public function set(variable:String, data:Dynamic):Void;
	public function call(func:String, ?args:Array<Dynamic>):Dynamic;
	public function stop():Void;
}

class HScript extends Script
{
	public static var printer:Printer = new Printer();
	public static var staticVariables:StringMap<Dynamic> = new StringMap<Dynamic>();
	public static var publicVariables:StringMap<Dynamic> = new StringMap<Dynamic>();

	public var interp:Interp;
	public var origin:Null<String>;
	public var scriptName:String;
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

	private final function onError(e:HscriptError)
	{
		if (Std.isOfType(e, HscriptError))
		{
			if (PlayState.instance != null)
			{
				PlayState.instance.addTextToDebug('[ERROR]: ${scriptName} - ' + Printer.errorToString(e), FlxColor.RED);
			}
			else
			{
				CoolLog.error('HScript ${scriptName}: ' + Printer.errorToString(e));
			}
		}
	}

	private final function onWarning(e:HscriptError)
	{
		if (Std.isOfType(e, HscriptError))
		{
			if (PlayState.instance != null)
			{
				PlayState.instance.addTextToDebug('[WARNING]: ${scriptName} - ' + Printer.errorToString(e), FlxColor.YELLOW);
			}
			else
			{
				CoolLog.warning('HScript ${scriptName}: ' + Printer.errorToString(e));
			}
		}
	}

	static function resolveClass(className:String):Class<Dynamic>
	{
		return StructureCompatibility.resolveClass(className);
	}

	private final function onImportFailed(classPath:Array<String>, classAlias:Null<String>):Bool
	{
		var varName = (classAlias != null) ? classAlias : classPath[classPath.length - 1];
		var fullPath = classPath.join(".");
		var classObj = resolveClass(fullPath);
		if (classObj != null)
		{
			set(varName, classObj);
			return true;
		}
		if (get("hscriptDebugMode"))
		{
			PlayState.instance.addTextToDebug('[DEBUG] Import failed: $fullPath (alias: ${classAlias != null ? classAlias : "none"})', FlxColor.YELLOW);
			PlayState.instance.addTextToDebug('[DEBUG] Attempted to resolve as: $varName', FlxColor.YELLOW);
			return true;
		}
		return false;
	}

	public function new(?_:String = "", ?file:String = '', ?varsToBring:Any = null, ?parentInstance:Dynamic = null)
	{
		super(file);

		interp = new Interp();
		interp.printCallStack = true;
		interp.allowStaticVariables = interp.allowPublicVariables = true;
		interp.errorHandler = onError;
		interp.importFailedCallback = onImportFailed;
		interp.publicVariables = publicVariables;
		interp.staticVariables = staticVariables;
		interp.variables.set("this", this);
		this.setParent((parentInstance != null ? parentInstance : LuaUtils.getHScriptScriptObject()));
		addExHScript(this.interp, LuaUtils.isPlayStateScript(interp.scriptObject));

		this.scriptName = this.fileName;
		this.origin = file;

		#if MODS_ALLOWED
		if (file != null && file.length > 0)
		{
			var myFolder:Array<String> = file.split('/');
			if (myFolder[0] + '/' == Paths.mods()
				&& (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1])))
				this.modFolder = myFolder[1];
		}
		#end

		Script.preset(this);
		preset(varsToBring);

		if (file != null && file.length > 0)
		{
			var scriptContent:String = file;
			if (!file.contains('\n'))
			{
				// It's a file path
				try
				{
					scriptContent = File.getContent(file);
				}
				catch (e:Dynamic)
				{
					CoolLog.error('Failed to load script IO file: "${file}"');
					return;
				}
			}

			execute(scriptContent);
			call('onCreate', []);
		}
	}

	public override function execute(code:String):Dynamic
	{
		if (closed)
			return null;

		var cachedExpr:Dynamic;
		var cacheKey:String = CacheScript.hashCode(#if MODS_ALLOWED modFolder + #end scriptName + code);
		if (!(CacheScript.exists(cacheKey, CacheType.HSCRIPT)))
		{
			cachedExpr = CacheParser.parse(code, CacheType.HSCRIPT);
			CacheScript.set(cacheKey, cachedExpr, CacheType.HSCRIPT);
			CoolLog.info('HScript parsed AST for "${scriptName}" (${cacheKey})');
		}
		else
		{
			cachedExpr = CacheScript.get(cacheKey, CacheType.HSCRIPT);
			CoolLog.info('HScript reused AST for "${scriptName}" (${cacheKey})');
		}

		try
		{
			returnValue = interp.execute(cachedExpr);
		}
		catch (e:Dynamic)
		{
			CoolLog.error('HScript execution error in "' + scriptName + '": ' + e);
			returnValue = null;
		}
		cacheKey = cachedExpr = null;
		return returnValue;
	}

	public function setParent(parent:Dynamic)
	{
		if (interp != null)
		{
			interp.scriptObject = parent;
			if (parent.variables != null)
				interp.publicVariables = parent.variables;
		}
		return this;
	}

	public static function addExHScript(obj:Interp, isPlayState:Bool = false)
	{
		if (obj == null)
			return;

		if (isPlayState)
		{
			obj.variables.set("game", PlayState.instance);
			obj.variables.set("add", function(basic:FlxBasic, ?frontOfChars:Bool = false)
			{
				if (frontOfChars)
				{
					PlayState.instance.add(basic);
					return;
				}

				var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
				if (PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
					position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
				else if (PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
					position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);

				PlayState.instance.insert(position, basic);
			});

			obj.variables.set('insert', PlayState.instance.insert);
			obj.variables.set('remove', PlayState.instance.remove);
			obj.variables.set('addBehindGF', PlayState.instance.addBehindGF);
			obj.variables.set('addBehindDad', PlayState.instance.addBehindDad);
			obj.variables.set('addBehindBF', PlayState.instance.addBehindBF);
			obj.variables.set('setVar', function(name:String, value:Dynamic)
			{
				PlayState.instance.variables.set(name, value);
				return value;
			});
			obj.variables.set('getVar', function(name:String)
			{
				var result:Dynamic = null;
				if (PlayState.instance.variables.exists(name))
					result = PlayState.instance.variables.get(name);
				return result;
			});
			obj.variables.set('removeVar', function(name:String)
			{
				if (PlayState.instance.variables.exists(name))
				{
					PlayState.instance.variables.remove(name);
					return true;
				}
				return false;
			});

			obj.variables.set('customSubstate', CustomSubstate.instance);
			obj.variables.set('customSubstateName', CustomSubstate.name);
		}
		else
		{
			obj.variables.set("game", obj.scriptObject);
			obj.variables.set('add', obj.scriptObject.add);
			obj.variables.set('insert', obj.scriptObject.insert);
			obj.variables.set('remove', obj.scriptObject.remove);

			if (obj.scriptObject.variables != null)
			{
				obj.variables.set('setVar', function(name:String, value:Dynamic)
				{
					obj.scriptObject.variables.set(name, value);
					return value;
				});
				obj.variables.set('getVar', function(name:String)
				{
					var result:Dynamic = null;
					if (obj.scriptObject.variables.get(name) != null)
						result = obj.scriptObject.variables.get(name);
					return result;
				});
				obj.variables.set('removeVar', function(name:String)
				{
					if (obj.scriptObject.variables.get(name) != null)
					{
						obj.scriptObject.variables.remove(name);
						return true;
					}
					return false;
				});
			}
		}
	}

	public function preset(?varsToBring:Any):Void
	{
		// Bring variables from Lua / Haxe
		if (varsToBring != null)
		{
			for (k in Reflect.fields(varsToBring))
				set(k, Reflect.field(varsToBring, k));
		}

		Script.preset(this);

		// Core Haxe Classes
		set('Type', Type);
		set('Math', Math);
		set('Std', Std);
		set('StringTools', StringTools);
		#if sys
		set('File', File);
		set('FileSystem', FileSystem);
		#end

		// Flixel Classes
		set('FlxG', FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxText', flixel.text.FlxText);
		set('FlxCamera', flixel.FlxCamera);
		set('PsychCamera', funkin.objects.PsychCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', {
			tween: function(obj:Dynamic, props:Dynamic, duration:Float, ?options:Dynamic)
			{
				if (obj == null)
					return null;
				for (field in Reflect.fields(props))
					if (Reflect.getProperty(obj, field) == null)
						CoolLog.warning('FlxTween.tween: "$field" not found on $obj');
				return FlxTween.tween(obj, props, duration, options);
			},
			num: FlxTween.num,
			color: FlxTween.color,
			angle: FlxTween.angle,
			shake: FlxTween.shake,
			cancelTweensOf: FlxTween.cancelTweensOf,
			completeTweensOf: FlxTween.completeTweensOf,
			globalManager: FlxTween.globalManager
		});
		set('FlxEase', FlxEase);
		set('FlxSound', FlxSound);
		set('FlxStreamSound', FlxStreamSound);

		// Game Classes
		set('Countdown', funkin.backend.BaseStage.Countdown);
		set('PlayState', PlayState);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		set('Difficulty', Difficulty);
		set('CoolUtil', CoolUtil);
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Note', funkin.objects.Note);
		set('StrumNote', StrumNote);
		set('NoteSplash', NoteSplash);
		set('CustomSubstate', CustomSubstate);
		set('ModchartSprite', ModchartSprite);

		#if ACHIEVEMENTS_ALLOWED
		set('Achievements', Achievements);
		#end

		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		set('ErrorHandledRuntimeShader', funkin.shaders.ErrorHandledShader.ErrorHandledRuntimeShader);
		#end

		set('ShaderFilter', openfl.filters.ShaderFilter);

		#if flxanimate
		set('FlxAnimate', FlxAnimate);
		#end

		// Function control constants
		set('Function_StopLua', LuaUtils.Function_StopLua);
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopPython', LuaUtils.Function_StopPython);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);

		// Debug settings
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);

		// Version info
		set('version', funkin.states.MainMenuState.psychEngineVersion.trim());

		set("PlatformDex", PlatformDex);
		set("NdllUtil", NdllUtil);

		// Keyboard & Gamepads
		set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		set('anyGamepadPressed', function(name:String) return FlxG.gamepads.anyPressed(name));
		set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

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

		set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadJustPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		set('gamepadPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		set('gamepadReleased', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		set('keyJustPressed', function(name:String = '')
		{
			name = name.toLowerCase();
			switch (name)
			{
				case 'left':
					return Controls.instance.NOTE_LEFT_P;
				case 'down':
					return Controls.instance.NOTE_DOWN_P;
				case 'up':
					return Controls.instance.NOTE_UP_P;
				case 'right':
					return Controls.instance.NOTE_RIGHT_P;
				default:
					return Controls.instance.justPressed(name);
			}
			return false;
		});
		set('keyPressed', function(name:String = '')
		{
			name = name.toLowerCase();
			switch (name)
			{
				case 'left':
					return Controls.instance.NOTE_LEFT;
				case 'down':
					return Controls.instance.NOTE_DOWN;
				case 'up':
					return Controls.instance.NOTE_UP;
				case 'right':
					return Controls.instance.NOTE_RIGHT;
				default:
					return Controls.instance.pressed(name);
			}
			return false;
		});
		set('keyReleased', function(name:String = '')
		{
			name = name.toLowerCase();
			switch (name)
			{
				case 'left':
					return Controls.instance.NOTE_LEFT_R;
				case 'down':
					return Controls.instance.NOTE_DOWN_R;
				case 'up':
					return Controls.instance.NOTE_UP_R;
				case 'right':
					return Controls.instance.NOTE_RIGHT_R;
				default:
					return Controls.instance.justReleased(name);
			}
			return false;
		});
	}

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
			if (hasFunction(func))
			{
				var functionRef = interp.variables.get(func);
				if (Reflect.isFunction(functionRef))
				{
					var result = Reflect.callMethod(null, functionRef, args);
					if (result == null)
						result = LuaUtils.Function_Continue;
					return result;
				}
			}
		}
		catch (e:Dynamic)
		{
			var stack = haxe.CallStack.toString(haxe.CallStack.exceptionStack(true));
			CoolLog.error('HScript call error in $scriptName, function $func: $e\n$stack');
		}
		return LuaUtils.Function_Continue;
	}

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

#if LUA_ALLOWED
class HxLua
{
	public var hscript:HScript;
	public var lua:LuaScript;

	/** The HScript-side reference back to the owning Lua script. */
	public var parentInterpreted:Dynamic;

	static function resolveClass(className:String):Class<Dynamic>
	{
		return StructureCompatibility.resolveClass(className);
	}

	public function new(lua:LuaScript)
	{
		this.lua = lua;
		this.hscript = new HScript();
		this.parentInterpreted = lua;
		implement(lua, this);
	}

	/**
	 * Registers all runHaxeCode / runHaxeFunction / addHaxeLibrary callbacks
	 * on a LuaScript, routing them through the given HxLua bridge.
	 */
	public static function implement(funk:LuaScript, ?bridge:HxLua):Void
	{
		funk.set("runHaxeCode",
			function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic
			{
				var hs:HScript = (bridge != null) ? bridge.hscript : try funk.hscript catch (e) null;
				if (hs == null)
				{
					CoolLog.info('initializing haxe interp for: "${funk.scriptName}"');
					try
					{
						hs = new HScript();
						if (varsToBring != null)
							for (k in Reflect.fields(varsToBring))
								hs.set(k, Reflect.field(varsToBring, k));
						hs.returnValue = hs.execute(codeToRun);
						if (bridge != null)
							bridge.hscript = hs;
						else
							funk.hscript = hs;
					}
					catch (e:Dynamic)
					{
						CoolLog.error('HScript Error in ${funk.scriptName}: $e');
						return null;
					}
				}
				else
				{
					try
					{
						hs.returnValue = hs.execute(codeToRun);
					}
					catch (e:Dynamic)
					{
						CoolLog.error('HScript Error: $e');
						hs.returnValue = null;
					}
				}

				if (hs != null)
				{
					if (funcToRun != null)
					{
						var result = hs.call(funcToRun, funcArgs);
						return (result != null && result != LuaUtils.Function_Continue) ? result : hs.returnValue;
					}
					return hs.returnValue;
				}
				return null;
			});

		funk.set("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null)
		{
			var hs:HScript = (bridge != null) ? bridge.hscript : try funk.hscript catch (e) null;
			if (hs != null)
			{
				return hs.call(funcToRun, funcArgs);
			}
			else
			{
				CoolLog.error('runHaxeFunction: HScript has not been initialized yet! Use "runHaxeCode" to initialize it');
			}
			return null;
		});

		funk.set("addHaxeLibrary", function(libName:String, ?libPackage:String = '')
		{
			var str:String = '';
			if (libPackage.length > 0)
				str = libPackage + '.';
			else if (libName == null)
				libName = '';

			var c:Dynamic = resolveClass(str + libName);
			if (c == null)
				c = Type.resolveEnum(str + libName);

			var hs:HScript = (bridge != null) ? bridge.hscript : try funk.hscript catch (e) null;
			if (hs == null)
			{
				hs = new HScript();
				if (bridge != null)
					bridge.hscript = hs;
				else
					funk.hscript = hs;
			}

			try
			{
				if (c != null)
					hs.set(libName, c);
			}
			catch (e:Dynamic)
			{
				CoolLog.error('addHaxeLibrary error: $e');
			}
		});
	}

	public function stop():Void
	{
		if (hscript != null)
		{
			hscript.stop();
			hscript = null;
		}
		lua = null;
		parentInterpreted = null;
	}
}
#else
// Stub when Lua is not available — keeps call-sites compiling.
class HxLua
{
	public var hscript:HScript;

	public function new(?_:Dynamic)
	{
	}

	public static function implement(?_:Dynamic, ?__:Dynamic):Void
	{
	}

	public function stop():Void
	{
		if (hscript != null)
		{
			hscript.stop();
			hscript = null;
		}
	}
}
#end

#if PYTHON_ALLOWED
class HxPython
{
	public var hscript:HScript;
	public var python:Python;

	/** The HScript-side reference back to the owning Python script. */
	public var parentInterpreted:Dynamic;

	static function resolveClass(className:String):Class<Dynamic>
	{
		return StructureCompatibility.resolveClass(className);
	}

	public function new(python:Python)
	{
		this.python = python;
		this.hscript = new HScript();
		this.parentInterpreted = python;
		implement(python, this);
	}

	/**
	 * Registers all runHaxeCode / runHaxeFunction / addHaxeLibrary variables
	 * on a Python script, routing them through the given HxPython bridge.
	 */
	public static function implement(python:Python, ?bridge:HxPython):Void
	{
		python.set("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic
		{
			var hs:HScript = (bridge != null) ? bridge.hscript : try python.hscript catch (e) null;
			if (hs == null)
			{
				CoolLog.info('initializing haxe interp for: "${python.scriptName}"');
				try
				{
					hs = new HScript();
					if (varsToBring != null)
						for (k in Reflect.fields(varsToBring))
							hs.set(k, Reflect.field(varsToBring, k));
					hs.returnValue = hs.execute(codeToRun);
					if (bridge != null)
						bridge.hscript = hs;
					else
						python.hscript = hs;
				}
				catch (e:Dynamic)
				{
					CoolLog.error('HScript Error in ${python.scriptName}: $e');
					return null;
				}
			}
			else
			{
				try
				{
					hs.returnValue = hs.execute(codeToRun);
				}
				catch (e:Dynamic)
				{
					CoolLog.error('HScript Error: $e');
					hs.returnValue = null;
				}
			}

			if (hs != null)
			{
				if (funcToRun != null)
				{
					var result = hs.call(funcToRun, funcArgs);
					return (result != null && result != LuaUtils.Function_Continue) ? result : hs.returnValue;
				}
				return hs.returnValue;
			}
			return null;
		});

		python.set("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null)
		{
			var hs:HScript = (bridge != null) ? bridge.hscript : try python.hscript catch (e) null;
			if (hs != null)
			{
				return hs.call(funcToRun, funcArgs);
			}
			else
			{
				CoolLog.error('runHaxeFunction: HScript has not been initialized yet! Use "runHaxeCode" to initialize it');
			}
			return null;
		});

		python.set("addHaxeLibrary", function(libName:String, ?libPackage:String = '')
		{
			var str:String = '';
			if (libPackage.length > 0)
				str = libPackage + '.';
			else if (libName == null)
				libName = '';

			var c:Dynamic = resolveClass(str + libName);
			if (c == null)
				c = Type.resolveEnum(str + libName);

			var hs:HScript = (bridge != null) ? bridge.hscript : try python.hscript catch (e) null;
			if (hs == null)
			{
				hs = new HScript();
				if (bridge != null)
					bridge.hscript = hs;
				else
					python.hscript = hs;
			}

			try
			{
				if (c != null)
					hs.set(libName, c);
			}
			catch (e:Dynamic)
			{
				CoolLog.error('addHaxeLibrary error: $e');
			}
		});
	}

	public function stop():Void
	{
		if (hscript != null)
		{
			hscript.stop();
			hscript = null;
		}
		python = null;
		parentInterpreted = null;
	}
}
#else
// Stub when Python is not available — keeps call-sites compiling.
class HxPython
{
	public var hscript:HScript;

	public function new(?_:Dynamic)
	{
	}

	public static function implement(?_:Dynamic, ?__:Dynamic):Void
	{
	}

	public function stop():Void
	{
		if (hscript != null)
		{
			hscript.stop();
			hscript = null;
		}
	}
}
#end

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

	public static function fromInt(Value:Int):Int
		return cast FlxColor.fromInt(Value);

	public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Int
		return cast FlxColor.fromRGB(Red, Green, Blue, Alpha);

	public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);

	public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);

	public static function fromHSB(Hue:Float, Sat:Float, Brt:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromHSB(Hue, Sat, Brt, Alpha);

	public static function fromHSL(Hue:Float, Sat:Float, Light:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromHSL(Hue, Sat, Light, Alpha);

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
	{
		return flixel.math.FlxPoint.get(x, y);
	}

	public static inline function weak(x:Float = 0, y:Float = 0):flixel.math.FlxBasePoint
	{
		return flixel.math.FlxPoint.weak(x, y);
	}
}

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
	{
		return new CacheWrapper(@:privateAccess FlxG.bitmap._cache);
	}

	public function add(graphic:flixel.graphics.FlxGraphic, ?persistent:Bool = false, ?key:String):flixel.graphics.FlxGraphic
	{
		return FlxG.bitmap.add(graphic, persistent, key);
	}

	public function removeByKey(key:String):Void
	{
		FlxG.bitmap.removeByKey(key);
	}

	public function remove(graphic:flixel.graphics.FlxGraphic):Void
	{
		FlxG.bitmap.remove(graphic);
	}

	public function get(key:String):flixel.graphics.FlxGraphic
	{
		return FlxG.bitmap.get(key);
	}

	public function checkCache(key:String):Bool
	{
		return FlxG.bitmap.checkCache(key);
	}

	public function create(width:Int, height:Int, color:Int, ?unique:Bool = false, ?key:String):flixel.graphics.FlxGraphic
	{
		return FlxG.bitmap.create(width, height, color, unique, key);
	}

	public function reset():Void
	{
		FlxG.bitmap.reset();
	}

	public function clearCache():Void
	{
		FlxG.bitmap.clearCache();
	}

	public function clearUnused():Void
	{
		FlxG.bitmap.clearUnused();
	}
}

class CacheWrapper
{
	private var cache:Map<String, flixel.graphics.FlxGraphic>;

	public function new(cache:Map<String, flixel.graphics.FlxGraphic>)
	{
		this.cache = cache;
	}

	public function exists(key:String):Bool
	{
		return cache.exists(key);
	}

	public function get(key:String):flixel.graphics.FlxGraphic
	{
		return cache.get(key);
	}

	public function remove(key:String):Bool
	{
		return cache.remove(key);
	}

	public function set(key:String, value:flixel.graphics.FlxGraphic):Void
	{
		cache.set(key, value);
	}

	public function keys():Iterator<String>
	{
		return cache.keys();
	}

	public function count():Int
	{
		var count = 0;
		for (key in cache.keys())
			count++;
		return count;
	}
}
#else
class HScript
{
	#if LUA_ALLOWED
	public static function implement(funk:LuaScript)
	{
		funk.addLocalCallback("runHaxeCode",
			function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic
			{
				PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
				return null;
			});
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null)
		{
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '')
		{
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
	}
	#end
}

class HxLua
{
	public function new(?_:Dynamic)
	{
	}

	public static function implement(?_:Dynamic, ?__:Dynamic):Void
	{
	}

	public function stop():Void
	{
	}
}

class HxPython
{
	public function new(?_:Dynamic)
	{
	}

	public static function implement(?_:Dynamic, ?__:Dynamic):Void
	{
	}

	public function stop():Void
	{
	}
}
#end
