package funkin.modding.scripts;

import funkin.objects.Character;
import funkin.modding.scripts.LuaUtils;
import funkin.modding.scripts.components.*;
import funkin.utils.PlatformDex;
#if LUA_ALLOWED
import funkin.modding.scripts.FunkinLua;
#end
#if HSCRIPT_ALLOWED
import hscript.Parser;
import hscript.Interp;
import hscript.Printer;
import hscript.Tools;
import hscript.Expr.Error as HscriptError;
import hscript.Expr;
import hscript.Expr;
import haxe.ds.StringMap;
import funkin.utils.NdllUtil;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import funkin.modding.scripts.BuildInLib;

using StringTools;

interface IHscriptInterface
{
	public var scriptName:String;
	public function set(variable:String, data:Dynamic):Void;
	public function call(func:String, ?args:Array<Dynamic>):Dynamic;
	public function stop():Void;
}

class PaoPaoInterp extends Interp
{
	public var parentInstance(default, set):Dynamic = [];

	var _instanceFields:Array<String>;

	function set_parentInstance(inst:Dynamic):Dynamic
	{
		_instanceFields = inst == null ? [] : Type.getInstanceFields(Type.getClass(inst));
		return parentInstance = inst;
	}

	override function resolve(id:String, doException:Bool = true, allowProperty:Bool = true):Dynamic
	{
		if (locals.exists(id))
			return locals.get(id).r;
		else if (variables.exists(id))
			return variables.get(id);
		else if (customClasses.exists(id))
			return customClasses.get(id);
		if (parentInstance != null && _instanceFields.contains(id))
			return Reflect.getProperty(parentInstance, id);
		else
			return super.resolve(id, doException, allowProperty);
	}

	override function setVar(name:String, v:Dynamic):Void
	{
		if (allowStaticVariables && staticVariables.exists(name))
			staticVariables.set(name, v);
		else if (allowPublicVariables && publicVariables.exists(name))
			publicVariables.set(name, v);
		else if (parentInstance != null && _instanceFields.contains(name))
			Reflect.setProperty(parentInstance, name, v);
		else
			variables.set(name, v);
	}

	override function assign(e1:Expr, e2:Expr):Dynamic
	{
		var value:Dynamic = expr(e2);
		switch (Tools.expr(e1))
		{
			case EIdent(variable):
				var local:Dynamic = locals.get(variable);
				if (local != null)
				{
					if (!local.const)
						local.r = value;
					else
						warn(ECustom('$variable cannot be reassigned as it is a constant expression.'));
				}
				else if (parentInstance != null && _instanceFields.contains(variable))
					Reflect.setProperty(parentInstance, variable, value);
				else
				{
					if (!variables.exists(variable))
						error(EUnknownVariable(variable));

					setVar(variable, value);
				}

			case EField(variable, field, stinky):
				var variable:Dynamic = expr(variable);
				if (variable == null)
				{
					if (stinky)
						error(EInvalidAccess(field));
					else
						return null;
				}

				value = set(variable, field, value);

			case EArray(variable, index):
				expr(variable)[expr(index)] = value;

			default:
				error(EInvalidOp('='));
		}
		return value;
	}

	override function evalAssignOp(op:String, func:Dynamic->Dynamic->Dynamic, e1:Expr, e2:Expr):Dynamic
	{
		var value:Dynamic;
		var _value:Dynamic = expr(e2);
		switch (Tools.expr(e1))
		{
			case EIdent(variable):
				value = func(expr(e1), _value);
				var local:Dynamic = locals.get(variable);
				if (local != null)
				{
					if (!local.const)
						local.r = value;
					else
						warn(ECustom('$variable cannot be reassigned as it is a constant expression.'));
				}
				else if (parentInstance != null && _instanceFields.contains(variable))
					Reflect.setProperty(parentInstance, variable, value);
				else
				{
					if (!variables.exists(variable))
						error(EUnknownVariable(variable));

					setVar(variable, value);
				}

			case EField(variable, field, stinky):
				var variable:Dynamic = expr(variable);
				if (variable == null)
				{
					if (stinky)
						error(EInvalidAccess(field));
					else
						return null;
				}

				value = set(variable, field, func(get(variable, field), _value));

			case EArray(variable, index):
				var array:Dynamic = expr(variable);
				var index:Dynamic = expr(index);
				value = array[index] = func(array[index], _value);

			default:
				return error(EInvalidOp(op));
		}
		return value;
	}
}

class HScript implements IHscriptInterface implements IFlxDestroyable
{
	private static function createParser():Parser
	{
		var p = new Parser();
		p.allowJSON = true;
		p.allowMetadata = true;
		p.allowTypes = true;
		return p;
	}

	private static function createPrinter():Printer
	{
		var p = new Printer();
		return p;
	}

	public static var astCache:StringMap<Expr> = new StringMap();
	public static var parser:Parser = createParser();
	public static var printer:Printer = createPrinter();

	public var interp:PaoPaoInterp;
	public var origin:Null<String>;
	public var scriptName:String;
	public var returnValue:Dynamic;
	public var closed:Bool = false;

	#if MODS_ALLOWED
	public var modFolder:String = null;
	public var modName:String = null;
	#end

	public var parentInterpreted:Dynamic;

	public static function reset()
	{
		CoolLog.info('Resetting HScript cache');
		HScript.astCache.clear();
	}

	public static function initHaxeModule(parent:Dynamic)
	{
		if (parent.hscript == null)
		{
			CoolLog.info('initializing haxe interp for: "${parent.scriptName}"');
			parent.hscript = new HScript(parent);
		}
	}

	public static function initHaxeModuleCode(parent:Dynamic, code:String, ?varsToBring:Any = null)
	{
		var hs:HScript = try parent.hscript catch (e) null;
		if (hs == null)
		{
			CoolLog.info('initializing haxe interp for: "${parent.scriptName}"');
			try
			{
				parent.hscript = new HScript(parent, code, varsToBring, true);
				parent.hscript.execute(code);
			}
			catch (e:Dynamic)
			{
				CoolLog.error('HScript Error in ${parent.scriptName}: $e');
				parent.hscript = null;
			}
		}
		else
		{
			try
			{
				hs.returnValue = hs.execute(code);
			}
			catch (e:Dynamic)
			{
				CoolLog.error('HScript Error: $(e');
				hs.returnValue = null;
			}
		}
	}

	private final function onError(e:HscriptError)
	{
		if (Std.isOfType(e, HscriptError))
		{
			PlayState.instance.addTextToDebug(printer.exprToString(cast(e, Expr)), FlxColor.RED);
		}
	}

	private final function onWarning(e:HscriptError)
	{
		if (Std.isOfType(e, HscriptError))
		{
			PlayState.instance.addTextToDebug("[WARNING] " + printer.exprToString(cast(e, Expr)), FlxColor.YELLOW);
		}
	}

	private final function onImportFailed(classPath:Array<String>, classAlias:Null<String>):Bool
	{
		if (classPath[0] != "funkin")
		{
			var className = "funkin." + classPath.join(".");
			var varName = (classAlias != null) ? classAlias : classPath[classPath.length - 1];
			var cls = Type.resolveClass(className);
			if (cls != null)
			{
				set(varName, cls);
				return true;
			}
		}
		else if (classPath.contains("Discord"))
		{
			#if DISCORD_ALLOWED
			var varName = (classAlias != null) ? classAlias : "Discord";
			set(varName, Type.resolveClass("funkin.api.Discord"));
			return true;
			#end
		}
		return false;
	}

	public function new(?parent:Dynamic, ?file:String = '', ?varsToBring:Any = null, ?manualRun:Bool = false)
	{
		interp = new PaoPaoInterp();
		interp.allowStaticVariables = interp.allowPublicVariables = true;
		interp.errorHandler = onError;
		interp.importFailedCallback = onImportFailed;

		scriptName = origin = file;

		#if MODS_ALLOWED
		if (file != null && file.length > 0)
		{
			var myFolder:Array<String> = file.split('/');
			if (myFolder[0] + '/' == Paths.mods()
				&& (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1])))
				this.modFolder = myFolder[1];
		}
		#end

		#if LUA_ALLOWED
		parentInterpreted = parent;
		if (parent != null)
			scriptName = parent.scriptName;
		#end

		preset(varsToBring);

		if (!manualRun && file != null && file.length > 0)
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

	public function execute(code:String):Dynamic
	{
		if (closed)
			return null;

		var cachedExpr:Dynamic;
		var cacheKey:String = Sha256.make(Bytes.ofString(modFolder + scriptName + code)).toHex();
		if (!HScript.astCache.exists(cacheKey))
		{
			cachedExpr = HScript.parser.parseString(code);
			HScript.astCache.set(cacheKey, cachedExpr);
			CoolLog.info('HScript parsed AST for "${scriptName}"');
		}
		else
		{
			cachedExpr = HScript.astCache.get(cacheKey);
			CoolLog.info('HScript reused AST for "${scriptName}"');
		}

		try
		{
			var expr = cachedExpr;
			returnValue = interp.execute(expr);
			return returnValue;
		}
		catch (e:Dynamic)
		{
			CoolLog.error('HScript execution error in "' + scriptName + '": ' + e);
			return null;
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

		var lib = new BuildInLib(set);
		lib.addLib();
		lib.addVar();

		set("PlatformDex", PlatformDex);
		set("NdllUtil", NdllUtil);

		// Keyboard & Gamepads
		set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		set('anyGamepadPressed', function(name:String) return FlxG.gamepads.anyPressed(name));
		set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

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

		// For adding your own callbacks
		#if LUA_ALLOWED
		set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			for (script in PlayState.instance.luaArray)
				if (script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);

			FunkinLua.customFunctions.set(name, func);
		});

		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if (funk == null)
				funk = parentInterpreted;

			if (funk != null)
				funk.addLocalCallback(name, func);
			else
				CoolLog.error('createCallback ($name): 3rd argument is null');
		});
		#end

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '')
		{
			try
			{
				var str:String = '';
				if (libPackage.length > 0)
					str = libPackage + '.';

				var c:Dynamic = Type.resolveClass(str + libName);
				if (c == null)
					c = Type.resolveEnum(str + libName);

				if (c != null)
					set(libName, c);
			}
			catch (e:Dynamic)
			{
				CoolLog.error('addHaxeLibrary error: $e');
			}
		});

		#if LUA_ALLOWED
		set('parentInterpreted', parentInterpreted);
		#else
		set('parentInterpreted', null);
		#end
		set('this', this);
		set('game', FlxG.state);
		set('controls', Controls.instance);

		set('buildTarget', LuaUtils.getBuildTarget());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);
	}

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua)
	{
		funk.addLocalCallback("runHaxeCode",
			function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic
			{
				initHaxeModuleCode(funk, codeToRun, varsToBring);
				if (funk.hscript != null)
				{
					if (funcToRun != null)
					{
						var result = funk.hscript.call(funcToRun, funcArgs);
						return (result != null && result != LuaUtils.Function_Continue) ? result : funk.hscript.returnValue;
					}
					return funk.hscript.returnValue;
				}
				return null;
			});

		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null)
		{
			if (funk.hscript != null)
			{
				return funk.hscript.call(funcToRun, funcArgs);
			}
			else
			{
				CoolLog.error('runHaxeFunction: HScript has not been initialized yet! Use "runHaxeCode" to initialize it');
			}
			return null;
		});

		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '')
		{
			var str:String = '';
			if (libPackage.length > 0)
				str = libPackage + '.';
			else if (libName == null)
				libName = '';

			var c:Dynamic = Type.resolveClass(str + libName);
			if (c == null)
				c = Type.resolveEnum(str + libName);

			if (funk.hscript == null)
				initHaxeModule(funk);

			try
			{
				if (c != null)
					funk.hscript.set(libName, c);
			}
			catch (e:Dynamic)
			{
				CoolLog.error('addHaxeLibrary error: $e');
			}
		});
	}
	#end

	#if PYTHON_ALLOWED
	public static function pyimplement(python:Python):Void
	{
		python.set("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic
		{
			initHaxeModuleCode(python, codeToRun, varsToBring);
			if (python.hscript != null)
			{
				if (funcToRun != null)
				{
					var result = python.hscript.call(funcToRun, funcArgs);
					return (result != null && result != LuaUtils.Function_Continue) ? result : python.hscript.returnValue;
				}
				return python.hscript.returnValue;
			}
			return null;
		});

		python.set("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null)
		{
			if (python.hscript != null)
			{
				return python.hscript.call(funcToRun, funcArgs);
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

			var c:Dynamic = Type.resolveClass(str + libName);
			if (c == null)
				c = Type.resolveEnum(str + libName);

			if (python.hscript == null)
				initHaxeModule(cast python);

			try
			{
				if (c != null)
					python.hscript.set(libName, c);
			}
			catch (e:Dynamic)
			{
				CoolLog.error('addHaxeLibrary error: $e');
			}
		});
	}
	#end

	public function set(variable:String, data:Dynamic):Void
	{
		if (interp == null || closed)
			return;

		interp.variables.set(variable, data);
	}

	public function get(variable:String):Dynamic
	{
		if (interp == null || closed)
			return null;

		return interp.variables.get(variable);
	}

	public function exists(variable:String):Bool
	{
		if (interp == null || closed)
			return false;

		return interp.variables.exists(variable);
	}

	public function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		if (closed)
			return LuaUtils.Function_Continue;

		if (args == null)
			args = [];

		try
		{
			if (exists(func))
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
			CoolLog.error('HScript call error in $scriptName, function $func: $e');
		}
		return LuaUtils.Function_Continue;
	}

	public function stop():Void
	{
		if (closed)
			return;
		closed = true;
		interp = null;
		origin = null;
		#if LUA_ALLOWED
		parentInterpreted = null;
		#end
	}

	public function destroy():Void // for use old api
	{
		stop();
	}
}

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
#else
class HScript
{
	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua)
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

	#if PYTHON_ALLOWED
	public static function pyimplement(python:Python)
	{
		python.set("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic
		{
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		python.set("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null)
		{
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		python.set("addHaxeLibrary", function(libName:String, ?libPackage:String = '')
		{
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
	}
	#end
}
#end
