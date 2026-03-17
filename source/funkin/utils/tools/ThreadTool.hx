package funkin.utils.tools;

#if cpp
@:headerCode('
#include <iostream>
#include <thread>
')
#end
final class ThreadTool
{
    public static var defaultThreadCount:Int = 8; // Default to 8 threads if detection fails

	#if cpp
	@:functionCode('
		unsigned int count = std::thread::hardware_concurrency();
		return count > 0 ? count : defaultThreadCount;
	')
	@:noCompletion
	public static function getCPUThreadsCount(): Int
	{
		return defaultThreadCount;
	}
	
	#elseif hl
	@:hlNative("std", "sys_cpu_count")
	public static function getCPUThreadsCount(): Int
	{
		return defaultThreadCount;
	}
	
	#elseif (js && nodejs)
	public static function getCPUThreadsCount(): Int
	{
		try
		{
			var cpus = Os.cpus();
			return cpus != null ? cpus.length : defaultThreadCount;
		}
		catch (e:Dynamic)
		{
			#if debug
			trace('Failed to detect CPU count in Node.js: $e');
			#end
			return defaultThreadCount;
		}
	}
	
	#elseif html5
	public static function getCPUThreadsCount(): Int
	{
		try
		{
			var hardwareConcurrency:Null<Int> = untyped __js__("navigator.hardwareConcurrency");
			
			if (hardwareConcurrency != null && hardwareConcurrency >= 1)
			{
				return hardwareConcurrency;
			}
		}
		catch (e:Dynamic)
		{
			trace('Could not detect CPU cores in browser: $e');
		}
		
		return defaultThreadCount;
	}
	
	#elseif java
	public static function getCPUThreadsCount(): Int
	{
		try
		{
			var runtime = java.lang.Runtime.getRuntime();
			return runtime.availableProcessors();
		}
		catch (e:Dynamic)
		{
			trace('Failed to detect CPU count in Java: $e');
			return defaultThreadCount;
		}
	}
	
	#elseif cs
	public static function getCPUThreadsCount(): Int
	{
		try
		{
			return cs.system.Environment.ProcessorCount;
		}
		catch (e:Dynamic)
		{
			trace('Failed to detect CPU count in C#: $e');
			return defaultThreadCount;
		}
	}
	
	#else
	public static function getCPUThreadsCount(): Int
	{
		return defaultThreadCount;
	}
	#end
}