package funkin.backend.utils;

enum abstract AnsiCode(String) from String to String {
	var RESET = '\x1b[0m';
	var BOLD = '\x1b[1m';
	var DIM = '\x1b[2m';
	var UNDERLINE = '\x1b[4m';
	var BLINK = '\x1b[5m';
	var INVERSE = '\x1b[7m';
	var HIDDEN = '\x1b[8m';
	var STRIKETHROUGH = '\x1b[9m';

	var BLACK = '\x1b[30m';
	var RED = '\x1b[31m';
	var GREEN = '\x1b[32m';
	var YELLOW = '\x1b[33m';
	var BLUE = '\x1b[34m';
	var MAGENTA = '\x1b[35m';
	var CYAN = '\x1b[36m';
	var WHITE = '\x1b[37m';

	var BG_BLACK = '\x1b[40m';
	var BG_RED = '\x1b[41m';
	var BG_GREEN = '\x1b[42m';
	var BG_YELLOW = '\x1b[43m';
	var BG_BLUE = '\x1b[44m';
	var BG_MAGENTA = '\x1b[45m';
	var BG_CYAN = '\x1b[46m';
	var BG_WHITE = '\x1b[47m';

	var BRIGHT_BLACK = '\x1b[90m';
	var BRIGHT_RED = '\x1b[91m';
	var BRIGHT_GREEN = '\x1b[92m';
	var BRIGHT_YELLOW = '\x1b[93m';
	var BRIGHT_BLUE = '\x1b[94m';
	var BRIGHT_MAGENTA = '\x1b[95m';
	var BRIGHT_CYAN = '\x1b[96m';
	var BRIGHT_WHITE = '\x1b[97m';

	var BG_BRIGHT_BLACK = '\x1b[100m';
	var BG_BRIGHT_RED = '\x1b[101m';
	var BG_BRIGHT_GREEN = '\x1b[102m';
	var BG_BRIGHT_YELLOW = '\x1b[103m';
	var BG_BRIGHT_BLUE = '\x1b[104m';
	var BG_BRIGHT_MAGENTA = '\x1b[105m';
	var BG_BRIGHT_CYAN = '\x1b[106m';
	var BG_BRIGHT_WHITE = '\x1b[107m';
}

/**
 * Provides functionality for applying ANSI codes to strings for terminal output.
 */
@:nullSafety
class AnsiUtil {
	#if sys
	@:noCompletion
	private static final REGEX_TEAMCITY_VERSION:EReg = ~/^9\.(0*[1-9]\d*)\.|\d{2,}\./;

	@:noCompletion
	private static final REGEX_TERM_256:EReg = ~/(?i)-256(color)?$/;

	@:noCompletion
	private static final REGEX_TERM_TYPES:EReg = ~/(?i)^screen|^xterm|^vt100|^vt220|^rxvt|color|ansi|cygwin|linux/;
	#end

	@:noCompletion
	private static final REGEX_ANSI_CODES:EReg = ~/\x1b\[[0-9;]*m/g;

	@:noCompletion
	private static var codesSupported:Null<Bool> = null;

	/**
	 * Applies the specified ANSI codes to the input string,
	 * stripping them if the terminal does not support ANSI.
	 *
	 * @param input The input value to style.
	 * @param codes The ANSI codes to apply.
	 * @return The styled string, or a plain string if ANSI is unsupported.
	 */
	public static function apply(input:String, codes:Array<AnsiCode>):String {
		if (codes.length == 0) return resolveOutput(Std.string(input));
		final styled = codes.join('') + input + AnsiCode.RESET;
		return resolveOutput(styled);
	}

	/**
	 * Resets the cached ANSI support detection.
	 * Useful for testing or repl-like environments where env vars may change.
	 */
	public static function resetCache():Void {
		codesSupported = null;
	}

	@:noCompletion
	private static function resolveOutput(output:String):String {
		if (codesSupported == null)
			codesSupported = detectAnsiSupport();
		return codesSupported ? output : REGEX_ANSI_CODES.replace(output, '');
	}

	#if sys
	@:noCompletion
	private static function detectAnsiSupport():Bool {
		final term = getEnvSafe('TERM');
		if (term == 'dumb')
			return false;
		if (term != null && (REGEX_TERM_256.match(term) || REGEX_TERM_TYPES.match(term)))
			return true;
		if (isSupportedCiEnv())
			return true;
		if (isTeamCitySupported())
			return true;
		return checkTermProgram();
	}

	@:noCompletion
	private static function isSupportedCiEnv():Bool {
		if (getEnvSafe('CI') == null)
			return false;

		final ciEnvNames:Array<String> = [
			"GITHUB_ACTIONS", "GITEA_ACTIONS",    "TRAVIS", "CIRCLECI",
			      "APPVEYOR",     "GITLAB_CI", "BUILDKITE",    "DRONE"
		];

		for (ci in ciEnvNames)
			if (getEnvSafe(ci) != null)
				return true;

		return getEnvSafe("CI_NAME") == "codeship";
	}

	@:noCompletion
	private static function isTeamCitySupported():Bool {
		final tc = getEnvSafe("TEAMCITY_VERSION");
		return tc != null && REGEX_TEAMCITY_VERSION.match(tc);
	}

	@:noCompletion
	private static function checkTermProgram():Bool {
		return getEnvSafe('TERM_PROGRAM') == 'iTerm.app'
			|| getEnvSafe('TERM_PROGRAM') == 'Apple_Terminal'
			|| getEnvSafe('COLORTERM') != null
			|| getEnvSafe('ANSICON') != null
			|| getEnvSafe('ConEmuANSI') != null
			|| getEnvSafe('WT_SESSION') != null;
	}
	#else
	@:noCompletion
	private static inline function detectAnsiSupport():Bool
		return false;
	#end

	/**
	 * Safe wrapper for Sys.getEnv — returns null on non-sys targets.
	 */
	@:noCompletion
	private static function getEnvSafe(name:String):Null<String> {
		#if sys
		return Sys.getEnv(name);
		#else
		return null;
		#end
	}
}
