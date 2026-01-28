package;

import flixel.system.FlxBasePreloader;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.Sprite;
import flixel.FlxG;

#if LUA_ALLOWED
import llua.Lua;
#end
#if WindowColorMode
import hxwindowmode.WindowColorMode;
#end
import CompileTime;

@:nullSafety
@:sound("art/perload/sounds/beep.wav")
class PerloadSoundFX extends Sound
{
}

@:nullSafety
class Preloader extends FlxBasePreloader
{
	var terminal:Null<TextField>;
	var lines:Null<Array<String>>;
	var lastStep:Int = -1;
	var sound:PerloadSoundFX = new PerloadSoundFX();

	var cursorVisible:Bool = true;
	var cursorChar:String = "_";
	var cursorTimer:Float = 0;
	var cursorInterval:Float = 1;

	public function new(MinDisplayTime:Float = 5, ?AllowedURLs:Array<String>)
	{
		super(5, AllowedURLs); // fixed timer

		#if WindowColorMode
		WindowColorMode.setDarkMode();
		if (WindowColorMode.isWindows10)
			WindowColorMode.redrawWindowHeader();
		#end
	}

	override function create():Void
	{
		super.create();

		// background
		var bg = new Sprite();
		bg.graphics.beginFill(0x000000);
		bg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		bg.graphics.endFill();
		addChild(bg);

		terminal = new TextField();
		terminal.defaultTextFormat = new TextFormat("_typewriter", 14, 0x00FF00);
		terminal.width = stage.stageWidth - 20;
		terminal.height = stage.stageHeight - 20;
		terminal.x = 10;
		terminal.y = 10;
		terminal.multiline = true;
		terminal.wordWrap = true;
		terminal.selectable = false;
		addChild(terminal);

		lines = [
			'Starting Haxe Kernel ${CompileTime.getHaxeVersion()}...',
			'Building Target ${CompileTime.getTarget()}...',

			'Initializing Funkin...',
			'Initializing PaoPao Engine...',
			'Initializing Script Interpreter...',

			#if HSCRIPT_ALLOWED
			"Initializing HScript Interpreter...",
			#end

			#if LUA_ALLOWED
			'Initializing Lua ${Lua.version()} ${Lua.versionJIT()}...',
			#end

			"Initializing Game...",
			"Starting Game...",
		];
	}

	function refreshCursor():Void
	{
		if (terminal == null)
			return;

		var text = terminal.text;

		if (StringTools.endsWith(text, cursorChar))
			text = text.substr(0, text.length - 1);

		if (cursorVisible)
			text += cursorChar;

		terminal.text = text;
		terminal.scrollV = terminal.maxScrollV;
	}

	override function update(Percent:Float):Void
	{
		super.update(Percent);

		cursorTimer += FlxG.elapsed;
		if (cursorTimer >= cursorInterval)
		{
			cursorTimer = 0;
			cursorVisible = !cursorVisible;
			refreshCursor();
		}

		if (lines != null && terminal != null)
		{
			var step = Std.int(Percent * lines.length);

			if (step != lastStep && step < lines.length)
			{
				cursorVisible = false;
				refreshCursor();

				sound.play(0, 0, new SoundTransform(0.3));
				terminal.appendText("> " + lines[step] + "\n");

				lastStep = step;
				
				cursorVisible = true;
				refreshCursor();
			}
		}
	}
}
