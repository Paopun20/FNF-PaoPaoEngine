package funkin.ds;

import sys.thread.ElasticThreadPool;
import sys.thread.Mutex;
import funkin.backend.utils.ThreadUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.Exception;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import flixel.system.FlxAssets;

class FunkinAssetLoaderIsShutdownException extends Exception {}
class FunkinAssetLoaderInstanceAlreadyExistsException extends Exception {}

/**
 * Queued asset result produced by a background thread.
 * Bitmaps cannot be pushed into the cache on a background thread (OpenFL
 * restriction), so they are staged here and flushed via `flushStagedBitmaps`
 * from the main thread before switching state.
 */
typedef StagedBitmap = {
	var cacheKey:String;
	var fileKey:String;
	var bitmap:BitmapData;
}

/**
 * Signal-based, thread-pool-backed asset loader.
 */
class FunkinAssetLoader {
	/** Singleton instance. Null until `new FunkinAssetLoader()` is called. */
	public static var instance:FunkinAssetLoader;
	public var onAssetLoaded:FlxTypedSignal<String->Void>;

	/** Fires once every pending asset from the current batch has finished. */
	public var onAllLoaded:FlxTypedSignal<Void->Void>;

	public var isShutdown(get, never):Bool;

	inline function get_isShutdown():Bool
		return _pool.isShutdown;

	public var threadCount(get, never):Int;

	inline function get_threadCount():Int
		return _pool.threadsCount;

	/**
	 * @param maxThreads  Pool ceiling. Defaults to the physical CPU thread count.
	 */
	public function new(maxThreads:Int = -1) {
		if (instance != null)
			throw new FunkinAssetLoaderInstanceAlreadyExistsException("FunkinAssetLoader is a singleton - call destroy() before creating a new one.");

		if (maxThreads <= -1)
			maxThreads = ThreadUtil.getCPUThreadsCount();

		// At least 1 thread so single-CPU targets don't break.
		maxThreads = Std.int(Math.max(1, maxThreads));

		_pool = new ElasticThreadPool(maxThreads, maxThreads);
		_mutex = new Mutex();
		_stagedBitmaps = [];
		onAssetLoaded = new FlxTypedSignal<String->Void>();

		instance = this;
	}

	/** Shuts the pool down and clears the singleton reference. */
	public function destroy():Void {
		_pool.shutdown();
		if (instance == this)
			instance = null;
	}

	/**
	 * Queue one asset for background loading.
	 *
	 * @param assetID    Human-readable type tag used in logs and signals.
	 *                   Accepted values: `"image"`, `"sound"`, `"music"`, `"song"`.
	 * @param assetPath  Path relative to each asset type's root, e.g. `"ui/healthBar"`.
	 *                   For songs, pass the full key (e.g. `"bopeebo/Inst"`).
	 */
	public function load(assetID:String, assetPath:String):Void {
		if (isShutdown)
			throw new FunkinAssetLoaderIsShutdownException("Cannot load assets after the pool has been shut down.");

		_pool.run(() -> {
			_executeLoad(assetID, assetPath);
			onAssetLoaded.dispatch(assetID);
		});
	}

	/**
	 * Must be called from the **main thread** before switching game state.
	 * Pushes every bitmap that background threads staged into `FunkinCache`.
	 */
	public function flushStagedBitmaps():Void {
		_mutex.acquire();
		var snapshot = _stagedBitmaps.copy();
		_stagedBitmaps = [];
		_mutex.release();

		for (entry in snapshot) {
			if (entry.bitmap != null) {
				if (FunkinCache.cacheBitmap(entry.cacheKey, entry.bitmap) == null)
					CoolLog.error('Failed to cache bitmap ${entry.cacheKey}');
			} else {
				CoolLog.error('Staged bitmap for ${entry.cacheKey} was null');
			}
		}
	}

	private var _pool:ElasticThreadPool;
	private var _mutex:Mutex;
	private var _stagedBitmaps:Array<StagedBitmap>;

	private function _executeLoad(assetID:String, assetPath:String):Void {
		try {
			switch (assetID) {
				case "image":
					_loadGraphic(assetPath);
				case "sound":
					_loadSound('sounds/$assetPath');
				case "music":
					_loadSound('music/$assetPath');
				case "song":
					_loadSound(assetPath, 'songs', true, false);
				default:
					CoolLog.error('FunkinAssetLoader: unknown assetID "$assetID" for path "$assetPath"');
			}
		} catch (e:Dynamic) {
			CoolLog.error('FunkinAssetLoader: error loading $assetID "$assetPath": $e');
		}
	}

	private function _loadSound(key:String, ?path:String, modsAllowed:Bool = true, beepOnNull:Bool = true):Null<Sound> {
		var resolvedFile = Paths.getPath(Language.getFileTranslation(key) + '.${Paths.SOUND_EXT}', SOUND, path, modsAllowed);

		if (FunkinCache.currentTrackedSounds.exists(resolvedFile)) {
			_trackSoundLocally(resolvedFile);
			return FunkinCache.currentTrackedSounds.get(resolvedFile);
		}

		var soundExists = #if sys FileSystem.exists(resolvedFile) || #end OpenFlAssets.exists(resolvedFile, SOUND);

		if (!soundExists) {
			if (beepOnNull) {
				CoolLog.error('Sound not found - key: $key, path: $path');
				return FlxAssets.getSoundAddExtension('flixel/sounds/beep', true);
			}
			return null;
		}

		var sound:Sound = #if sys Sound.fromFile(resolvedFile) #else OpenFlAssets.getSound(resolvedFile, false) #end;

		_mutex.acquire();
		FunkinCache.currentTrackedSounds.set(resolvedFile, sound);
		_mutex.release();

		_trackSoundLocally(resolvedFile);
		return sound;
	}

	inline private function _trackSoundLocally(resolvedFile:String):Void {
		_mutex.acquire();
		FunkinCache.localTrackedAssets.push(resolvedFile);
		_mutex.release();
	}

	private function _loadGraphic(key:String):Null<BitmapData> {
		var requestKey = 'images/$key';
		#if TRANSLATIONS_ALLOWED requestKey = Language.getFileTranslation(requestKey); #end
		if (requestKey.lastIndexOf('.') < 0)
			requestKey += '.png';

		// Already cached - nothing to do.
		if (FunkinCache.currentTrackedAssets.exists(requestKey))
			return FunkinCache.currentTrackedAssets.get(requestKey).bitmap;

		var resolvedFile = Paths.getPath(requestKey, IMAGE);
		var imageExists = #if sys FileSystem.exists(resolvedFile) || #end OpenFlAssets.exists(resolvedFile, IMAGE);

		if (!imageExists) {
			CoolLog.error('Image not found: $key');
			return null;
		}

		var bitmap:BitmapData = #if sys BitmapData.fromFile(resolvedFile) #else OpenFlAssets.getBitmapData(resolvedFile, false) #end;

		// Stage for main-thread cache insertion (OpenFL restriction).
		_mutex.acquire();
		_stagedBitmaps.push({
			cacheKey: requestKey,
			fileKey: resolvedFile,
			bitmap: bitmap
		});
		_mutex.release();

		return bitmap;
	}
}
