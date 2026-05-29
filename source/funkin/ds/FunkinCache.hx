package funkin.ds;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import funkin.backend.display.BetterBitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import lime.utils.Assets;
import openfl.media.Sound;
import flixel.system.FlxAssets;
#if MODS_ALLOWED
import funkin.backend.Mods;
#end

@:access(openfl.display.BitmapData)
@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
class FunkinCache {
	/** Assets that must never be evicted from memory, even during a full clear. */
	public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.${funkin.backend.Paths.SOUND_EXT}'];

	/** Assets referenced by the current scene - cleared between screens. */
	public static var localTrackedAssets:Array<String> = [];

	/** All bitmaps currently held in the cache, keyed by resolved path. */
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	/** All sounds currently held in the cache, keyed by resolved path. */
	public static var currentTrackedSounds:Map<String, Sound> = [];

	/** Mark `key` as permanent - it will never be swept by any clear pass. */
	public static function excludeAsset(key:String):Void {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	/**
	 * Remove a single bitmap from the cache if it is not local or excluded.
	 * Runs the GC afterwards for good measure.
	 */
	public static function clearMemoryByName(name:String):Void {
		if (!localTrackedAssets.contains(name) && !dumpExclusions.contains(name)) {
			destroyGraphic(currentTrackedAssets.get(name));
			currentTrackedAssets.remove(name);
		}
		System.gc();
	}

	/**
	 * Sweep every tracked bitmap that is not pinned by `localTrackedAssets`
	 * or `dumpExclusions`.
	 */
	public static function clearUnusedMemory():Void {
		for (key in currentTrackedAssets.keys())
			clearMemoryByName(key);

		#if cpp
		cpp.vm.Gc.run(true);
		#end
	}

	/**
	 * Forcefully clear anything not listed in `currentTrackedAssets` from
	 * Flixel's bitmap front-end, evict all non-local sounds, then reset the
	 * local-asset list so everything is eligible for the next sweep.
	 */
	public static function clearStoredMemory():Void {
		for (key in FlxG.bitmap._cache.keys()) {
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		for (key => asset in currentTrackedSounds) {
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null) {
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		localTrackedAssets = [];
		#if !html5
		openfl.Assets.cache.clear("songs");
		#end
	}

	/**
	 * Walk the current scene graph, collect every `FlxGraphic` actively
	 * displayed, then free every cached graphic that is not protected.
	 *
	 * Sprites still on screen are never evicted, so this is safe to call
	 * mid-session without visual glitches.
	 */
	public static function freeGraphicsFromMemory():Void {
		var protectedGraphics:Array<FlxGraphic> = collectActiveGraphics();

		for (key in currentTrackedAssets.keys()) {
			if (dumpExclusions.contains(key))
				continue;

			var graphic:FlxGraphic = currentTrackedAssets.get(key);
			if (!protectedGraphics.contains(graphic)) {
				destroyGraphic(graphic);
				currentTrackedAssets.remove(key);
			}
		}
	}

	/**
	 * Resolve `key` to a `FlxGraphic`, uploading to the GPU if `allowGPU` is
	 * set and the user's preferences permit it.  Returns `null` on failure.
	 *
	 * Callers should check the cache via `currentTrackedAssets` before calling
	 * this - it will overwrite any existing entry for `key`.
	 */
	public static function cacheBitmap(key:String, ?parentFolder:String, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic {
		if (key == null || key.length == 0) {
			CoolLog.error('FunkinCache.cacheBitmap - invalid key "$key"');
			return null;
		}

		if (bitmap == null)
			bitmap = loadBitmapFromDisk(key, parentFolder);

		if (bitmap == null) {
			CoolLog.error('FunkinCache.cacheBitmap - bitmap not found for key "$key"');
			return null;
		}

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null)
			uploadBitmapToGPU(bitmap);

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graphic.persist = true;
		graphic.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graphic);
		localTrackedAssets.push(key);
		return graphic;
	}

	/** Dispose GPU memory and remove `graphic` from Flixel's bitmap front-end. */
	static function destroyGraphic(graphic:FlxGraphic):Void {
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	/**
	 * Walk `FlxG.state` (and its sub-state if present), collecting every
	 * `FlxGraphic` that is currently referenced by a visible sprite.
	 */
	static function collectActiveGraphics():Array<FlxGraphic> {
		var result:Array<FlxGraphic> = [];

		function walk(spr:Dynamic):Void {
			// Groups expose a `members` array - recurse into them.
			try {
				var members:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if (members != null) {
					for (member in members)
						walk(member);
					return;
				}
			} catch (_) {}

			// Leaf sprites expose a `graphic` field.
			try {
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if (gfx != null)
					result.push(gfx);
			} catch (_) {}
		}

		for (member in FlxG.state.members)
			walk(member);

		if (FlxG.state.subState != null)
			for (member in FlxG.state.subState.members)
				walk(member);

		return result;
	}

	/** Load raw `BitmapData` from the filesystem or the OpenFL asset bundle. */
	static function loadBitmapFromDisk(key:String, ?parentFolder:String):BitmapData {
		var file:String = Paths.getPath(key, IMAGE, parentFolder, true);
		#if MODS_ALLOWED
		if (FileSystem.exists(file))
			return BitmapData.fromFile(file);
		#end
		if (OpenFlAssets.exists(file, IMAGE))
			return OpenFlAssets.getBitmapData(file);
		return null;
	}

	/** Upload `bitmap` to a GPU rectangle texture and discard the CPU copy. */
	@:access(openfl.display.BitmapData)
	static function uploadBitmapToGPU(bitmap:BitmapData):Void {
		bitmap.lock();
		if (bitmap.__texture == null) {
			bitmap.image.premultiplied = true;
			bitmap.getTexture(FlxG.stage.context3D);
		}
		bitmap.getSurface();
		bitmap.disposeImage();
		bitmap.image.data = null;
		bitmap.image = null;
		bitmap.readable = true;
	}
}
