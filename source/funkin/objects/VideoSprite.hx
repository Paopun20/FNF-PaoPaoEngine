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
using funkin.backend.utils.tools.QolTools;

enum VideoState {
	Idle;
	Loading;
	Playing;
	Skipped;
	Finished;
	Destroyed;
}

typedef VideoSubtitle = {
	var time:Float; // in ms
	var subtitle:String;
}

@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class VideoSprite extends FlxSpriteGroup {
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

	static final SKIP_HOLD_DURATION:Float = 1.0;

	var state:VideoState = Idle;
	var holdingTime:Float = 0;
	#if sys
	final _lock = new Mutex();
	#end
	var alreadyDestroyed:Bool = false;

	public var videoSprite:FlxVideoSprite;

	var skipSprite:FlxPieDial;
	var cover:FlxSprite;
	var subtitleBg:FlxSprite;
	var subtitleText:FlxText;

	public var subtitles:Array<VideoSubtitle> = [];

	var curSubtitle:Int = 0;
	var videoName:String;

	public function new(videoName:String, isWaiting:Bool, allowSkip:Bool = false, shouldLoop:Bool = false) {
		super();

		this.videoName = videoName;
		this.waiting = isWaiting;

		scrollFactor.set();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		if (!waiting)
			createCover();

		parseSubtitles();
		createSubtitleUI();
		createVideo(shouldLoop);

		if (allowSkip)
			enableSkip();
	}

	override function update(elapsed:Float) {
		if (isDestroyed())
			return;

		if (state == Playing) {
			if (canSkip)
				updateSkip(elapsed);

			updateSubtitles();
		}

		if (!isDestroyed())
			super.update(elapsed);
	}

	override function destroy() {
		cleanupAndDestroy();
	}

	inline function isDestroyed():Bool {
		#if sys
		_lock.acquire();
		var d = alreadyDestroyed;
		_lock.release();
		return d;
		#else
		return alreadyDestroyed;
		#end
	}

	inline function acquireDestroyLock():Bool {
		#if sys
		_lock.acquire();
		var won = !alreadyDestroyed;
		if (won) {
			alreadyDestroyed = true;
			state = Destroyed;
		}
		_lock.release();
		return won;
		#else
		if (alreadyDestroyed)
			return false;
		alreadyDestroyed = true;
		state = Destroyed;
		return true;
		#end
	}

	function createVideo(shouldLoop:Bool) {
		videoSprite = new FlxVideoSprite();
		videoSprite.antialiasing = ClientPrefs.data.antialiasing;
		add(videoSprite);

		// Both LibVLC callbacks fire on a native thread — guard every access.
		videoSprite.bitmap.onFormatSetup.add(() -> {
			if (!isDestroyed())
				fitVideoToScreen();
		});

		if (!shouldLoop) {
			videoSprite.bitmap.onEndReached.add(() -> {
				if (!isDestroyed())
					scheduleOnMainThread(() -> endVideo(false));
			});
		}

		state = Loading;

		#if sys
		ThreadUtil.execAsync(function() {
			var loaded = videoSprite.load(videoName, shouldLoop ? ['input-repeat=65545'] : null);

			new flixel.util.FlxTimer().start(0.001, _ -> {
				if (!isDestroyed()) {
					if (loaded)
						onVideoReady();
					else
						endVideo(false);
				}
			});
		});
		#else
		// Synchronous fallback for targets without thread support.
		videoSprite.load(videoName, shouldLoop ? ['input-repeat=65545'] : null);
		onVideoReady();
		#end
	}

	function onVideoReady() {
		if (isDestroyed())
			return;

		#if sys
		_lock.acquire();
		if (!alreadyDestroyed)
			state = Playing;
		_lock.release();
		#else
		state = Playing;
		#end

		videoSprite.play();
	}

	/**
	 * Scales the video to fill the screen, preserving its aspect ratio.
	 * Guarded against a null or uninitialised native bitmap handle.
	 */
	function fitVideoToScreen() {
		#if hxvlc
		// `bitmap` is a native LibVLC object — it can be null if the format
		// callback fires before or after the object is fully initialised.
		if (videoSprite?.bitmap == null)
			return;

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

	function endVideo(skipped:Bool) {
		if (isDestroyed())
			return;

		#if sys
		_lock.acquire();
		if (!alreadyDestroyed)
			state = skipped ? Skipped : Finished;
		_lock.release();
		#else
		state = skipped ? Skipped : Finished;
		#end

		if (skipped && onSkip != null)
			onSkip();

		if (finishCallback != null)
			finishCallback();

		cleanupAndDestroy();
	}

	function parseSubtitles() {
		#if sys
		var srtPath = Paths.subtitles("subtitles/video/" + videoName);

		if (!FileSystem.exists(srtPath))
			return;

		var lines = File.getContent(srtPath).split("\n");

		while (lines.length > 0) {
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
			while (t != null && t.trim() != "") {
				parts.push(t);
				t = lines.shift();
			}
			if (parts.length <= 0)
				continue;

			// Remove any trailing auto-reset entry that would overlap this subtitle.
			var lastSub = subtitles.last();
			if (lastSub != null && lastSub.subtitle == "" && lastSub.time >= beginTime)
				subtitles.pop();

			subtitles.push({subtitle: parts.join(""), time: beginTime * 1000});
			subtitles.push({subtitle: "", time: endTime * 1000});
		}
		#end
	}

	static function splitTime(str:String):Float {
		if (str == null || str.trim() == "")
			return -1;

		// Supports both H:M:S,ms and M:S,ms formats.
		var multipliers:Array<Float> = [1, 60, 3600, 86400];
		var parts:Array<Null<Float>> = [for (e in str.split(":")) Std.parseFloat(e.replace(",", "."))];
		var time:Float = 0;

		for (k => v in parts) {
			var mul = multipliers[parts.length - 1 - k];
			if (v != null)
				time += v * mul;
		}
		return time;
	}

	function createSubtitleUI() {
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

	function updateSubtitles() {
		if (subtitles.length == 0 || curSubtitle >= subtitles.length)
			return;

		#if hxvlc
		// `bitmap` may be null if the LibVLC media object was torn down
		// before this update tick fires (e.g., during end-of-stream cleanup).
		if (videoSprite?.bitmap == null)
			return;

		@:privateAccess
		var rawTime:Int64 = videoSprite.bitmap.time;
		var timeMs:Float = FPHelper.i64ToDouble(rawTime.low, rawTime.high);

		while (curSubtitle < subtitles.length && subtitles[curSubtitle].time < timeMs) {
			setSubtitle(subtitles[curSubtitle]);
			curSubtitle++;
		}
		#end
	}

	function setSubtitle(sub:VideoSubtitle) {
		if (subtitleBg == null || subtitleText == null)
			return;

		var hasText = sub.subtitle.length > 0;
		subtitleBg.visible = subtitleText.visible = hasText;

		if (hasText) {
			subtitleText.text = sub.subtitle;
			subtitleText.screenCenter(X);
			subtitleBg.scale.set(subtitleText.width + 8, subtitleText.height + 8);
			subtitleBg.updateHitbox();
			subtitleBg.setPosition(subtitleText.x - 4, subtitleText.y - 4);
		}
	}

	function updateSkip(elapsed:Float) {
		if (Controls.instance.pressed('accept'))
			increaseHold(elapsed);
		else
			decreaseHold(elapsed);

		updateSkipUI();

		if (holdingTime >= SKIP_HOLD_DURATION)
			endVideo(true);
	}

	inline function increaseHold(elapsed:Float) {
		holdingTime = Math.min(SKIP_HOLD_DURATION, holdingTime + elapsed);
	}

	inline function decreaseHold(elapsed:Float) {
		holdingTime = Math.max(0, holdingTime - elapsed * 3);
	}

	function updateSkipUI() {
		if (skipSprite == null)
			return;

		skipSprite.amount = holdingTime / SKIP_HOLD_DURATION;
		skipSprite.alpha = FlxMath.remapToRange(skipSprite.amount, 0.05, 1, 0, 1);
	}

	public function enableSkip() {
		if (canSkip)
			return;

		canSkip = true;
		createSkipUI();
	}

	public function disableSkip() {
		if (!canSkip)
			return;

		canSkip = false;
		destroySkipUI();
	}

	function createSkipUI() {
		skipSprite = new FlxPieDial(0, 0, 40, FlxColor.WHITE, 40, true, 24);
		skipSprite.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);

		skipSprite.x = FlxG.width - (skipSprite.width + 80);
		skipSprite.y = FlxG.height - (skipSprite.height + 72);

		skipSprite.amount = 0;
		add(skipSprite);
	}

	function destroySkipUI() {
		if (skipSprite == null)
			return;

		remove(skipSprite);
		skipSprite.destroy();
		skipSprite = null;
	}

	function createCover() {
		cover = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		cover.scale.set(FlxG.width + 100, FlxG.height + 100);
		cover.screenCenter();
		cover.scrollFactor.set();
		add(cover);
	}

	function cleanupAndDestroy() {
		// `acquireDestroyLock` is atomic: only the first caller proceeds.
		// Every subsequent call — from any thread — returns false and exits.
		if (!acquireDestroyLock())
			return;

		clearCallbacks();
		removeFromState();
		destroyVisuals();

		super.destroy();
		System.gc();
	}

	inline function clearCallbacks() {
		finishCallback = null;
		onSkip = null;
	}

	function removeFromState() {
		if (FlxG.state?.members.contains(this))
			FlxG.state.remove(this);

		if (FlxG.state?.subState?.members.contains(this))
			FlxG.state.subState.remove(this);
	}

	function destroyVisuals() {
		if (cover != null) {
			remove(cover);
			cover.destroy();
			cover = null;
		}

		if (subtitleBg != null) {
			remove(subtitleBg);
			subtitleBg.destroy();
			subtitleBg = null;
		}

		if (subtitleText != null) {
			remove(subtitleText);
			subtitleText.destroy();
			subtitleText = null;
		}

		destroySkipUI();
	}

	static inline function scheduleOnMainThread(fn:Void->Void) {
		new flixel.util.FlxTimer().start(0.001, _ -> fn());
	}
}
#end
