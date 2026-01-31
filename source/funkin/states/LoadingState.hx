package funkin.states;

import lime.app.Future;
#if (sys || MULTITHREADED_LOADING)
import sys.thread.FixedThreadPool;
import sys.thread.Mutex;
#end
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import flixel.system.FlxAssets;
import flixel.FlxState;
import flash.media.Sound;
import funkin.backend.Song;
import funkin.backend.StageData;
import funkin.objects.Note;
import funkin.objects.NoteSplash;
#if HSCRIPT_ALLOWED
import funkin.modding.scripts.HScript;
#end

#if (cpp || MULTITHREADED_LOADING)
@:headerCode('
#include <iostream>
#include <thread>
')
#end
class LoadingState extends MusicBeatState
{
	public static var loaded:Int = 0;
	public static var loadMax:Int = 0;
	static var currentAssetName:String = "...";

	static var originalBitmapKeys:Map<String, String> = [];
	static var requestedBitmaps:Map<String, BitmapData> = [];
	#if (sys || MULTITHREADED_LOADING)
	static var mutex:Mutex;
	static var arrayMutex:Mutex; // Separate mutex for array operations
	static var threadPool:FixedThreadPool = null;
	#end

	inline static private function safeIncrementLoaded(?assetName:String):Void
	{
		#if (sys || MULTITHREADED_LOADING)
		if (mutex == null)
			mutex = new Mutex();
		mutex.acquire();
		#end
		loaded++;
		if (assetName != null)
			currentAssetName = assetName;
		#if (sys || MULTITHREADED_LOADING)
		mutex.release();
		#end
	}

	inline static private function safeGetLoadProgress():{loaded:Int, max:Int, assetName:String}
	{
		#if (sys || MULTITHREADED_LOADING)
		if (mutex == null)
			return {loaded: 0, max: 0, assetName: "..."};
		mutex.acquire();
		var result = {loaded: loaded, max: loadMax, assetName: currentAssetName};
		mutex.release();
		return result;
		#else
		return {loaded: loaded, max: loadMax, assetName: currentAssetName};
		#end
	}

	inline static private function safeSetLoadMax(value:Int):Void
	{
		#if (sys || MULTITHREADED_LOADING)
		if (mutex == null)
			mutex = new Mutex();
		mutex.acquire();
		#end
		loadMax = value;
		#if (sys || MULTITHREADED_LOADING)
		mutex.release();
		#end
	}

	function new(target:FlxState, stopMusic:Bool)
	{
		this.target = target;
		this.stopMusic = stopMusic;

		super();
	}

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true)
		MusicBeatState.switchState(getNextState(target, stopMusic, intrusive));

	var target:FlxState = null;
	var stopMusic:Bool = false;
	var dontUpdate:Bool = false;

	var barGroup:FlxSpriteGroup;
	var bar:FlxSprite;
	var barWidth:Int = 0;
	var intendedPercent:Float = 0;
	var curPercent:Float = 0;
	var stateChangeDelay:Float = 0;

	var loadingText:FlxText;
	var assetText:FlxText;

	var timePassed:Float = 0;

	#if HSCRIPT_ALLOWED
	var hscript:HScript;
	#end

	override function create()
	{
		persistentUpdate = true;
		barGroup = new FlxSpriteGroup();
		add(barGroup);

		var barBack:FlxSprite = new FlxSprite(0, 660).makeGraphic(1, 1, FlxColor.BLACK);
		barBack.scale.set(FlxG.width - 300, 25);
		barBack.updateHitbox();
		barBack.screenCenter(X);
		barGroup.add(barBack);

		bar = new FlxSprite(barBack.x + 5, barBack.y + 5).makeGraphic(1, 1, FlxColor.WHITE);
		bar.scale.set(0, 15);
		bar.updateHitbox();
		barGroup.add(bar);
		barWidth = Std.int(barBack.width - 10);

		#if HSCRIPT_ALLOWED
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.trim().length > 0)
		{
			var scriptPath:String = 'mods/${Mods.currentModDirectory}/data/LoadingScreen.hx'; // mods/My-Mod/data/LoadingScreen.hx
			if (FileSystem.exists(scriptPath))
			{
				try
				{
					hscript = new HScript(null, scriptPath);
					hscript.set('getLoaded', function() return loaded);
					hscript.set('getLoadMax', function() return loadMax);
					hscript.set('barBack', barBack);
					hscript.set('bar', bar);

					if (hscript.exists('onCreate'))
					{
						hscript.call('onCreate');
						CoolLog.info('initialized hscript interp successfully: $scriptPath');
						return super.create();
					}
					else
					{
						CoolLog.error('"$scriptPath" contains no \"onCreate" function, stopping script.');
					}
				}
				catch (e:Dynamic)
				{
					CoolLog.error('Error loading HScript from $scriptPath: $e');
				}
				if (hscript != null)
					hscript.destroy();
				hscript = null;
			}
		}
		#end

		var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(FlxG.width));
		bg.color = 0xFFD16FFF;
		bg.updateHitbox();
		addBehindBar(bg);

		loadingText = new FlxText(0, 550, FlxG.width, Language.getPhrase('now_loading', 'Now Loading', ['...']), 32);
		loadingText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		loadingText.borderSize = 2;
		addBehindBar(loadingText);

		assetText = new FlxText(0, 580, FlxG.width, Language.getPhrase('asset_loading', 'Asset Loading: ', ['N/A', '(67/[N/A])']), 32);
		assetText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		assetText.borderSize = 2;
		addBehindBar(assetText);

		super.create();

		if (stateChangeDelay <= 0 && checkLoaded())
		{
			dontUpdate = true;
			onLoad();
		}
	}

	function addBehindBar(obj:flixel.FlxBasic)
	{
		insert(members.indexOf(barGroup), obj);
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (dontUpdate)
			return;

		if (!transitioning)
		{
			if (!finishedLoading && checkLoaded())
			{
				if (stateChangeDelay <= 0)
				{
					transitioning = true;
					onLoad();
					return;
				}
				else
					stateChangeDelay = Math.max(0, stateChangeDelay - elapsed);
			}
			intendedPercent = loaded / loadMax;
		}

		if (curPercent != intendedPercent)
		{
			if (Math.abs(curPercent - intendedPercent) < 0.001)
				curPercent = intendedPercent;
			else
				curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));

			bar.scale.x = barWidth * curPercent;
			bar.updateHitbox();
		}

		#if HSCRIPT_ALLOWED
		if (hscript != null)
		{
			if (hscript.exists('onUpdate'))
				hscript.call('onUpdate', [elapsed]);
			return;
		}
		#end

		timePassed += elapsed;
		var dots:String = '';
		switch (Math.floor(timePassed % 1 * 3))
		{
			case 0:
				dots = '.';
			case 1:
				dots = '..';
			case 2:
				dots = '...';
		}
		loadingText.text = Language.getPhrase('now_loading', 'Now Loading{1}', [dots]);

		// Update asset loading text
		var progress = safeGetLoadProgress();
		assetText.text = Language.getPhrase('asset_loading', 'Asset Loading: {1} {2}', [progress.assetName, '(${progress.loaded}/${progress.max})']);
	}

	#if HSCRIPT_ALLOWED
	override function destroy()
	{
		if (hscript != null)
		{
			if (hscript.exists('onDestroy'))
				hscript.call('onDestroy');
			hscript.destroy();
		}
		hscript = null;
		super.destroy();
	}
	#end

	var finishedLoading:Bool = false;

	function onLoad()
	{
		_loaded();

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.camera.visible = false;
		MusicBeatState.switchState(target);
		transitioning = true;
		finishedLoading = true;
	}

	static function _loaded()
	{
		#if (sys || MULTITHREADED_LOADING)
		if (mutex != null)
			mutex.acquire();
		#end
		loaded = 0;
		loadMax = 0;
		currentAssetName = "...";
		initialThreadCompleted = true;
		isIntrusive = false;
		#if (sys || MULTITHREADED_LOADING)
		if (mutex != null)
			mutex.release();
		#end

		FlxTransitionableState.skipNextTransIn = true;
		#if (sys || MULTITHREADED_LOADING)
		if (threadPool != null)
			threadPool.shutdown();
		threadPool = null;
		mutex = null;
		arrayMutex = null;
		#end
	}

	public static function checkLoaded():Bool
	{
		// Thread-safe: Copy and clear maps atomically
		#if (sys || MULTITHREADED_LOADING)
		if (mutex == null)
			return false;

		mutex.acquire();
		#end
		var localRequestedBitmaps = requestedBitmaps.copy();
		var localOriginalBitmapKeys = originalBitmapKeys.copy();
		// Clear immediately to prevent lost updates
		requestedBitmaps.clear();
		originalBitmapKeys.clear();
		#if (sys || MULTITHREADED_LOADING)
		mutex.release();
		#end

		// Process bitmaps outside the mutex lock
		for (key => bitmap in localRequestedBitmaps)
		{
			if (bitmap != null && Paths.cacheBitmap(localOriginalBitmapKeys.get(key), bitmap) != null)
			{
				// CoolLog.info('finished preloading image $key');
			}
			else if (bitmap != null)
			{
				CoolLog.error('failed to cache image $key');
			}
			else
			{
				CoolLog.error('failed to load image $key');
			}
		}

		// Thread-safe check of completion status
		#if (sys || MULTITHREADED_LOADING)
		mutex.acquire();
		#end
		var result = (loaded >= loadMax && initialThreadCompleted);
		#if (sys || MULTITHREADED_LOADING)
		mutex.release();
		#end

		return result;
	}

	public static function loadNextDirectory()
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '')
			directory = weekDir;

		Paths.setCurrentLevel(directory);
		CoolLog.info('Setting asset folder to ' + directory);
	}

	static var isIntrusive:Bool = false;

	static function getNextState(target:FlxState, stopMusic = false, intrusive:Bool = true):FlxState
	{
		#if !SHOW_LOADING_SCREEN
		intrusive = false;
		#end

		LoadingState.isIntrusive = intrusive;
		_startPool();
		loadNextDirectory();

		if (intrusive)
			return new LoadingState(target, stopMusic);

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		#if (sys || MULTITHREADED_LOADING)
		while (true)
		{
			if (checkLoaded())
			{
				_loaded();
				break;
			}
			else
				Sys.sleep(0.001);
		}
		#else
		// For HTML5, load synchronously
		while (!checkLoaded())
		{
			// Just wait for the next frame
		}
		_loaded();
		#end
		return target;
	}

	static var imagesToPrepare:Array<String> = [];
	static var soundsToPrepare:Array<String> = [];
	static var musicToPrepare:Array<String> = [];
	static var songsToPrepare:Array<String> = [];

	public static function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null)
	{
		// Initialize array mutex if needed
		#if (sys || MULTITHREADED_LOADING)
		if (arrayMutex == null)
			arrayMutex = new Mutex();

		arrayMutex.acquire();
		#end
		if (images != null)
			imagesToPrepare = imagesToPrepare.concat(images);
		if (sounds != null)
			soundsToPrepare = soundsToPrepare.concat(sounds);
		if (music != null)
			musicToPrepare = musicToPrepare.concat(music);
		#if (sys || MULTITHREADED_LOADING)
		arrayMutex.release();
		#end
	}

	static var initialThreadCompleted:Bool = true;
	static var dontPreloadDefaultVoices:Bool = false;

	static function _startPool()
	{
		#if (sys || MULTITHREADED_LOADING)
		#if MULTITHREADED_LOADING
		// Due to the Main thread and Discord thread, we decrease it by 2.
		var threadCount:Int = Std.int(Math.max(1, getCPUThreadsCount() - #if DISCORD_ALLOWED 2 #else 1 #end));
		#else
		var threadCount:Int = 1;
		#end
		threadPool = new FixedThreadPool(threadCount);
		#end
	}

	public static function prepareToSong()
	{
		if (PlayState.SONG == null)
		{
			// Reset state safely
			#if (sys || MULTITHREADED_LOADING)
			arrayMutex = new Mutex();
			arrayMutex.acquire();
			#end
			imagesToPrepare = [];
			soundsToPrepare = [];
			musicToPrepare = [];
			songsToPrepare = [];
			#if (sys || MULTITHREADED_LOADING)
			arrayMutex.release();

			mutex = new Mutex();
			mutex.acquire();
			#end
			loaded = 0;
			loadMax = 0;
			currentAssetName = "...";
			initialThreadCompleted = true;
			isIntrusive = false;
			#if (sys || MULTITHREADED_LOADING)
			mutex.release();
			#end
			return;
		}

		_startPool();

		// Initialize mutexes before any threading
		#if (sys || MULTITHREADED_LOADING)
		if (arrayMutex == null)
			arrayMutex = new Mutex();
		if (mutex == null)
			mutex = new Mutex();

		arrayMutex.acquire();
		#end
		imagesToPrepare = [];
		soundsToPrepare = [];
		musicToPrepare = [];
		songsToPrepare = [];
		#if (sys || MULTITHREADED_LOADING)
		arrayMutex.release();

		mutex.acquire();
		#end
		initialThreadCompleted = false;
		currentAssetName = "...";
		#if (sys || MULTITHREADED_LOADING)
		mutex.release();
		#end

		var threadsCompleted:Int = 0;
		var threadsMax:Int = 0;
		#if (sys || MULTITHREADED_LOADING)
		var threadMutex = new Mutex(); // Local mutex for thread completion
		#end

		function completedThread()
		{
			#if (sys || MULTITHREADED_LOADING)
			threadMutex.acquire();
			#end
			threadsCompleted++;
			var allCompleted = (threadsCompleted == threadsMax);
			#if (sys || MULTITHREADED_LOADING)
			threadMutex.release();
			#end

			if (allCompleted)
			{
				clearInvalids();
				startThreads();

				// Thread-safe flag update
				#if (sys || MULTITHREADED_LOADING)
				if (mutex != null)
				{
					mutex.acquire();
					initialThreadCompleted = true;
					mutex.release();
				}
				#else
				initialThreadCompleted = true;
				#end
			}
		}

		var song:SwagSong = PlayState.SONG;
		var folder:String = Paths.formatToSongPath(Song.loadedSongName);

		new Future<Bool>(() ->
		{
			// LOAD NOTE IMAGE
			var noteSkin:String = Note.defaultNoteSkin;
			if (PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1)
				noteSkin = PlayState.SONG.arrowSkin;

			var customSkin:String = noteSkin + Note.getNoteSkinPostfix();
			if (Paths.fileExists('images/$customSkin.png', IMAGE))
				noteSkin = customSkin;

			// Thread-safe array access
			#if (sys || MULTITHREADED_LOADING)
			arrayMutex.acquire();
			#end
			imagesToPrepare.push(noteSkin);
			#if (sys || MULTITHREADED_LOADING)
			arrayMutex.release();
			#end

			// LOAD NOTE SPLASH IMAGE
			var noteSplash:String = NoteSplash.defaultNoteSplash;
			if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
				noteSplash = PlayState.SONG.splashSkin;
			else
				noteSplash += NoteSplash.getSplashSkinPostfix();

			#if (sys || MULTITHREADED_LOADING)
			arrayMutex.acquire();
			#end
			imagesToPrepare.push(noteSplash);
			#if (sys || MULTITHREADED_LOADING)
			arrayMutex.release();
			#end

			try
			{
				var path:String = Paths.json('$folder/preload');
				var json:Dynamic = null;

				#if MODS_ALLOWED
				var moddyFile:String = Paths.modsJson('$folder/preload');
				if (FileSystem.exists(moddyFile))
					json = Json.parse(File.getContent(moddyFile));
				else
					json = Json.parse(File.getContent(path));
				#else
				json = Json.parse(Assets.getText(path));
				#end

				if (json != null)
				{
					var imgs:Array<String> = [];
					var snds:Array<String> = [];
					var mscs:Array<String> = [];
					for (asset in Reflect.fields(json))
					{
						var filters:Int = Reflect.field(json, asset);
						var asset:String = asset.trim();

						if (filters < 0 || StageData.validateVisibility(filters))
						{
							if (asset.startsWith('images/'))
								imgs.push(asset.substr('images/'.length));
							else if (asset.startsWith('sounds/'))
								snds.push(asset.substr('sounds/'.length));
							else if (asset.startsWith('music/'))
								mscs.push(asset.substr('music/'.length));
						}
					}
					prepare(imgs, snds, mscs);
				}
			}
			catch (e:Dynamic)
			{
			}

			return true;
		}, isIntrusive).then((_) -> new Future<Bool>(() ->
			{
				if (song.stage == null || song.stage.length < 1)
					song.stage = StageData.vanillaSongStage(folder);

				var stageData:StageFile = StageData.getStageFile(song.stage);
				if (stageData != null)
				{
					var imgs:Array<String> = [];
					var snds:Array<String> = [];
					var mscs:Array<String> = [];
					if (stageData.preload != null)
					{
						for (asset in Reflect.fields(stageData.preload))
						{
							var filters:Int = Reflect.field(stageData.preload, asset);
							var asset:String = asset.trim();

							if (filters < 0 || StageData.validateVisibility(filters))
							{
								if (asset.startsWith('images/'))
									imgs.push(asset.substr('images/'.length));
								else if (asset.startsWith('sounds/'))
									snds.push(asset.substr('sounds/'.length));
								else if (asset.startsWith('music/'))
									mscs.push(asset.substr('music/'.length));
							}
						}
					}

					if (stageData.objects != null)
					{
						for (sprite in stageData.objects)
						{
							if (sprite.type == 'sprite' || sprite.type == 'animatedSprite')
								if ((sprite.filters < 0 || StageData.validateVisibility(sprite.filters)) && !imgs.contains(sprite.image))
									imgs.push(sprite.image);
						}
					}
					prepare(imgs, snds, mscs);
				}

				// Thread-safe array operations
				#if (sys || MULTITHREADED_LOADING)
				arrayMutex.acquire();
				#end
				songsToPrepare.push('$folder/Inst');
				#if (sys || MULTITHREADED_LOADING)
				arrayMutex.release();
				#end

				var player1:String = song.player1;
				var player2:String = song.player2;
				var gfVersion:String = song.gfVersion;
				var prefixVocals:String = song.needsVoices ? '$folder/Voices' : null;
				if (gfVersion == null)
					gfVersion = 'gf';

				dontPreloadDefaultVoices = false;
				preloadCharacter(player1, prefixVocals);

				if (!dontPreloadDefaultVoices && prefixVocals != null)
				{
					if (Paths.fileExists('$prefixVocals-Player.${Paths.SOUND_EXT}', SOUND, false, 'songs')
						&& Paths.fileExists('$prefixVocals-Opponent.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
					{
						#if (sys || MULTITHREADED_LOADING)
						arrayMutex.acquire();
						#end
						songsToPrepare.push('$prefixVocals-Player');
						songsToPrepare.push('$prefixVocals-Opponent');
						#if (sys || MULTITHREADED_LOADING)
						arrayMutex.release();
						#end
					}
					else if (Paths.fileExists('$prefixVocals.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
					{
						#if (sys || MULTITHREADED_LOADING)
						arrayMutex.acquire();
						#end
						songsToPrepare.push(prefixVocals);
						#if (sys || MULTITHREADED_LOADING)
						arrayMutex.release();
						#end
					}
				}

				if (player2 != player1)
				{
					#if (sys || MULTITHREADED_LOADING)
					threadMutex.acquire();
					#end
					threadsMax++;
					#if (sys || MULTITHREADED_LOADING)
					threadMutex.release();

					threadPool.run(() ->
					{
						try
						{
							preloadCharacter(player2, prefixVocals);
						}
						catch (e:Dynamic)
						{
						}
						completedThread();
					});
					#else
					// HTML5: run synchronously
					try
					{
						preloadCharacter(player2, prefixVocals);
					}
					catch (e:Dynamic)
					{
					}
					completedThread();
					#end
				}

				if (!stageData.hide_girlfriend && gfVersion != player2 && gfVersion != player1)
				{
					#if (sys || MULTITHREADED_LOADING)
					threadMutex.acquire();
					#end
					threadsMax++;
					#if (sys || MULTITHREADED_LOADING)
					threadMutex.release();

					threadPool.run(() ->
					{
						try
						{
							preloadCharacter(gfVersion);
						}
						catch (e:Dynamic)
						{
						}
						completedThread();
					});
					#else
					// HTML5: run synchronously
					try
					{
						preloadCharacter(gfVersion);
					}
					catch (e:Dynamic)
					{
					}
					completedThread();
					#end
				}

				// Final check for completion
				#if (sys || MULTITHREADED_LOADING)
				threadMutex.acquire();
				#end
				var allCompleted = (threadsCompleted == threadsMax);
				#if (sys || MULTITHREADED_LOADING)
				threadMutex.release();
				#end

				if (allCompleted)
				{
					clearInvalids();
					startThreads();

					#if (sys || MULTITHREADED_LOADING)
					if (mutex != null)
					{
						mutex.acquire();
						initialThreadCompleted = true;
						mutex.release();
					}
					#else
					initialThreadCompleted = true;
					#end
				}
				return true;
			}, isIntrusive)).onError((err:Dynamic) ->
			{
				CoolLog.error('ERROR! while preparing song: $err');
			});
	}

	public static function clearInvalids()
	{
		// This is called from the main thread before starting threads, so no mutex needed
		clearInvalidFrom(imagesToPrepare, 'images', '.png', IMAGE);
		clearInvalidFrom(soundsToPrepare, 'sounds', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(musicToPrepare, 'music', ' .${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(songsToPrepare, 'songs', '.${Paths.SOUND_EXT}', SOUND, 'songs');

		for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
			while (arr.contains(null))
				arr.remove(null);
	}

	static function clearInvalidFrom(arr:Array<String>, prefix:String, ext:String, type:AssetType, ?parentFolder:String = null)
	{
		// Process folder expansion before filtering - this is safe as it only reads
		for (folder in arr.copy())
		{
			var nam:String = folder.trim();
			if (nam.endsWith('/'))
			{
				for (subfolder in Mods.directoriesWithFile(Paths.getSharedPath(), '$prefix/$nam'))
				{
					#if (sys || MULTITHREADED_LOADING)
					for (file in FileSystem.readDirectory(subfolder))
					{
						if (file.endsWith(ext))
						{
							var toAdd:String = nam + haxe.io.Path.withoutExtension(file);
							if (!arr.contains(toAdd))
								arr.push(toAdd);
						}
					}
					#end
				}
			}
		}

		// Filter invalid entries - this modifies the array
		var i:Int = 0;
		while (i < arr.length)
		{
			var member:String = arr[i];
			var myKey = '$prefix/$member$ext';
			if (parentFolder == 'songs')
				myKey = '$member$ext';

			var doTrace:Bool = false;
			if (member.endsWith('/') || (!Paths.fileExists(myKey, type, false, parentFolder) && (doTrace = true)))
			{
				arr.remove(member);
				if (doTrace)
					CoolLog.info('Removed invalid $prefix: $member');
			}
			else
				i++;
		}
	}

	public static function startThreads()
	{
		#if (sys || MULTITHREADED_LOADING)
		mutex = new Mutex();
		// Set loadMax in a thread-safe way
		mutex.acquire();
		#end
		loadMax = imagesToPrepare.length + soundsToPrepare.length + musicToPrepare.length + songsToPrepare.length;
		loaded = 0;
		currentAssetName = "...";
		#if (sys || MULTITHREADED_LOADING)
		mutex.release();
		#end

		// then start threads
		_threadFunc();
	}

	static function _threadFunc()
	{
		_startPool();
		for (sound in soundsToPrepare)
			initThread(() -> preloadSound('sounds/$sound'), 'sound $sound');
		for (music in musicToPrepare)
			initThread(() -> preloadSound('music/$music'), 'music $music');
		for (song in songsToPrepare)
			initThread(() -> preloadSound(song, 'songs', true, false), 'song $song');

		// for images, they get to have their own thread
		for (image in imagesToPrepare)
			initThread(() -> preloadGraphic(image), 'image $image');
	}

	static function initThread(func:Void->Dynamic, traceData:String)
	{
		#if debug
		var threadSchedule = Sys.time();
		#end

		#if (sys || MULTITHREADED_LOADING)
		threadPool.run(() ->
		{
			#if debug
			var threadStart = Sys.time();
			CoolLog.info('$traceData took ${threadStart - threadSchedule}s to start preloading');
			#end

			try
			{
				if (func() != null)
				{
					#if debug
					var diff = Sys.time() - threadStart;
					CoolLog.info('finished preloading $traceData in ${diff}s');
					#end
				}
				else
					CoolLog.error('ERROR! fail on preloading $traceData');
			}
			catch (e:Dynamic)
			{
				CoolLog.error('ERROR! fail on preloading $traceData: $e');
			}

			// Use thread-safe increment
			safeIncrementLoaded(traceData);
		});
		#else
		// HTML5: run synchronously
		try
		{
			if (func() != null)
			{
				#if debug
				CoolLog.info('finished preloading $traceData');
				#end
			}
			else
				CoolLog.error('ERROR! fail on preloading $traceData');
		}
		catch (e:Dynamic)
		{
			CoolLog.error('ERROR! fail on preloading $traceData: $e');
		}

		safeIncrementLoaded(traceData);
		#end
	}

	inline private static function preloadCharacter(char:String, ?prefixVocals:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end

			var isAnimateAtlas:Bool = false;
			var img:String = character.image;
			img = img.trim();

			#if flxanimate
			var animToFind:String = Paths.getPath('images/$img/Animation.json', TEXT);
			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
				isAnimateAtlas = true;
			#end

			if (!isAnimateAtlas)
			{
				var split:Array<String> = img.split(',');
				#if (sys || MULTITHREADED_LOADING)
				if (arrayMutex != null)
					arrayMutex.acquire();
				#end
				for (file in split)
				{
					imagesToPrepare.push(file.trim());
				}
				#if (sys || MULTITHREADED_LOADING)
				if (arrayMutex != null)
					arrayMutex.release();
				#end
			}
			#if flxanimate
			else
			{
				#if (sys || MULTITHREADED_LOADING)
				if (arrayMutex != null)
					arrayMutex.acquire();
				#end
				for (i in 0...10)
				{
					var st:String = '$i';
					if (i == 0)
						st = '';

					if (Paths.fileExists('images/$img/spritemap$st.png', IMAGE))
					{
						imagesToPrepare.push('$img/spritemap$st');
						break;
					}
				}
				#if (sys || MULTITHREADED_LOADING)
				if (arrayMutex != null)
					arrayMutex.release();
				#end
			}
			#end

			if (prefixVocals != null && character.vocals_file != null && character.vocals_file.length > 0)
			{
				#if (sys || MULTITHREADED_LOADING)
				if (arrayMutex != null)
					arrayMutex.acquire();
				#end
				songsToPrepare.push(prefixVocals + "-" + character.vocals_file);
				#if (sys || MULTITHREADED_LOADING)
				if (arrayMutex != null)
					arrayMutex.release();
				#end

				if (char == PlayState.SONG.player1)
					dontPreloadDefaultVoices = true;
			}
		}
		catch (e:haxe.Exception)
		{
			CoolLog.error(e.details());
		}
	}

	// thread safe sound loader
	static function preloadSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true):Null<Sound>
	{
		var file:String = Paths.getPath(Language.getFileTranslation(key) + '.${Paths.SOUND_EXT}', SOUND, path, modsAllowed);

		if (!Paths.currentTrackedSounds.exists(file))
		{
			if (#if (sys || MULTITHREADED_LOADING) FileSystem.exists(file) || #end OpenFlAssets.exists(file, SOUND))
			{
				var sound:Sound = #if (sys || MULTITHREADED_LOADING) Sound.fromFile(file) #else OpenFlAssets.getSound(file, false) #end;
				#if (sys || MULTITHREADED_LOADING)
				if (mutex != null)
					mutex.acquire();
				#end
				Paths.currentTrackedSounds.set(file, sound);
				#if (sys || MULTITHREADED_LOADING)
				if (mutex != null)
					mutex.release();
				#end
			}
			else if (beepOnNull)
			{
				CoolLog.error('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSoundAddExtension('flixel/sounds/beep', true);
			}
		}
		#if (sys || MULTITHREADED_LOADING)
		if (mutex != null)
			mutex.acquire();
		#end
		Paths.localTrackedAssets.push(file);
		#if (sys || MULTITHREADED_LOADING)
		if (mutex != null)
			mutex.release();
		#end

		return Paths.currentTrackedSounds.get(file);
	}

	// thread safe graphic loader
	static function preloadGraphic(key:String):Null<BitmapData>
	{
		try
		{
			var requestKey:String = 'images/$key';
			#if TRANSLATIONS_ALLOWED requestKey = Language.getFileTranslation(requestKey); #end
			if (requestKey.lastIndexOf('.') < 0)
				requestKey += '.png';

			if (!Paths.currentTrackedAssets.exists(requestKey))
			{
				var file:String = Paths.getPath(requestKey, IMAGE);
				if (#if (sys || MULTITHREADED_LOADING) FileSystem.exists(file) || #end OpenFlAssets.exists(file, IMAGE))
				{
					#if (sys || MULTITHREADED_LOADING)
					var bitmap:BitmapData = BitmapData.fromFile(file);
					#else
					var bitmap:BitmapData = OpenFlAssets.getBitmapData(file, false);
					#end

					// Thread-safe storage
					#if (sys || MULTITHREADED_LOADING)
					if (mutex == null)
						mutex = new Mutex();
					mutex.acquire();
					#end
					requestedBitmaps.set(file, bitmap);
					originalBitmapKeys.set(file, requestKey);
					#if (sys || MULTITHREADED_LOADING)
					mutex.release();
					#end

					return bitmap;
				}
				else
					CoolLog.error('no such image $key exists');
			}

			return Paths.currentTrackedAssets.get(requestKey).bitmap;
		}
		catch (e:haxe.Exception)
		{
			CoolLog.error('ERROR! fail on preloading image $key');
		}

		return null;
	}

	#if (cpp || MULTITHREADED_LOADING)
	@:functionCode('
		return std::thread::hardware_concurrency();
    	')
	@:noCompletion
	public static function getCPUThreadsCount():Int
	{
		return -1;
	}
	#end
}
