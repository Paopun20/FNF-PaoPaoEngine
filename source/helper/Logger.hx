package helper;

import haxe.Log;
import haxe.PosInfos;
import haxe.format.JsonPrinter;

using StringTools;

enum Level
{
	DEBUG;
	INFO;
	WARN;
	ERROR;
}

class Logger
{
	static final COLORS:Map<String, String> = [
		"DEBUG" => "\x1b[36m", // cyan
		"INFO" => "\x1b[32m", // green
		"WARN" => "\x1b[33m", // yellow
		"ERROR" => "\x1b[31m" // red
	];

	static final RESET = "\x1b[0m";

	static var level:Level =
		#if debug
		Level.DEBUG;
		#else
		Level.INFO;
		#end

	static var nativeTrace:(Dynamic, ?PosInfos) -> Void;

	public static function init()
	{
		nativeTrace = Log.trace;
		#if debug
		Log.trace = (v, ?infos) ->
		{
			info(v, infos);
		}
		#end
	}

	static inline function now():String
	{
		var t = Date.now();
		return lpad(Std.string(t.getHours()), 2, "0") + ":" + lpad(Std.string(t.getMinutes()), 2, "0") + ":" + lpad(Std.string(t.getSeconds()), 2, "0")
			+ "." + lpad(Std.string(Std.int(t.getTime() % 1000)), 3, "0");
	}

	static inline function lpad(s:String, length:Int, char:String):String
	{
		while (s.length < length)
			s = char + s;
		return s;
	}

	static inline function rpad(s:String, length:Int, char:String = " "):String
	{
		while (s.length < length)
			s = s + char;
		return s;
	}

	static inline function pretty(v:Dynamic):String
	{
		try
		{
			return JsonPrinter.print(v, null, "  ");
		}
		catch (_)
		{
			return Std.string(v);
		}
	}

	static function levelToInt(lvl:Level):Int
	{
		return switch (lvl)
		{
			case DEBUG: 0;
			case INFO: 1;
			case WARN: 2;
			case ERROR: 3;
		}
	}

	static function log(lvl:Level, v:Dynamic, ?infos:PosInfos)
	{
		if (levelToInt(lvl) < levelToInt(level))
			return;

		var tag = switch (lvl)
		{
			case DEBUG: "DEBUG";
			case INFO: "INFO";
			case WARN: "WARN";
			case ERROR: "ERROR";
		};

		var col = COLORS.get(tag);
		var msg = if (Reflect.isObject(v)) pretty(v) else Std.string(v);
		var location = "";

		if (infos != null)
		{
			var f = infos.fileName.split("/").pop();
			location = " " + f + ":" + infos.lineNumber;
		}

		Sys.println('${col}[${now()}] ${rpad(tag, 5)} |${location} : ${RESET}${msg}');
	}

	public static inline function debug(v:Dynamic, ?infos:PosInfos)
	{
		#if debug
		log(Level.DEBUG, v, infos);
		#end
	}

	public static inline function info(v:Dynamic, ?infos:PosInfos)
	{
		log(Level.INFO, v, infos);
	}

	public static inline function warn(v:Dynamic, ?infos:PosInfos)
	{
		log(Level.WARN, v, infos);
	}

	public static inline function error(v:Dynamic, ?infos:PosInfos)
	{
		log(Level.ERROR, v, infos);
	}
}
