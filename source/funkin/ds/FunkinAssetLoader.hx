package funkin.ds;

import sys.thread.ElasticThreadPool;
import funkin.backend.utils.ThreadUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.Exception;

class FunkinAssetLoaderIsShutdownException extends Exception {}
class FunkinAssetLoaderInstanceAlreadyExistsException extends Exception {}

/*
	Signal-based asset loader that uses an ElasticThreadPool
	to load assets in the background.

	It provides signals for:
	- individual asset completion
	- all assets completion

	Designed to be generic/flexible and usable for any
	asset type as long as a loading function is provided.
 */
class FunkinAssetLoader {
	public static var instance:FunkinAssetLoader;

	private var _threadPool:ElasticThreadPool;

	public var isShutdown(get, never):Bool;

	inline function get_isShutdown():Bool {
		return _threadPool.isShutdown;
	}

	public var threadsCount(get, never):Int;

	inline function get_threadsCount():Int {
		return _threadPool.threadsCount;
	}

	public function new(maxThreads:Int = -1) {
		if (instance != null) {
			throw new FunkinAssetLoaderInstanceAlreadyExistsException("FunkinAssetLoader is a singleton and has already been initialized.");
		}

		if (maxThreads <= -1) {
			maxThreads = ThreadUtil.getCPUThreadsCount();
		}

		maxThreads = Std.int(Math.max(1, maxThreads)); // Ensure at least 1 thread

		_threadPool = new ElasticThreadPool(maxThreads, maxThreads);

		instance = this;
	}
}
