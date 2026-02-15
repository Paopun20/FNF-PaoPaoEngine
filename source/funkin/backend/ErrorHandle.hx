package funkin.backend;

#if CRASH_HANDLER
import haxe.CallStack;
import haxe.io.Path;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;
import lime.app.Application;
import sys.FileSystem;
import sys.io.File;
import flixel.FlxG;
import flixel.util.FlxSignal;
#end

/**
 * Error and crash handling system for PaoPaoEngine
 * Handles uncaught errors, critical errors, and provides logging functionality
 */
class ErrorHandle
{
	#if CRASH_HANDLER
	/**
	 * Signal dispatched when a crash occurs
	 * Passes the error message and log file path
	 */
	public static var onCrashSignal:FlxTypedSignal<String->String->Void>;

	/**
	 * Signal dispatched when a critical error occurs
	 * Passes the error message
	 */
	public static var onCriticalErrorSignal:FlxTypedSignal<String->Void>;

	/**
	 * Initialize the error handling system
	 * Call this once during application startup
	 */
	public static function init():Void
	{
		// Initialize signals
		onCrashSignal = new FlxTypedSignal<String->String->Void>();
		onCriticalErrorSignal = new FlxTypedSignal<String->Void>();

		// Setup uncaught error handler
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		#if cpp
		// Setup critical error handler for C++
		untyped __global__.__hxcpp_set_critical_error_handler(onCritical);
		#end

		CoolLog.info("Error handling system initialized");
	}

	/**
	 * Handle uncaught errors
	 */
	private static function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		CoolLog.critical("Crash detected!");

		dateNow = dateNow.replace(" ", "_").replace(":", "-");
		path = "./crash/" + "PaoPaoEngine_" + dateNow + ".log";

		// Build stack trace
		var stackIndex:Int = 0;
		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += "#" + stackIndex + " " + file + " (line " + line;
					if (column != null)
						errMsg += ", column " + column;
					errMsg += ")\n";
					stackIndex++;
				default:
					errMsg += "#" + stackIndex + " " + Std.string(stackItem) + "\n";
					stackIndex++;
			}
		}

		errMsg += "\nUncaught Error: " + e.error;
		#if officialBuild
		errMsg += "\nPlease report this error to the GitHub page: https://github.com/Paopun20/FNF-PaoPaoEngine";
		#end
		errMsg += "\n\n> New Crash Handler written by: Paopun20";

		// Save crash log
		saveLogs(path, errMsg);

		// Dispatch crash signal
		if (onCrashSignal != null)
			onCrashSignal.dispatch(errMsg, path);

		// Show dialog and shutdown
		showDialogWindow(errMsg, "Game Crash!");
		shutdown();
	}

	#if cpp
	/**
	 * Handle critical errors (C++ only)
	 */
	private static function onCritical(message:String):Void
	{
		try
		{
			var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "-");
			var path:String = "./crash/" + "PaoPaoEngine_" + dateNow + ".log";

			saveLogs(path, message);

			// Dispatch critical error signal
			if (onCriticalErrorSignal != null)
				onCriticalErrorSignal.dispatch(message);

			showDialogWindow(message, "Critical Error!");
		}
		catch (e:Dynamic)
		{
			trace('Error while handling critical error: $e');
			trace('Original message: $message');
		}

		shutdown();
	}
	#end

	/**
	 * Save logs to file
	 */
	private static function saveLogs(filename:String, content:String):Void
	{
		try
		{
			if (!FileSystem.exists("./crash/"))
				FileSystem.createDirectory("./crash/");

			File.saveContent(filename, content + "\n");
			CoolLog.critical("Crash dump saved in " + Path.normalize(filename));
		}
		catch (e:Dynamic)
		{
			trace('Failed to save crash log: $e');
		}
	}

	/**
	 * Show a dialog window with error message
	 */
	private static function showDialogWindow(message:String, title:String):Void
	{
		try
		{
			Application.current.window.alert(message, title);
		}
		catch (e:Dynamic)
		{
			trace('Failed to show dialog window: $e');
		}
	}

	/**
	 * Shutdown the application
	 */
	private static function shutdown():Void
	{
		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end

		#if sys
		Sys.exit(1);
		#end
	}
	#end
}
