package funkin.modding.scripts;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import funkin.utils.PlatformDex;
import funkin.utils.NdllUtil;
import funkin.backend.Paths;
import funkin.backend.Conductor;
import funkin.backend.Difficulty;
import funkin.backend.CoolUtil;
import funkin.objects.Character;
import funkin.objects.Alphabet;
import funkin.objects.Note;
import funkin.objects.StrumNote;
import funkin.objects.NoteSplash;
import funkin.objects.PsychCamera;
import funkin.states.MainMenuState;
import funkin.states.PlayState;
import funkin.modding.scripts.components.CustomSubstate;
import funkin.modding.scripts.ModchartSprite;
import funkin.backend.ClientPrefs;
import funkin.modding.scripts.utils.LuaUtils;
import flixel.sound.FlxStreamSound;
import flixel.sound.FlxSound;
#if ACHIEVEMENTS_ALLOWED
import funkin.backend.Achievements;
#end
#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end
#if flxanimate
import flxanimate.FlxAnimate;
#end
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;
using Lambda;
using PPQolTool;

class Script implements IFlxDestroyable
{
	var scriptCode:String;
	var executed:Bool = false;
	public var closed:Bool = false;

	public var fileName:String;
	public var folderName:String;

	public static function preset(?script:Script):Void
	{
		if (script == null) return;
		var defaults = getDefaultVariables(script);
		for (key => value in defaults)
			script.set(key, value);
	}

	public static function getDefaultVariables(?script:Script):Map<String, Dynamic>
	{
		var defaults:Map<String, Dynamic> = [];
		defaults.set('Type', Type);
		defaults.set('Math', Math);
		defaults.set('Std', Std);
		defaults.set('StringTools', StringTools);
		#if sys
		defaults.set('File', File);
		defaults.set('FileSystem', FileSystem);
		#end
		defaults.set('FlxG', FlxG);
		defaults.set('FlxMath', FlxMath);
		defaults.set('FlxSprite', FlxSprite);
		defaults.set('FlxText', FlxText);
		defaults.set('FlxCamera', FlxCamera);
		defaults.set('PsychCamera', PsychCamera);
		defaults.set('FlxTimer', FlxTimer);
		defaults.set('FlxTween', FlxTween);
		defaults.set('FlxEase', FlxEase);
		defaults.set('FlxSound', FlxSound);
		defaults.set('FlxStreamSound', FlxStreamSound);
		defaults.set('Countdown', funkin.backend.BaseStage.Countdown);
		defaults.set('PlayState', PlayState);
		defaults.set('Paths', Paths);
		defaults.set('Conductor', Conductor);
		defaults.set('ClientPrefs', ClientPrefs);
		defaults.set('Difficulty', Difficulty);
		defaults.set('CoolUtil', CoolUtil);
		defaults.set('Character', Character);
		defaults.set('Alphabet', Alphabet);
		defaults.set('Note', Note);
		defaults.set('StrumNote', StrumNote);
		defaults.set('NoteSplash', NoteSplash);
		defaults.set('CustomSubstate', CustomSubstate);
		defaults.set('ModchartSprite', ModchartSprite);
		#if ACHIEVEMENTS_ALLOWED
		defaults.set('Achievements', Achievements);
		#end
		#if (!flash && sys)
		defaults.set('FlxRuntimeShader', FlxRuntimeShader);
		#end
		#if flxanimate
		defaults.set('FlxAnimate', FlxAnimate);
		#end
		defaults.set('Function_StopLua', LuaUtils.Function_StopLua);
		defaults.set('Function_StopHScript', LuaUtils.Function_StopHScript);
		defaults.set('Function_StopPython', LuaUtils.Function_StopPython);
		defaults.set('Function_StopAll', LuaUtils.Function_StopAll);
		defaults.set('Function_Stop', LuaUtils.Function_Stop);
		defaults.set('Function_Continue', LuaUtils.Function_Continue);
		defaults.set('luaDebugMode', false);
		defaults.set('luaDeprecatedWarnings', true);
		defaults.set('version', MainMenuState.psychEngineVersion.trim());
		defaults.set('PlatformDex', PlatformDex);
		defaults.set('NdllUtil', NdllUtil);
		return defaults;
	}

	public var parent(get, set):Dynamic;

	function set_parent(value:Dynamic):Dynamic
		return null;

	function get_parent():Dynamic
		return null;

	inline public static function getFileContent(path:String):String
	{
		// trace(path);
		var data:String;
		try
		{
			data = #if mobile openfl.utils.Assets.exists(path) ? openfl.utils.Assets.getText(path) : #end
			sys.io.File.getContent(path);
		}
		catch (e)
		{
			data = "";
		}
		return data;
	}

	public function new(path:String, isCode:Bool = false)
	{
		var code:String = !isCode ? getFileContent(path) : path;
		if (!isCode)
		{
			var filePath = path.split("/");
			this.fileName = filePath.pop();
			if (filePath.first() == "mods")
				this.folderName = filePath[1];
			else
				this.folderName = filePath.first();
		}
		this.scriptCode = code;
	}

	public function call(funcName:String, ?args:Array<Dynamic>):Dynamic
		return null;

	public function execute(code:String):Dynamic
		return null;

	public function set(variable:String, value:Dynamic) {}

	public function get(variable:String):Dynamic
		return null;

	public function hasFunction(funcName:String):Bool
		return false;

	public function stop():Void
		closed = true;

	public function destroy()
		closed = true;
}
