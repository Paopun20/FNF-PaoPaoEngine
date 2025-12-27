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
	];

	static final RESET = "\x1b[0m";

	public static function getColorByHex(color:String):String
	{
		if (color.charAt(0) == "#")
		{
			color = color.substr(1);
		}

		var r = Std.parseInt("0x" + color.substr(0, 2));
		var g = Std.parseInt("0x" + color.substr(2, 2));
		var b = Std.parseInt("0x" + color.substr(4, 2));
		
		return rgb(r, g, b);
	}

	static inline function rgb(r:Int, g:Int, b:Int):String
	{
		return '\x1b[38;2;${r};${g};${b}m';
	}

	static inline function bg(r:Int, g:Int, b:Int):String
	{
		return '\x1b[48;2;${r};${g};${b}m';
	}

	static final TIME_COLOR = rgb(160, 120, 255);
	static final FILE_COLOR = rgb(80, 200, 255);
	static final LINE_COLOR = rgb(140, 140, 140);
	static final MSG_COLOR = rgb(230, 230, 230);
	static final OBJ_COLOR = rgb(120, 220, 220);

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

		var tag = COLORS.get(lvl) + levelTag(lvl) + RESET;

		var time = TIME_COLOR + "[" + now() + "]" + RESET;

		var file = "unknown";
		var line = "0";

		if (infos != null)
		{
			file = infos.fileName.split("/").pop();
			line = Std.string(infos.lineNumber);
			line.replace("\"", "");
		}

		var location = FILE_COLOR + file + RESET + ":" + LINE_COLOR + line + RESET;

		var msg = switch (v)
		{
			case String: MSG_COLOR + v + RESET;
			default: OBJ_COLOR + pretty(v) + RESET;
		}

		Sys.println('$time $tag $location: $msg');
	}

	public static inline function debug(v:Dynamic, ?infos:PosInfos)
	{
		log(Level.DEBUG, v, infos);
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
