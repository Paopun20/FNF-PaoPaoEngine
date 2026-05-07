package funkin.modding.scripts;

#if LUA_ALLOWED
import haxe.PosInfos;
import flixel.*;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import funkin.modding.scripts.components.PsychFunctions;
import funkin.modding.scripts.components.ReflectionFunctions;
import funkin.modding.scripts.components.TextFunctions;
import lscript.LScript;
#end

using StringTools;
using funkin.backend.utils.tools.PPQolTools;

class LuaScript extends Script {
	#if LUA_ALLOWED
	var internalScript:LScript;

	#if HSCRIPT_ALLOWED
	public var hscript:HScript = null;
	#end

	override function set_parent(value:Dynamic):Dynamic
		return internalScript.parent = value;

	override function get_parent():Dynamic
		return internalScript.parent;

	public override function new(path:String) {
		super(path);

		internalScript = new LScript(Script.getFileContent(path));
		internalScript.tracePrefix = '[$scriptPath] ';
		internalScript.print = (line:Int, s:String) -> {
			var info:PosInfos = {
				fileName: '$folderName/$scriptPath',
				lineNumber: line,
				className: '$folderName/$scriptPath',
				methodName: "",
				customParams: []
			}
			CoolLog.info(s, info);
		}
		Script.preset(this);
		PsychFunctions.implement(this, scriptPack);
	}

	public override function execute() {
		try {
			initVars();
			internalScript.execute();
			call('onCreate', []);
		} catch (e:Dynamic) {
			CoolLog.error('Lua Script Error: $e');
		}
	}

	public function initVars() {
		set('scriptName', scriptName);

		// Flixel
		set('FlxG', FlxG);
		set('FlxAngle', FlxAngle);
		set('FlxBasic', FlxBasic);
		set('FlxObject', FlxObject);
		set('FlxSprite', FlxSprite);
		set('FlxCamera', FlxCamera);
		set('FlxText', FlxText);
		set('FlxTween', FlxTween);
		set('FlxTimer', FlxTimer);
		set('FlxMath', FlxMath);
		set('FlxGroup', FlxGroup);
		set('FlxSpriteGroup', FlxSpriteGroup);
		set('FlxSound', FlxSound);
		set('FlxColor', {
			TRANSPARENT: FlxColor.TRANSPARENT,
			WHITE: FlxColor.WHITE,
			GRAY: FlxColor.GRAY,
			BLACK: FlxColor.BLACK,
			GREEN: FlxColor.GREEN,
			LIME: FlxColor.LIME,
			YELLOW: FlxColor.YELLOW,
			ORANGE: FlxColor.ORANGE,
			RED: FlxColor.RED,
			PURPLE: FlxColor.PURPLE,
			BLUE: FlxColor.BLUE,
			BROWN: FlxColor.BROWN,
			PINK: FlxColor.PINK,
			MAGENTA: FlxColor.MAGENTA,
			CYAN: FlxColor.CYAN
		});
		set('FlxAxes', {
			X: FlxAxes.X,
			Y: FlxAxes.Y,
			XY: FlxAxes.XY
		});

		set('Paths', Paths);

		set('print', (s:String) -> {
			var info:PosInfos = {
				fileName: '$folderName/$fileName',
				lineNumber: 0,
				className: '$folderName/$fileName',
				methodName: "",
				customParams: [] // Fuck YOU
			}
			CoolLog.info(s, info);
		});

		// Custom
		/* set('add', (object:FlxBasic) -> return FlxG.state.add(object));
			set('remove', (object:FlxBasic) -> return FlxG.state.remove(object));
			set('insert', (pos:Int, object:FlxBasic) -> return FlxG.state.insert(pos, object));

			set('trace', (value:Dynamic) -> log(value, internalScript.interp.posInfos()));
			set('log', (value:Dynamic, type:backend.console.Logs.LogType = LogMessage) -> log(value, type, internalScript.interp.posInfos())); */
	}

	override public function call(funcName:String, ?args:Array<Dynamic>):Dynamic {
		try {
			return internalScript.callFunc(funcName, args ?? []);
		} catch (e:Dynamic) {
			CoolLog.error('Lua Call Error ($funcName): $e');
			return null;
		}
	}

	override public function set(variable:String, value:Dynamic) {
		try {
			internalScript.setVar(variable, value);
		} catch (e:Dynamic) {
			CoolLog.error('Lua Set Error ($variable): $e');
		}
	}

	override public function get(variable:String):Dynamic {
		try {
			return internalScript.getVar(variable);
		} catch (e:Dynamic) {
			CoolLog.error('Lua Get Error ($variable): $e');
			return null;
		}
	}
	#end
}
