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
import funkin.modding.objects.ModchartSprite;
import funkin.backend.ClientPrefs;
import funkin.modding.scripts.utils.LuaUtils;
import flixel.sound.FlxStreamSound;
import flixel.sound.FlxSound;
import funkin.backend.Song;
import funkin.backend.WeekData;
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
using PPQolTools;

class Script implements IFlxDestroyable
{
	public var scriptCode:String;
	public var scriptName:String;
	public var scriptPath:String;
	public var scriptPack:Null<ScriptPack>;

	public var closed:Bool = false;

	public var fileName:String;
	public var folderName:String;

	public function new(pathOrCode:String, isCode:Bool = false)
	{
		var code:String = !isCode ? getFileContent(pathOrCode) : pathOrCode;
		scriptPath = !isCode ? pathOrCode : "UnknownWhere";
		if (!isCode)
		{
			var filePath = pathOrCode.split("/");
			this.fileName = filePath.pop();
			if (filePath.first() == "mods")
				this.folderName = filePath[1];
			else
				this.folderName = filePath.first();
		}
		this.scriptCode = code;
	}

	public static function preset(?script:Script):Void
	{
		if (script == null)
			return;
		var defaults = getDefaultVariables(script);
		for (key => value in defaults)
			script.set(key, value);
	}

	public static function getDefaultVariables(?script:Script):Map<String, Dynamic>
	{
		var defaults:Map<String, Dynamic> = [];

		// Stop functions
		defaults.set('Function_StopLua', LuaUtils.Function_StopLua);
		defaults.set('Function_StopHScript', LuaUtils.Function_StopHScript);
		defaults.set('Function_StopPython', LuaUtils.Function_StopPython);
		defaults.set('Function_StopAll', LuaUtils.Function_StopAll);
		defaults.set('Function_Stop', LuaUtils.Function_Stop);
		defaults.set('Function_Continue', LuaUtils.Function_Continue);

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
		defaults.set('FlxTween', {
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
		defaults.set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		defaults.set('ErrorHandledRuntimeShader', funkin.shaders.ErrorHandledShader.ErrorHandledRuntimeShader);
		#end
		defaults.set('ShaderFilter', openfl.filters.ShaderFilter);
		#if flxanimate
		defaults.set('FlxAnimate', FlxAnimate);
		#end

		// Version and settings
		defaults.set('version', MainMenuState.psychEngineVersion.trim());
		defaults.set('scriptName', script.scriptPath);
		defaults.set('currentModDirectory', Mods.currentModDirectory);
		defaults.set('buildTarget', LuaUtils.getBuildTarget());

		// Song/Week data
		defaults.set('curBpm', Conductor.bpm);
		defaults.set('bpm', PlayState.SONG.bpm);
		defaults.set('scrollSpeed', PlayState.SONG.speed);
		defaults.set('crochet', Conductor.crochet);
		defaults.set('stepCrochet', Conductor.stepCrochet);
		defaults.set('songLength', FlxG.sound.music != null ? FlxG.sound.music.length : 0);
		defaults.set('songName', PlayState.SONG.song);
		defaults.set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		defaults.set('loadedSongName', Song.loadedSongName);
		defaults.set('loadedSongPath', Paths.formatToSongPath(Song.loadedSongName));
		defaults.set('chartPath', Song.chartPath);
		defaults.set('startedCountdown', false);
		defaults.set('curStage', PlayState.SONG.stage);
		defaults.set('isStoryMode', PlayState.isStoryMode);
		defaults.set('difficulty', PlayState.storyDifficulty);
		defaults.set('difficultyName', Difficulty.getString(false));
		defaults.set('difficultyPath', Difficulty.getFilePath());
		defaults.set('difficultyNameTranslation', Difficulty.getString(true));
		defaults.set('weekRaw', PlayState.storyWeek);
		defaults.set('week', WeekData.weeksList[PlayState.storyWeek]);
		defaults.set('seenCutscene', PlayState.seenCutscene);
		defaults.set('hasVocals', PlayState.SONG.needsVoices);

		defaults.set('FlxColor', function(color:String) return FlxColor.fromString(color));
		defaults.set('getColorFromName', function(color:String) return FlxColor.fromString(color));
		defaults.set('getColorFromString', function(color:String) return FlxColor.fromString(color));
		defaults.set('getColorFromHex', function(color:String) return FlxColor.fromString('#$color'));

		// Screen
		defaults.set('screenWidth', FlxG.width);
		defaults.set('screenHeight', FlxG.height);

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

	public function call(funcName:String, ?args:Array<Dynamic>):Dynamic
		return null;

	public function execute():Void {}

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
