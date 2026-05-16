package funkin.backend.utils.tools;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class QolTools {
	public function new() {}

	// Float extensions
	// myFloat.clamp(0, 1)

	public static inline function clamp(v:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, v));

	public static inline function lerp(a:Float, b:Float, t:Float):Float
		return a + (b - a) * t;

	/** Frame-rate independent lerp — safe in update() */
	public static inline function flerp(a:Float, b:Float, ratio:Float):Float
		return a + (b - a) * (ratio * FlxG.elapsed * 60);

	public static inline function remap(v:Float, inMin:Float, inMax:Float, outMin:Float, outMax:Float):Float
		return outMin + (v - inMin) / (inMax - inMin) * (outMax - outMin);

	public static inline function snap(v:Float, step:Float):Float
		return Math.round(v / step) * step;

	public static inline function sign(v:Float):Int
		return v > 0 ? 1 : v < 0 ? -1 : 0;

	public static inline function between(v:Float, min:Float, max:Float):Bool
		return v >= min && v <= max;

	public static inline function abs(v:Float):Float
		return v < 0 ? -v : v;

	public static inline function toInt(v:Float):Int
		return Std.int(v);

	public static inline function roundTo(v:Float, decimals:Int):Float {
		var f = Math.pow(10, decimals);
		return Math.round(v * f) / f;
	}

	// Ping-pong: great for oscillating effects
	public static inline function pingPong(v:Float, length:Float):Float {
		v = v % (length * 2);
		return v > length ? length * 2 - v : v;
	}

	public static inline function randomRange(min:Float, max:Float):Float
		return min + Math.random() * (max - min);

	// Useful for proc-gen / loot rolls
	public static inline function chance(percent:Float):Bool
		return Math.random() * 100 < percent;

	// Int wrap
	public static inline function wrap(v:Int, min:Int, max:Int):Int {
		var range = max - min + 1;
		return ((v - min) % range + range) % range + min;
	}

	// quick random int
	public static inline function randomInt(min:Int, max:Int):Int
		return min + Std.int(Math.random() * (max - min + 1));

	/** Smooth 3rd-order interpolation — no overshoot, feels more natural than lerp */
	public static inline function smoothStep(edge0:Float, edge1:Float, v:Float):Float {
		var t = clamp((v - edge0) / (edge1 - edge0), 0, 1);
		return t * t * (3 - 2 * t);
	}

	/** Smoother 5th-order version of smoothStep */
	public static inline function smootherStep(edge0:Float, edge1:Float, v:Float):Float {
		var t = clamp((v - edge0) / (edge1 - edge0), 0, 1);
		return t * t * t * (t * (t * 6 - 15) + 10);
	}

	/** Inverse lerp — what t produces v between a and b? Returns 0–1 */
	public static inline function inverseLerp(a:Float, b:Float, v:Float):Float
		return (v - a) / (b - a);

	/** Deadzone — treat values within ±threshold of zero as exactly zero */
	public static inline function deadzone(v:Float, threshold:Float):Float
		return abs(v) < threshold ? 0.0 : v;

	/** Approach target by fixed step per frame, no overshoot */
	public static inline function approach(current:Float, target:Float, step:Float):Float
		return current < target ? Math.min(current + step, target) : Math.max(current - step, target);

	/** Oscillate with sin — good for idle bobs, breathing effects */
	public static inline function oscillate(time:Float, freq:Float, amplitude:Float, offset:Float = 0):Float
		return Math.sin((time * freq + offset) * Math.PI * 2) * amplitude;

	/** Convert degrees to radians */
	public static inline function toRad(deg:Float):Float
		return deg * (Math.PI / 180);

	/** Convert radians to degrees */
	public static inline function toDeg(rad:Float):Float
		return rad * (180 / Math.PI);

	// Int extensions
	// myInt.inRange(0, 10)

	public static inline function inRange(v:Int, min:Int, max:Int):Bool
		return v >= min && v <= max;

	public static inline function isEven(v:Int):Bool
		return v % 2 == 0;

	public static inline function isOdd(v:Int):Bool
		return v % 2 != 0;

	public static inline function toFloat(v:Int):Float
		return v;

	/** Number of digits in a non-negative integer */
	public static inline function digitCount(v:Int):Int
		return v == 0 ? 1 : Std.int(Math.log(v) / Math.log(10)) + 1;

	/** Greatest common divisor — useful for aspect-ratio reduction */
	public static function gcd(a:Int, b:Int):Int
		return b == 0 ? a : gcd(b, a % b);

	/** Least common multiple */
	public static inline function lcm(a:Int, b:Int):Int
		return Std.int(a / gcd(a, b)) * b;

	/** Bit flag helpers */
	public static inline function hasFlag(v:Int, flag:Int):Bool
		return v & flag != 0;

	public static inline function setFlag(v:Int, flag:Int):Int
		return v | flag;

	public static inline function clearFlag(v:Int, flag:Int):Int
		return v & ~flag;

	public static inline function toggleFlag(v:Int, flag:Int):Int
		return v ^ flag;

	// String extensions
	// myString.capitalize()

	public static inline function isNullOrEmpty(s:String):Bool
		return s == null || s.length == 0;

	public static inline function capitalize(s:String):String
		return s.charAt(0).toUpperCase() + s.substr(1).toLowerCase();

	public static inline function trimTo(s:String, max:Int, ellipsis:String = "..."):String
		return s.length > max ? s.substr(0, max - ellipsis.length) + ellipsis : s;

	public static function padLeft(s:String, len:Int, char:String = "0"):String {
		while (s.length < len)
			s = char + s;
		return s;
	}

	public static function padRight(s:String, len:Int, char:String = " "):String {
		while (s.length < len)
			s = s + char;
		return s;
	}

	public static inline function contains(s:String, sub:String):Bool
		return s.indexOf(sub) != -1;

	public static inline function toColor(s:String):FlxColor
		return FlxColor.fromString(s.startsWith("#") ? s : "#" + s);

	/** Repeat a string n times — "=-" × 3 → "=-=-=" */
	public static function repeat(s:String, times:Int):String {
		var out = "";
		for (_ in 0...times)
			out += s;
		return out;
	}

	/** Safe parseInt — returns fallback instead of throwing on bad input */
	public static inline function toIntSafe(s:String, fallback:Int = 0):Int {
		var n = Std.parseInt(s);
		return n == null ? fallback : n;
	}

	/** Safe parseFloat */
	public static inline function toFloatSafe(s:String, fallback:Float = 0):Float {
		var n = Std.parseFloat(s);
		return Math.isNaN(n) ? fallback : n;
	}

	/** Reverse a string */
	public static function reverse(s:String):String {
		var chars = s.split("");
		chars.reverse();
		return chars.join("");
	}

	/** Count occurrences of sub in s */
	public static function countOccurrences(s:String, sub:String):Int {
		var count = 0;
		var i = 0;
		while ((i = s.indexOf(sub, i)) != -1) {
			count++;
			i += sub.length;
		}
		return count;
	}

	/** Word-wrap: split s into lines no longer than maxLen */
	public static function wordWrap(s:String, maxLen:Int):Array<String> {
		var words = s.split(" ");
		var lines:Array<String> = [];
		var line = "";
		for (w in words) {
			if (line.length == 0) {
				line = w;
				continue;
			}
			if (line.length + 1 + w.length <= maxLen)
				line += " " + w;
			else {
				lines.push(line);
				line = w;
			}
		}
		if (line.length > 0)
			lines.push(line);
		return lines;
	}

	// Array extensions
	// myArray.shuffle()

	public static function shuffle<T>(arr:Array<T>):Array<T> {
		var i = arr.length;
		while (i > 1) {
			var j = Std.int(Math.random() * i--);
			var tmp = arr[i];
			arr[i] = arr[j];
			arr[j] = tmp;
		}
		return arr;
	}

	public static inline function randomItem<T>(arr:Array<T>):Null<T>
		return arr.length > 0 ? arr[Std.int(Math.random() * arr.length)] : null;

	public static inline function first<T>(arr:Array<T>):Null<T>
		return arr.length > 0 ? arr[0] : null;

	public static inline function last<T>(arr:Array<T>):Null<T>
		return arr.length > 0 ? arr[arr.length - 1] : null;

	public static function flatten<T>(arr:Array<Array<T>>):Array<T> {
		var out:Array<T> = [];
		for (a in arr)
			out = out.concat(a);
		return out;
	}

	public static function removeDuplicates<T>(arr:Array<T>):Array<T> {
		var seen = new Map<String, Bool>();
		return arr.filter(v -> {
			var k = Std.string(v);
			var fresh = !seen.exists(k);
			seen.set(k, true);
			fresh;
		});
	}

	public static inline function isEmpty<T>(arr:Array<T>):Bool
		return arr.length == 0;

	public static inline function clear<T>(arr:Array<T>):Array<T> {
		arr.splice(0, arr.length);
		return arr;
	}

	/** Sum of all elements */
	public static function sum(arr:Array<Float>):Float {
		var total = 0.0;
		for (v in arr)
			total += v;
		return total;
	}

	/** Average of all elements */
	public static inline function average(arr:Array<Float>):Float
		return arr.length == 0 ? 0 : sum(arr) / arr.length;

	/** Min value in array */
	public static function minOf(arr:Array<Float>):Float {
		var m = Math.POSITIVE_INFINITY;
		for (v in arr)
			if (v < m)
				m = v;
		return m;
	}

	/** Max value in array */
	public static function maxOf(arr:Array<Float>):Float {
		var m = Math.NEGATIVE_INFINITY;
		for (v in arr)
			if (v > m)
				m = v;
		return m;
	}

	/** Split array into chunks of size n */
	public static function chunk<T>(arr:Array<T>, size:Int):Array<Array<T>> {
		var out:Array<Array<T>> = [];
		var i = 0;
		while (i < arr.length) {
			out.push(arr.slice(i, i + size));
			i += size;
		}
		return out;
	}

	/** Rotate array left by n positions — [1,2,3,4].rotate(1) → [2,3,4,1] */
	public static function rotate<T>(arr:Array<T>, n:Int):Array<T> {
		var len = arr.length;
		if (len == 0)
			return arr;
		n = ((n % len) + len) % len;
		return arr.slice(n).concat(arr.slice(0, n));
	}

	/** Count elements matching a predicate */
	public static function count<T>(arr:Array<T>, pred:T->Bool):Int {
		var n = 0;
		for (v in arr)
			if (pred(v))
				n++;
		return n;
	}

	/** True if any element matches predicate */
	public static function any<T>(arr:Array<T>, pred:T->Bool):Bool {
		for (v in arr)
			if (pred(v))
				return true;
		return false;
	}

	/** True if all elements match predicate */
	public static function all<T>(arr:Array<T>, pred:T->Bool):Bool {
		for (v in arr)
			if (!pred(v))
				return false;
		return true;
	}

	/** Zip two arrays into pairs — stops at the shorter length */
	public static function zip<A, B>(a:Array<A>, b:Array<B>):Array<{a:A, b:B}> {
		var len = Std.int(Math.min(a.length, b.length));
		var out = [];
		for (i in 0...len)
			out.push({a: a[i], b: b[i]});
		return out;
	}

	// FlxColor extensions
	// myColor.withAlpha(0.5)

	public static function lerpColor(a:FlxColor, b:FlxColor, t:Float):FlxColor
		return FlxColor.fromRGBFloat(lerp(a.redFloat, b.redFloat, t), lerp(a.greenFloat, b.greenFloat, t), lerp(a.blueFloat, b.blueFloat, t),
			lerp(a.alphaFloat, b.alphaFloat, t));

	public static inline function withAlpha(color:FlxColor, alpha:Float):FlxColor {
		color.alphaFloat = clamp(alpha, 0, 1);
		return color;
	}

	public static inline function withBrightness(color:FlxColor, factor:Float):FlxColor
		return FlxColor.fromRGBFloat(clamp(color.redFloat * factor, 0, 1), clamp(color.greenFloat * factor, 0, 1), clamp(color.blueFloat * factor, 0, 1),
			color.alphaFloat);

	/** Invert RGB channels, keep alpha */
	public static inline function invert(color:FlxColor):FlxColor
		return FlxColor.fromRGB(255 - color.red, 255 - color.green, 255 - color.blue, color.alpha);

	/** Convert to greyscale using luminance weights */
	public static inline function toGreyscale(color:FlxColor):FlxColor {
		var lum = Std.int(color.red * 0.299 + color.green * 0.587 + color.blue * 0.114);
		return FlxColor.fromRGB(lum, lum, lum, color.alpha);
	}

	/** Complementary hue (180° rotation) */
	public static inline function complementary(color:FlxColor):FlxColor
		return FlxColor.fromHSB((color.hue + 180) % 360, color.saturation, color.brightness, color.alphaFloat);

	/** Shift hue by degrees */
	public static inline function shiftHue(color:FlxColor, degrees:Float):FlxColor
		return FlxColor.fromHSB((color.hue + degrees + 360) % 360, color.saturation, color.brightness, color.alphaFloat);

	// FlxObject extensions
	// mySprite.centerOnScreen()

	public static inline function centerOnScreen(obj:FlxObject):FlxObject {
		obj.x = (FlxG.width - obj.width) * 0.5;
		obj.y = (FlxG.height - obj.height) * 0.5;
		return obj;
	}

	public static inline function centerX(obj:FlxObject):FlxObject {
		obj.x = (FlxG.width - obj.width) * 0.5;
		return obj;
	}

	public static inline function centerY(obj:FlxObject):FlxObject {
		obj.y = (FlxG.height - obj.height) * 0.5;
		return obj;
	}

	public static inline function setPos(obj:FlxObject, x:Float, y:Float):FlxObject {
		obj.x = x;
		obj.y = y;
		return obj;
	}

	public static inline function nudge(obj:FlxObject, dx:Float, dy:Float):FlxObject {
		obj.x += dx;
		obj.y += dy;
		return obj;
	}

	/** True if the object's bounds are fully within the screen */
	public static inline function isFullyOnScreen(obj:FlxObject):Bool
		return obj.x >= 0 && obj.y >= 0 && obj.x + obj.width <= FlxG.width && obj.y + obj.height <= FlxG.height;

	/** True if any part of the object overlaps the screen */
	public static inline function isPartlyOnScreen(obj:FlxObject):Bool
		return obj.x + obj.width > 0 && obj.y + obj.height > 0 && obj.x < FlxG.width && obj.y < FlxG.height;

	/** Snap position to a pixel grid of size n */
	public static inline function snapToGrid(obj:FlxObject, gridSize:Float):FlxObject {
		obj.x = Math.round(obj.x / gridSize) * gridSize;
		obj.y = Math.round(obj.y / gridSize) * gridSize;
		return obj;
	}

	/** Set both width and height at once */
	public static inline function setSize(obj:FlxObject, w:Float, h:Float):FlxObject {
		obj.width = w;
		obj.height = h;
		return obj;
	}

	/** Place obj so its right edge aligns to x */
	public static inline function alignRight(obj:FlxObject, x:Float):FlxObject {
		obj.x = x - obj.width;
		return obj;
	}

	/** Place obj so its bottom edge aligns to y */
	public static inline function alignBottom(obj:FlxObject, y:Float):FlxObject {
		obj.y = y - obj.height;
		return obj;
	}

	// FlxSprite extensions
	// mySprite.fadeIn(0.3)

	public static inline function fadeIn(spr:FlxSprite, dur:Float, ?ease:Float->Float):FlxTween {
		spr.alpha = 0;
		return FlxTween.tween(spr, {alpha: 1}, dur, {ease: ease ?? FlxEase.quartOut});
	}

	public static inline function fadeOut(spr:FlxSprite, dur:Float, ?ease:Float->Float):FlxTween
		return FlxTween.tween(spr, {alpha: 0}, dur, {ease: ease ?? FlxEase.quartOut});

	public static inline function popIn(spr:FlxSprite, dur:Float = 0.25):FlxTween {
		spr.scale.set(0, 0);
		return FlxTween.tween(spr.scale, {x: 1, y: 1}, dur, {ease: FlxEase.backOut});
	}

	public static inline function setAlpha(spr:FlxSprite, a:Float):FlxSprite {
		spr.alpha = clamp(a, 0, 1);
		return spr;
	}

	// Repeating pulse — good for UI "press me" hints
	public static inline function pulse(spr:FlxSprite, scale:Float = 1.1, dur:Float = 0.4):FlxTween
		return FlxTween.tween(spr.scale, {x: scale, y: scale}, dur, {
			ease: FlxEase.sineInOut,
			type: FlxTweenType.PINGPONG
		});

	// Color flash — hit flash, pickups, etc.
	public static function flash(spr:FlxSprite, color:FlxColor = FlxColor.WHITE, dur:Float = 0.1):Void {
		spr.color = color;
		FlxTween.color(spr, dur, color, FlxColor.WHITE, {
			onComplete: _ -> spr.color = FlxColor.WHITE
		});
	}

	/** Shake sprite by randomly offsetting its position each frame for dur seconds */
	public static function shake(spr:FlxSprite, intensity:Float = 4, dur:Float = 0.3):FlxTween {
		var ox = spr.x, oy = spr.y;
		return FlxTween.num(0, 1, dur, {
			onUpdate: _ -> {
				spr.x = ox + randomRange(-intensity, intensity);
				spr.y = oy + randomRange(-intensity, intensity);
			},
			onComplete: _ -> {
				spr.x = ox;
				spr.y = oy;
			}
		});
	}

	/** Gentle vertical bob loop — idle animations, floating icons */
	public static inline function bob(spr:FlxSprite, amount:Float = 4, dur:Float = 1.0):FlxTween
		return FlxTween.tween(spr, {y: spr.y - amount}, dur, {
			ease: FlxEase.sineInOut,
			type: FlxTweenType.PINGPONG
		});

	/** Squash-and-stretch hit impact — squash wide then spring back */
	public static function squash(spr:FlxSprite, dur:Float = 0.2):FlxTween {
		spr.scale.set(1.4, 0.6);
		return FlxTween.tween(spr.scale, {x: 1, y: 1}, dur, {ease: FlxEase.elasticOut});
	}

	/** Reset scale and alpha to defaults */
	public static inline function resetTransform(spr:FlxSprite):FlxSprite {
		spr.scale.set(1, 1);
		spr.alpha = 1;
		spr.color = FlxColor.WHITE;
		return spr;
	}

	// FlxPoint extensions
	// myPoint.distanceTo(other)

	public static inline function distanceTo(a:FlxPoint, b:FlxPoint):Float {
		var dx = a.x - b.x, dy = a.y - b.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public static inline function lerpTo(a:FlxPoint, b:FlxPoint, t:Float):FlxPoint
		return FlxPoint.get(lerp(a.x, b.x, t), lerp(a.y, b.y, t));

	public static inline function angleTo(a:FlxPoint, b:FlxPoint):Float
		return Math.atan2(b.y - a.y, b.x - a.x) * (180 / Math.PI);

	public static inline function normalize(p:FlxPoint):FlxPoint {
		var len = Math.sqrt(p.x * p.x + p.y * p.y);
		return len > 0 ? FlxPoint.get(p.x / len, p.y / len) : FlxPoint.get(0, 0);
	}

	public static inline function dot(a:FlxPoint, b:FlxPoint):Float
		return a.x * b.x + a.y * b.y;

	/** Scale a point by a scalar */
	public static inline function scale(p:FlxPoint, factor:Float):FlxPoint
		return FlxPoint.get(p.x * factor, p.y * factor);

	/** Add two points */
	public static inline function add(a:FlxPoint, b:FlxPoint):FlxPoint
		return FlxPoint.get(a.x + b.x, a.y + b.y);

	/** Subtract b from a */
	public static inline function subtract(a:FlxPoint, b:FlxPoint):FlxPoint
		return FlxPoint.get(a.x - b.x, a.y - b.y);

	/** Perpendicular vector (rotated 90° CCW) */
	public static inline function perpendicular(p:FlxPoint):FlxPoint
		return FlxPoint.get(-p.y, p.x);

	/** Clamp magnitude to maxLen */
	public static function clampMagnitude(p:FlxPoint, maxLen:Float):FlxPoint {
		var len = Math.sqrt(p.x * p.x + p.y * p.y);
		return len > maxLen ? scale(normalize(p), maxLen) : FlxPoint.get(p.x, p.y);
	}

	/** Midpoint between two points */
	public static inline function midpoint(a:FlxPoint, b:FlxPoint):FlxPoint
		return FlxPoint.get((a.x + b.x) * 0.5, (a.y + b.y) * 0.5);

	/** Reflect a vector off a surface normal */
	public static function reflect(v:FlxPoint, normal:FlxPoint):FlxPoint {
		var d = dot(v, normal) * 2;
		return FlxPoint.get(v.x - d * normal.x, v.y - d * normal.y);
	}

	/** True if two points are within radius of each other */
	public static inline function withinRadius(a:FlxPoint, b:FlxPoint, radius:Float):Bool
		return distanceTo(a, b) <= radius;
}
