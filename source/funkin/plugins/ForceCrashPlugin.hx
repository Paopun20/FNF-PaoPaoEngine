package funkin.plugins;

import haxe.Exception;
import flixel.FlxBasic;
import flixel.FlxG;

class ForceCrashException extends Exception {}

@:nullSafety(Strict)
class ForceCrashPlugin extends FlxBasic {
	public function new() {
		super();
	}

	public static function initialize():Void {
		FlxG.plugins.addPlugin(new ForceCrashPlugin());
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.L) {
			trace("Force crash keybind activated, crashing the game...");
			throw new ForceCrashException("Crashing the game via debug keybind!");
		}
	}

	public override function destroy():Void {
		super.destroy();
	}
}
