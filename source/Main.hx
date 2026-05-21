package;

#if (android || ios)
import lime.system.System;
#end
import flixel.FlxG;
import funkin.backend.Highscore;
import funkin.frontend.huds.FPSCounter;
import funkin.states.TitleState;
import flixel.util.FlxSignal;
import lime.app.Application;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import sys.thread.Thread;
#if (linux || mac)
import lime.graphics.Image;
#end
#if desktop
import funkin.backend.modules.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end
#if hxhardware
import hxhardware.CPU;
#end
#if SlWindowsAPI
import winapi.WindowsAPI;
#end
#if hxWindowColorMode
import hxwindowmode.WindowColorMode;
#end
#if hxvlc
import hxvlc.util.Handle as VLCHandle;
#end
import funkin.backend.game.FunkinGame;
#if cpp
import funkin.backend.utils.HxSignalKill;
#end

import openfl.Lib;

#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end
class Main extends Sprite {
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

	public static var onClose(default, null):FlxSignal = new FlxSignal();

	static var threadList:Array<Thread> = [];

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void {
		FlxG.random.resetInitialSeed(); // Reset the RNG seed to ensure different random values each run
		#if SlWindowsAPI
		WindowsAPI.reDefineMainWindowTitle(Application.current.window.title);
		#end

		CoolLog.init();

		#if hxWindowColorMode
		WindowColorMode.setDarkMode();
		if (WindowColorMode.isWindows10)
			WindowColorMode.redrawWindowHeader();
		#end
		#if CRASH_HANDLER
		ErrorHandle.init();
		#end
		#if hxhardware
		CPU.init();
		#end

		#if hxvlc
		// Initialize hxvlc's Handle here so the videos are loading faster.
		VLCHandle.initAsync(#if (hxvlc >= "1.8.0") ['--no-lua'] #end, function(success:Bool):Void {
			if (success) {
				CoolLog.info('HXVLC has LibVLC instance initialized!');
			} else {
				CoolLog.warning('HXVLC has LibVLC instance failed to initialize!');
			}
		});
		#end

		#if cpp
		HxSignalKill.init();

		HxSignalKill.onSIGTERM = HxSignalKill.onSIGINT = function() {
			// kill message, but why?
			var messages = [
				"Ctrl + C is kill me",
				"oops i died",
				"welp",
				"The engine has left the chat",
				"Task failed successfully",
				"User used violence",
				"SIGINT jumpscare",
				"guess i'll die",
				"brb crashing",
				"Windows moment",
				"Sending myself to the shadow realm",
				"The bugs won",
				"Forced to stop existing",
				"Runtime has chosen death",
				"keyboard interrupt but emotionally",
				"i have become null",
				"Exiting before things get worse",
				"Too much gaming detected",
				"Engine exploded respectfully",
				"Achievement unlocked: Segmentation Fault",
				"Unhandled emotional exception"
			];

			CoolLog.info(messages[FlxG.random.int(0, messages.length - 1)]);
			ClientPrefs.saveSettings();
			#if DISCORD_ALLOWED
			DiscordClient.shutdown();
			#end
			#if hxvlc
			VLCHandle.dispose();
			#end
			Sys.exit(0);
		};

		#if !windows
		HxSignalKill.onSIGHUP = function() {
			ClientPrefs.loadDefaultKeys();
		};
		#end
		#end

		Lib.current.addChild(new Main());

		Lib.current.stage.window.onClose.add(onClose.dispatch);
		onClose.add(function() {
			#if cpp
			for (thread in threadList) {
				thread.sendMessage("kill");
			}
			#end
			#if hxvlc
			VLCHandle.dispose();
			CoolLog.init();
			#end
			ClientPrefs.saveSettings();
		});

		funkin.plugins.ForceCrashPlugin.initialize();
	}

	public function new() {
		super();

		#if (cpp && windows)
		funkin.backend.Native.fixScaling();
		#end

		#if android
		Sys.setCwd(Path.addTrailingSlash(System.applicationStorageDirectory));
		#elseif ios
		Sys.setCwd(System.documentsDirectory);
		#end

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		Highscore.load();

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
		if (fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end

		#if (linux || mac) // fix the app icon not showing up on the Linux Panel / Mac Dock
		Lib.current.stage.window.setIcon(Image.fromFile("icon.png"));
		#end

		#if html5
		FlxG.mouse.visible = FlxG.autoPause = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.mouse.useSystemCursor = true;

		#if cpp
		threadList.push(Thread.create(function():Void {
			while (true) {
				var msg = Thread.readMessage(false);

				if (msg == "kill") {
					return;
				}

				HxSignalKill.updateSignal();
				HxSignalKill.dispatchPending();

				Sys.sleep(0.1);
			}
		}));
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		#if FLX_DEBUG
		FlxG.debugger.toggleKeys.remove(BACKSLASH);
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h) {
			if (FlxG.cameras != null)
				for (cam in FlxG.cameras.list)
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);

			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}
