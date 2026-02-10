package;

import CompileTime;
import flixel.system.FlxBasePreloader;
import funkin.utils.CoolLog;
import funkin.backend.ErrorHandler;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.Event;
#if LUA_ALLOWED
import llua.Lua;
#end
#if WindowColorMode
import hxwindowmode.WindowColorMode;
#end

@:sound("art/preload/sounds/beep.wav")
class PreloadSoundFX extends Sound
{
}

typedef Task =
{
	message:String,
	action:Void->Void,
	?delay:Float
}

class Preloader extends FlxBasePreloader
{
	var terminal:Array<TextField>;
	var tasks:Array<Task>;
	var sound:PreloadSoundFX;
	var soundChannel:SoundChannel;
	var cursorVisible:Bool = true;
	var cursorChar:String = "_";
	var cursorTimer:Float = 0;
	var cursorInterval:Float = 0.5;

	var currentTaskIndex:Int = 0;
	var taskTimer:Float = 0;
	var waitingForTask:Bool = false;
	var hasPlayedSound:Bool = false;
	var currentLineIndex:Int = 0;
	var lineHeight:Float = 16;

	public function new(MinDisplayTime:Float = 0, ?AllowedURLs:Array<String>)
	{
		#if WindowColorMode
		WindowColorMode.setDarkMode();
		if (WindowColorMode.isWindows10)
			WindowColorMode.redrawWindowHeader();
		#end

		CoolLog.init();
		ErrorHandler.init();

		// Initialize terminal array
		terminal = [];

		// Initialize tasks
		tasks = [
			{
				message: 'Starting Haxe Kernel ${CompileTime.getHaxeVersion()}...',
				action: function()
				{
				},
				delay: 0.2
			},
			{
				message: 'Initializing Funkin...',
				action: function()
				{/* Funkin init */},
				delay: 0.2
			},
			{
				message: 'Initializing PaoPao Engine...',
				action: function()
				{/* Engine init */},
				delay: 0.25
			},
			#if HSCRIPT_ALLOWED
			{
				message: "Initializing HScript Interpreter...",
				action: function()
				{/* HScript init */},
				delay: 0.2
			},
			#end
			#if LUA_ALLOWED
			{
				message: 'Initializing Lua ${StringTools.replace(Lua.version(), "Lua ", "")} LuaJIT ${StringTools.replace(Lua.versionJIT(), "LuaJIT ", "")}...',
				action: function()
				{/* Lua init */},
				delay: 0.3
			},
			#end
			{
				message: "Starting Game...",
				action: function()
				{/* Start game */},
				delay: 0.2
			},
		];

		var ttime:Float = 0;
		for (i in 0...tasks.length)
		{
			ttime += tasks[i].delay != null ? tasks[i].delay : 0.3;
		}

		super(ttime, AllowedURLs);

		// Initialize sound
		sound = new PreloadSoundFX();
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

		addEventListener(Event.ENTER_FRAME, onFirstFrame);
	}

	function onFirstFrame(e:Event):Void
	{
		if (!hasPlayedSound && sound != null)
		{
			soundChannel = sound.play(0, 0, new SoundTransform(0.5));
			hasPlayedSound = true;
		}
		removeEventListener(Event.ENTER_FRAME, onFirstFrame);
	}

	function createLine(text:String):TextField
	{
		var line = new TextField();
		line.defaultTextFormat = new TextFormat("_typewriter", 14, 0x00FF00);
		line.width = stage.stageWidth - 20;
		line.height = lineHeight;
		line.x = 10;
		line.y = 10 + (currentLineIndex * lineHeight);
		line.multiline = false;
		line.wordWrap = false;
		line.selectable = false;
		line.text = text;
		addChild(line);
		return line;
	}

	function print(text:String):Void
	{
		var line = createLine(text);
		terminal.push(line);
		currentLineIndex++;
	}

	function ok():Void
	{
		if (terminal.length > 0)
		{
			var lastLine = terminal[terminal.length - 1];
			lastLine.text = " [  OK  ]  " + lastLine.text;
		}
	}

	function doTask(task:Task, done:Void->Void):Void
	{
		print(task.message);

		// Execute the task action
		if (task.action != null)
			task.action();

		// Mark as done
		ok();

		// Call completion callback
		if (done != null)
			done();
	}

	function refreshCursor():Void
	{
		if (terminal.length == 0)
			return;

		var lastLine = terminal[terminal.length - 1];
		var text = lastLine.text;

		// Remove existing cursor
		if (StringTools.endsWith(text, cursorChar))
			text = text.substr(0, text.length - 1);

		// Add cursor if visible
		if (cursorVisible)
			text += cursorChar;

		lastLine.text = text;
	}

	override function update(_:Float):Void
	{
		super.update(0);

		var elapsed:Float = 1 / 60;

		// Update cursor blink
		cursorTimer += elapsed;
		if (cursorTimer >= cursorInterval)
		{
			cursorTimer = 0;
			cursorVisible = !cursorVisible;
			refreshCursor();
		}

		// Process tasks
		if (currentTaskIndex < tasks.length && !waitingForTask)
		{
			taskTimer += elapsed;
			var currentTask = tasks[currentTaskIndex];
			var delay = currentTask.delay != null ? currentTask.delay : 0.3;

			if (taskTimer >= delay)
			{
				waitingForTask = true;

				doTask(currentTask, function()
				{
					currentTaskIndex++;
					taskTimer = 0;
					waitingForTask = false;
					sound.play(0, 0, new SoundTransform(0.31415926535897932384626433));
				});
			}
		}

		if (currentTaskIndex >= tasks.length)
		{
			super.update(1); // end loop
		}
	}

	override function destroy():Void
	{
		if (soundChannel != null)
		{
			soundChannel.stop();
			soundChannel = null;
		}

		if (terminal != null)
		{
			for (line in terminal)
			{
				if (line != null)
				{
					removeChild(line);
				}
			}
			terminal = null;
		}

		sound = null;
		tasks = null;

		super.destroy();
	}
}
