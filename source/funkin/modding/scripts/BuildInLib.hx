package funkin.modding.scripts;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import funkin.backend.Highscore;
import funkin.backend.Song;
import funkin.backend.WeekData;
import funkin.frontend.cutscenes.DialogueBoxPsych;
import funkin.objects.Character;
import funkin.objects.Note;
import funkin.objects.NoteSplash;
import funkin.objects.StrumNote;
import funkin.modding.objects.DebugLuaText;
import funkin.modding.scripts.LuaUtils.LuaTweenOptions;
import funkin.modding.scripts.LuaUtils;
import funkin.modding.scripts.ModchartSprite;
import funkin.modding.scripts.components.*;
import funkin.states.FreeplayState;
import funkin.states.MainMenuState;
import funkin.states.StoryMenuState;
import funkin.substates.GameOverSubstate;
import funkin.substates.PauseSubState;
import funkin.utils.NdllUtil;
import haxe.Json;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.utils.Assets;

/**
 * BuildInLib - Centralized library for common scripting functions
 *
 * This class provides a unified set of functions and variables that can be used
 * across all script types (Lua, HScript, Python). This reduces code duplication
 * and ensures consistency across different scripting languages.
 *
 * Usage:
 * ```haxe
 * var buildInLib = new BuildInLib(set);
 * buildInLib.addVar();      // Add common variables
 * buildInLib.addLib();      // Add common libraries
 * buildInLib.addGameVar();  // Add game state variables
 * buildInLib.addFuncs();    // Add common functions
 * ```
 */
class BuildInLib
{
	private var set:(String, Dynamic) -> Void;
	private var origin:String = null;

	/**
	 * Constructor
	 * @param set The function to set variables in the scripting environment
	 * @param origin Optional script origin/name for logging purposes
	 */
	public function new(set:(String, Dynamic) -> Void, ?origin:String = null)
	{
		this.set = set;
		this.origin = origin;
	}

	/**
	 * Add common variables and constants
	 * Includes: Function_Stop*, debug settings, version info
	 */
	public function addVar():Void
	{
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
		set('version', MainMenuState.psychEngineVersion.trim());
	}

	/**
	 * Add common libraries and classes
	 * Includes: Core classes (Type, Math, Std), Flixel classes, Game classes
	 */
	public function addLib():Void
	{
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
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxSound', flixel.system.FlxSound);
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
	}

	/**
	 * Add game state variables
	 * Only call this when PlayState.instance is not null
	 * Includes: curBeat, curStep, score, rating, character positions, etc.
	 */
	public function addGameVar():Void
	{
		var game:PlayState = PlayState.instance;
		if (game == null)
			return;

		@:privateAccess
		{
			var curSection:SwagSection = PlayState.SONG.notes[game.curSection];

			// Beat/Step tracking
			set('curSection', game.curSection);
			set('curBeat', game.curBeat);
			set('curStep', game.curStep);
			set('curDecBeat', game.curDecBeat);
			set('curDecStep', game.curDecStep);

			// Score tracking
			set('score', game.songScore);
			set('misses', game.songMisses);
			set('hits', game.songHits);
			set('combo', game.combo);
			set('deaths', PlayState.deathCounter);

			// Rating info
			set('rating', game.ratingPercent);
			set('ratingName', game.ratingName);
			set('ratingFC', game.ratingFC);
			set('totalPlayed', game.totalPlayed);
			set('totalNotesHit', game.totalNotesHit);

			// Game state flags
			set('inGameOver', GameOverSubstate.instance != null);
			set('mustHitSection', curSection != null ? (curSection.mustHitSection == true) : false);
			set('altAnim', curSection != null ? (curSection.altAnim == true) : false);
			set('gfSection', curSection != null ? (curSection.gfSection == true) : false);

			// Health multipliers
			set('healthGainMult', game.healthGain);
			set('healthLossMult', game.healthLoss);

			// Playback
			#if FLX_PITCH
			set('playbackRate', game.playbackRate);
			#else
			set('playbackRate', 1);
			#end

			// Gameplay settings
			set('guitarHeroSustains', game.guitarHeroSustains);
			set('instakillOnMiss', game.instakillOnMiss);
			set('botPlay', game.cpuControlled);
			set('practice', game.practiceMode);

			// Default strum positions
			for (i in 0...4)
			{
				set('defaultPlayerStrumX' + i, 0);
				set('defaultPlayerStrumY' + i, 0);
				set('defaultOpponentStrumX' + i, 0);
				set('defaultOpponentStrumY' + i, 0);
			}

			// Default character positions
			set('defaultBoyfriendX', game.BF_X);
			set('defaultBoyfriendY', game.BF_Y);
			set('defaultOpponentX', game.DAD_X);
			set('defaultOpponentY', game.DAD_Y);
			set('defaultGirlfriendX', game.GF_X);
			set('defaultGirlfriendY', game.GF_Y);

			// Character names
			set('boyfriendName', game.boyfriend != null ? game.boyfriend.curCharacter : PlayState.SONG.player1);
			set('dadName', game.dad != null ? game.dad.curCharacter : PlayState.SONG.player2);
			set('gfName', game.gf != null ? game.gf.curCharacter : PlayState.SONG.gfVersion);
		}
	}

	/**
	 * Internal helper for note tween functions
	 */
	private function noteTweenFunction(tag:String, note:Int, data:Dynamic, duration:Float, ease:String):String
	{
		if (PlayState.instance == null)
			return null;

		var strumNote:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];
		if (strumNote == null)
			return null;

		if (tag != null)
		{
			var originalTag:String = tag;
			tag = LuaUtils.formatVariable('tween_$tag');
			LuaUtils.cancelTween(tag);

			var variables = MusicBeatState.getVariables();
			variables.set(tag, FlxTween.tween(strumNote, data, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					variables.remove(tag);
					if (PlayState.instance != null)
						PlayState.instance.callOnLuas('onTweenCompleted', [originalTag]);
				}
			}));
			return tag;
		}
		else
			FlxTween.tween(strumNote, data, duration, {ease: LuaUtils.getTweenEaseByString(ease)});

		return null;
	}

	/**
	 * Add all common functions
	 * This includes: variables, tweens, timers, game state, sprites, sounds, etc.
	 * @param isLua Whether this is being called from Lua (to avoid overriding Lua-specific functions)
	 */
	public function addFuncs(isLua:Bool = false):Void
	{
		var game:PlayState = PlayState.instance;

		// ================================================================
		// VARIABLE MANAGEMENT
		// ================================================================

		set('setVar', function(name:String, value:Dynamic)
		{
			MusicBeatState.getVariables().set(name, value);
			return value;
		});

		set('getVar', function(name:String)
		{
			return MusicBeatState.getVariables().get(name);
		});

		set('removeVar', function(name:String)
		{
			if (MusicBeatState.getVariables().exists(name))
			{
				MusicBeatState.getVariables().remove(name);
				return true;
			}
			return false;
		});

		// ================================================================
		// NOTE TWEENS
		// ================================================================

		set("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {x: value}, duration, ease);
		});

		set("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {y: value}, duration, ease);
		});

		set("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {angle: value}, duration, ease);
		});

		set("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {alpha: value}, duration, ease);
		});

		set("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {direction: value}, duration, ease);
		});

		// ================================================================
		// SCRIPT MANAGEMENT
		// ================================================================

		set('getRunningScripts', function()
		{
			var runningScripts:Array<String> = [];
			if (game == null)
				return runningScripts;

			#if LUA_ALLOWED
			for (script in game.luaArray)
				runningScripts.push(script.scriptName);
			#end
			#if HSCRIPT_ALLOWED
			for (script in game.hscriptArray)
				runningScripts.push(script.origin);
			#end
			#if PYTHON_ALLOWED
			for (script in game.pythonArray)
				runningScripts.push(script.origin);
			#end
			return runningScripts;
		});

		set('setOnScripts', function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (game == null)
				return;
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && origin != null && !exclusions.contains(origin))
				exclusions.push(origin);
			game.setOnScripts(varName, arg, exclusions);
		});

		set('callOnScripts',
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null)
			{
				if (game == null)
					return LuaUtils.Function_Continue;
				if (excludeScripts == null)
					excludeScripts = [];
				if (ignoreSelf && origin != null && !excludeScripts.contains(origin))
					excludeScripts.push(origin);
				return game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
			});

		// ================================================================
		// TWEENS
		// ================================================================

		set('startTween', function(tag:String, vars:String, values:Any = null, duration:Float, ?options:Any = null)
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null && values != null)
			{
				var myOptions:LuaTweenOptions = LuaUtils.getLuaTween(options);
				if (tag != null)
				{
					var variables = MusicBeatState.getVariables();
					var originalTag:String = 'tween_' + LuaUtils.formatVariable(tag);
					variables.set(tag, FlxTween.tween(penisExam, values, duration, myOptions != null ? {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,
						onUpdate: function(twn:FlxTween)
						{
							if (myOptions.onUpdate != null && game != null)
								game.callOnScripts(myOptions.onUpdate, [originalTag, vars]);
						},
						onStart: function(twn:FlxTween)
						{
							if (myOptions.onStart != null && game != null)
								game.callOnScripts(myOptions.onStart, [originalTag, vars]);
						},
						onComplete: function(twn:FlxTween)
						{
							if (twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD)
								variables.remove(tag);
							if (myOptions.onComplete != null && game != null)
								game.callOnScripts(myOptions.onComplete, [originalTag, vars]);
						}
					} : null));
					return tag;
				}
			}
			return null;
		});

		set('cancelTween', function(tag:String)
		{
			LuaUtils.cancelTween(tag);
		});

		// ================================================================
		// TIMERS
		// ================================================================

		set('runTimer', function(tag:String, time:Float = 1, loops:Int = 1)
		{
			LuaUtils.cancelTimer(tag);
			var variables = MusicBeatState.getVariables();
			var originalTag:String = tag;
			tag = LuaUtils.formatVariable('timer_$tag');
			variables.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				if (tmr.finished)
					variables.remove(tag);
				if (game != null)
					game.callOnScripts('onTimerCompleted', [originalTag, tmr.loops, tmr.loopsLeft]);
			}, loops));
			return tag;
		});

		set('cancelTimer', function(tag:String)
		{
			LuaUtils.cancelTimer(tag);
		});

		// ================================================================
		// GAME STATE
		// ================================================================

		set('addScore', function(value:Int = 0)
		{
			if (game == null)
				return;
			game.songScore += value;
			game.RecalculateRating();
		});

		set('addMisses', function(value:Int = 0)
		{
			if (game == null)
				return;
			game.songMisses += value;
			game.RecalculateRating();
		});

		set('addHits', function(value:Int = 0)
		{
			if (game == null)
				return;
			game.songHits += value;
			game.RecalculateRating();
		});

		set('setScore', function(value:Int = 0)
		{
			if (game == null)
				return;
			game.songScore = value;
			game.RecalculateRating();
		});

		set('setMisses', function(value:Int = 0)
		{
			if (game == null)
				return;
			game.songMisses = value;
			game.RecalculateRating();
		});

		set('setHits', function(value:Int = 0)
		{
			if (game == null)
				return;
			game.songHits = value;
			game.RecalculateRating();
		});

		set('setHealth', function(value:Float = 1)
		{
			if (game != null)
				game.health = value;
		});

		set('addHealth', function(value:Float = 0)
		{
			if (game != null)
				game.health += value;
		});

		set('getHealth', function():Float
		{
			return game != null ? game.health : 0.0;
		});

		// ================================================================
		// COLORS
		// ================================================================

		set('FlxColor', function(color:String)
		{
			return FlxColor.fromString(color);
		});

		set('getColorFromName', function(color:String)
		{
			return FlxColor.fromString(color);
		});

		set('getColorFromString', function(color:String)
		{
			return FlxColor.fromString(color);
		});

		set('getColorFromHex', function(color:String)
		{
			return FlxColor.fromString('#$color');
		});

		// ================================================================
		// PRECACHING
		// ================================================================

		set('addCharacterToList', function(name:String, type:String)
		{
			if (game == null)
				return;
			var charType:Int = 0;
			switch (type.toLowerCase())
			{
				case 'dad':
					charType = 1;
				case 'gf' | 'girlfriend':
					charType = 2;
			}
			game.addCharacterToList(name, charType);
		});

		set('precacheImage', function(name:String, ?allowGPU:Bool = true)
		{
			Paths.image(name, allowGPU);
		});

		set('precacheSound', function(name:String)
		{
			Paths.sound(name);
		});

		set('precacheMusic', function(name:String)
		{
			Paths.music(name);
		});

		// ================================================================
		// EVENTS
		// ================================================================

		set('triggerEvent', function(name:String, ?value1:String = '', ?value2:String = '')
		{
			if (game == null)
				return false;
			game.triggerEvent(name, value1, value2, Conductor.songPosition);
			return true;
		});

		// ================================================================
		// SONG CONTROL
		// ================================================================

		set('startCountdown', function()
		{
			if (game == null)
				return false;
			game.startCountdown();
			return true;
		});

		set('endSong', function()
		{
			if (game == null)
				return false;
			game.KillNotes();
			game.endSong();
			return true;
		});

		set('restartSong', function(?skipTransition:Bool = false)
		{
			if (game == null)
				return false;
			game.persistentUpdate = false;
			FlxG.camera.followLerp = 0;
			PauseSubState.restartSong(skipTransition);
			return true;
		});

		set('exitSong', function(?skipTransition:Bool = false)
		{
			if (game == null)
				return false;
			if (skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}
			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			game.transitioning = true;
			FlxG.camera.followLerp = 0;
			Mods.loadTopMod();
			return true;
		});

		set('getSongPosition', function()
		{
			return Conductor.songPosition;
		});

		// ================================================================
		// CHARACTER CONTROL
		// ================================================================

		set('getCharacterX', function(type:String):Float
		{
			if (game == null)
				return 0.0;
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return game.dadGroup.x;
				case 'gf' | 'girlfriend':
					return game.gfGroup.x;
				default:
					return game.boyfriendGroup.x;
			}
		});

		set('setCharacterX', function(type:String, value:Float)
		{
			if (game == null)
				return;
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					game.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.x = value;
				default:
					game.boyfriendGroup.x = value;
			}
		});

		set('getCharacterY', function(type:String):Float
		{
			if (game == null)
				return 0.0;
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return game.dadGroup.y;
				case 'gf' | 'girlfriend':
					return game.gfGroup.y;
				default:
					return game.boyfriendGroup.y;
			}
		});

		set('setCharacterY', function(type:String, value:Float)
		{
			if (game == null)
				return;
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					game.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.y = value;
				default:
					game.boyfriendGroup.y = value;
			}
		});

		set('cameraSetTarget', function(target:String)
		{
			if (game == null)
				return;
			switch (target.toLowerCase())
			{
				case 'boyfriend' | 'bf' | 'player':
					game.camFollow.setPosition(game.boyfriendGroup.x + 150, game.boyfriendGroup.y - 100);
				case 'dad' | 'opponent':
					game.camFollow.setPosition(game.dadGroup.x + 150, game.dadGroup.y - 100);
				case 'gf' | 'girlfriend':
					game.camFollow.setPosition(game.gfGroup.x, game.gfGroup.y);
			}
		});

		set('cameraShake', function(camera:String, intensity:Float, duration:Float)
		{
			LuaUtils.cameraFromString(camera).shake(intensity, duration);
		});

		set('cameraFlash', function(camera:String, color:String, duration:Float, ?forced:Bool = false)
		{
			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});

		set('cameraFade', function(camera:String, color:String, duration:Float, ?forced:Bool = false, ?fadeOut:Bool = false)
		{
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, fadeOut, null, forced);
		});

		// ================================================================
		// SPRITE CREATION (Python/Lua compatible)
		// ================================================================

		set('makePythonSprite', function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0)
		{
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0)
				leSprite.loadGraphic(Paths.image(image));
			MusicBeatState.getVariables().set(tag, leSprite);
			leSprite.active = true;
		});

		set('makeAnimatedPythonSprite', function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = 'auto')
		{
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0)
				LuaUtils.loadFrames(leSprite, image, spriteType);
			MusicBeatState.getVariables().set(tag, leSprite);
		});

		set('addPythonSprite', function(tag:String, ?inFront:Bool = false)
		{
			var mySprite:FlxSprite = MusicBeatState.getVariables().get(tag);
			if (mySprite == null)
				return;
			var instance = LuaUtils.getTargetInstance();
			if (inFront)
				instance.add(mySprite);
			else
			{
				if (PlayState.instance == null || !PlayState.instance.isDead)
					instance.insert(instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), mySprite);
				else
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
			}
		});

		set('removePythonSprite', function(tag:String, destroy:Bool = true, ?group:String = null)
		{
			var obj:FlxSprite = LuaUtils.getObjectDirectly(tag);
			if (obj == null || obj.destroy == null)
				return;
			var groupObj:Dynamic = null;
			if (group == null)
				groupObj = LuaUtils.getTargetInstance();
			else
				groupObj = LuaUtils.getObjectDirectly(group);
			groupObj.remove(obj, true);
			if (destroy)
			{
				MusicBeatState.getVariables().remove(tag);
				obj.destroy();
			}
		});

		// ================================================================
		// SOUND
		// ================================================================

		set('playMusic', function(sound:String, ?volume:Float = 1, ?loop:Bool = false)
		{
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});

		set('playSound', function(sound:String, ?volume:Float = 1, ?tag:String = null, ?loop:Bool = false)
		{
			if (tag != null && tag.length > 0)
			{
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('sound_$tag');
				var variables = MusicBeatState.getVariables();
				var oldSnd = variables.get(tag);
				if (oldSnd != null)
				{
					oldSnd.stop();
					oldSnd.destroy();
				}
				variables.set(tag, FlxG.sound.play(Paths.sound(sound), volume, loop, null, true, function()
				{
					if (!loop)
						variables.remove(tag);
					if (game != null)
						game.callOnScripts('onSoundFinished', [originalTag]);
				}));
				return tag;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
			return null;
		});

		set('stopSound', function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var variables = MusicBeatState.getVariables();
				var snd:FlxSound = variables.get(tag);
				if (snd != null)
				{
					snd.stop();
					variables.remove(tag);
				}
			}
		});

		set('pauseSound', function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
					FlxG.sound.music.pause();
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					snd.pause();
			}
		});

		set('resumeSound', function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
					FlxG.sound.music.play();
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					snd.play();
			}
		});

		set('getSoundVolume', function(tag:String):Float
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
					return FlxG.sound.music.volume;
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					return snd.volume;
			}
			return 0.0;
		});

		set('setSoundVolume', function(tag:String, value:Float)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
					FlxG.sound.music.volume = value;
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					snd.volume = value;
			}
		});

		// ================================================================
		// ANIMATION
		// ================================================================

		set('addAnimationByPrefix', function(obj:String, name:String, prefix:String, framerate:Float = 24, loop:Bool = true)
		{
			var obj:FlxSprite = cast LuaUtils.getObjectDirectly(obj);
			if (obj != null && obj.animation != null)
			{
				obj.animation.addByPrefix(name, prefix, framerate, loop);
				if (obj.animation.curAnim == null)
				{
					var dyn:Dynamic = cast obj;
					if (dyn.playAnim != null)
						dyn.playAnim(name, true);
					else
						dyn.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		set('playAnim', function(obj:String, name:String, ?forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj);
			if (obj.playAnim != null)
			{
				obj.playAnim(name, forced, reverse, startFrame);
				return true;
			}
			else
			{
				if (obj.anim != null)
					obj.anim.play(name, forced, reverse, startFrame);
				else
					obj.animation.play(name, forced, reverse, startFrame);
				return true;
			}
			return false;
		});

		// ================================================================
		// PROPERTY UTILITIES
		// ================================================================

		// Only add these if not from Lua (Lua has its own implementations)
		if (!isLua)
		{
			set('getProperty', function(variable:String)
			{
				var split:Array<String> = variable.split('.');
				var obj:Dynamic = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				return obj;
			});

			set('setProperty', function(variable:String, value:Dynamic)
			{
				var split:Array<String> = variable.split('.');
				if (split.length > 1)
					LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1], value);
				else
					LuaUtils.setVarInArray(LuaUtils.getTargetInstance(), variable, value);
				return true;
			});

			set('getPropertyFromClass', function(className:String, variable:String)
			{
				var myClass:Dynamic = Type.resolveClass(className);
				if (myClass == null)
				{
					pythonTrace('getPropertyFromClass: Class $className not found', FlxColor.RED);
					return null;
				}
				return Reflect.getProperty(myClass, variable);
			});

			set('setPropertyFromClass', function(className:String, variable:String, value:Dynamic)
			{
				var myClass:Dynamic = Type.resolveClass(className);
				if (myClass == null)
				{
					pythonTrace('setPropertyFromClass: Class $className not found', FlxColor.RED);
					return false;
				}
				Reflect.setProperty(myClass, variable, value);
				return true;
			});

			// ================================================================
			// POSITION UTILITIES
			// ================================================================

			set('getMidpointX', function(variable:String):Float
			{
				var split:Array<String> = variable.split('.');
				var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				if (obj != null)
					return obj.getMidpoint().x;
				return 0.0;
			});

			set('getMidpointY', function(variable:String):Float
			{
				var split:Array<String> = variable.split('.');
				var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				if (obj != null)
					return obj.getMidpoint().y;
				return 0.0;
			});

			set('getGraphicMidpointX', function(variable:String):Float
			{
				var split:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				if (obj != null)
					return obj.getGraphicMidpoint().x;
				return 0.0;
			});

			set('getGraphicMidpointY', function(variable:String):Float
			{
				var split:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				if (obj != null)
					return obj.getGraphicMidpoint().y;
				return 0.0;
			});

			set('getScreenPositionX', function(variable:String, ?camera:String = 'game'):Float
			{
				var split:Array<String> = variable.split('.');
				var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				if (obj != null)
					return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).x;
				return 0.0;
			});

			set('getScreenPositionY', function(variable:String, ?camera:String = 'game'):Float
			{
				var split:Array<String> = variable.split('.');
				var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				if (obj != null)
					return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).y;
				return 0.0;
			});

			// ================================================================
			// OBJECT TRANSFORM
			// ================================================================

			set('setGraphicSize', function(obj:String, x:Float, y:Float = 0, updateHitbox:Bool = true)
			{
				var split:Array<String> = obj.split('.');
				var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				if (poop != null)
				{
					poop.setGraphicSize(x, y);
					if (updateHitbox)
						poop.updateHitbox();
					return;
				}
				pythonTrace('setGraphicSize: Couldnt find object: ' + obj, FlxColor.RED);
			});

			set('scaleObject', function(obj:String, x:Float, y:Float, updateHitbox:Bool = true)
			{
				var split:Array<String> = obj.split('.');
				var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				if (poop != null)
				{
					poop.scale.set(x, y);
					if (updateHitbox)
						poop.updateHitbox();
					return;
				}
				pythonTrace('scaleObject: Couldnt find object: ' + obj, FlxColor.RED);
			});

			set('updateHitbox', function(obj:String)
			{
				var split:Array<String> = obj.split('.');
				var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				if (poop != null)
				{
					poop.updateHitbox();
					return;
				}
				pythonTrace('updateHitbox: Couldnt find object: ' + obj, FlxColor.RED);
			});

			set('screenCenter', function(obj:String, pos:String = 'xy')
			{
				var spr:FlxObject = LuaUtils.getObjectDirectly(obj);
				if (spr == null)
				{
					var split:Array<String> = obj.split('.');
					spr = LuaUtils.getObjectDirectly(split[0]);
					if (split.length > 1)
						spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				}
				if (spr != null)
				{
					switch (pos.trim().toLowerCase())
					{
						case 'x':
							spr.screenCenter(X);
							return;
						case 'y':
							spr.screenCenter(Y);
							return;
						default:
							spr.screenCenter(XY);
							return;
					}
				}
				pythonTrace("screenCenter: Object " + obj + " doesn't exist!", FlxColor.RED);
			});

			set('setObjectCamera', function(obj:String, camera:String = 'game')
			{
				var real:FlxBasic = LuaUtils.getObjectDirectly(obj);
				if (real != null)
				{
					real.cameras = [LuaUtils.cameraFromString(camera)];
					return true;
				}
				var split:Array<String> = obj.split('.');
				var object:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				if (object != null)
				{
					object.cameras = [LuaUtils.cameraFromString(camera)];
					return true;
				}
				pythonTrace("setObjectCamera: Object " + obj + " doesn't exist!", FlxColor.RED);
				return false;
			});

			set('setScrollFactor', function(obj:String, scrollX:Float, scrollY:Float)
			{
				var object:FlxObject = LuaUtils.getObjectDirectly(obj);
				if (object != null)
					object.scrollFactor.set(scrollX, scrollY);
			});

			// ================================================================
			// BAR COLORS
			// ================================================================

			set('setHealthBarColors', function(left:String, right:String)
			{
				if (game == null)
					return;
				var left_color:Null<FlxColor> = null;
				var right_color:Null<FlxColor> = null;
				if (left != null && left != '')
					left_color = CoolUtil.colorFromString(left);
				if (right != null && right != '')
					right_color = CoolUtil.colorFromString(right);
				game.healthBar.setColors(left_color, right_color);
			});

			set('setTimeBarColors', function(left:String, right:String)
			{
				if (game == null)
					return;
				var left_color:Null<FlxColor> = null;
				var right_color:Null<FlxColor> = null;
				if (left != null && left != '')
					left_color = CoolUtil.colorFromString(left);
				if (right != null && right != '')
					right_color = CoolUtil.colorFromString(right);
				game.timeBar.setColors(left_color, right_color);
			});

			// ================================================================
			// DIALOGUE & VIDEO
			// ================================================================

			set('startDialogue', function(dialogueFile:String, ?music:String = null)
			{
				if (game == null)
					return false;

				var path:String;
				var songPath:String = Paths.formatToSongPath(Song.loadedSongName);
				#if TRANSLATIONS_ALLOWED
				path = Paths.getPath('data/$songPath/${dialogueFile}_${ClientPrefs.data.language}.json', TEXT);
				#if MODS_ALLOWED
				if (!FileSystem.exists(path))
				#else
				if (!Assets.exists(path, TEXT))
				#end
				#end
				path = Paths.getPath('data/$songPath/$dialogueFile.json', TEXT);

				pythonTrace('startDialogue: Trying to load dialogue: ' + path);

				#if MODS_ALLOWED
				if (FileSystem.exists(path))
				#else
				if (Assets.exists(path, TEXT))
				#end
				{
					var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
					if (shit.dialogue.length > 0)
					{
						game.startDialogue(shit, music);
						pythonTrace('startDialogue: Successfully loaded dialogue', FlxColor.GREEN);
						return true;
					}
					else
						pythonTrace('startDialogue: Your dialogue file is badly formatted!', FlxColor.RED);
				}
			else
			{
				pythonTrace('startDialogue: Dialogue file not found', FlxColor.RED);
				if (game.endingSong)
					game.endSong();
				else
					game.startCountdown();
			}
				return false;
			});

			set('startVideo', function(videoFile:String, ?canSkip:Bool = true, ?forMidSong:Bool = false, ?shouldLoop:Bool = false, ?playOnLoad:Bool = true)
			{
				if (game == null)
					return false;

				#if VIDEOS_ALLOWED
				if (FileSystem.exists(Paths.video(videoFile)))
				{
					if (game.videoCutscene != null)
					{
						game.remove(game.videoCutscene);
						game.videoCutscene.destroy();
					}
					game.videoCutscene = game.startVideo(videoFile, forMidSong, canSkip, shouldLoop, playOnLoad);
					return true;
				}
				else
				{
					pythonTrace('startVideo: Video file not found: ' + videoFile, FlxColor.RED);
				}
				return false;
				#else
				PlayState.instance.inCutscene = true;
				new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					PlayState.instance.inCutscene = false;
					if (game.endingSong)
						game.endSong();
					else
						game.startCountdown();
				});
				return true;
				#end
			});

			// ================================================================
			// DEBUG
			// ================================================================

			set('debugPrint', function(text:Dynamic = '', ?color:FlxColor = null)
			{
				if (color == null)
					color = FlxColor.WHITE;
				PlayState.instance.addTextToDebug(text, color);
			});

			// ================================================================
			// MOD SETTINGS
			// ================================================================

			set("getModSetting", function(saveTag:String, ?modName:String = null)
			{
				#if MODS_ALLOWED
				if (modName == null)
				{
					pythonTrace('getModSetting: Mod name not provided!', FlxColor.RED);
					return null;
				}
				return LuaUtils.getModSetting(saveTag, modName);
				#else
				pythonTrace("getModSetting: Mods are disabled in this build!", FlxColor.RED);
				return null;
				#end
			});

			// ================================================================
			// CLOSE SCRIPT
			// ================================================================

			set("close", function()
			{
				pythonTrace('Closing script via close() function');
				return LuaUtils.Function_Stop;
			});
		}
	}

	/**
	 * Helper function for trace/debug output
	 */
	private static function pythonTrace(text:String, ?color:FlxColor = null)
	{
		if (color == null)
			color = FlxColor.WHITE;
		if (PlayState.instance != null)
			PlayState.instance.addTextToDebug(text, color);
	}
}
