package;

#if android
import android.content.Context;
#end
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import funkin.backend.Highscore;
import funkin.frontend.huds.FPSCounter;
import funkin.states.TitleState;
import haxe.io.Path;
import lime.app.Application;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
#if (linux || mac)
import lime.graphics.Image;
#end
#if desktop
import funkin.backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end
#if CRASH_HANDLER
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSignal;
import funkin.utils.macro.SourceMap;
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import openfl.events.UncaughtErrorEvent;
import sys.FileSystem;
import sys.io.File;
#end
#if CRASH_DEBUGGER
// Placeholder for crash debugger UI library
#end
import haxe.Exception;

class FunkinGame extends FlxGame
{
	public static var onGameCrash(default, null):FlxTypedSignal<(Exception) -> Void> = new FlxTypedSignal<(Exception) -> Void>();

	/**
	 * Used to instantiate the guts of the flixel game object once we have a valid reference to the root.
	 */
	override function create(_):Void
	{
		try
			super.create(_)
		catch (e:Exception)
			onCrash(e);
	}

	override function onFocus(_):Void
	{
		try
			super.onFocus(_)
		catch (e:Exception)
			onCrash(e);
	}

	override function onFocusLost(_):Void
	{
		try
			super.onFocusLost(_)
		catch (e:Exception)
			onCrash(e);
	}

	override function onEnterFrame(_):Void
	{
		try
			super.onEnterFrame(_)
		catch (e:Exception)
			onCrash(e);
	}

	override function update():Void
	{
		try
			super.update()
		catch (e:Exception)
			onCrash(e);
	}

	override function draw():Void
	{
		try
			super.draw()
		catch (e:Exception)
			onCrash(e);
	}

	private final function onCrash(e:Exception):Void
	{
		if (onGameCrash != null)
		{
			onGameCrash.dispatch(e);
		}
	}
}

/**
 * Error and crash handling system for PaoPaoEngine
 * Handles uncaught errors, critical errors, and provides logging functionality
 */
class ErrorHandle
{
	#if CRASH_HANDLER
	private static var _sourceMap:Map<String, String> = SourceMap.build();

	public static function init():Void
	{
		FunkinGame.onGameCrash.add(onCrash);
	}

	private static function onCrash(e:haxe.Exception):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();
		var getLine = function(file:String, line:Int):String
		{
			var content = getFile(file);
			if (content != null)
			{
				var lines = content.split("\n");
				if (line > 0 && line <= lines.length)
				{
					return lines[line - 1].trim();
				}
			}
			return "Could not retrieve source code line.";
		};

		CoolLog.critical("Crash detected!");

		dateNow = dateNow.replace(" ", "_").replace(":", "-");
		path = "./crash/" + "PaoPaoEngine_" + dateNow + ".log";

		// Build stack trace
		var stackIndex:Int = 0;
		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
					errMsg += "-> " + getLine(file, line) + "\n";
					stackIndex++;
				default:
					errMsg += "#" + stackIndex + " " + Std.string(stackItem) + "\n";
					stackIndex++;
			}
		}

		errMsg += "\nUncaught Error: " + e.toString();
		#if officialBuild
		errMsg += "\nPlease report this error to the GitHub page: https://github.com/Paopun20/FNF-PaoPaoEngine";
		#end
		errMsg += "\n\n> New Crash Handler written by: Paopun20";

		// Save crash log
		#if CRASH_DEBUGGER
		// uhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh, what lib I can use like imgui and easy to use in Haxe?

		// For now, just save the logs and show a simple dialog, but in the future we can make a full crash debugger with stack trace navigation
		saveLogs(path, errMsg);
		showDialogWindow(errMsg, "Game Crash!");
		shutdown();
		#else
		saveLogs(path, errMsg);
		showDialogWindow(errMsg, "Game Crash!");
		shutdown();
		#end
	}

	/**
	 * Save logs to file
	 */
	private static function saveLogs(filename:String, content:String):Void
	{
		try
		{
			if (!FileSystem.exists("./crash/"))
				FileSystem.createDirectory("./crash/");

			File.saveContent(filename, content + "\n");
			CoolLog.critical("Crash dump saved in " + Path.normalize(filename));
		}
		catch (e:Dynamic)
		{
			trace('Failed to save crash log: $e');
		}
	}

	/**
	 * Show a dialog window with error message
	 */
	private static function showDialogWindow(message:String, title:String):Void
	{
		try
		{
			Application.current.window.alert(message, title);
		}
		catch (e:Dynamic)
		{
			trace('Failed to show dialog window: $e');
		}
	}

	/**
	 * Shutdown the application
	 */
	private static function shutdown():Void
	{
		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end

		#if sys
		Sys.exit(1);
		#end
	}

	private static function getFile(path:String):Null<String>
	{
		return _sourceMap.get(path.replace("\\", "/"));
	}
	#end
}

#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end
class Main extends Sprite
{
	public static final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPSCounter; // for showing FPS on screen, if enabled in settings
	public static var gameInstance:Main; // for mods to access the main class instance, if needed
	public static var flxInstance:FunkinGame; // just FunkinGame instance, for mods to access it directly if needed

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		funkin.plugins.ForceCrashPlugin.initialize();
	}

	public function new()
	{
		super();

		#if (cpp && windows)
		funkin.backend.Native.fixScaling();
		#end

		// Credits to MAJigsaw77 (he's the og author for this code)
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end
		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0") ['--no-lua'] #end);
		#end

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		Highscore.load();

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(funkin.modding.scripts.components.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		gameInstance = this;
		flxInstance = new FunkinGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen);
		addChild(flxInstance);

		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null)
		{
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end

		#if (linux || mac) // fix the app icon not showing up on the Linux Panel / Mac Dock
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.mouse.useSystemCursor = true;

		#if CRASH_HANDLER
		ErrorHandle.init();
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h)
		{
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
				{
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}
