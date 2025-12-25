package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.addons.display.FlxPieDial;
#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end

#if VIDEOS_ALLOWED
enum VideoState
{
	Idle;
	Playing;
	Skipped;
	Finished;
	Destroyed;
}

class VideoSprite extends FlxSpriteGroup
{
	// Public API
	public var finishCallback:Void->Void;
	public var onSkip:Void->Void;

	public var canSkip(default, null):Bool = false;
	public var waiting(default, null):Bool = false;

	public function play()
		videoSprite?.play();

	public function pause()
		videoSprite?.pause();

	public function resume()
		videoSprite?.resume();

	// Config
	final _timeToSkip:Float = 1.0;

	// Runtime
	var state:VideoState = Idle;
	var holdingTime:Float = 0;

	// Visuals
	public var videoSprite:FlxVideoSprite;

	var skipSprite:FlxPieDial;
	var cover:FlxSprite;

	// Internal
	var videoName:String;
	var alreadyDestroyed:Bool = false;

	public function new(videoName:String, isWaiting:Bool, allowSkip:Bool = false, shouldLoop:Bool = false)
	{
		super();

		this.videoName = videoName;
		this.waiting = isWaiting;

		scrollFactor.set();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		if (!waiting)
			createCover();

		createVideo(shouldLoop);

		if (allowSkip)
			enableSkip();
	}

	override function update(elapsed:Float)
	{
		if (state == Playing && canSkip)
			updateSkip(elapsed);

		super.update(elapsed);
	}

	override function destroy()
	{
		cleanupAndDestroy();
	}

	// VIDEO LIFECYCLE

	function createVideo(shouldLoop:Bool)
	{
		videoSprite = new FlxVideoSprite();
		videoSprite.antialiasing = ClientPrefs.data.antialiasing;
		add(videoSprite);

		videoSprite.bitmap.onFormatSetup.add(fitVideoToScreen);

		if (!shouldLoop)
			videoSprite.bitmap.onEndReached.add(() -> endVideo(false));

		videoSprite.load(videoName, shouldLoop ? ['input-repeat=65545'] : null);

		state = Playing;
	}

	function fitVideoToScreen()
	{
		#if hxvlc
		var vw = videoSprite.bitmap.width;
		var vh = videoSprite.bitmap.height;

		if (vw <= 0 || vh <= 0)
			return;

		var scale = Math.max(FlxG.width / vw, FlxG.height / vh);
		videoSprite.scale.set(scale, scale);
		videoSprite.updateHitbox();
		videoSprite.screenCenter();
		#end
	}

	function endVideo(skipped:Bool)
	{
		if (alreadyDestroyed || state == Destroyed)
			return;

		state = skipped ? Skipped : Finished;

		if (skipped)
			if (onSkip != null)
				onSkip();
			else if (finishCallback != null)
				finishCallback();

		cleanupAndDestroy();
	}

	// SKIP LOGIC

	function updateSkip(elapsed:Float)
	{
		if (Controls.instance.pressed('accept'))
			increaseHold(elapsed);
		else
			decreaseHold(elapsed);

		updateSkipUI();

		if (holdingTime >= _timeToSkip)
			endVideo(true);
	}

	inline function increaseHold(elapsed:Float)
	{
		holdingTime = Math.min(_timeToSkip, holdingTime + elapsed);
	}

	inline function decreaseHold(elapsed:Float)
	{
		holdingTime = Math.max(0, holdingTime - elapsed * 3);
	}

	function updateSkipUI()
	{
		if (skipSprite == null)
			return;

		skipSprite.amount = holdingTime / _timeToSkip;
		skipSprite.alpha = FlxMath.remapToRange(skipSprite.amount, 0.05, 1, 0, 1);
	}

	public function enableSkip()
	{
		if (canSkip)
			return;

		canSkip = true;
		createSkipUI();
	}

	public function disableSkip()
	{
		if (!canSkip)
			return;

		canSkip = false;
		destroySkipUI();
	}

	function createSkipUI()
	{
		skipSprite = new FlxPieDial(0, 0, 40, FlxColor.WHITE, 40, true, 24);
		skipSprite.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);

		skipSprite.x = FlxG.width - (skipSprite.width + 80);
		skipSprite.y = FlxG.height - (skipSprite.height + 72);

		skipSprite.amount = 0;
		add(skipSprite);
	}

	function destroySkipUI()
	{
		if (skipSprite == null)
			return;

		remove(skipSprite);
		skipSprite.destroy();
		skipSprite = null;
	}

	// CLEANUP

	function createCover()
	{
		cover = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		cover.scale.set(FlxG.width + 100, FlxG.height + 100);
		cover.screenCenter();
		cover.scrollFactor.set();
		add(cover);
	}

	function cleanupAndDestroy()
	{
		if (alreadyDestroyed)
			return;

		alreadyDestroyed = true;
		state = Destroyed;

		clearCallbacks();
		removeFromState();
		destroyVisuals();

		super.destroy();
	}

	inline function clearCallbacks()
	{
		finishCallback = null;
		onSkip = null;
	}

	function removeFromState()
	{
		if (FlxG.state?.members.contains(this))
			FlxG.state.remove(this);

		if (FlxG.state?.subState?.members.contains(this))
			FlxG.state.subState.remove(this);
	}

	function destroyVisuals()
	{
		if (cover != null)
		{
			remove(cover);
			cover.destroy();
			cover = null;
		}

		destroySkipUI();
	}
}
#end
