package funkin.objects;

import funkin.backend.utils.ThreadUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxPieDial;
import openfl.system.System;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.Int64;
import haxe.io.FPHelper;
import haxe.io.Path;
#if sys
import sys.io.File;
import sys.FileSystem;
import sys.thread.Mutex;
#end
#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end

#if VIDEOS_ALLOWED
using PPQolTools;

enum VideoState
{
	Idle;
	Loading;
	Playing;
	Skipped;
	Finished;
	Destroyed;
}

typedef VideoSubtitle =
{
	var time:Float; // in ms
	var subtitle:String;
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

	// Loading UI
	var loadingBackdrop:FlxBackdrop;
	var loadingText:FlxText;

	// Subtitles
	var subtitleBg:FlxSprite;
	var subtitleText:FlxText;

	public var subtitles:Array<VideoSubtitle> = [];

	var curSubtitle:Int = 0;

	// Internal
	var videoName:String;
	var alreadyDestroyed:Bool = false;
	#if sys
	final mutex = new Mutex();
	#end

	public function new(videoName:String, isWaiting:Bool, allowSkip:Bool = false, shouldLoop:Bool = false)
	{
		super();

		this.videoName = videoName;
		this.waiting = isWaiting;

		scrollFactor.set();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		if (!waiting)
			createCover();

		createLoadingUI();
		parseSubtitles();
		createSubtitleUI();
		createVideo(shouldLoop);

		if (allowSkip)
			enableSkip();
	}

	override function update(elapsed:Float)
	{
		if (alreadyDestroyed || state == Destroyed)
			return;

		if (state == Playing)
		{
			if (canSkip)
				updateSkip(elapsed);

			updateSubtitles();
		}

		// Only drive child updates while the group is still intact
		if (!alreadyDestroyed && state != Destroyed)
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

		state = Loading;

		#if sys
		ThreadUtil.execAsync(function()
		{
			if (videoSprite.load(videoName, shouldLoop ? ['input-repeat=65545'] : null))
				new flixel.util.FlxTimer().start(0.001, _ ->
				{
					mutex.acquire();
					onVideoReady(); // already guarded now
					mutex.release();
				});
			else
			{
				new flixel.util.FlxTimer().start(0.001, _ ->
				{
					mutex.acquire();
					if (!alreadyDestroyed)
						endVideo(false);
					mutex.release();
				});
			}
		});
		#else
		// No async support — load blocking and proceed immediately
		videoSprite.load(videoName, shouldLoop ? ['input-repeat=65545'] : null);
		onVideoReady();
		#end
	}

	function onVideoReady()
	{
		if (alreadyDestroyed || state == Destroyed) // <-- add this guard
			return;

		if (loadingBackdrop != null)
		{
			FlxTween.cancelTweensOf(loadingBackdrop);
			FlxTween.tween(loadingBackdrop, {alpha: 0}, 0.7, {
				ease: FlxEase.sineInOut,
				onComplete: function(_)
				{
					loadingBackdrop?.destroy();
					loadingText?.destroy();
					loadingBackdrop = null;
					loadingText = null;
				}
			});
		}

		state = Playing;
		videoSprite.play();
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

		if (skipped && onSkip != null)
			onSkip();

		if (finishCallback != null)
			finishCallback();

		cleanupAndDestroy();
	}

	// LOADING UI

	function createLoadingUI()
	{
		loadingText = new FlxText(10, 10, Std.int(FlxG.width / 2), "Loading video...", 16);
		loadingText.scrollFactor.set();
		loadingText.visible = false;
		@:privateAccess
		loadingText.regenGraphic();
		add(loadingText);

		loadingBackdrop = new FlxBackdrop(loadingText.graphic, X);
		loadingBackdrop.y = FlxG.height - 20 - loadingBackdrop.height;
		loadingBackdrop.velocity.x = 70;
		loadingBackdrop.scrollFactor.set();
		loadingBackdrop.alpha = 0;
		add(loadingBackdrop);

		FlxTween.tween(loadingBackdrop, {alpha: 1}, 0.5, {ease: FlxEase.sineInOut});
	}

	// SUBTITLE LOGIC

	function parseSubtitles()
	{
		#if sys
		var srtPath = Paths.subtitles("subtitles/video/" + videoName);

		if (!FileSystem.exists(srtPath))
			return;

		var lines = File.getContent(srtPath).split("\n");

		while (lines.length > 0)
		{
			var head = lines.shift();
			if (head == null || head.trim() == "")
				continue;
			if (Std.parseInt(head) == null)
				continue;

			var timeLine = lines.shift();
			if (timeLine == null)
				continue;

			var arrowIndex = timeLine.indexOf('-->');
			if (arrowIndex < 0)
				continue;

			var beginTime = splitTime(timeLine.substr(0, arrowIndex).trim());
			var endTime = splitTime(timeLine.substr(arrowIndex + 3).trim());
			if (beginTime < 0 || endTime < 0)
				continue;

			var parts:Array<String> = [];
			var t = lines.shift();
			while (t != null && t.trim() != "")
			{
				parts.push(t);
				t = lines.shift();
			}
			if (parts.length <= 0)
				continue;

			// Remove the auto-reset entry that would overlap this one
			var lastSub = subtitles.last();
			if (lastSub != null && lastSub.subtitle == "" && lastSub.time >= beginTime)
				subtitles.pop();

			subtitles.push({subtitle: parts.join(""), time: beginTime * 1000});
			subtitles.push({subtitle: "", time: endTime * 1000});
		}
		#end
	}

	static function splitTime(str:String):Float
	{
		if (str == null || str.trim() == "")
			return -1;

		// Supports H:M:S,ms and M:S,ms formats
		var multipliers:Array<Float> = [1, 60, 3600, 86400];
		var parts:Array<Null<Float>> = [for (e in str.split(":")) Std.parseFloat(e.replace(",", "."))];
		var time:Float = 0;

		for (k => v in parts)
		{
			var mul = multipliers[parts.length - 1 - k];
			if (v != null)
				time += v * mul;
		}
		return time;
	}

	function createSubtitleUI()
	{
		subtitleBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		subtitleBg.alpha = 0.5;
		subtitleBg.visible = false;
		subtitleBg.scrollFactor.set();

		subtitleText = new FlxText(0, FlxG.height * 0.875, FlxG.width, "", 20);
		subtitleText.alignment = CENTER;
		subtitleText.visible = false;
		subtitleText.scrollFactor.set();

		add(subtitleBg);
		add(subtitleText);
	}

	function updateSubtitles()
	{
		if (subtitles.length == 0 || curSubtitle >= subtitles.length)
			return;

		#if hxvlc
		@:privateAccess
		var rawTime:Int64 = videoSprite.bitmap.time;
		var timeMs:Float = FPHelper.i64ToDouble(rawTime.low, rawTime.high);

		while (curSubtitle < subtitles.length && subtitles[curSubtitle].time < timeMs)
		{
			setSubtitle(subtitles[curSubtitle]);
			curSubtitle++;
		}
		#end
	}

	function setSubtitle(sub:VideoSubtitle)
	{
		if (subtitleBg == null || subtitleText == null)
			return;

		var hasText = sub.subtitle.length > 0;
		subtitleBg.visible = subtitleText.visible = hasText;

		if (hasText)
		{
			subtitleText.text = sub.subtitle;
			subtitleText.screenCenter(X);
			subtitleBg.scale.set(subtitleText.width + 8, subtitleText.height + 8);
			subtitleBg.updateHitbox();
			subtitleBg.setPosition(subtitleText.x - 4, subtitleText.y - 4);
		}
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
		System.gc();
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

		// loadingBackdrop
		if (loadingBackdrop != null)
		{
			FlxTween.cancelTweensOf(loadingBackdrop); // cancel first
			remove(loadingBackdrop);
			loadingBackdrop.destroy();
			loadingBackdrop = null;
		}

		// loadingText
		if (loadingText != null)
		{
			remove(loadingText);
			loadingText.destroy();
			loadingText = null;
		}

		if (subtitleBg != null)
		{
			remove(subtitleBg);
			subtitleBg.destroy();
			subtitleBg = null;
		}

		if (subtitleText != null)
		{
			remove(subtitleText);
			subtitleText.destroy();
			subtitleText = null;
		}

		destroySkipUI();
	}
}
#end
