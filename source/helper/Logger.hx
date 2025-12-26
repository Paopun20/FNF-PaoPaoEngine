package helper;

import haxe.Log;
import haxe.PosInfos;
import haxe.format.JsonPrinter;

using StringTools;

enum Level
{
	DEBUG;
	INFO;
	WARNING;
	ERROR;
	CRITICAL;
}

class Logger
{
	static final COLORS:Map<Level, String> = [
		DEBUG => "\x1b[36m",
		INFO => "\x1b[32m",
		WARNING => "\x1b[33m",
		ERROR => "\x1b[31m",
		CRITICAL => "\x1b[41;97m",
		RESET => "\x1b[0m"
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
			case DEBUG: 10;
			case INFO: 20;
			case WARNING: 30;
			case ERROR: 40;
			case CRITICAL: 50;
		}
	}

	static function levelTag(lvl:Level):String
	{
		return switch (lvl)
		{
			case DEBUG: "DEBUG";
			case INFO: "INFO";
			case WARNING: "WARNING";
			case ERROR: "ERROR";
			case CRITICAL: "CRITICAL";
		}
	}

	static function log(lvl:Level, v:Dynamic, ?infos:PosInfos)
	{
		if (levelToInt(lvl) < levelToInt(level))
			return;

		var tag = levelTag(lvl);
		var col = COLORS.get(lvl);
		var msg = Std.string(v);

		var location = "unknown:0";
		if (infos != null)
		{
			location = infos.fileName.split("/").pop() + ":" + infos.lineNumber;
		}

		Sys.println('${col}[${now()}] ${tag} ${location} ${msg}${RESET}');
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

	public static inline function error(v:Dynamic, ?infos:PosInfos)
	{
		log(Level.ERROR, v, infos);
	}

	public static inline function warning(v, ?i)
	{
		log(Level.WARNING, v, i);
	}

	public static inline function critical(v, ?i)
	{
		log(Level.CRITICAL, v, i);
	}
}
