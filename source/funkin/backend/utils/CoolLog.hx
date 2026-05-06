package funkin.backend.utils;

import haxe.Log;
import haxe.PosInfos;
import haxe.format.JsonPrinter;
import funkin.backend.utils.AnsiUtil;
import funkin.backend.utils.AnsiUtil.AnsiCode;

using StringTools;
using PPQolTools;

private enum Level
{
	DEBUG;
	INFO;
	WARNING;
	ERROR;
	CRITICAL;
	TRACE;
}

class CoolLog
{
	private static final COLORS:Map<Level, Array<AnsiCode>> = [
		DEBUG => [AnsiCode.CYAN],
		INFO => [AnsiCode.GREEN],
		WARNING => [AnsiCode.YELLOW],
		ERROR => [AnsiCode.RED],
		CRITICAL => [AnsiCode.BG_MAGENTA, AnsiCode.BLACK],
		TRACE => [AnsiCode.WHITE],
	];

	private static final TIME_COLOR = rgb(160, 120, 255);
	private static final FILE_COLOR = rgb(80, 200, 255);
	private static final LINE_COLOR = rgb(140, 140, 140);
	private static final MSG_COLOR = rgb(230, 230, 230);
	private static final OBJ_COLOR = rgb(120, 220, 220);

	private static var level:Level =
		#if debug
		Level.DEBUG;
		#else
		Level.INFO;
		#end

	private static var nativeTrace:(Dynamic, ?PosInfos) -> Void;

	public static function init()
	{
		nativeTrace = Log.trace;
		Log.trace = (v, ?infos) -> log(Level.TRACE, v, infos); // Fixed
	}

	public static function uninit()
	{
		if (nativeTrace != null)
			Log.trace = nativeTrace;
	}

	public static function setLevel(lvl:Level)
	{
		level = lvl;
	}

	public static function getLevel():Level
	{
		return level;
	}

	private static inline function now():String
	{
		var t = Date.now();
		return lpad('${t.getHours()}', 2, "0") + ":" + lpad('${t.getMinutes()}', 2, "0") + ":" + lpad('${t.getSeconds()}', 2, "0") + "."
			+ lpad('${Std.int(t.getTime() % 1000)}', 3, "0");
	}

	private static inline function lpad(s:String, len:Int, c:String):String
	{
		while (s.length < len)
			s = c + s;
		return s;
	}

	public static function getColorByHex(hex:String):AnsiCode
	{
		if (hex.startsWith("#"))
			hex = hex.substr(1);
		if (hex.length != 6)
			return AnsiCode.WHITE;

		var r = Std.parseInt("0x" + hex.substr(0, 2));
		var g = Std.parseInt("0x" + hex.substr(2, 2));
		var b = Std.parseInt("0x" + hex.substr(4, 2));

		if (r == null || g == null || b == null)
			return AnsiCode.WHITE;

		return cast rgb(r, g, b);
	}

	private static inline function rgb(r:Int, g:Int, b:Int):String
		return '\x1b[38;2;${r};${g};${b}m';

	private static inline function pretty(v:Dynamic):String
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

	private static function levelToInt(lvl:Level):Int
	{
		return switch (lvl)
		{
			case DEBUG: 10;
			case INFO: 20;
			case WARNING: 30;
			case ERROR: 40;
			case CRITICAL: 50;
			case TRACE: 60;
		}
	}

	private static function levelTag(lvl:Level):String
	{
		return switch (lvl)
		{
			case DEBUG: "DEBUG";
			case INFO: "INFO";
			case WARNING: "WARNING";
			case ERROR: "ERROR";
			case CRITICAL: "CRITICAL";
			case TRACE: "TRACE";
		}
	}


	/**
	 * Creates a clickable hyperlink using the OSC 8 ANSI escape sequence.
	 * Supported in terminals like iTerm2, Windows Terminal, GNOME Terminal, etc.
	 * Falls back to plain text in unsupported terminals.
	 * @param url  The URL to open when clicked.
	 * @param text The visible label shown in the terminal.
	 */
	private static inline function link(url:String, text:String):String
    	return '\033]8;;$url\033\\$text\033]8;;\033\\';

	private static function log(lvl:Level, v:Dynamic, ?infos:PosInfos)
	{
		var current = levelToInt(level);
		if (levelToInt(lvl) < current)
			return;

		var time = AnsiUtil.apply('[' + now() + ']', [cast TIME_COLOR]);
		var tag = AnsiUtil.apply(levelTag(lvl), COLORS.get(lvl));

		var fs = infos != null ? infos.fileName.split("/") : [];

		var file = "unknown";
		var line = "0";

		if (infos != null)
		{
			file = fs.last();
			line = Std.string(infos.lineNumber);
		}

		var location = AnsiUtil.apply(file, [cast FILE_COLOR]) + ":" + AnsiUtil.apply(line, [cast LINE_COLOR]);
		// location = link(location, file); // why the fack, it not working >:(

		var msg = Std.isOfType(v, String) ? AnsiUtil.apply(v, [cast MSG_COLOR]) : AnsiUtil.apply(pretty(v), [cast OBJ_COLOR]);

		Sys.println('$time $tag $location: $msg');
	}

	public static inline function debug(v:Dynamic, ?i)
		log(Level.DEBUG, v, i);

	public static inline function info(v:Dynamic, ?i)
		log(Level.INFO, v, i);

	public static inline function warning(v:Dynamic, ?i)
		log(Level.WARNING, v, i);

	public static inline function error(v:Dynamic, ?i)
		log(Level.ERROR, v, i);

	public static inline function critical(v:Dynamic, ?i)
		log(Level.CRITICAL, v, i);
}
