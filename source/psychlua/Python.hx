package psychlua;

#if PYTHON_ALLOWED
import backend.WeekData;
import backend.Highscore;
import backend.Song;
import openfl.Lib;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxState;
#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end
import cutscenes.DialogueBoxPsych;
import objects.StrumNote;
import objects.Note;
import objects.NoteSplash;
import objects.Character;
import states.MainMenuState;
import states.StoryMenuState;
import states.FreeplayState;
import substates.PauseSubState;
import substates.GameOverSubstate;
import psychlua.LuaUtils;
import psychlua.LuaUtils.LuaTweenOptions;
#if HSCRIPT_ALLOWED
import psychlua.HScript;
#end
#if LUA_ALLOWED
import psychlua.FunkinLua;
#end
import psychlua.DebugLuaText;
import psychlua.ModchartSprite;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import haxe.Json;
import paopao.hython.Interp as PyInterp;
import paopao.hython.Parser as PyParser;

class Python
{
	public var parser:PyParser;
	public var interp:PyInterp;
	public var origin:Null<String>;
	public var returnValue:Dynamic;
	public var closed:Bool = false;

	#if MODS_ALLOWED
	public var modFolder:String = null;
	public var modName:String = null;
	#end

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	#end

	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

	public function new(?parent:Dynamic, ?file:String = '', ?varsToBring:Any = null, ?manualRun:Bool = false)
	{
		parser = new PyParser();
		interp = new PyInterp();
		origin = file;

		var game:PlayState = PlayState.instance;
		if (game != null)
			game.pythonArray.push(this);

		#if MODS_ALLOWED
		var myFolder:Array<String> = file.split('/');
		if (myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1])))
			this.modFolder = myFolder[1];
		#end

		#if LUA_ALLOWED
		parentLua = parent;
		#end

		preset(varsToBring);

		if (!manualRun && file != null && file.length > 0)
		{
			var code:String = null;
			#if MODS_ALLOWED
			if (FileSystem.exists(file))
				code = File.getContent(file);
			#else
			if (Assets.exists(file, TEXT))
				code = Assets.getText(file);
			#end

			if (code != null && code.length > 0)
			{
				try
				{
					execute(code);
					call('onCreate', []);
				}
				catch (e)
				{
					this.stop();
					throw e;
				}
			}
		}
	}

	public function execute(code:String):Dynamic
	{
		if (closed)
			return null;

		try
		{
			var expr = parser.parseString(code);
			returnValue = interp.execute(expr);
			return returnValue;
		}
		catch (e:Dynamic)
		{
			pythonTrace('Execute Error: ' + e, false, false, FlxColor.RED);
			return null;
		}
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
				var result = interp.calldef(func, args);
				if (result == null)
					result = LuaUtils.Function_Continue;
				if (closed)
					stop();
				return result;
			}
		}
		catch (e:Dynamic)
		{
			pythonTrace('Call Error ($func): ' + e, false, false, FlxColor.RED);
		}
		return LuaUtils.Function_Continue;
	}

	public function exists(func:String):Bool
	{
		return interp.getdef(func);
	}

	public function set(variable:String, arg:Dynamic)
	{
		if (interp != null)
			interp.setVar(variable, arg);
	}

	private function noteTweenFunction(tag:String, note:Int, data:Dynamic, duration:Float, ease:String)
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

	function preset(varsToBring:Any)
	{
		var game:PlayState = PlayState.instance;

		// Bring variables from Lua / Haxe
		if (varsToBring != null)
		{
			for (k in Reflect.fields(varsToBring))
				set(k, Reflect.field(varsToBring, k));
		}

		#if LUA_ALLOWED
		set("parentLua", parentLua);
		#end

		// Stop functions
		set('Function_StopLua', LuaUtils.Function_StopLua);
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopPython', LuaUtils.Function_StopPython);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);

		// Core Classes
		set('Type', Type);
		set('Math', Math);
		set('Std', Std);
		set('StringTools', StringTools);
		#if sys
		set('File', File);
		set('FileSystem', FileSystem);
		#end

		// Flixel
		set('FlxG', FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxText', flixel.text.FlxText);
		set('FlxCamera', flixel.FlxCamera);
		set('PsychCamera', backend.PsychCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxSound', flixel.system.FlxSound);

		// Game Classes
		set('Countdown', backend.BaseStage.Countdown);
		set('PlayState', PlayState);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		set('Difficulty', Difficulty);
		set('CoolUtil', CoolUtil);
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Note', objects.Note);
		set('StrumNote', StrumNote);
		set('NoteSplash', NoteSplash);
		set('CustomSubstate', CustomSubstate);
		set('ModchartSprite', ModchartSprite);

		#if ACHIEVEMENTS_ALLOWED
		set('Achievements', Achievements);
		#end
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		set('ErrorHandledRuntimeShader', shaders.ErrorHandledShader.ErrorHandledRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		#if flxanimate
		set('FlxAnimate', FlxAnimate);
		#end

		// Version and settings
		set('version', MainMenuState.psychEngineVersion.trim());
		set('modFolder', this.modFolder);
		set('scriptName', origin);
		set('currentModDirectory', Mods.currentModDirectory);
		set('buildTarget', LuaUtils.getBuildTarget());

		// Song/Week data
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music != null ? FlxG.sound.music.length : 0);
		set('songName', PlayState.SONG.song);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		set('loadedSongName', Song.loadedSongName);
		set('loadedSongPath', Paths.formatToSongPath(Song.loadedSongName));
		set('chartPath', Song.chartPath);
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);
		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);
		set('difficultyName', Difficulty.getString(false));
		set('difficultyPath', Difficulty.getFilePath());
		set('difficultyNameTranslation', Difficulty.getString(true));
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);
		set('hasVocals', PlayState.SONG.needsVoices);

		set('FlxColor', function(color:String) return FlxColor.fromString(color));
		set('getColorFromName', function(color:String) return FlxColor.fromString(color));
		set('getColorFromString', function(color:String) return FlxColor.fromString(color));
		set('getColorFromHex', function(color:String) return FlxColor.fromString('#$color'));

		// Screen
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState variables
		if (game != null)
			@:privateAccess
		{
			var curSection:SwagSection = PlayState.SONG.notes[game.curSection];
			set('curSection', game.curSection);
			set('curBeat', game.curBeat);
			set('curStep', game.curStep);
			set('curDecBeat', game.curDecBeat);
			set('curDecStep', game.curDecStep);

			set('score', game.songScore);
			set('misses', game.songMisses);
			set('hits', game.songHits);
			set('combo', game.combo);
			set('deaths', PlayState.deathCounter);

			set('rating', game.ratingPercent);
			set('ratingName', game.ratingName);
			set('ratingFC', game.ratingFC);
			set('totalPlayed', game.totalPlayed);
			set('totalNotesHit', game.totalNotesHit);

			set('inGameOver', GameOverSubstate.instance != null);
			set('mustHitSection', curSection != null ? (curSection.mustHitSection == true) : false);
			set('altAnim', curSection != null ? (curSection.altAnim == true) : false);
			set('gfSection', curSection != null ? (curSection.gfSection == true) : false);

			set('healthGainMult', game.healthGain);
			set('healthLossMult', game.healthLoss);

			#if FLX_PITCH
			set('playbackRate', game.playbackRate);
			#else
			set('playbackRate', 1);
			#end

			set('guitarHeroSustains', game.guitarHeroSustains);
			set('instakillOnMiss', game.instakillOnMiss);
			set('botPlay', game.cpuControlled);
			set('practice', game.practiceMode);

			for (i in 0...4)
			{
				set('defaultPlayerStrumX$i', 0);
				set('defaultPlayerStrumY$i', 0);
				set('defaultOpponentStrumX$i', 0);
				set('defaultOpponentStrumY$i', 0);
			}

			set('defaultBoyfriendX', game.BF_X);
			set('defaultBoyfriendY', game.BF_Y);
			set('defaultOpponentX', game.DAD_X);
			set('defaultOpponentY', game.DAD_Y);
			set('defaultGirlfriendX', game.GF_X);
			set('defaultGirlfriendY', game.GF_Y);

			set('boyfriendName', game.boyfriend != null ? game.boyfriend.curCharacter : PlayState.SONG.player1);
			set('dadName', game.dad != null ? game.dad.curCharacter : PlayState.SONG.player2);
			set('gfName', game.gf != null ? game.gf.curCharacter : PlayState.SONG.gfVersion);
		}

		// Client preferences
		set('downscroll', ClientPrefs.data.downScroll);
		set('middlescroll', ClientPrefs.data.middleScroll);
		set('framerate', ClientPrefs.data.framerate);
		set('ghostTapping', ClientPrefs.data.ghostTapping);
		set('hideHud', ClientPrefs.data.hideHud);
		set('timeBarType', ClientPrefs.data.timeBarType);
		set('scoreZoom', ClientPrefs.data.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		set('flashingLights', ClientPrefs.data.flashing);
		set('noteOffset', ClientPrefs.data.noteOffset);
		set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		set('noResetButton', ClientPrefs.data.noReset);
		set('lowQuality', ClientPrefs.data.lowQuality);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);

		// === FUNCTIONS ===

		// Variable management
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

		// Script management
		set('getRunningScripts', function()
		{
			var runningScripts:Array<String> = [];
			#if PYTHON_ALLOWED
			for (script in game.pythonArray)
				runningScripts.push(script.origin);
			#end
			return runningScripts;
		});

		set('setOnScripts', function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(origin))
				exclusions.push(origin);
			game.setOnScripts(varName, arg, exclusions);
		});

		set('callOnScripts',
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null)
			{
				if (excludeScripts == null)
					excludeScripts = [];
				if (ignoreSelf && !excludeScripts.contains(origin))
					excludeScripts.push(origin);
				return game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
			});

		// Tweens
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
							if (myOptions.onUpdate != null)
								game.callOnScripts(myOptions.onUpdate, [originalTag, vars]);
						},
						onStart: function(twn:FlxTween)
						{
							if (myOptions.onStart != null)
								game.callOnScripts(myOptions.onStart, [originalTag, vars]);
						},
						onComplete: function(twn:FlxTween)
						{
							if (twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD)
								variables.remove(tag);
							if (myOptions.onComplete != null)
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

		// Timers
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
				game.callOnScripts('onTimerCompleted', [originalTag, tmr.loops, tmr.loopsLeft]);
			}, loops));
			return tag;
		});

		set('cancelTimer', function(tag:String)
		{
			LuaUtils.cancelTimer(tag);
		});

		// Game state
		set('addScore', function(value:Int = 0)
		{
			game.songScore += value;
			game.RecalculateRating();
		});
		set('addMisses', function(value:Int = 0)
		{
			game.songMisses += value;
			game.RecalculateRating();
		});
		set('addHits', function(value:Int = 0)
		{
			game.songHits += value;
			game.RecalculateRating();
		});
		set('setScore', function(value:Int = 0)
		{
			game.songScore = value;
			game.RecalculateRating();
		});
		set('setMisses', function(value:Int = 0)
		{
			game.songMisses = value;
			game.RecalculateRating();
		});
		set('setHits', function(value:Int = 0)
		{
			game.songHits = value;
			game.RecalculateRating();
		});
		set('setHealth', function(value:Float = 1)
		{
			game.health = value;
		});
		set('addHealth', function(value:Float = 0)
		{
			game.health += value;
		});
		set('getHealth', function()
		{
			return game.health;
		});

		// Colors
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

		// Precaching
		set('addCharacterToList', function(name:String, type:String)
		{
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

		// Events
		set('triggerEvent', function(name:String, ?value1:String = '', ?value2:String = '')
		{
			game.triggerEvent(name, value1, value2, Conductor.songPosition);
			return true;
		});

		// Song control
		set('startCountdown', function()
		{
			game.startCountdown();
			return true;
		});
		set('endSong', function()
		{
			game.KillNotes();
			game.endSong();
			return true;
		});
		set('restartSong', function(?skipTransition:Bool = false)
		{
			game.persistentUpdate = false;
			FlxG.camera.followLerp = 0;
			PauseSubState.restartSong(skipTransition);
			return true;
		});
		set('exitSong', function(?skipTransition:Bool = false)
		{
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

		// Character control
		set('getCharacterX', function(type:String)
		{
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
		set('getCharacterY', function(type:String)
		{
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
			switch (target.trim().toLowerCase())
			{
				case 'gf', 'girlfriend':
					game.moveCameraToGirlfriend();
				case 'dad', 'opponent':
					game.moveCamera(true);
				default:
					game.moveCamera(false);
			}
		});
		set('characterDance', function(character:String)
		{
			switch (character.toLowerCase())
			{
				case 'dad':
					game.dad.dance();
				case 'gf' | 'girlfriend':
					if (game.gf != null)
						game.gf.dance();
				default:
					game.boyfriend.dance();
			}
		});

		// Camera
		set('setCameraScroll', function(x:Float, y:Float)
		{
			FlxG.camera.scroll.set(x - FlxG.width / 2, y - FlxG.height / 2);
		});
		set('setCameraFollowPoint', function(x:Float, y:Float)
		{
			game.camFollow.setPosition(x, y);
		});
		set('addCameraScroll', function(?x:Float = 0, ?y:Float = 0)
		{
			FlxG.camera.scroll.add(x, y);
		});
		set('addCameraFollowPoint', function(?x:Float = 0, ?y:Float = 0)
		{
			game.camFollow.x += x;
			game.camFollow.y += y;
		});
		set('getCameraScrollX', function()
		{
			return FlxG.camera.scroll.x + FlxG.width / 2;
		});
		set('getCameraScrollY', function()
		{
			return FlxG.camera.scroll.y + FlxG.height / 2;
		});
		set('getCameraFollowX', function()
		{
			return game.camFollow.x;
		});
		set('getCameraFollowY', function()
		{
			return game.camFollow.y;
		});
		set('cameraShake', function(camera:String, intensity:Float, duration:Float)
		{
			LuaUtils.cameraFromString(camera).shake(intensity, duration);
		});
		set('cameraFlash', function(camera:String, color:String, duration:Float, forced:Bool)
		{
			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});
		set('cameraFade', function(camera:String, color:String, duration:Float, forced:Bool, ?fadeOut:Bool = false)
		{
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, fadeOut, null, forced);
		});

		// Mouse
		set('getMouseX', function(?camera:String = 'game')
		{
			return FlxG.mouse.getScreenPosition(LuaUtils.cameraFromString(camera)).x;
		});
		set('getMouseY', function(?camera:String = 'game')
		{
			return FlxG.mouse.getScreenPosition(LuaUtils.cameraFromString(camera)).y;
		});
		set('mouseClicked', function(?button:String = 'left')
		{
			var click:Bool = FlxG.mouse.justPressed;
			switch (button.trim().toLowerCase())
			{
				case 'middle':
					click = FlxG.mouse.justPressedMiddle;
				case 'right':
					click = FlxG.mouse.justPressedRight;
			}
			return click;
		});
		set('mousePressed', function(?button:String = 'left')
		{
			var press:Bool = FlxG.mouse.pressed;
			switch (button.trim().toLowerCase())
			{
				case 'middle':
					press = FlxG.mouse.pressedMiddle;
				case 'right':
					press = FlxG.mouse.pressedRight;
			}
			return press;
		});
		set('mouseReleased', function(?button:String = 'left')
		{
			var released:Bool = FlxG.mouse.justReleased;
			switch (button.trim().toLowerCase())
			{
				case 'middle':
					released = FlxG.mouse.justReleasedMiddle;
				case 'right':
					released = FlxG.mouse.justReleasedRight;
			}
			return released;
		});

		// Sprites
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

		// Sound
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
		set('getSoundVolume', function(tag:String)
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
			return 0;
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

		// Animation
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

		// Object utilities
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
				pythonTrace('getPropertyFromClass: Class $className not found', false, false, FlxColor.RED);
				return null;
			}
			return Reflect.getProperty(myClass, variable);
		});
		set('setPropertyFromClass', function(className:String, variable:String, value:Dynamic)
		{
			var myClass:Dynamic = Type.resolveClass(className);
			if (myClass == null)
			{
				pythonTrace('setPropertyFromClass: Class $className not found', false, false, FlxColor.RED);
				return false;
			}
			Reflect.setProperty(myClass, variable, value);
			return true;
		});

		// Object position utilities
		set('getMidpointX', function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getMidpoint().x;
			return 0;
		});
		set('getMidpointY', function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getMidpoint().y;
			return 0;
		});
		set('getGraphicMidpointX', function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getGraphicMidpoint().x;
			return 0;
		});
		set('getGraphicMidpointY', function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getGraphicMidpoint().y;
			return 0;
		});
		set('getScreenPositionX', function(variable:String, ?camera:String = 'game')
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).x;
			return 0;
		});
		set('getScreenPositionY', function(variable:String, ?camera:String = 'game')
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).y;
			return 0;
		});

		// Object transform
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
			pythonTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
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
			pythonTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
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
			pythonTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
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
			pythonTrace("screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
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
			pythonTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		set('setScrollFactor', function(obj:String, scrollX:Float, scrollY:Float)
		{
			var object:FlxObject = LuaUtils.getObjectDirectly(obj);
			if (object != null)
				object.scrollFactor.set(scrollX, scrollY);
		});

		// Bar colors
		set('setHealthBarColors', function(left:String, right:String)
		{
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
			var left_color:Null<FlxColor> = null;
			var right_color:Null<FlxColor> = null;
			if (left != null && left != '')
				left_color = CoolUtil.colorFromString(left);
			if (right != null && right != '')
				right_color = CoolUtil.colorFromString(right);
			game.timeBar.setColors(left_color, right_color);
		});

		// Dialogue & video
		set('startDialogue', function(dialogueFile:String, ?music:String = null)
		{
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
					pythonTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				}
				else
					pythonTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
			}
		else
		{
			pythonTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
			if (game.endingSong)
				game.endSong();
			else
				game.startCountdown();
		}
			return false;
		});

		set('startVideo', function(videoFile:String, ?canSkip:Bool = true, ?forMidSong:Bool = false, ?shouldLoop:Bool = false, ?playOnLoad:Bool = true)
		{
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
				pythonTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
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

		// Debug
		set('debugPrint', function(text:Dynamic = '', ?color:FlxColor = null)
		{
			if (color == null)
				color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});

		// Mod settings
		set("getModSetting", function(saveTag:String, ?modName:String = null)
		{
			#if MODS_ALLOWED
			if (modName == null)
			{
				if (this.modFolder == null)
				{
					pythonTrace('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', false, false, FlxColor.RED);
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
			#else
			pythonTrace("getModSetting: Mods are disabled in this build!", false, false, FlxColor.RED);
			return null;
			#end
		});

		// Close script
		set("close", function()
		{
			closed = true;
			Logger.info('Closing Python script $origin');
			return closed;
		});

		// Add custom functions
		for (name => func in customFunctions)
		{
			if (func != null)
				set(name, func);
		}

		#if DISCORD_ALLOWED DiscordClient.addPythonCallbacks(this); #end
		// #if ACHIEVEMENTS_ALLOWED Achievements.addPythonCallbacks(this); #end // wip
		// #if TRANSLATIONS_ALLOWED Language.addPythonCallbacks(this); #end // wip
		ReflectionFunctions.implementPython(this);
		// TextFunctions.implementPython(this); // wip
		// ExtraFunctions.implementPython(this); // wip
		// CustomSubstate.implementPython(this); // wip
		// ShaderFunctions.implementPython(this); // wip
	}

	public static function pythonTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE)
	{
		if (PlayState.instance != null)
			PlayState.instance.addTextToDebug(text, color);
	}

	public function stop()
	{
		closed = true;
		if (interp != null)
		{
			interp.stop();
			interp = null;
		}
	}

	public function destroy()
	{
		stop();
		parser = null;
		interp = null;
		returnValue = null;
		#if LUA_ALLOWED parentLua = null; #end
	}
}
#else
// Fallback version if Python is not allowed
class Python
{
	public var origin:String = null;
	public var closed:Bool = true;

	public function new(?parent:Dynamic, ?file:String = '', ?varsToBring:Any = null, ?manualRun:Bool = false)
	{
		Logger.error("[Python] Python is not allowed on this platform!");
		if (PlayState.instance != null)
			PlayState.instance.addTextToDebug("Python: Python is not allowed on this platform!", FlxColor.RED);
	}

	public function execute(code:String):Dynamic
	{
		Logger.error("[Python] Python is not allowed on this platform!");
		if (PlayState.instance != null)
			PlayState.instance.addTextToDebug("Python: Python is not allowed on this platform!", FlxColor.RED);
		return null;
	}

	public function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		return null;
	}

	public function exists(func:String):Bool
	{
		return false;
	}

	public function set(variable:String, arg:Dynamic)
	{
	}

	public function stop()
	{
	}

	public function destroy()
	{
		if (PlayState.instance != null)
			PlayState.instance.addTextToDebug("Python: Python is not allowed on this platform!", FlxColor.RED);
		Logger.error("[Python] Python is not allowed on this platform!");
	}
}
#end
