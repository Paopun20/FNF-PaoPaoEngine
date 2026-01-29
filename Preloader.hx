package;
import CompileTime;
import flixel.system.FlxBasePreloader;
import funkin.utils.CoolLog;
import openfl.Lib;
import openfl.display.Sprite;
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

@:sound("art/perload/sounds/beep.wav")
class PerloadSoundFX extends Sound {}

class Preloader extends FlxBasePreloader
{
	var terminal:TextField;
	var lines:Array<String>;
	var lastStep:Int = -1;
	var sound:PerloadSoundFX;
	var soundChannel:SoundChannel;
	var cursorVisible:Bool = true;
	var cursorChar:String = "_";
	var cursorTimer:Float = 0;
	var cursorInterval:Float = 0.5;
	
	var endWaitTimer:Float = 0;
	var endWaitDuration:Float = 1;
	var allLinesShown:Bool = false;
	
	public function new(MinDisplayTime:Float = 5, ?AllowedURLs:Array<String>)
	{
		super(MinDisplayTime, AllowedURLs);
		#if WindowColorMode
		WindowColorMode.setDarkMode();
		if (WindowColorMode.isWindows10)
			WindowColorMode.redrawWindowHeader();
		#end
		CoolLog.init(); // Initialize the logging system
	}
	
	override function create():Void
	{
		super.create();
		
		// Background
		var bg = new Sprite();
		bg.graphics.beginFill(0x000000);
		bg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		bg.graphics.endFill();
		addChild(bg);
		
		// Terminal
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
		
		// Initialize lines
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
			'Initializing Lua ${StringTools.replace(Lua.version(), "Lua ", "")} LuaJIT ${StringTools.replace(Lua.versionJIT(), "LuaJIT ", "")}...',
			#end
			"Initializing Game...",
			"Starting Game...",
		];
		
		// Initialize sound
		sound = new PerloadSoundFX();
	}
	
	function refreshCursor():Void
	{
		var text = terminal.text;
		
		// Remove existing cursor
		if (StringTools.endsWith(text, cursorChar))
			text = text.substr(0, text.length - 1);
		
		// Add cursor if visible
		if (cursorVisible)
			text += cursorChar;
		
		terminal.text = text;
		terminal.scrollV = terminal.maxScrollV;
	}
	
	function setCursorVisibility(visible:Bool):Void
	{
		cursorVisible = visible;
		refreshCursor();
	}
	
	override function update(Percent:Float):Void
	{
		// Get delta time
		var dt = 1 / Lib.current.stage.frameRate;
		
		// Update cursor blink
		cursorTimer += dt;
		if (cursorTimer >= cursorInterval)
		{
			cursorTimer = 0;
			setCursorVisibility(!cursorVisible);
		}
		
		// Update loading progress
		var step = Std.int(Percent * lines.length);
		
		if (step != lastStep && step < lines.length)
		{
			setCursorVisibility(false);
			
			// Play sound effect
			if (sound != null)
				soundChannel = sound.play(0, 0, new SoundTransform(0.3));
			
			// Add new line
			terminal.appendText("> " + lines[step] + "\n");
			lastStep = step;
			
			setCursorVisibility(true);
			
			// Check if all lines are shown
			if (step >= lines.length - 1)
			{
				allLinesShown = true;
			}
		}
		
		// Wait at the end before finishing
		if (allLinesShown && Percent >= 1.0)
		{
			endWaitTimer += dt;
			
			// Only call super.update after wait period
			if (endWaitTimer >= endWaitDuration)
			{
				super.update(Percent);
			}
		}
		else
		{
			super.update(Percent);
		}
	}
	
	override function destroy():Void
	{
		// Stop sound
		if (soundChannel != null)
		{
			soundChannel.stop();
			soundChannel = null;
		}
		
		// Clean up terminal
		if (terminal != null)
		{
			removeChild(terminal);
			terminal = null;
		}
		
		// Clean up references
		sound = null;
		lines = null;
		
		super.destroy();
	}
}