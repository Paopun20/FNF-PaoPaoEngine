// OG CODE: https://github.com/CodenameCrew/CodenameEngine/blob/main/source/funkin/backend/utils/ThreadUtil.hx
package funkin.backend.utils;

#if (target.threaded)
import sys.thread.Deque;
import sys.thread.Mutex;
import sys.thread.Thread;
#else
private typedef Thread = Dynamic;
#end

#if cpp
@:headerCode('
#include <iostream>
#include <thread>
')
#end
private class _GetThreadCount {
	public static var defaultThreadCount:Int = 1; // Default to 1 threads if detection fails

	#if cpp
	@:functionCode('
		unsigned int count = std::thread::hardware_concurrency();
		return count > 0 ? count : defaultThreadCount;
	')
	@:noCompletion
	public static function getCPUThreadsCount():Int {
		return defaultThreadCount;
	}
	#elseif hl
	@:hlNative("std", "sys_cpu_count")
	public static function getCPUThreadsCount():Int {
		return defaultThreadCount;
	}
	#elseif (js && nodejs)
	public static function getCPUThreadsCount():Int {
		try {
			var cpus = Os.cpus();
			return cpus != null ? cpus.length : defaultThreadCount;
		} catch (e:Dynamic) {
			#if debug
			trace('Failed to detect CPU count in Node.js: $e');
			#end
			return defaultThreadCount;
		}
	}
	#elseif html5
	public static function getCPUThreadsCount():Int {
		try {
			var hardwareConcurrency:Null<Int> = untyped __js__("navigator.hardwareConcurrency");

			if (hardwareConcurrency != null && hardwareConcurrency >= 1) {
				return hardwareConcurrency;
			}
		} catch (e:Dynamic) {
			trace('Could not detect CPU cores in browser: $e');
		}

		return defaultThreadCount;
	}
	#elseif java
	public static function getCPUThreadsCount():Int {
		try {
			var runtime = java.lang.Runtime.getRuntime();
			return runtime.availableProcessors();
		} catch (e:Dynamic) {
			trace('Failed to detect CPU count in Java: $e');
			return defaultThreadCount;
		}
	}
	#elseif cs
	public static function getCPUThreadsCount():Int {
		try {
			return cs.system.Environment.ProcessorCount;
		} catch (e:Dynamic) {
			trace('Failed to detect CPU count in C#: $e');
			return defaultThreadCount;
		}
	}
	#else
	public static function getCPUThreadsCount():Int {
		return defaultThreadCount;
	}
	#end
}

final class ThreadUtil {
	inline static function error(text:String) {
		#if macro
		trace(text);
		#else
		CoolLog.error(text);
		#end
	}

	/**
	 * Creates a new Thread with an error handler.
	 * @param func Function to execute
	 * @param autoRestart Whenever the thread should auto restart itself after crashing.
	 */
	public static function createSafe(func:Void->Void, autoRestart:Bool = false):Thread {
		#if (target.threaded)
		try {
			return if (autoRestart) Thread.create(() -> {
				var restart = true;
				while (restart)
					try {
						func();
						restart = false;
					} catch (e)
						error(e.details());
			}) else Thread.create(() -> {
				try {
					func();
				} catch (e)
					error(e.details());
			});
		} catch (e)
			error("Failed to safely create a thread: " + e.details());
		#end
		return null;
	}

	public static var maxThreads(get, null):Int;

	public static function get_maxThreads() {
		return getCPUThreadsCount();
	}

	public static inline function getCPUThreadsCount():Int {
		return _GetThreadCount.getCPUThreadsCount();
	}

	static var __threads:Array<Thread> = [];
	static var __pendingExecs:Deque<Void->Void> = new Deque();
	static var __threadMutex:Mutex = new Mutex();
	static var __threadUsed:Int = 0;

	static function __threadExecAsync() {
		var callback:Void->Void;
		while ((callback = __pendingExecs.pop(true)) != null) {
			__threadMutex.acquire();
			__threadUsed++;
			__threadMutex.release();

			callback();

			__threadMutex.acquire();
			__threadUsed--;
			__threadMutex.release();
		}
		__threadMutex.acquire();
		__threads.remove(Thread.current());
		__threadMutex.release();
	}

	public static function execAsync(func:Void->Void) {
		if (func == null)
			return;

		#if (!macro && target.threaded)
		__pendingExecs.add(func);
		if (__threadUsed >= __threads.length) {
			if (__threads.length == maxThreads)
				return;

			__threadMutex.acquire();
			try {
				var thread = Thread.create(__threadExecAsync);
				__threads.push(thread);
			} catch (e)
				CoolLog.warning(e.details());
			__threadMutex.release();
		}
		#else
		func();
		#end
	}

	private static function runSync(asyncFunc:((Dynamic) -> Void)->Void):Dynamic {
		var result:Dynamic = null;
		var completed = false;

		asyncFunc(function(arg:Dynamic) {
			completed = true;
			result = arg;
		});

		while (!completed)
			Sys.sleep(0.01);
		return result;
	}
}
