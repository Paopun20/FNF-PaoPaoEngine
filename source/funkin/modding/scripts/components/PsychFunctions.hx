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
import funkin.modding.objects.ModchartSprite;
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
import funkin.modding.scripts.ScriptPack;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
#end
#if MODS_ALLOWED
import funkin.backend.Mods;
#end
#if LUA_ALLOWED
import funkin.modding.scripts.LuaScript;
#end
#if HSCRIPT_ALLOWED
import funkin.modding.scripts.HScript;
#end
#if PYTHON_ALLOWED
import funkin.modding.scripts.Python;
#end

class PsychFunctions {
	public static function implement(lua:LuaScript, pack:ScriptPack) {
		var game = PlayState.instance;

		inline function resolveExclusions(exclusions:Array<String>, ignoreSelf:Bool):Array<Script> {
			if (exclusions == null)
				exclusions = [];

			if (ignoreSelf && !exclusions.contains(lua.scriptName))
				exclusions.push(lua.scriptName);

			return pack.getScriptsByName(exclusions);
		}

		// Lua shit
		lua.set('luaDebugMode', false);
		lua.set('luaDeprecatedWarnings', true);
		lua.set('inChartEditor', false);

		// Song/Week shit
		lua.set('curBpm', Conductor.bpm);
		lua.set('bpm', PlayState.SONG.bpm);
		lua.set('scrollSpeed', PlayState.SONG.speed);
		lua.set('crochet', Conductor.crochet);
		lua.set('stepCrochet', Conductor.stepCrochet);
		lua.set('songLength', FlxG.sound.music.length);
		lua.set('songName', PlayState.SONG.song);
		lua.set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		lua.set('startedCountdown', false);
		lua.set('curStage', PlayState.SONG.stage);

		lua.set('isStoryMode', PlayState.isStoryMode);
		lua.set('difficulty', PlayState.storyDifficulty);

		lua.set('difficultyName', Difficulty.getString());
		lua.set('difficultyPath', Paths.formatToSongPath(Difficulty.getString()));
		lua.set('weekRaw', PlayState.storyWeek);
		lua.set('week', WeekData.weeksList[PlayState.storyWeek]);
		lua.set('seenCutscene', PlayState.seenCutscene);
		lua.set('hasVocals', PlayState.SONG.needsVoices);

		// Camera poo
		lua.set('cameraX', 0);
		lua.set('cameraY', 0);

		// Screen stuff
		lua.set('screenWidth', FlxG.width);
		lua.set('screenHeight', FlxG.height);

		// PlayState variables
		lua.set('curSection', 0);
		lua.set('curBeat', 0);
		lua.set('curStep', 0);
		lua.set('curDecBeat', 0);
		lua.set('curDecStep', 0);

		lua.set('score', 0);
		lua.set('misses', 0);
		lua.set('hits', 0);
		lua.set('combo', 0);

		lua.set('rating', 0);
		lua.set('ratingName', '');
		lua.set('ratingFC', '');
		lua.set('version', MainMenuState.psychEngineVersion.trim());

		lua.set('inGameOver', false);
		lua.set('mustHitSection', false);
		lua.set('altAnim', false);
		lua.set('gfSection', false);

		// Other settings
		lua.set('downscroll', ClientPrefs.data.downScroll);
		lua.set('middlescroll', ClientPrefs.data.middleScroll);
		lua.set('framerate', ClientPrefs.data.framerate);
		lua.set('ghostTapping', ClientPrefs.data.ghostTapping);
		lua.set('hideHud', ClientPrefs.data.hideHud);
		lua.set('timeBarType', ClientPrefs.data.timeBarType);
		lua.set('scoreZoom', ClientPrefs.data.scoreZoom);
		lua.set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		lua.set('flashingLights', ClientPrefs.data.flashing);
		lua.set('noteOffset', ClientPrefs.data.noteOffset);
		lua.set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		lua.set('noResetButton', ClientPrefs.data.noReset);
		lua.set('lowQuality', ClientPrefs.data.lowQuality);
		lua.set('shadersEnabled', ClientPrefs.data.shaders);
		lua.set('currentModDirectory', Mods.currentModDirectory);

		// Noteskin/Splash
		lua.set('noteSkin', ClientPrefs.data.noteSkin);
		lua.set('noteSkinPostfix', Note.getNoteSkinPostfix());
		lua.set('splashSkin', ClientPrefs.data.splashSkin);
		lua.set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
		lua.set('splashAlpha', ClientPrefs.data.splashAlpha);

		// build target (windows, mac, linux, etc.)
		lua.set('buildTarget', LuaUtils.getBuildTarget());

		lua.set("getRunningScripts", function():Array<String> {
			var runningScripts:Array<String> = [];
			if (pack == null)
				return runningScripts;
			for (script in pack.scripts) {
				#if LUA_ALLOWED
				if (Std.isOfType(script, LuaScript))
					runningScripts.push(cast(script, LuaScript).scriptName);
				#end
			}
			return runningScripts;
		});

		lua.set("setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(lua.scriptName))
				exclusions.push(lua.scriptName);
			var excludeObjs = resolveExclusions(exclusions, ignoreSelf);
			pack.set(varName, arg, excludeObjs);
		});

		lua.set("setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(lua.scriptName))
				exclusions.push(lua.scriptName);
			var excludeObjs = resolveExclusions(exclusions, ignoreSelf);
			pack.setOnly(ScriptType.HSCRIPT, varName, arg, excludeObjs);
		});

		lua.set("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(lua.scriptName))
				exclusions.push(lua.scriptName);
			var excludeObjs = resolveExclusions(exclusions, ignoreSelf);
			pack.setOnly(ScriptType.LUA, varName, arg, excludeObjs);
		});

		lua.set("setOnPython", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(lua.scriptName))
				exclusions.push(lua.scriptName);
			var excludeObjs = resolveExclusions(exclusions, ignoreSelf);
			pack.setOnly(ScriptType.HSCRIPT, varName, arg, excludeObjs);
		});

		lua.set("callOnScripts",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null) {
				var excludeObjs = resolveExclusions(excludeScripts, ignoreSelf);
				var result = pack.call(funcName, args, ignoreStops, excludeObjs, excludeValues);
				return result != null ? result : LuaUtils.Function_Continue;
			});

		lua.set("callOnLuas",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null) {
				var excludeObjs = resolveExclusions(excludeScripts, ignoreSelf);
				var result = pack.callOnly(ScriptType.LUA, funcName, args, ignoreStops, excludeObjs, excludeValues);
				return result != null ? result : LuaUtils.Function_Continue;
			});

		lua.set("callOnHScript",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null) {
				var excludeObjs = resolveExclusions(excludeScripts, ignoreSelf);
				var result = pack.callOnly(ScriptType.HSCRIPT, funcName, args, ignoreStops, excludeObjs, excludeValues);
				return result != null ? result : LuaUtils.Function_Continue;
			});

		lua.set("callOnPython",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null) {
				var excludeObjs = resolveExclusions(excludeScripts, ignoreSelf);
				var result = pack.callOnly(ScriptType.PYTHON, funcName, args, ignoreStops, excludeObjs, excludeValues);
				return result != null ? result : LuaUtils.Function_Continue;
			});

		lua.set("callScript", function(luaFile:String, funcName:String, ?args:Array<Dynamic> = null) {
			if (args == null)
				args = [];
			var luaPath:String = findScript(luaFile);
			if (luaPath != null)
				for (script in pack.scripts) {
					#if LUA_ALLOWED
					if (Std.isOfType(script, LuaScript)) {
						var luaInstance:LuaScript = cast script;
						if (luaInstance.scriptName == luaPath)
							return luaInstance.call(funcName, args);
					}
					#end
				}
			return null;
		});

		lua.set("isRunning", function(scriptFile:String):Bool {
			var luaPath:String = findScript(scriptFile);
			if (luaPath != null) {
				for (script in pack.scripts) {
					#if LUA_ALLOWED
					if (Std.isOfType(script, LuaScript)) {
						var luaInstance:LuaScript = cast script;
						if (luaInstance.scriptName == luaPath)
							return true;
					}
					#end
				}
			}
			#if HSCRIPT_ALLOWED
			var hscriptPath:String = findScript(scriptFile, '.hx');
			if (hscriptPath != null) {
				for (script in pack.scripts) {
					if (Std.isOfType(script, HScript)) {
						var hscriptInstance:HScript = cast script;
						if (hscriptInstance.origin == hscriptPath)
							return true;
					}
				}
			}
			#end
			#if PYTHON_ALLOWED
			var pythonPath:String = findScript(scriptFile, '.py');
			if (pythonPath != null) {
				for (script in pack.scripts) {
					if (Std.isOfType(script, Python)) {
						var pythonInstance:Python = cast script;
						if (pythonInstance.origin == pythonPath)
							return true;
					}
				}
			}
			#end
			return false;
		});

		lua.set("setVar", function(varName:String, value:Dynamic) {
			MusicBeatState.getVariables().set(varName, ReflectionFunctions.parseSingleInstance(value));
			return value;
		});

		lua.set("getVar", function(varName:String):Dynamic {
			return MusicBeatState.getVariables().get(varName);
		});

		lua.set("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) {
			var luaPath:String = findScript(luaFile);
			if (luaPath != null) {
				if (!ignoreAlreadyRunning)
					for (script in pack.scripts) {
						#if LUA_ALLOWED
						if (Std.isOfType(script, LuaScript)) {
							var luaInstance:LuaScript = cast script;
							if (luaInstance.scriptName == luaPath) {
								CoolLog.info('addLuaScript: The script "' + luaPath + '" is already running!');
								return;
							}
						}
						#end
					}
				#if LUA_ALLOWED
				var newScript = new LuaScript(luaPath);
				pack.add(newScript);
				newScript.execute();
				#end
				return;
			}
			CoolLog.info("addLuaScript: Script doesn't exist!");
		});

		lua.set("addHScript", function(scriptFile:String, ?ignoreAlreadyRunning:Bool = false) {
			#if HSCRIPT_ALLOWED
			var scriptPath:String = findScript(scriptFile, '.hx');
			if (scriptPath != null) {
				if (!ignoreAlreadyRunning) {
					for (script in pack.scripts) {
						if (Std.isOfType(script, HScript)) {
							var hscriptInstance:HScript = cast script;
							if (hscriptInstance.origin == scriptPath) {
								CoolLog.info('addHScript: The script "' + scriptPath + '" is already running!');
								return;
							}
						}
					}
				}
				var newScript = new HScript(scriptPath);
				pack.add(newScript);
				newScript.execute();
				return;
			}
			CoolLog.info("addHScript: Script doesn't exist!");
			#else
			CoolLog.info("addHScript: HScript is not supported on this platform!");
			#end
		});

		lua.set("addPython", function(scriptFile:String, ?ignoreAlreadyRunning:Bool = false) {
			#if PYTHON_ALLOWED
			var scriptPath:String = findScript(scriptFile, '.py');
			if (scriptPath != null) {
				if (!ignoreAlreadyRunning) {
					for (script in pack.scripts) {
						if (Std.isOfType(script, Python)) {
							var pythonInstance:Python = cast script;
							if (pythonInstance.origin == scriptPath) {
								CoolLog.info('addPython: The script "' + scriptPath + '" is already running!');
								return;
							}
						}
					}
				}
				var newScript = new Python(scriptPath);
				pack.add(newScript);
				newScript.execute();
				return;
			}
			CoolLog.info("addPython: Script doesn't exist!");
			#else
			CoolLog.info("addPython: Python is not supported on this platform!");
			#end
		});

		lua.set("removeLuaScript", function(luaFile:String):Bool {
			var luaPath:String = findScript(luaFile);
			if (luaPath != null) {
				var foundAny:Bool = false;
				for (script in pack.scripts) {
					#if LUA_ALLOWED
					if (Std.isOfType(script, LuaScript)) {
						var luaInstance:LuaScript = cast script;
						if (luaInstance.scriptName == luaPath) {
							luaInstance.destroy();
							pack.remove(luaInstance);
							foundAny = true;
						}
					}
					#end
				}
				if (foundAny)
					return true;
			}
			CoolLog.info('removeLuaScript: Script $luaFile isn\'t running!');
			return false;
		});

		lua.set("removeHScript", function(scriptFile:String):Bool {
			#if HSCRIPT_ALLOWED
			var scriptPath:String = findScript(scriptFile, '.hx');
			if (scriptPath != null) {
				var foundAny:Bool = false;
				for (script in pack.scripts) {
					if (Std.isOfType(script, HScript)) {
						var hscriptInstance:HScript = cast script;
						if (hscriptInstance.origin == scriptPath) {
							hscriptInstance.destroy();
							pack.remove(hscriptInstance);
							foundAny = true;
						}
					}
				}
				if (foundAny)
					return true;
			}
			CoolLog.info('removeHScript: Script $scriptFile isn\'t running!');
			return false;
			#else
			CoolLog.info("removeHScript: HScript is not supported on this platform!");
			return false;
			#end
		});

		lua.set("removePython", function(scriptFile:String):Bool {
			#if PYTHON_ALLOWED
			var scriptPath:String = findScript(scriptFile, '.py');
			if (scriptPath != null) {
				var foundAny:Bool = false;
				for (script in pack.scripts) {
					if (Std.isOfType(script, Python)) {
						var pythonInstance:Python = cast script;
						if (pythonInstance.origin == scriptPath) {
							pythonInstance.destroy();
							pack.remove(pythonInstance);
							foundAny = true;
						}
					}
				}
				if (foundAny)
					return true;
			}
			CoolLog.info("removePython: Python script $scriptFile isn't running!");
			return false;
			#else
			CoolLog.info("removePython: Python is not supported on this platform!");
			return false;
			#end
		});

		lua.set("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			var animated = gridX != 0 || gridY != 0;

			if (split.length > 1) {
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && image != null && image.length > 0) {
				spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			}
		});

		lua.set("loadFrames", function(variable:String, image:String, spriteType:String = 'auto') {
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && image != null && image.length > 0) {
				LuaUtils.loadFrames(spr, image, spriteType);
			}
		});

		lua.set("loadMultipleFrames", function(variable:String, images:Array<String>) {
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && images != null && images.length > 0) {
				spr.frames = Paths.getMultiAtlas(images);
			}
		});

		lua.set("getObjectOrder", function(obj:String, ?group:String = null):Int {
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(obj);
			if (leObj != null) {
				if (group != null) {
					var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
					if (groupOrArray != null) {
						switch (Type.typeof(groupOrArray)) {
							case TClass(Array):
								return groupOrArray.indexOf(leObj);
							default:
								return Reflect.getProperty(groupOrArray, 'members').indexOf(leObj);
						}
					} else {
						CoolLog.info('getObjectOrder: Group $group doesn\'t exist!');
						return -1;
					}
				}
				var groupOrArray:Dynamic = CustomSubstate.instance != null ? CustomSubstate.instance : LuaUtils.getTargetInstance();
				return groupOrArray.members.indexOf(leObj);
			}
			CoolLog.info('getObjectOrder: Object $obj doesn\'t exist!');
			return -1;
		});

		lua.set("setObjectOrder", function(obj:String, position:Int, ?group:String = null) {
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(obj);
			if (leObj != null) {
				if (group != null) {
					var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
					if (groupOrArray != null) {
						switch (Type.typeof(groupOrArray)) {
							case TClass(Array):
								groupOrArray.remove(leObj);
								groupOrArray.insert(position, leObj);
							default:
								groupOrArray.remove(leObj, true);
								groupOrArray.insert(position, leObj);
						}
					} else
						CoolLog.info('setObjectOrder: Group $group doesn\'t exist!');
				} else {
					var groupOrArray:Dynamic = CustomSubstate.instance != null ? CustomSubstate.instance : LuaUtils.getTargetInstance();
					groupOrArray.remove(leObj, true);
					groupOrArray.insert(position, leObj);
				}
				return;
			}
			CoolLog.info('setObjectOrder: Object $obj doesn\'t exist!');
		});

		lua.set("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, ?options:Any = null) {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null) {
				if (values != null) {
					var myOptions:LuaTweenOptions = LuaUtils.getLuaTween(options);
					if (tag != null) {
						var variables = MusicBeatState.getVariables();
						var originalTag:String = 'tween_' + LuaUtils.formatVariable(tag);
						variables.set(tag, FlxTween.tween(penisExam, values, duration, myOptions != null ? {
							type: myOptions.type,
							ease: myOptions.ease,
							startDelay: myOptions.startDelay,
							loopDelay: myOptions.loopDelay,
							onUpdate: function(twn:FlxTween) {
								if (myOptions.onUpdate != null)
									pack.callOnly(ScriptType.LUA, myOptions.onUpdate, [originalTag, vars]);
							},
							onStart: function(twn:FlxTween) {
								if (myOptions.onStart != null)
									pack.callOnly(ScriptType.LUA, myOptions.onStart, [originalTag, vars]);
							},
							onComplete: function(twn:FlxTween) {
								if (twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD)
									variables.remove(tag);
								if (myOptions.onComplete != null)
									pack.callOnly(ScriptType.LUA, myOptions.onComplete, [originalTag, vars]);
							}
						} : null));
						return tag;
					} else
						FlxTween.tween(penisExam, values, duration, myOptions != null ? {
							type: myOptions.type,
							ease: myOptions.ease,
							startDelay: myOptions.startDelay,
							loopDelay: myOptions.loopDelay,
							onUpdate: function(twn:FlxTween) {
								if (myOptions.onUpdate != null)
									pack.callOnly(ScriptType.LUA, myOptions.onUpdate, [null, vars]);
							},
							onStart: function(twn:FlxTween) {
								if (myOptions.onStart != null)
									pack.callOnly(ScriptType.LUA, myOptions.onStart, [null, vars]);
							},
							onComplete: function(twn:FlxTween) {
								if (myOptions.onComplete != null)
									pack.callOnly(ScriptType.LUA, myOptions.onComplete, [null, vars]);
							}
						} : null);
				} else
					CoolLog.info('startTween: No values on 2nd argument!');
			} else
				CoolLog.info('startTween: Couldnt find object: ' + vars);
			return null;
		});

		lua.set("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return oldTweenFunction(pack, tag, vars, {x: value}, duration, ease, 'doTweenX');
		});

		lua.set("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return oldTweenFunction(pack, tag, vars, {y: value}, duration, ease, 'doTweenY');
		});

		lua.set("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return oldTweenFunction(pack, tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
		});

		lua.set("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return oldTweenFunction(pack, tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
		});

		lua.set("doTweenZoom", function(tag:String, camera:String, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			switch (camera.toLowerCase()) {
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
			return oldTweenFunction(pack, tag, camera, {zoom: value}, duration, ease, 'doTweenZoom');
		});

		lua.set("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ?ease:String = 'linear') {
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null) {
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;

				if (tag != null) {
					var originalTag:String = tag;
					tag = LuaUtils.formatVariable('tween_$tag');
					var variables = MusicBeatState.getVariables();
					variables.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {
						ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							variables.remove(tag);
							pack.callOnly(ScriptType.LUA, 'onTweenCompleted', [originalTag, vars]);
						}
					}));
					return tag;
				} else
					FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {ease: LuaUtils.getTweenEaseByString(ease)});
			} else
				CoolLog.info('doTweenColor: Couldnt find object: ' + vars);
			return null;
		});

		lua.set("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return noteTweenFunction(game, pack, tag, note, {x: value}, duration, ease);
		});

		lua.set("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return noteTweenFunction(game, pack, tag, note, {y: value}, duration, ease);
		});

		lua.set("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return noteTweenFunction(game, pack, tag, note, {angle: value}, duration, ease);
		});

		lua.set("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return noteTweenFunction(game, pack, tag, note, {alpha: value}, duration, ease);
		});

		lua.set("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			return noteTweenFunction(game, pack, tag, note, {direction: value}, duration, ease);
		});

		lua.set("mouseClicked", function(?button:String = 'left'):Bool {
			var click:Bool = FlxG.mouse.justPressed;
			switch (button.trim().toLowerCase()) {
				case 'middle':
					click = FlxG.mouse.justPressedMiddle;
				case 'right':
					click = FlxG.mouse.justPressedRight;
			}
			return click;
		});

		lua.set("mousePressed", function(?button:String = 'left'):Bool {
			var press:Bool = FlxG.mouse.pressed;
			switch (button.trim().toLowerCase()) {
				case 'middle':
					press = FlxG.mouse.pressedMiddle;
				case 'right':
					press = FlxG.mouse.pressedRight;
			}
			return press;
		});

		lua.set("mouseReleased", function(?button:String = 'left'):Bool {
			var released:Bool = FlxG.mouse.justReleased;
			switch (button.trim().toLowerCase()) {
				case 'middle':
					released = FlxG.mouse.justReleasedMiddle;
				case 'right':
					released = FlxG.mouse.justReleasedRight;
			}
			return released;
		});

		lua.set("cancelTween", function(tag:String) LuaUtils.cancelTween(tag));

		lua.set("runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			LuaUtils.cancelTimer(tag);
			var variables = MusicBeatState.getVariables();

			var originalTag:String = tag;
			tag = LuaUtils.formatVariable('timer_$tag');

			var localPack = pack;

			variables.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				try {
					if (tmr.finished)
						variables.remove(tag);

					if (localPack != null) {
						localPack.callOnly(ScriptType.LUA, 'onTimerCompleted', [originalTag, tmr.loops, tmr.loopsLeft]);
					}
				} catch (e:Dynamic) {
					CoolLog.error('Timer callback error: ' + e);
				}
			}, loops));
			return tag;
		});

		lua.set("cancelTimer", function(tag:String) LuaUtils.cancelTimer(tag));

		lua.set("FlxColor", function(color:String) return FlxColor.fromString(color));
		lua.set("getColorFromName", function(color:String) return FlxColor.fromString(color));
		lua.set("getColorFromString", function(color:String) return FlxColor.fromString(color));
		lua.set("getColorFromHex", function(color:String) return FlxColor.fromString('#$color'));

		lua.set("addCharacterToList", function(name:String, type:String) {
			if (game == null)
				return;
			var charType:Int = 0;
			switch (type.toLowerCase()) {
				case 'dad':
					charType = 1;
				case 'gf' | 'girlfriend':
					charType = 2;
			}
			game.addCharacterToList(name, charType);
		});

		lua.set("precacheImage", function(name:String, ?allowGPU:Bool = true) {
			Paths.image(name, allowGPU);
		});

		lua.set("precacheSound", function(name:String) {
			Paths.sound(name);
		});

		lua.set("precacheMusic", function(name:String) {
			Paths.music(name);
		});

		lua.set("cameraSetTarget", function(target:String) {
			if (game == null)
				return;
			switch (target.trim().toLowerCase()) {
				case 'gf', 'girlfriend':
					game.moveCameraToGirlfriend();
				case 'dad', 'opponent':
					game.moveCamera(true);
				default:
					game.moveCamera(false);
			}
		});

		lua.set("setCameraScroll", function(x:Float, y:Float) FlxG.camera.scroll.set(x - FlxG.width / 2, y - FlxG.height / 2));
		lua.set("setCameraFollowPoint", function(x:Float, y:Float) if (game != null)
			game.camFollow.setPosition(x, y));
		lua.set("addCameraScroll", function(?x:Float = 0, ?y:Float = 0) FlxG.camera.scroll.add(x, y));
		lua.set("addCameraFollowPoint", function(?x:Float = 0, ?y:Float = 0) {
			if (game != null) {
				game.camFollow.x += x;
				game.camFollow.y += y;
			}
		});
		lua.set("getCameraScrollX", function():Float return FlxG.camera.scroll.x + FlxG.width / 2);
		lua.set("getCameraScrollY", function():Float return FlxG.camera.scroll.y + FlxG.height / 2);

		lua.set("cameraShake", function(camera:String, intensity:Float, duration:Float) {
			LuaUtils.cameraFromString(camera).shake(intensity, duration);
		});

		lua.set("cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool) {
			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});

		lua.set("cameraFade", function(camera:String, color:String, duration:Float, forced:Bool, ?fadeOut:Bool = false) {
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, fadeOut, null, forced);
		});

		lua.set("setRatingPercent", function(value:Float) {
			if (game != null) {
				game.ratingPercent = value;
				pack.set('rating', game.ratingPercent);
			}
		});

		lua.set("setRatingName", function(value:String) {
			if (game != null) {
				game.ratingName = value;
				pack.set('ratingName', game.ratingName);
			}
		});

		lua.set("setRatingFC", function(value:String) {
			if (game != null) {
				game.ratingFC = value;
				pack.set('ratingFC', game.ratingFC);
			}
		});

		lua.set("updateScoreText", function() if (game != null)
			game.updateScoreText());

		lua.set("getMouseX", function(?camera:String = 'game'):Float {
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getViewPosition(cam).x;
		});

		lua.set("getMouseY", function(?camera:String = 'game'):Float {
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getViewPosition(cam).y;
		});

		lua.set("getMidpointX", function(variable:String):Float {
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().x;
			return 0;
		});

		lua.set("getMidpointY", function(variable:String):Float {
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().y;
			return 0;
		});

		lua.set("getGraphicMidpointX", function(variable:String):Float {
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().x;
			return 0;
		});

		lua.set("getGraphicMidpointY", function(variable:String):Float {
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().y;
			return 0;
		});

		lua.set("getScreenPositionX", function(variable:String, ?camera:String = 'game'):Float {
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).x;
			return 0;
		});

		lua.set("getScreenPositionY", function(variable:String, ?camera:String = 'game'):Float {
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).y;
			return 0;
		});

		lua.set("characterDance", function(character:String) {
			if (game == null)
				return;
			switch (character.toLowerCase()) {
				case 'dad':
					game.dad.dance();
				case 'gf' | 'girlfriend':
					if (game.gf != null)
						game.gf.dance();
				default:
					game.boyfriend.dance();
			}
		});

		lua.set("makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0) {
				leSprite.loadGraphic(Paths.image(image));
			}
			MusicBeatState.getVariables().set(tag, leSprite);
			leSprite.active = true;
		});

		lua.set("makeAnimatedLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = 'auto') {
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);

			if (image != null && image.length > 0) {
				LuaUtils.loadFrames(leSprite, image, spriteType);
			}
			MusicBeatState.getVariables().set(tag, leSprite);
		});

		lua.set("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF') {
			var spr:FlxSprite = LuaUtils.getObjectDirectly(obj);
			if (spr != null)
				spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
		});

		lua.set("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Float = 24, loop:Bool = true):Bool {
			var obj:FlxSprite = cast LuaUtils.getObjectDirectly(obj);
			if (obj != null && obj.animation != null) {
				obj.animation.addByPrefix(name, prefix, framerate, loop);
				if (obj.animation.curAnim == null) {
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

		lua.set("addAnimation", function(obj:String, name:String, frames:Any, framerate:Float = 24, loop:Bool = true):Bool {
			return LuaUtils.addAnimByIndices(obj, name, null, frames, framerate, loop);
		});

		lua.set("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:Any, framerate:Float = 24, loop:Bool = false):Bool {
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});

		lua.set("playAnim", function(obj:String, name:String, ?forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Bool {
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj);
			if (obj == null)
				return false;

			if (obj.playAnim != null) {
				obj.playAnim(name, forced, reverse, startFrame);
				return true;
			} else {
				if (obj.anim != null)
					obj.anim.play(name, forced, reverse, startFrame);
				else
					obj.animation.play(name, forced, reverse, startFrame);
				return true;
			}
			return false;
		});

		lua.set("addOffset", function(obj:String, anim:String, x:Float, y:Float):Bool {
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj);
			if (obj != null && obj.addOffset != null) {
				obj.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		lua.set("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
			if (game != null && game.getLuaObject(obj) != null) {
				game.getLuaObject(obj).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (object != null) {
				object.scrollFactor.set(scrollX, scrollY);
			}
		});

		lua.set("addLuaSprite", function(tag:String, ?inFront:Bool = false) {
			var mySprite:FlxSprite = MusicBeatState.getVariables().get(tag);
			if (mySprite == null)
				return;

			var instance = LuaUtils.getTargetInstance();
			if (inFront)
				instance.add(mySprite);
			else {
				if (game == null || !game.isDead)
					instance.insert(instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), mySprite);
				else if (GameOverSubstate.instance != null)
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
			}
		});

		lua.set("setGraphicSize", function(obj:String, x:Float, y:Float = 0, updateHitbox:Bool = true) {
			if (game != null && game.getLuaObject(obj) != null) {
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.setGraphicSize(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null) {
				poop.setGraphicSize(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			CoolLog.info('setGraphicSize: Couldnt find object: ' + obj);
		});

		lua.set("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
			if (game != null && game.getLuaObject(obj) != null) {
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.scale.set(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null) {
				poop.scale.set(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			CoolLog.info('scaleObject: Couldnt find object: ' + obj);
		});

		lua.set("updateHitbox", function(obj:String) {
			if (game != null && game.getLuaObject(obj) != null) {
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null) {
				poop.updateHitbox();
				return;
			}
			CoolLog.info('updateHitbox: Couldnt find object: ' + obj);
		});

		lua.set("removeLuaSprite", function(tag:String, destroy:Bool = true, ?group:String = null) {
			var obj:FlxSprite = LuaUtils.getObjectDirectly(tag);
			if (obj == null || obj.destroy == null)
				return;

			var groupObj:Dynamic = null;
			if (group == null)
				groupObj = LuaUtils.getTargetInstance();
			else
				groupObj = LuaUtils.getObjectDirectly(group);

			groupObj.remove(obj, true);
			if (destroy) {
				MusicBeatState.getVariables().remove(tag);
				obj.destroy();
			}
		});

		lua.set("luaSpriteExists", function(tag:String):Bool {
			var obj:FlxSprite = MusicBeatState.getVariables().get(tag);
			return (obj != null && (Std.isOfType(obj, ModchartSprite) || Std.isOfType(obj, ModchartAnimateSprite)));
		});

		lua.set("luaTextExists", function(tag:String):Bool {
			var obj:FlxText = MusicBeatState.getVariables().get(tag);
			return (obj != null && Std.isOfType(obj, FlxText));
		});

		lua.set("luaSoundExists", function(tag:String):Bool {
			var obj:FlxSound = MusicBeatState.getVariables().get('sound_$tag');
			return (obj != null && Std.isOfType(obj, FlxSound));
		});

		lua.set("setHealthBarColors", function(left:String, right:String) {
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

		lua.set("setTimeBarColors", function(left:String, right:String) {
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

		lua.set("setObjectCamera", function(obj:String, camera:String = 'game'):Bool {
			if (game != null) {
				var real:FlxBasic = game.getLuaObject(obj);
				if (real != null) {
					real.cameras = [LuaUtils.cameraFromString(camera)];
					return true;
				}
			}

			var split:Array<String> = obj.split('.');
			var object:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (object != null) {
				object.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			CoolLog.info("setObjectCamera: Object " + obj + " doesn't exist!");
			return false;
		});

		lua.set("setBlendMode", function(obj:String, blend:String = ''):Bool {
			if (game != null) {
				var real:FlxSprite = game.getLuaObject(obj);
				if (real != null) {
					real.blend = LuaUtils.blendModeFromString(blend);
					return true;
				}
			}

			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null) {
				spr.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}
			CoolLog.info("setBlendMode: Object " + obj + " doesn't exist!");
			return false;
		});

		lua.set("screenCenter", function(obj:String, pos:String = 'xy') {
			var spr:FlxObject = null;
			if (game != null)
				spr = game.getLuaObject(obj);

			if (spr == null) {
				var split:Array<String> = obj.split('.');
				spr = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1) {
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				}
			}

			if (spr != null) {
				switch (pos.trim().toLowerCase()) {
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
			CoolLog.info("screenCenter: Object " + obj + " doesn't exist!");
		});

		lua.set("objectsOverlap", function(obj1:String, obj2:String):Bool {
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxBasic> = [];
			for (i in 0...namesArray.length) {
				var real:FlxBasic = null;
				if (game != null)
					real = game.getLuaObject(namesArray[i]);
				if (real != null)
					objectsArray.push(real);
				else
					objectsArray.push(Reflect.getProperty(LuaUtils.getTargetInstance(), namesArray[i]));
			}
			return (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]));
		});

		lua.set("getPixelColor", function(obj:String, x:Int, y:Int) {
			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null)
				return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});

		lua.set("debugPrint", function(text:Dynamic = '', color:String = 'WHITE') {
			CoolLog.info(text);
		});

		lua.set("getModSetting", function(saveTag:String, ?modName:String = null):Dynamic {
			#if MODS_ALLOWED
			if (modName == null) {
				modName = lua.folderName;
			}
			return LuaUtils.getModSetting(saveTag, modName);
			#else
			CoolLog.warning("getModSetting: Mods are disabled in this build!");
			return null;
			#end
		});

		lua.set("close", function():Bool {
			lua.closed = true;
			return lua.closed;
		});

		lua.set("playSound", function(sound:String, ?volume:Float = 1, ?tag:String = null, ?loop:Bool = false) {
			if (tag != null && tag.length > 0) {
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('sound_$tag');
				var variables = MusicBeatState.getVariables();
				var oldSnd = variables.get(tag);
				if (oldSnd != null) {
					oldSnd.stop();
					oldSnd.destroy();
				}

				variables.set(tag, FlxG.sound.play(Paths.sound(sound), volume, loop, null, true, function() {
					if (!loop)
						variables.remove(tag);
					pack.callOnly(ScriptType.LUA, 'onSoundFinished', [originalTag]);
				}));
				return tag;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
			return null;
		});

		lua.set("playMusic", function(sound:String, ?volume:Float = 1, ?loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});

		lua.set("stopSound", function(tag:String) {
			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var variables = MusicBeatState.getVariables();
				var snd:FlxSound = variables.get(tag);
				if (snd != null) {
					snd.stop();
					variables.remove(tag);
				}
			}
		});

		lua.set("pauseSound", function(tag:String) {
			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music != null)
					FlxG.sound.music.pause();
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					snd.pause();
			}
		});
		lua.set("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music != null)
					FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					snd.fadeIn(duration, fromValue, toValue);
			}
		});
		lua.set("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music != null)
					FlxG.sound.music.fadeOut(duration, toValue);
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					snd.fadeOut(duration, toValue);
			}
		});
		lua.set("soundFadeCancel", function(tag:String) {
			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music != null && FlxG.sound.music.fadeTween != null)
					FlxG.sound.music.fadeTween.cancel();
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null && snd.fadeTween != null)
					snd.fadeTween.cancel();
			}
		});
		lua.set("getSoundVolume", function(tag:String) {
			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music != null)
					return FlxG.sound.music.volume;
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					return snd.volume;
			}
			return 0;
		});
		lua.set("setSoundVolume", function(tag:String, value:Float) {
			if (tag == null || tag.length < 1) {
				tag = LuaUtils.formatVariable('sound_$tag');
				if (FlxG.sound.music != null) {
					FlxG.sound.music.volume = value;
					return;
				}
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					snd.volume = value;
			}
		});
		lua.set("getSoundTime", function(tag:String) {
			if (tag == null || tag.length < 1) {
				return FlxG.sound.music != null ? FlxG.sound.music.time : 0;
			}
			tag = LuaUtils.formatVariable('sound_$tag');
			var snd:FlxSound = MusicBeatState.getVariables().get(tag);
			return snd != null ? snd.time : 0;
		});
		lua.set("setSoundTime", function(tag:String, value:Float) {
			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music != null) {
					FlxG.sound.music.time = value;
					return;
				}
			} else {
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					snd.time = value;
			}
		});
		lua.set("getSoundPitch", function(tag:String) {
			#if FLX_PITCH
			tag = LuaUtils.formatVariable('sound_$tag');
			var snd:FlxSound = MusicBeatState.getVariables().get(tag);
			return snd != null ? snd.pitch : 1;
			#else
			CoolLog.warning("getSoundPitch: Sound Pitch is not supported on this platform!");
			return 1;
			#end
		});
		lua.set("setSoundPitch", function(tag:String, value:Float, ?doPause:Bool = false) {
			#if FLX_PITCH
			tag = LuaUtils.formatVariable('sound_$tag');
			var snd:FlxSound = MusicBeatState.getVariables().get(tag);
			if (snd != null) {
				var wasResumed:Bool = snd.playing;
				if (doPause)
					snd.pause();
				snd.pitch = value;
				if (doPause && wasResumed)
					snd.play();
			}

			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music != null) {
					var wasResumed:Bool = FlxG.sound.music.playing;
					if (doPause)
						FlxG.sound.music.pause();
					FlxG.sound.music.pitch = value;
					if (doPause && wasResumed)
						FlxG.sound.music.play();
					return;
				}
			} else {
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null) {
					var wasResumed:Bool = snd.playing;
					if (doPause)
						snd.pause();
					snd.pitch = value;
					if (doPause && wasResumed)
						snd.play();
				}
			}
			#else
			CoolLog.warning("setSoundPitch: Sound Pitch is not supported on this platform!");
			#end
		});

		if (game != null) {
			// Gameplay settings
			lua.set('healthGainMult', game.healthGain);
			lua.set('healthLossMult', game.healthLoss);

			#if FLX_PITCH
			lua.set('playbackRate', game.playbackRate);
			#else
			lua.set('playbackRate', 1);
			#end

			lua.set('guitarHeroSustains', game.guitarHeroSustains);
			lua.set('instakillOnMiss', game.instakillOnMiss);
			lua.set('botPlay', game.cpuControlled);
			lua.set('practice', game.practiceMode);

			for (i in 0...4) {
				lua.set('defaultPlayerStrumX' + i, 0);
				lua.set('defaultPlayerStrumY' + i, 0);
				lua.set('defaultOpponentStrumX' + i, 0);
				lua.set('defaultOpponentStrumY' + i, 0);
			}

			// Default character
			lua.set('defaultBoyfriendX', game.BF_X);
			lua.set('defaultBoyfriendY', game.BF_Y);
			lua.set('defaultOpponentX', game.DAD_X);
			lua.set('defaultOpponentY', game.DAD_Y);
			lua.set('defaultGirlfriendX', game.GF_X);
			lua.set('defaultGirlfriendY', game.GF_Y);

			// Character shit
			lua.set('boyfriendName', PlayState.SONG.player1);
			lua.set('dadName', PlayState.SONG.player2);
			lua.set('gfName', PlayState.SONG.gfVersion);

			lua.set("startVideo",
				function(videoFile:String, ?canSkip:Bool = true, ?forMidSong:Bool = false, ?shouldLoop:Bool = false, ?playOnLoad:Bool = true) {
					#if VIDEOS_ALLOWED
					if (FileSystem.exists(Paths.video(videoFile))) {
						if (game.videoCutscene != null) {
							game.remove(game.videoCutscene);
							game.videoCutscene.destroy();
						}
						game.videoCutscene = game.startVideo(videoFile, forMidSong, canSkip, shouldLoop, playOnLoad);
						return true;
					} else {
						CoolLog.warning('startVideo: Video file not found: ' + videoFile);
					}
					return false;
					#else
					game.inCutscene = true;
					new FlxTimer().start(0.1, function(tmr:FlxTimer) {
						game.inCutscene = false;
						if (game.endingSong)
							game.endSong();
						else
							game.startCountdown();
					});
					return true;
					#end
				});

			lua.set("triggerEvent", function(name:String, ?value1:String = '', ?value2:String = ''):Bool {
				if (game != null) {
					game.triggerEvent(name, value1, value2, Conductor.songPosition);
					return true;
				}
				return false;
			});

			lua.set("startCountdown", function():Bool {
				if (game != null) {
					game.startCountdown();
					return true;
				}
				return false;
			});

			lua.set("endSong", function():Bool {
				if (game != null) {
					game.KillNotes();
					game.endSong();
					return true;
				}
				return false;
			});

			lua.set("restartSong", function(?skipTransition:Bool = false):Bool {
				if (game != null) {
					game.persistentUpdate = false;
					FlxG.camera.followLerp = 0;
					PauseSubState.restartSong(skipTransition);
					return true;
				}
				return false;
			});

			lua.set("exitSong", function(?skipTransition:Bool = false):Bool {
				if (skipTransition) {
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
				if (game != null)
					game.transitioning = true;
				FlxG.camera.followLerp = 0;
				#if MODS_ALLOWED
				Mods.loadTopMod();
				#end
				return true;
			});

			lua.set("getSongPosition", function():Float return Conductor.songPosition);

			lua.set("getCharacterX", function(type:String):Float {
				if (game == null)
					return 0;
				switch (type.toLowerCase()) {
					case 'dad' | 'opponent':
						return game.dadGroup.x;
					case 'gf' | 'girlfriend':
						return game.gfGroup.x;
					default:
						return game.boyfriendGroup.x;
				}
			});

			lua.set("setCharacterX", function(type:String, value:Float) {
				if (game == null)
					return;
				switch (type.toLowerCase()) {
					case 'dad' | 'opponent':
						game.dadGroup.x = value;
					case 'gf' | 'girlfriend':
						game.gfGroup.x = value;
					default:
						game.boyfriendGroup.x = value;
				}
			});

			lua.set("getCharacterY", function(type:String):Float {
				if (game == null)
					return 0;
				switch (type.toLowerCase()) {
					case 'dad' | 'opponent':
						return game.dadGroup.y;
					case 'gf' | 'girlfriend':
						return game.gfGroup.y;
					default:
						return game.boyfriendGroup.y;
				}
			});

			lua.set("setCharacterY", function(type:String, value:Float) {
				if (game == null)
					return;
				switch (type.toLowerCase()) {
					case 'dad' | 'opponent':
						game.dadGroup.y = value;
					case 'gf' | 'girlfriend':
						game.gfGroup.y = value;
					default:
						game.boyfriendGroup.y = value;
				}
			});

			lua.set("loadSong", function(?name:String = null, ?difficultyNum:Int = -1) {
				if (name == null || name.length < 1)
					name = Song.loadedSongName;
				if (difficultyNum == -1 && game != null)
					difficultyNum = PlayState.storyDifficulty;

				var poop = Highscore.formatSong(name, difficultyNum);
				Song.loadFromJson(poop, name);
				if (game != null)
					PlayState.storyDifficulty = difficultyNum;
				FlxG.state.persistentUpdate = false;
				LoadingState.loadAndSwitchState(new PlayState());

				if (FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					FlxG.sound.music.volume = 0;
				}
				if (game != null && game.vocals != null) {
					game.vocals.pause();
					game.vocals.volume = 0;
				}
				FlxG.camera.followLerp = 0;
			});

			lua.set("addScore", function(value:Int = 0) {
				if (game != null) {
					game.songScore += value;
					game.RecalculateRating();
				}
			});

			lua.set("addMisses", function(value:Int = 0) {
				if (game != null) {
					game.songMisses += value;
					game.RecalculateRating();
				}
			});

			lua.set("addHits", function(value:Int = 0) {
				if (game != null) {
					game.songHits += value;
					game.RecalculateRating();
				}
			});

			lua.set("setScore", function(value:Int = 0) {
				if (game != null) {
					game.songScore = value;
					game.RecalculateRating();
				}
			});

			lua.set("getScore", function():Int {
				if (game != null)
					return game.songScore;
				return 0;
			});

			lua.set("setMisses", function(value:Int = 0) {
				if (game != null) {
					game.songMisses = value;
					game.RecalculateRating();
				}
			});

			lua.set("getMisses", function():Int {
				if (game != null)
					return game.songMisses;
				return 0;
			});

			lua.set("setHits", function(value:Int = 0) {
				if (game != null) {
					game.songHits = value;
					game.RecalculateRating();
				}
			});

			lua.set("getHits", function():Int {
				if (game != null)
					return game.songHits;
				return 0;
			});

			lua.set("setHealth", function(value:Float = 1) if (game != null)
				game.health = value);
			lua.set("addHealth", function(value:Float = 0) if (game != null)
				game.health += value);
			lua.set("getHealth", function():Float return game != null ? game.health : 0);

			lua.set("getCameraFollowX", function():Float return game != null ? game.camFollow.x : 0);
			lua.set("getCameraFollowY", function():Float return game != null ? game.camFollow.y : 0);
		}

		#if DISCORD_ALLOWED DiscordClient.addLuaCallbacks(lua); #end
		#if ACHIEVEMENTS_ALLOWED Achievements.addCallbacks(lua); #end
		#if TRANSLATIONS_ALLOWED Language.addLuaCallbacks(lua); #end
		#if flxanimate FlxAnimateFunctions.implement(lua); #end
		HxLua.implement(lua);
		ReflectionFunctions.implement(lua);
		TextFunctions.implement(lua);
		ExtraFunctions.implement(lua);
		CustomSubstate.implement(lua);
		ShaderFunctions.implement(lua);
		DeprecatedFunctions.implement(lua);
	}

	private static function findScript(scriptFile:String, ext:String = '.lua'):String {
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

	private static function oldTweenFunction(pack:ScriptPack, tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String):Dynamic {
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		var variables = MusicBeatState.getVariables();
		if (target != null) {
			if (tag != null) {
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('tween_$tag');
				variables.set(tag, FlxTween.tween(target, tweenValue, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						variables.remove(tag);
						pack.callOnly(ScriptType.LUA, 'onTweenCompleted', [originalTag, vars]);
					}
				}));
			}
		} else
			CoolLog.warning('$funcName: Couldnt find object: $vars');
		return null;
	}

	private static function noteTweenFunction(game:PlayState, pack:ScriptPack, tag:String, note:Int, data:Dynamic, duration:Float, ease:String):Dynamic {
		var strumNote:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];
		if (strumNote == null)
			return null;

		if (tag != null) {
			var originalTag:String = tag;
			tag = LuaUtils.formatVariable('tween_$tag');
			LuaUtils.cancelTween(tag);

			var variables = MusicBeatState.getVariables();
			variables.set(tag, FlxTween.tween(strumNote, data, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween) {
					variables.remove(tag);
					pack.callOnly(ScriptType.LUA, 'onTweenCompleted', [originalTag]);
				}
			}));
			return tag;
		} else
			FlxTween.tween(strumNote, data, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		return null;
	}
}
