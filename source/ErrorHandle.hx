package;

import funkin.ds.BytesMap;
import funkin.backend.game.FunkinGame;
import lime.app.Application;
#if CRASH_HANDLER
import haxe.CallStack;
import haxe.Exception;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end
#if CRASH_DEBUGGER
import funkin.backend.utils.macro.SourceMap;
#end
#if cpp
import funkin.backend.utils.HxSignalKill;
#end

class StackFormatter {
	#if CRASH_DEBUGGER
	private static var _sourceMap:BytesMap = SourceMap.build();
	static inline var MAX_SOURCE_PREVIEW:Int = 120;
	#end

	/**
	 * Generate readable text from a full stack
	 */
	public static function genStack(stack:Array<StackItem>):String {
		var out:String = "";

		for (i => item in stack) {
			out += '[$i] ';
			out += genTextFromStackItem(item);
			out += "\n";
		}

		return out;
	}

	/**
	 * Recursively format a StackItem
	 */
	public static function genTextFromStackItem(s:StackItem):String {
		return switch (s) {
			case CFunction:
				"[C Function]";

			case Module(m):
				'Module($m)';

			case Method(classname, method):
				'$classname.$method()';

			case LocalFunction(v):
				'LocalFunction($v)';

			case FilePos(inner, file, line, column):
				var base:String = inner != null ? genTextFromStackItem(inner) : "Unknown";

				var text:String = '$base at $file:$line';

				if (column != null)
					text += ':$column';

				#if CRASH_DEBUGGER
				var sourceLine = getLine(file, line);

				if (sourceLine != null) {
					if (sourceLine.length > MAX_SOURCE_PREVIEW)
						sourceLine = sourceLine.substr(0, MAX_SOURCE_PREVIEW) + "...";

					text += "\n-> " + sourceLine;
				}
				#end

				text;
		}
	}

	#if CRASH_DEBUGGER
	/**
	 * Get source line from file
	 */
	static function getLine(file:String, line:Int):Null<String> {
		var content = getFile(file);
		if (content == null)
			return null;

		var lines = content.split("\n");
		if (line <= 0 || line > lines.length)
			return null;

		return lines[line - 1].trim();
	}

	private static function getFile(path:String):Null<String> {
		return _sourceMap.get(path.replace("\\", "/"));
	}
	#end
}

/**
 * Error and crash handling system for PaoPaoEngine
 * Handles uncaught errors, critical errors, and provides logging functionality
 */
final class ErrorHandle {
	#if CRASH_HANDLER
	public static function init():Void {
		FunkinGame.onGameCrash.add(onCrash);
		untyped __global__.__hxcpp_set_critical_error_handler(onCriticalError);
	}

	static function onCriticalError(message:String):Void // 💀 it cook
	{
		// Wrap as a synthetic exception so onCrash can handle it uniformly
		onCrash(new Exception(message));
	}

	private static function onCrash(e:Exception):Void {
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		errMsg += StackFormatter.genStack(callStack);

		CoolLog.critical("Crash detected!");

		dateNow = dateNow.replace(" ", "_").replace(":", "-");
		path = "./crash/" + "PaoPaoEngine_" + dateNow + ".log";

		// Improved error reporting: always show something useful
		var errorDetail = "";
		var errorType = "";
		if (e != null) {
			errorType = Type.getClassName(Type.getClass(e));
			if (e.message != null && e.message != "") {
				errorDetail = e.message;
			} else if (e.toString() != null && e.toString() != "") {
				errorDetail = e.toString();
			} else {
				errorDetail = "<no error details available>";
			}
		} else {
			errorType = "<Unknown Exception Type>";
			errorDetail = "<Exception object is null>";
		}
		errMsg += '\n${errorType.split(".").pop()}: ' + errorDetail;
		#if officialBuild
		errMsg += "\nPlease report this error to the GitHub page: https://github.com/Paopun20/FNF-PaoPaoEngine";
		#end
		errMsg += "\n\n> Cool Crash Handler written by: PaoPao";

		// Save crash log
		#if CRASH_DEBUGGER
		// uhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh, what lib I can use like imgui and easy to use in Haxe?

		// For now, just save the logs and show a simple dialog, but in the future we can make a full crash debugger with stack trace navigation
		saveLogs(path, errMsg);
		showDialogWindow(errMsg, "Game Crash!");
		shutdown();
		#else
		saveLogs(path, errMsg);
		showDialogWindow(errMsg, "Game Crash!");
		shutdown();
		#end
	}

	/**
	 * Save logs to file
	 */
	private static function saveLogs(filename:String, content:String):Void {
		try {
			if (!FileSystem.exists("./crash/"))
				FileSystem.createDirectory("./crash/");

			File.saveContent(filename, content + "\n");
			CoolLog.critical("Crash dump saved in " + Path.normalize(filename));
			Sys.println(content);
		} catch (e:Dynamic) {
			trace('Failed to save crash log: $e');
		}
	}

	/**
	 * Show a dialog window with error message
	 */
	private static function showDialogWindow(message:String, title:String):Void {
		try {
			Application.current.window.alert(message, title);
		} catch (e:Dynamic) {
			trace('Failed to show dialog window: $e');
		}
	}

	/**
	 * Shutdown the application
	 */
	private static function shutdown():Void {
		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end

		#if sys
		Sys.exit(1);
		#end
	}
	#end
}
