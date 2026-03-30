package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class PPQolTool {
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

    // Int extensions
    // myInt.inRange(0, 10)

    public static inline function inRange(v:Int, min:Int, max:Int):Bool
        return v >= min && v <= max;

    public static inline function isEven(v:Int):Bool return v % 2 == 0;
    public static inline function isOdd(v:Int):Bool  return v % 2 != 0;

    public static inline function toFloat(v:Int):Float return v;

    // String extensions
    // myString.capitalize()

    public static inline function isNullOrEmpty(s:String):Bool
        return s == null || s.length == 0;

    public static inline function capitalize(s:String):String
        return s.charAt(0).toUpperCase() + s.substr(1).toLowerCase();

    public static inline function trimTo(s:String, max:Int, ellipsis:String = "..."):String
        return s.length > max ? s.substr(0, max - ellipsis.length) + ellipsis : s;

    public static function padLeft(s:String, len:Int, char:String = "0"):String {
        while (s.length < len) s = char + s;
        return s;
    }

    public static function padRight(s:String, len:Int, char:String = " "):String {
        while (s.length < len) s = s + char;
        return s;
    }

    public static inline function contains(s:String, sub:String):Bool
        return s.indexOf(sub) != -1;

    public static inline function toColor(s:String):FlxColor
        return FlxColor.fromString(s.startsWith("#") ? s : "#" + s);

    // Array extensions
    // myArray.shuffle()

    public static function shuffle<T>(arr:Array<T>):Array<T> {
        var i = arr.length;
        while (i > 1) {
            var j = Std.int(Math.random() * i--);
            var tmp = arr[i]; arr[i] = arr[j]; arr[j] = tmp;
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
        for (a in arr) out = out.concat(a);
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

    // FlxColor extensions
    // myColor.withAlpha(0.5)

    public static function lerpColor(a:FlxColor, b:FlxColor, t:Float):FlxColor
        return FlxColor.fromRGBFloat(
            lerp(a.redFloat,   b.redFloat,   t),
            lerp(a.greenFloat, b.greenFloat, t),
            lerp(a.blueFloat,  b.blueFloat,  t),
            lerp(a.alphaFloat, b.alphaFloat, t)
        );

    public static inline function withAlpha(color:FlxColor, alpha:Float):FlxColor {
        color.alphaFloat = clamp(alpha, 0, 1);
        return color;
    }

    public static inline function withBrightness(color:FlxColor, factor:Float):FlxColor
        return FlxColor.fromRGBFloat(
            clamp(color.redFloat   * factor, 0, 1),
            clamp(color.greenFloat * factor, 0, 1),
            clamp(color.blueFloat  * factor, 0, 1),
            color.alphaFloat
        );

    // FlxObject extensions
    // mySprite.centerOnScreen()

    public static inline function centerOnScreen(obj:FlxObject):FlxObject {
        obj.x = (FlxG.width  - obj.width)  * 0.5;
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
        obj.x = x; obj.y = y;
        return obj;
    }

    public static inline function nudge(obj:FlxObject, dx:Float, dy:Float):FlxObject {
        obj.x += dx; obj.y += dy;
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

    // FlxPoint extensions
    // myPoint.distanceTo(other)

    public static inline function distanceTo(a:FlxPoint, b:FlxPoint):Float {
        var dx = a.x - b.x, dy = a.y - b.y;
        return Math.sqrt(dx * dx + dy * dy);
    }

    public static inline function lerpTo(a:FlxPoint, b:FlxPoint, t:Float):FlxPoint
        return FlxPoint.get(lerp(a.x, b.x, t), lerp(a.y, b.y, t));
}