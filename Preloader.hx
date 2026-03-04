package;

import CompileTime;
import Main;
import flixel.system.FlxBasePreloader;
import funkin.utils.CoolLog;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.text.TextField;
import openfl.text.TextFormat;
#if LUA_ALLOWED
import llua.Lua;
#end
#if WindowColorMode
import hxwindowmode.WindowColorMode;
#end

class Preloader extends FlxBasePreloader
{
	public function new(MinDisplayTime:Float = 0, ?AllowedURLs:Array<String>)
	{
		#if WindowColorMode
		WindowColorMode.setDarkMode();
		if (WindowColorMode.isWindows10)
			WindowColorMode.redrawWindowHeader();
		#end

		CoolLog.init();
		ErrorHandle.init();

		super(MinDisplayTime, AllowedURLs);
	}

	override function create():Void
	{
		super.create();
	}

	override function update(_:Float):Void
	{
		super.update(1);
	}

	override function destroy():Void
	{
		super.destroy();
	}
}
