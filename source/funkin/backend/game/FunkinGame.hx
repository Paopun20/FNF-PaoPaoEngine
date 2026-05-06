package funkin.backend.game;

import flixel.FlxGame;

#if CRASH_HANDLER
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSignal;
#end

import haxe.Exception;

final class FunkinGame extends FlxGame
{
	#if CRASH_HANDLER
	public static var onGameCrash(default, null):FlxTypedSignal<(Exception) -> Void> = new FlxTypedSignal<(Exception) -> Void>();
	#end

	var skipNextTickUpdate:Bool = false;
	var hasCrashed:Bool = false;

	override function create(_):Void
	{
		try
			super.create(_)
		catch (e:Exception)
			onCrash(e);
	}

	override function switchState():Void
	{
		try
		{
			super.switchState();

			// Pre-draw to upload textures to GPU (prevents lag spike)
			draw();

			// Reset timing so next frame doesn't think a ton of time passed
			_total = ticks = getTicks();

			skipNextTickUpdate = true;
		}
		catch (e:Exception)
			onCrash(e);
	}

	override function onEnterFrame(t):Void
	{
		try
		{
			if (skipNextTickUpdate != (skipNextTickUpdate = false))
				_total = ticks = getTicks();

			super.onEnterFrame(t);
		}
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
		if (hasCrashed) return;
		hasCrashed = true;

		#if CRASH_HANDLER
		if (onGameCrash != null)
			onGameCrash.dispatch(e);
		#end
	}
}