package funkin.backend.utils.tools;

// unless code is unnecessarily verbose, it's more efficient to parse and generate Roman numerals
// using a single master symbol table, rather than separate logic for subtractive notation, overlines
class RomanTools {
	static inline final OVERLINE = "\u0305"; // combining overline
	static inline final UNCIA = "•"; // uncia dot  (1/12)
	static inline final MAX_INT = 2147483647;

	/**
	 * Master symbol table, ordered strictly from highest to lowest value.
	 *
	 * This single ordering drives both:
	 *   - Generation  (greedy subtraction picks the largest fitting symbol)
	 *   - Parsing     (at each position, the highest-value match wins,
	 *                  which is always the canonical one)
	 */
	static final SYMBOLS:Array<{sym:String, val:Int}> = [
		// ── vinculum range  (4 000 – 3 999 000) ──────────────────────────
		{sym: "M\u0305", val: 1_000_000}, // M̄
		{sym: "C\u0305M\u0305", val: 900_000}, // C̄M̄
		{sym: "D\u0305", val: 500_000}, // D̄
		{sym: "C\u0305D\u0305", val: 400_000}, // C̄D̄
		{sym: "C\u0305", val: 100_000}, // C̄
		{sym: "X\u0305C\u0305", val: 90_000}, // X̄C̄
		{sym: "L\u0305", val: 50_000}, // L̄
		{sym: "X\u0305L\u0305", val: 40_000}, // X̄L̄
		{sym: "X\u0305", val: 10_000}, // X̄
		{sym: "MX\u0305", val: 9_000}, // MX̄  (10 000 − 1 000)
		{sym: "V\u0305", val: 5_000}, // V̄
		{sym: "MV\u0305", val: 4_000}, // MV̄  (5 000 − 1 000)
		// ── standard range  (1 – 3 999) ──────────────────────────────────
		{sym: "M", val: 1_000},
		{sym: "CM", val: 900},
		{sym: "D", val: 500},
		{sym: "CD", val: 400},
		{sym: "C", val: 100},
		{sym: "XC", val: 90},
		{sym: "L", val: 50},
		{sym: "XL", val: 40},
		{sym: "X", val: 10},
		{sym: "IX", val: 9},
		{sym: "V", val: 5},
		{sym: "IV", val: 4},
		{sym: "I", val: 1},
	];

	// Int → Roman

	/**
	 * Convert a positive integer (1–3,999,999) to a Roman numeral string.
	 *
	 *   fromInt(4)         → "IV"
	 *   fromInt(1999)      → "MCMXCIX"
	 *   fromInt(4000)      → "MV̄"
	 *   fromInt(1_000_000) → "M̄"
	 *
	 * @throws String if `num` is outside the valid range.
	 */
	public static function fromInt(num:Int):String {
		if (num < 1)
			return ""; // zero and negative numbers have no representation in Roman numerals
		if (num > MAX_INT)
			num = MAX_INT; // clamp to prevent overflow in parsing

		var result = new StringBuf();
		var n = num;

		for (entry in SYMBOLS) {
			while (n >= entry.val) {
				result.add(entry.sym);
				n -= entry.val;
			}
		}

		return result.toString();
	}

	// Float → Roman

	/**
	 * Convert a positive float to Roman numerals, with uncia dots (•) for
	 * the fractional part, rounded to the nearest 1/12.
	 *
	 *   fromFloat(2.5)  → "II••••••"   (2 + 6 twelfths)
	 *   fromFloat(0.25) → "•••"        (3 twelfths)
	 *   fromFloat(1.0)  → "I"
	 *
	 * @throws String if the value is negative or out of range.
	 */
	public static function fromFloat(num:Float):String {
		if (num < 0 || num > MAX_INT + 11 / 12.0)
			throw 'RomanTools.fromFloat: $num is out of range';

		var intPart = Std.int(num);
		var twelfths = Math.round((num - intPart) * 12);

		// Rounding may push the fractional part to exactly 12 twelfths
		if (twelfths >= 12) {
			intPart++;
			twelfths -= 12;
		}

		var result = new StringBuf();
		if (intPart > 0)
			result.add(fromInt(intPart));
		for (_ in 0...twelfths)
			result.add(UNCIA);

		return result.toString();
	}

	// Roman → Int

	/**
	 * Parse a canonical Roman numeral string into an integer.
	 *
	 * Validation strategy: parse greedily, then re-encode and compare.
	 * Any non-canonical form (IIII, IIX, VV, LC …) will produce a value
	 * whose canonical encoding differs from the input, and is rejected.
	 *
	 * @throws String on empty input, unrecognised characters, or
	 *                non-canonical ordering/repetition.
	 */
	public static function toInt(roman:String):Int {
		if (roman == null || roman.length == 0)
			throw 'RomanTools.toInt: input is empty';

		var pos = 0;
		var total = 0;

		while (pos < roman.length) {
			var matched = false;

			for (entry in SYMBOLS) {
				var len = entry.sym.length;
				if (pos + len <= roman.length && roman.substr(pos, len) == entry.sym) {
					total += entry.val;
					pos += len;
					matched = true;
					break;
				}
			}

			if (!matched)
				throw 'RomanTools.toInt: unrecognised symbol at position $pos in "$roman"';
		}

		// Round-trip check — rejects IIII, IIX, VV, LC, etc.
		var canonical = fromInt(total);
		if (roman != canonical)
			throw 'RomanTools.toInt: "$roman" is not canonical (expected "$canonical")';

		return total;
	}

	// Roman → Float

	/**
	 * Parse a Roman numeral string with optional trailing uncia dots into a Float.
	 *
	 *   toFloat("II••••••") → 2.5
	 *   toFloat("•••")      → 0.25
	 *   toFloat("MCMXCIX")  → 1999.0
	 *
	 * @throws String on invalid input or too many uncia dots (max 11).
	 */
	public static function toFloat(roman:String):Float {
		if (roman == null || roman.length == 0)
			throw 'RomanTools.toFloat: input is empty';

		// Strip trailing uncia dots
		var end = roman.length;
		var unciaCount = 0;
		while (end > 0 && roman.charAt(end - 1) == UNCIA) {
			unciaCount++;
			end--;
		}

		if (unciaCount > 11)
			throw 'RomanTools.toFloat: $unciaCount uncia dots exceeds maximum of 11';

		var intPart:Int = (end > 0) ? toInt(roman.substr(0, end)) : 0;

		return intPart + unciaCount / 12.0;
	}

	// Validation helpers

	/** Returns true if `roman` is a valid, canonical Roman numeral integer. */
	public static function isValidInt(roman:String):Bool {
		try {
			toInt(roman);
			return true;
		} catch (_:Dynamic) {
			return false;
		}
	}

	/** Returns true if `roman` is a valid Roman numeral (with optional uncia). */
	public static function isValidFloat(roman:String):Bool {
		try {
			toFloat(roman);
			return true;
		} catch (_:Dynamic) {
			return false;
		}
	}
}
