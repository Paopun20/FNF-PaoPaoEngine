package funkin.modding.scripts.components;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import funkin.backend.Highscore;
import funkin.backend.Song;
import funkin.backend.WeekData;
import funkin.backend.Paths;
import funkin.backend.Conductor;
import funkin.backend.Difficulty;
import funkin.backend.CoolUtil;
import funkin.frontend.cutscenes.DialogueBoxPsych;
import funkin.objects.Character;
import funkin.objects.Note;
import funkin.objects.NoteSplash;
import funkin.objects.StrumNote;
import funkin.modding.objects.DebugLuaText;
import funkin.modding.scripts.ModchartSprite;
import funkin.modding.scripts.utils.LuaUtils.LuaTweenOptions;
import funkin.modding.scripts.utils.LuaUtils;
import funkin.modding.scripts.utils.ImplementUtils;
import funkin.states.FreeplayState;
import funkin.states.MainMenuState;
import funkin.states.StoryMenuState;
import funkin.states.PlayState;
import funkin.backend.MusicBeatState;
import funkin.substates.GameOverSubstate;
import funkin.substates.PauseSubState;
import funkin.modding.scripts.components.CustomSubstate;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
#end
#if MODS_ALLOWED
import funkin.backend.Mods;
#end
#if LUA_ALLOWED
import funkin.modding.scripts.FunkinLua;
#end
#if HSCRIPT_ALLOWED
import funkin.modding.scripts.HScript;
#end
#if PYTHON_ALLOWED
import funkin.modding.scripts.Python;
#end

class PsychFunctions
{
	public static function implement(funk:Dynamic)
	{
		var impl = ImplementUtils.make(funk);
		var game:PlayState = PlayState.instance;

		impl("getRunningScripts", function():Array<String>
		{
			var runningScripts:Array<String> = [];
			if (game == null || game.scriptPack == null) return runningScripts;
			for (script in game.scriptPack.scripts)
			{
				#if LUA_ALLOWED
				if (Std.isOfType(script, FunkinLua))
					runningScripts.push(cast(script, FunkinLua).scriptName);
				#end
			}
			return runningScripts;
		});

		impl("setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null) exclusions = [];
			if (ignoreSelf && !exclusions.contains(funk.scriptName))
				exclusions.push(funk.scriptName);
			if (game != null) game.setOnScripts(varName, arg, exclusions);
		});

		impl("setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null) exclusions = [];
			if (ignoreSelf && !exclusions.contains(funk.scriptName))
				exclusions.push(funk.scriptName);
			if (game != null) game.setOnScripts(varName, arg, exclusions);
		});

		impl("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null) exclusions = [];
			if (ignoreSelf && !exclusions.contains(funk.scriptName))
				exclusions.push(funk.scriptName);
			if (game != null) game.setOnScripts(varName, arg, exclusions);
		});

		impl("setOnPython", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null) exclusions = [];
			if (ignoreSelf && !exclusions.contains(funk.scriptName))
				exclusions.push(funk.scriptName);
			if (game != null) game.setOnScripts(varName, arg, exclusions);
		});

		impl("callOnScripts", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null)
		{
			if (excludeScripts == null) excludeScripts = [];
			if (ignoreSelf && !excludeScripts.contains(funk.scriptName))
				excludeScripts.push(funk.scriptName);
			if (game != null) return game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return LuaUtils.Function_Continue;
		});

		impl("callOnLuas", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null)
		{
			if (excludeScripts == null) excludeScripts = [];
			if (ignoreSelf && !excludeScripts.contains(funk.scriptName))
				excludeScripts.push(funk.scriptName);
			if (game != null) return game.callOnLuas(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return LuaUtils.Function_Continue;
		});

		impl("callOnHScript", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null)
		{
			if (excludeScripts == null) excludeScripts = [];
			if (ignoreSelf && !excludeScripts.contains(funk.scriptName))
				excludeScripts.push(funk.scriptName);
			if (game != null) return game.callOnHScript(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return LuaUtils.Function_Continue;
		});

		impl("callOnPython", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null)
		{
			if (excludeScripts == null) excludeScripts = [];
			if (ignoreSelf && !excludeScripts.contains(funk.scriptName))
				excludeScripts.push(funk.scriptName);
			if (game != null) return game.callOnPython(funcName, args, ignoreStops, excludeScripts, excludeValues);
			return LuaUtils.Function_Continue;
		});

		impl("callScript", function(luaFile:String, funcName:String, ?args:Array<Dynamic> = null)
		{
			if (args == null) args = [];
			if (game == null) return null;
			var luaPath:String = findScript(luaFile);
			if (luaPath != null)
				for (script in game.scriptPack.scripts)
				{
					#if LUA_ALLOWED
					if (Std.isOfType(script, FunkinLua))
					{
						var luaInstance:FunkinLua = cast script;
						if (luaInstance.scriptName == luaPath)
							return luaInstance.call(funcName, args);
					}
					#end
				}
			return null;
		});

		impl("isRunning", function(scriptFile:String):Bool
		{
			if (game == null) return false;
			var luaPath:String = findScript(scriptFile);
			if (luaPath != null)
			{
				for (script in game.scriptPack.scripts)
				{
					#if LUA_ALLOWED
					if (Std.isOfType(script, FunkinLua))
					{
						var luaInstance:FunkinLua = cast script;
						if (luaInstance.scriptName == luaPath)
							return true;
					}
					#end
				}
			}
			#if HSCRIPT_ALLOWED
			var hscriptPath:String = findScript(scriptFile, '.hx');
			if (hscriptPath != null)
			{
				for (script in game.scriptPack.scripts)
				{
					if (Std.isOfType(script, HScript))
					{
						var hscriptInstance:HScript = cast script;
						if (hscriptInstance.origin == hscriptPath)
							return true;
					}
				}
			}
			#end
			#if PYTHON_ALLOWED
			var pythonPath:String = findScript(scriptFile, '.py');
			if (pythonPath != null)
			{
				for (script in game.scriptPack.scripts)
				{
					if (Std.isOfType(script, Python))
					{
						var pythonInstance:Python = cast script;
						if (pythonInstance.origin == pythonPath)
							return true;
					}
				}
			}
			#end
			return false;
		});

		impl("setVar", function(varName:String, value:Dynamic)
		{
			MusicBeatState.getVariables().set(varName, ReflectionFunctions.parseSingleInstance(value));
			return value;
		});

		impl("getVar", function(varName:String):Dynamic
		{
			return MusicBeatState.getVariables().get(varName);
		});

		impl("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			if (game == null) return;
			var luaPath:String = findScript(luaFile);
			if (luaPath != null)
			{
				if (!ignoreAlreadyRunning)
					for (script in game.scriptPack.scripts)
					{
						#if LUA_ALLOWED
						if (Std.isOfType(script, FunkinLua))
						{
							var luaInstance:FunkinLua = cast script;
							if (luaInstance.scriptName == luaPath)
							{
								trace('addLuaScript: The script "' + luaPath + '" is already running!');
								return;
							}
						}
						#end
					}
				#if LUA_ALLOWED
				new FunkinLua(luaPath);
				#end
				return;
			}
			trace("addLuaScript: Script doesn't exist!");
		});

		impl("addHScript", function(scriptFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			#if HSCRIPT_ALLOWED
			if (game == null) return;
			var scriptPath:String = findScript(scriptFile, '.hx');
			if (scriptPath != null)
			{
				if (!ignoreAlreadyRunning)
					for (script in game.scriptPack.scripts)
					{
						if (Std.isOfType(script, HScript))
						{
							var hscriptInstance:HScript = cast script;
							if (hscriptInstance.origin == scriptPath)
							{
								trace('addHScript: The script "' + scriptPath + '" is already running!');
								return;
							}
						}
					}
				PlayState.instance.initHScript(scriptPath);
				return;
			}
			trace("addHScript: Script doesn't exist!");
			#else
			trace("addHScript: HScript is not supported on this platform!");
			#end
		});

		impl("addPython", function(scriptFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			#if PYTHON_ALLOWED
			if (game == null) return;
			var scriptPath:String = findScript(scriptFile, '.py');
			if (scriptPath != null)
			{
				if (!ignoreAlreadyRunning)
					for (script in game.scriptPack.scripts)
					{
						if (Std.isOfType(script, Python))
						{
							var pythonInstance:Python = cast script;
							if (pythonInstance.origin == scriptPath)
							{
								trace('addPython: The script "' + scriptPath + '" is already running!');
								return;
							}
						}
					}
				PlayState.instance.initPython(scriptPath);
				return;
			}
			trace("addPython: Script doesn't exist!");
			#else
			trace("addPython: Python is not supported on this platform!");
			#end
		});

		impl("removeLuaScript", function(luaFile:String):Bool
		{
			if (game == null) return false;
			var luaPath:String = findScript(luaFile);
			if (luaPath != null)
			{
				var foundAny:Bool = false;
				for (script in game.scriptPack.scripts)
				{
					#if LUA_ALLOWED
					if (Std.isOfType(script, FunkinLua))
					{
						var luaInstance:FunkinLua = cast script;
						if (luaInstance.scriptName == luaPath)
						{
							luaInstance.stop();
							foundAny = true;
						}
					}
					#end
				}
				if (foundAny) return true;
			}
			trace('removeLuaScript: Script $luaFile isn\'t running!');
			return false;
		});

		impl("removeHScript", function(scriptFile:String):Bool
		{
			#if HSCRIPT_ALLOWED
			if (game == null) return false;
			var scriptPath:String = findScript(scriptFile, '.hx');
			if (scriptPath != null)
			{
				var foundAny:Bool = false;
				for (script in game.scriptPack.scripts)
				{
					if (Std.isOfType(script, HScript))
					{
						var hscriptInstance:HScript = cast script;
						if (hscriptInstance.origin == scriptPath)
						{
							hscriptInstance.destroy();
							foundAny = true;
						}
					}
				}
				if (foundAny) return true;
			}
			trace('removeHScript: Script $scriptFile isn\'t running!');
			return false;
			#else
			trace("removeHScript: HScript is not supported on this platform!");
			return false;
			#end
		});

		impl("removePython", function(scriptFile:String):Bool
		{
			#if PYTHON_ALLOWED
			if (game == null) return false;
			var scriptPath:String = findScript(scriptFile, '.py');
			if (scriptPath != null)
			{
				var foundAny:Bool = false;
				for (script in game.scriptPack.scripts)
				{
					if (Std.isOfType(script, Python))
					{
						var pythonInstance:Python = cast script;
						if (pythonInstance.origin == scriptPath)
						{
							pythonInstance.destroy();
							foundAny = true;
						}
					}
				}
				if (foundAny) return true;
			}
			trace("removePython: Python script $scriptFile isn't running!");
			return false;
			#else
			trace("removePython: Python is not supported on this platform!");
			return false;
			#end
		});

		impl("loadSong", function(?name:String = null, ?difficultyNum:Int = -1)
		{
			if (name == null || name.length < 1)
				name = Song.loadedSongName;
			if (difficultyNum == -1 && game != null)
				difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			Song.loadFromJson(poop, name);
			if (game != null) PlayState.storyDifficulty = difficultyNum;
			FlxG.state.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				FlxG.sound.music.volume = 0;
			}
			if (game != null && game.vocals != null)
			{
				game.vocals.pause();
				game.vocals.volume = 0;
			}
			FlxG.camera.followLerp = 0;
		});

		impl("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0)
		{
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			var animated = gridX != 0 || gridY != 0;

			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && image != null && image.length > 0)
			{
				spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			}
		});

		impl("loadFrames", function(variable:String, image:String, spriteType:String = 'auto')
		{
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && image != null && image.length > 0)
			{
				LuaUtils.loadFrames(spr, image, spriteType);
			}
		});

		impl("loadMultipleFrames", function(variable:String, images:Array<String>)
		{
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && images != null && images.length > 0)
			{
				spr.frames = Paths.getMultiAtlas(images);
			}
		});

		impl("getObjectOrder", function(obj:String, ?group:String = null):Int
		{
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(obj);
			if (leObj != null)
			{
				if (group != null)
				{
					var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
					if (groupOrArray != null)
					{
						switch (Type.typeof(groupOrArray))
						{
							case TClass(Array):
								return groupOrArray.indexOf(leObj);
							default:
								return Reflect.getProperty(groupOrArray, 'members').indexOf(leObj);
						}
					}
					else
					{
						trace('getObjectOrder: Group $group doesn\'t exist!');
						return -1;
					}
				}
				var groupOrArray:Dynamic = CustomSubstate.instance != null ? CustomSubstate.instance : LuaUtils.getTargetInstance();
				return groupOrArray.members.indexOf(leObj);
			}
			trace('getObjectOrder: Object $obj doesn\'t exist!');
			return -1;
		});

		impl("setObjectOrder", function(obj:String, position:Int, ?group:String = null)
		{
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(obj);
			if (leObj != null)
			{
				if (group != null)
				{
					var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
					if (groupOrArray != null)
					{
						switch (Type.typeof(groupOrArray))
						{
							case TClass(Array):
								groupOrArray.remove(leObj);
								groupOrArray.insert(position, leObj);
							default:
								groupOrArray.remove(leObj, true);
								groupOrArray.insert(position, leObj);
						}
					}
					else
						trace('setObjectOrder: Group $group doesn\'t exist!');
				}
				else
				{
					var groupOrArray:Dynamic = CustomSubstate.instance != null ? CustomSubstate.instance : LuaUtils.getTargetInstance();
					groupOrArray.remove(leObj, true);
					groupOrArray.insert(position, leObj);
				}
				return;
			}
			trace('setObjectOrder: Object $obj doesn\'t exist!');
		});

		impl("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, ?options:Any = null)
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null)
			{
				if (values != null)
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
									game.callOnLuas(myOptions.onUpdate, [originalTag, vars]);
							},
							onStart: function(twn:FlxTween)
							{
								if (myOptions.onStart != null && game != null)
									game.callOnLuas(myOptions.onStart, [originalTag, vars]);
							},
							onComplete: function(twn:FlxTween)
							{
								if (twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD)
									variables.remove(tag);
								if (myOptions.onComplete != null && game != null)
									game.callOnLuas(myOptions.onComplete, [originalTag, vars]);
							}
						} : null));
						return tag;
					}
					else
						FlxTween.tween(penisExam, values, duration, myOptions != null ? {
							type: myOptions.type,
							ease: myOptions.ease,
							startDelay: myOptions.startDelay,
							loopDelay: myOptions.loopDelay,
							onUpdate: function(twn:FlxTween)
							{
								if (myOptions.onUpdate != null && game != null)
									game.callOnLuas(myOptions.onUpdate, [null, vars]);
							},
							onStart: function(twn:FlxTween)
							{
								if (myOptions.onStart != null && game != null)
									game.callOnLuas(myOptions.onStart, [null, vars]);
							},
							onComplete: function(twn:FlxTween)
							{
								if (myOptions.onComplete != null && game != null)
									game.callOnLuas(myOptions.onComplete, [null, vars]);
							}
						} : null);
				}
				else
					trace('startTween: No values on 2nd argument!');
			}
			else
				trace('startTween: Couldnt find object: ' + vars);
			return null;
		});

		impl("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX');
		});

		impl("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY');
		});

		impl("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
		});

		impl("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
		});

		impl("doTweenZoom", function(tag:String, camera:String, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			switch (camera.toLowerCase())
			{
				case 'camgame' | 'game':
					camera = 'camGame';
				case 'camhud' | 'hud':
					camera = 'camHUD';
				case 'camother' | 'other':
					camera = 'camOther';
				default:
					var cam:FlxCamera = MusicBeatState.getVariables().get(camera);
					if (cam == null || !Std.isOfType(cam, FlxCamera))
						camera = 'camGame';
			}
			return oldTweenFunction(tag, camera, {zoom: value}, duration, ease, 'doTweenZoom');
		});

		impl("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ?ease:String = 'linear')
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null)
			{
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;

				if (tag != null)
				{
					var originalTag:String = tag;
					tag = LuaUtils.formatVariable('tween_$tag');
					var variables = MusicBeatState.getVariables();
					variables.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {
						ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween)
						{
							variables.remove(tag);
							if (game != null)
								game.callOnLuas('onTweenCompleted', [originalTag, vars]);
						}
					}));
					return tag;
				}
				else
					FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {ease: LuaUtils.getTweenEaseByString(ease)});
			}
			else
				trace('doTweenColor: Couldnt find object: ' + vars);
			return null;
		});

		impl("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {x: value}, duration, ease);
		});

		impl("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {y: value}, duration, ease);
		});

		impl("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {angle: value}, duration, ease);
		});

		impl("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {alpha: value}, duration, ease);
		});

		impl("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {direction: value}, duration, ease);
		});

		impl("mouseClicked", function(?button:String = 'left'):Bool
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

		impl("mousePressed", function(?button:String = 'left'):Bool
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

		impl("mouseReleased", function(?button:String = 'left'):Bool
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

		impl("cancelTween", function(tag:String) LuaUtils.cancelTween(tag));

		impl("runTimer", function(tag:String, time:Float = 1, loops:Int = 1)
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
					game.callOnLuas('onTimerCompleted', [originalTag, tmr.loops, tmr.loopsLeft]);
			}, loops));
			return tag;
		});

		impl("cancelTimer", function(tag:String) LuaUtils.cancelTimer(tag));

		impl("addScore", function(value:Int = 0)
		{
			if (game != null)
			{
				game.songScore += value;
				game.RecalculateRating();
			}
		});

		impl("addMisses", function(value:Int = 0)
		{
			if (game != null)
			{
				game.songMisses += value;
				game.RecalculateRating();
			}
		});

		impl("addHits", function(value:Int = 0)
		{
			if (game != null)
			{
				game.songHits += value;
				game.RecalculateRating();
			}
		});

		impl("setScore", function(value:Int = 0)
		{
			if (game != null)
			{
				game.songScore = value;
				game.RecalculateRating();
			}
		});

		impl("setMisses", function(value:Int = 0)
		{
			if (game != null)
			{
				game.songMisses = value;
				game.RecalculateRating();
			}
		});

		impl("setHits", function(value:Int = 0)
		{
			if (game != null)
			{
				game.songHits = value;
				game.RecalculateRating();
			}
		});

		impl("setHealth", function(value:Float = 1) if (game != null) game.health = value);
		impl("addHealth", function(value:Float = 0) if (game != null) game.health += value);
		impl("getHealth", function():Float return game != null ? game.health : 0);

		impl("FlxColor", function(color:String) return FlxColor.fromString(color));
		impl("getColorFromName", function(color:String) return FlxColor.fromString(color));
		impl("getColorFromString", function(color:String) return FlxColor.fromString(color));
		impl("getColorFromHex", function(color:String) return FlxColor.fromString('#$color'));

		impl("addCharacterToList", function(name:String, type:String)
		{
			if (game == null) return;
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

		impl("precacheImage", function(name:String, ?allowGPU:Bool = true)
		{
			Paths.image(name, allowGPU);
		});

		impl("precacheSound", function(name:String)
		{
			Paths.sound(name);
		});

		impl("precacheMusic", function(name:String)
		{
			Paths.music(name);
		});

		impl("triggerEvent", function(name:String, ?value1:String = '', ?value2:String = ''):Bool
		{
			if (game != null)
			{
				game.triggerEvent(name, value1, value2, Conductor.songPosition);
				return true;
			}
			return false;
		});

		impl("startCountdown", function():Bool
		{
			if (game != null)
			{
				game.startCountdown();
				return true;
			}
			return false;
		});

		impl("endSong", function():Bool
		{
			if (game != null)
			{
				game.KillNotes();
				game.endSong();
				return true;
			}
			return false;
		});

		impl("restartSong", function(?skipTransition:Bool = false):Bool
		{
			if (game != null)
			{
				game.persistentUpdate = false;
				FlxG.camera.followLerp = 0;
				PauseSubState.restartSong(skipTransition);
				return true;
			}
			return false;
		});

		impl("exitSong", function(?skipTransition:Bool = false):Bool
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

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			if (game != null) game.transitioning = true;
			FlxG.camera.followLerp = 0;
			#if MODS_ALLOWED
			Mods.loadTopMod();
			#end
			return true;
		});

		impl("getSongPosition", function():Float return Conductor.songPosition);

		impl("getCharacterX", function(type:String):Float
		{
			if (game == null) return 0;
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

		impl("setCharacterX", function(type:String, value:Float)
		{
			if (game == null) return;
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

		impl("getCharacterY", function(type:String):Float
		{
			if (game == null) return 0;
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

		impl("setCharacterY", function(type:String, value:Float)
		{
			if (game == null) return;
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

		impl("cameraSetTarget", function(target:String)
		{
			if (game == null) return;
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

		impl("setCameraScroll", function(x:Float, y:Float) FlxG.camera.scroll.set(x - FlxG.width / 2, y - FlxG.height / 2));
		impl("setCameraFollowPoint", function(x:Float, y:Float) if (game != null) game.camFollow.setPosition(x, y));
		impl("addCameraScroll", function(?x:Float = 0, ?y:Float = 0) FlxG.camera.scroll.add(x, y));
		impl("addCameraFollowPoint", function(?x:Float = 0, ?y:Float = 0)
		{
			if (game != null)
			{
				game.camFollow.x += x;
				game.camFollow.y += y;
			}
		});
		impl("getCameraScrollX", function():Float return FlxG.camera.scroll.x + FlxG.width / 2);
		impl("getCameraScrollY", function():Float return FlxG.camera.scroll.y + FlxG.height / 2);
		impl("getCameraFollowX", function():Float return game != null ? game.camFollow.x : 0);
		impl("getCameraFollowY", function():Float return game != null ? game.camFollow.y : 0);

		impl("cameraShake", function(camera:String, intensity:Float, duration:Float)
		{
			LuaUtils.cameraFromString(camera).shake(intensity, duration);
		});

		impl("cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});

		impl("cameraFade", function(camera:String, color:String, duration:Float, forced:Bool, ?fadeOut:Bool = false)
		{
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, fadeOut, null, forced);
		});

		impl("setRatingPercent", function(value:Float)
		{
			if (game != null)
			{
				game.ratingPercent = value;
				game.setOnScripts('rating', game.ratingPercent);
			}
		});

		impl("setRatingName", function(value:String)
		{
			if (game != null)
			{
				game.ratingName = value;
				game.setOnScripts('ratingName', game.ratingName);
			}
		});

		impl("setRatingFC", function(value:String)
		{
			if (game != null)
			{
				game.ratingFC = value;
				game.setOnScripts('ratingFC', game.ratingFC);
			}
		});

		impl("updateScoreText", function() if (game != null) game.updateScoreText());

		impl("getMouseX", function(?camera:String = 'game'):Float
		{
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});

		impl("getMouseY", function(?camera:String = 'game'):Float
		{
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});

		impl("getMidpointX", function(variable:String):Float
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().x;
			return 0;
		});

		impl("getMidpointY", function(variable:String):Float
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().y;
			return 0;
		});

		impl("getGraphicMidpointX", function(variable:String):Float
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().x;
			return 0;
		});

		impl("getGraphicMidpointY", function(variable:String):Float
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().y;
			return 0;
		});

		impl("getScreenPositionX", function(variable:String, ?camera:String = 'game'):Float
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).x;
			return 0;
		});

		impl("getScreenPositionY", function(variable:String, ?camera:String = 'game'):Float
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).y;
			return 0;
		});

		impl("characterDance", function(character:String)
		{
			if (game == null) return;
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

		impl("makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0)
		{
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0)
			{
				leSprite.loadGraphic(Paths.image(image));
			}
			MusicBeatState.getVariables().set(tag, leSprite);
			leSprite.active = true;
		});

		impl("makeAnimatedLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = 'auto')
		{
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);

			if (image != null && image.length > 0)
			{
				LuaUtils.loadFrames(leSprite, image, spriteType);
			}
			MusicBeatState.getVariables().set(tag, leSprite);
		});

		impl("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF')
		{
			var spr:FlxSprite = LuaUtils.getObjectDirectly(obj);
			if (spr != null)
				spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
		});

		impl("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Float = 24, loop:Bool = true):Bool
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

		impl("addAnimation", function(obj:String, name:String, frames:Any, framerate:Float = 24, loop:Bool = true):Bool
		{
			return LuaUtils.addAnimByIndices(obj, name, null, frames, framerate, loop);
		});

		impl("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:Any, framerate:Float = 24, loop:Bool = false):Bool
		{
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});

		impl("playAnim", function(obj:String, name:String, ?forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Bool
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

		impl("addOffset", function(obj:String, anim:String, x:Float, y:Float):Bool
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj);
			if (obj != null && obj.addOffset != null)
			{
				obj.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		impl("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float)
		{
			if (game != null && game.getLuaObject(obj) != null)
			{
				game.getLuaObject(obj).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (object != null)
			{
				object.scrollFactor.set(scrollX, scrollY);
			}
		});

		impl("addLuaSprite", function(tag:String, ?inFront:Bool = false)
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
				else if (GameOverSubstate.instance != null)
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
			}
		});

		impl("setGraphicSize", function(obj:String, x:Float, y:Float = 0, updateHitbox:Bool = true)
		{
			if (game != null && game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.setGraphicSize(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null)
			{
				poop.setGraphicSize(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			trace('setGraphicSize: Couldnt find object: ' + obj);
		});

		impl("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true)
		{
			if (game != null && game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.scale.set(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null)
			{
				poop.scale.set(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			trace('scaleObject: Couldnt find object: ' + obj);
		});

		impl("updateHitbox", function(obj:String)
		{
			if (game != null && game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null)
			{
				poop.updateHitbox();
				return;
			}
			trace('updateHitbox: Couldnt find object: ' + obj);
		});

		impl("removeLuaSprite", function(tag:String, destroy:Bool = true, ?group:String = null)
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

		impl("luaSpriteExists", function(tag:String):Bool
		{
			var obj:FlxSprite = MusicBeatState.getVariables().get(tag);
			return (obj != null && (Std.isOfType(obj, ModchartSprite) || Std.isOfType(obj, ModchartAnimateSprite)));
		});

		impl("luaTextExists", function(tag:String):Bool
		{
			var obj:FlxText = MusicBeatState.getVariables().get(tag);
			return (obj != null && Std.isOfType(obj, FlxText));
		});

		impl("luaSoundExists", function(tag:String):Bool
		{
			var obj:FlxSound = MusicBeatState.getVariables().get('sound_$tag');
			return (obj != null && Std.isOfType(obj, FlxSound));
		});

		impl("setHealthBarColors", function(left:String, right:String)
		{
			if (game == null) return;
			var left_color:Null<FlxColor> = null;
			var right_color:Null<FlxColor> = null;
			if (left != null && left != '')
				left_color = CoolUtil.colorFromString(left);
			if (right != null && right != '')
				right_color = CoolUtil.colorFromString(right);
			game.healthBar.setColors(left_color, right_color);
		});

		impl("setTimeBarColors", function(left:String, right:String)
		{
			if (game == null) return;
			var left_color:Null<FlxColor> = null;
			var right_color:Null<FlxColor> = null;
			if (left != null && left != '')
				left_color = CoolUtil.colorFromString(left);
			if (right != null && right != '')
				right_color = CoolUtil.colorFromString(right);
			game.timeBar.setColors(left_color, right_color);
		});

		impl("setObjectCamera", function(obj:String, camera:String = 'game'):Bool
		{
			if (game != null)
			{
				var real:FlxBasic = game.getLuaObject(obj);
				if (real != null)
				{
					real.cameras = [LuaUtils.cameraFromString(camera)];
					return true;
				}
			}

			var split:Array<String> = obj.split('.');
			var object:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (object != null)
			{
				object.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			trace("setObjectCamera: Object " + obj + " doesn't exist!");
			return false;
		});

		impl("setBlendMode", function(obj:String, blend:String = ''):Bool
		{
			if (game != null)
			{
				var real:FlxSprite = game.getLuaObject(obj);
				if (real != null)
				{
					real.blend = LuaUtils.blendModeFromString(blend);
					return true;
				}
			}

			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null)
			{
				spr.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}
			trace("setBlendMode: Object " + obj + " doesn't exist!");
			return false;
		});

		impl("screenCenter", function(obj:String, pos:String = 'xy')
		{
			var spr:FlxObject = null;
			if (game != null) spr = game.getLuaObject(obj);

			if (spr == null)
			{
				var split:Array<String> = obj.split('.');
				spr = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
				{
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				}
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
			trace("screenCenter: Object " + obj + " doesn't exist!");
		});

		impl("objectsOverlap", function(obj1:String, obj2:String):Bool
		{
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxBasic> = [];
			for (i in 0...namesArray.length)
			{
				var real:FlxBasic = null;
				if (game != null) real = game.getLuaObject(namesArray[i]);
				if (real != null)
					objectsArray.push(real);
				else
					objectsArray.push(Reflect.getProperty(LuaUtils.getTargetInstance(), namesArray[i]));
			}
			return (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]));
		});

		impl("getPixelColor", function(obj:String, x:Int, y:Int)
		{
			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null)
				return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});

		impl("debugPrint", function(text:Dynamic = '', color:String = 'WHITE')
		{
			if (PlayState.instance == null)
			{
				trace(text);
				return;
			}
			PlayState.instance.addTextToDebug(text, CoolUtil.colorFromString(color));
		});

		impl("getModSetting", function(saveTag:String, ?modName:String = null):Dynamic
		{
			#if MODS_ALLOWED
			if (modName == null)
			{
				modName = funk.folderName;
			}
			return LuaUtils.getModSetting(saveTag, modName);
			#else
			trace("getModSetting: Mods are disabled in this build!");
			return null;
			#end
		});

		impl("close", function():Bool
		{
			funk.closed = true;
			return funk.closed;
		});

		#if DISCORD_ALLOWED DiscordClient.addLuaCallbacks(funk); #end
		#if ACHIEVEMENTS_ALLOWED Achievements.addCallbacks(funk); #end
		#if TRANSLATIONS_ALLOWED Language.addLuaCallbacks(funk); #end
		#if flxanimate FlxAnimateFunctions.implement(funk); #end
		HxLua.implement(funk);
		ReflectionFunctions.implement(funk);
		TextFunctions.implement(funk);
		ExtraFunctions.implement(funk);
		CustomSubstate.implement(funk);
		ShaderFunctions.implement(funk);
		DeprecatedFunctions.implement(funk);
	}

	private static function findScript(scriptFile:String, ext:String = '.lua'):String
	{
		if (!scriptFile.endsWith(ext))
			scriptFile += ext;
		var preloadPath:String = Paths.getSharedPath(scriptFile);
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(scriptFile);
		if (FileSystem.exists(scriptFile))
			return scriptFile;
		else if (FileSystem.exists(path))
			return path;

		if (FileSystem.exists(preloadPath))
		#else
		if (Assets.exists(preloadPath))
		#end
		{
			return preloadPath;
		}
		return null;
	}

	private static function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String):Dynamic
	{
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		var variables = MusicBeatState.getVariables();
		if (target != null)
		{
			if (tag != null)
			{
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('tween_$tag');
				variables.set(tag, FlxTween.tween(target, tweenValue, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						variables.remove(tag);
						if (PlayState.instance != null)
							PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, vars]);
					}
				}));
			}
			else
				FlxTween.tween(target, tweenValue, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
			return tag;
		}
		else
			trace('$funcName: Couldnt find object: $vars');
		return null;
	}

	private static function noteTweenFunction(tag:String, note:Int, data:Dynamic, duration:Float, ease:String):Dynamic
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
}