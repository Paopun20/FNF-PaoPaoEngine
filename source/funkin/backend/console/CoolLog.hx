package funkin.backend.console;

import haxe.Log;
import haxe.PosInfos;
import funkin.ds.Int8;
import haxe.io.Bytes;
import haxe.io.Encoding;
import haxe.format.JsonPrinter;
import funkin.backend.utils.AnsiUtil;
import funkin.backend.utils.AnsiUtil.AnsiCode;

using StringTools;
using funkin.backend.utils.tools.QolTools;

/**
 * Log levels ordered by numeric severity.
 * The underlying Int8 value IS the severity — no separate levelToInt needed.
 */
private enum abstract Level(Int8) from Int8 to Int8 {
	var DEBUG = 10;
	var INFO = 20;
	var WARNING = 30;
	var ERROR = 40;
	var CRITICAL = 50;
	var TRACE = 60;
}

@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class CoolLog {
	private static final COLORS:Map<Int, Array<AnsiCode>> = [
		(DEBUG : Int) => [AnsiCode.CYAN],
		(INFO : Int) => [AnsiCode.GREEN],
		(WARNING : Int) => [AnsiCode.YELLOW],
		(ERROR : Int) => [AnsiCode.RED],
		(CRITICAL : Int) => [AnsiCode.BG_MAGENTA, AnsiCode.BLACK],
		(TRACE : Int) => [AnsiCode.WHITE],
	];

	private static final TIME_COLOR:AnsiCode = rgb(160, 120, 255);
	private static final FILE_COLOR:AnsiCode = rgb(80, 200, 255);
	private static final LINE_COLOR:AnsiCode = rgb(140, 140, 140);
	private static final MSG_COLOR:AnsiCode = rgb(230, 230, 230);
	private static final OBJ_COLOR:AnsiCode = rgb(120, 220, 220);

	private static var level:Level =
		#if debug
		Level.DEBUG;
		#else
		Level.INFO;
		#end

	private static var nativeTrace:(Dynamic, ?PosInfos) -> Void;

	public static function init() {
		nativeTrace = Log.trace;
		Log.trace = (v, ?infos) -> log(Level.TRACE, v, infos);
	}

	public static function uninit() {
		if (nativeTrace != null) {
			Log.trace = nativeTrace;
			nativeTrace = null; // add this
		}
	}

	public static function setLevel(lvl:Level):Void {
		level = lvl;
	}

	public static function getLevel():Level {
		return level;
	}

	public static inline function debug(v:Dynamic, ?i:PosInfos)
		log(Level.DEBUG, v, i);

	public static inline function info(v:Dynamic, ?i:PosInfos)
		log(Level.INFO, v, i);

	public static inline function warning(v:Dynamic, ?i:PosInfos)
		log(Level.WARNING, v, i);

	public static inline function error(v:Dynamic, ?i:PosInfos)
		log(Level.ERROR, v, i);

	public static inline function critical(v:Dynamic, ?i:PosInfos)
		log(Level.CRITICAL, v, i);

	private static function log(lvl:Level, v:Dynamic, ?infos:PosInfos):Void {
		if ((lvl : Int) < (level : Int))
			return;

		final colors = COLORS.get(lvl) ?? [AnsiCode.WHITE];

		#if ((debug && !no_unicode_output_at_debug) && !true) // debug test new output (todo: need to fix a Unicode error)
		/*
			https://en.wikipedia.org/wiki/Block_Elements
		 */
		final box = AnsiUtil.apply("▏", colors);

		final time = AnsiUtil.apply(now() + ' │', [TIME_COLOR]);
		final tag = AnsiUtil.apply(levelTag(lvl), colors);
		final location = formatLocation(infos);
		final msg = '$box ' + formatValue(v);

		final out = '$box $time $tag $location › $msg';
		#else
		final time = AnsiUtil.apply('[' + now() + ']', [TIME_COLOR]);
		final tag = AnsiUtil.apply(levelTag(lvl), colors);
		final location = formatLocation(infos);
		final msg = formatValue(v);

		final out = '$time $tag $location $msg';
		#end

		Sys.println(out);
	}

	private static function formatLocation(?infos:PosInfos):String {
		if (infos == null)
			return AnsiUtil.apply("unknown", [FILE_COLOR]) + ":" + AnsiUtil.apply("0", [LINE_COLOR]);

		final parts = infos.fileName.split("/");
		final file = AnsiUtil.apply(parts.last(), [FILE_COLOR]);
		final line = AnsiUtil.apply(Std.string(infos.lineNumber), [LINE_COLOR]);
		return '$file:$line';
	}

	private static function formatValue(v:Dynamic):String {
		return Std.isOfType(v, String) ? AnsiUtil.apply(v, [MSG_COLOR]) : AnsiUtil.apply(prettyJson(v), [OBJ_COLOR]);
	}

	/**
	 * Attempts JSON pretty-printing; falls back to Std.string on failure.
	 * Logs a warning when fallback is triggered so the exception isn't silently swallowed.
	 */
	private static function prettyJson(v:Dynamic):String {
		try {
			return JsonPrinter.print(v, null, "  ");
		} catch (e) {
			Sys.stderr().write(Bytes.ofString('[CoolLog] prettyJson fallback: ${e.message}\n'));
			Sys.stderr().flush();
			return Std.string(v);
		}
	}

	private static function levelTag(lvl:Level):String {
		return switch (lvl : Int) {
			case 10: "DEBUG";
			case 20: "INFO";
			case 30: "WARNING";
			case 40: "ERROR";
			case 50: "CRITICAL";
			case 60: "TRACE";
			default: "UNKNOWN";
		}
	}

	private static inline function now():String {
		final t = Date.now();
		return lpad('${t.getHours()}', 2, "0") + ":" + lpad('${t.getMinutes()}', 2, "0") + ":" + lpad('${t.getSeconds()}', 2, "0") + "."
			+ lpad('${Std.int(t.getTime() % 1000)}', 3, "0");
	}

	private static inline function lpad(s:String, len:Int, c:String):String {
		return StringTools.lpad(s, c, len);
	}

	public static function getColorByHex(hex:String):AnsiCode {
		final h = hex.startsWith("#") ? hex.substr(1) : hex;
		if (h.length != 6)
			return AnsiCode.WHITE;

		final r = Std.parseInt("0x" + h.substr(0, 2));
		final g = Std.parseInt("0x" + h.substr(2, 2));
		final b = Std.parseInt("0x" + h.substr(4, 2));

		if (r == null || g == null || b == null)
			return AnsiCode.WHITE;
		return rgb(r, g, b);
	}

	private static inline function rgb(r:Int, g:Int, b:Int):AnsiCode
		return '\x1b[38;2;${r};${g};${b}m';
}
