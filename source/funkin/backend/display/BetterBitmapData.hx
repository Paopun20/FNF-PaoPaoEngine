package funkin.backend.display;

import lime.graphics.Image;
import lime.graphics.cairo.CairoImageSurface;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class BetterBitmapData extends BitmapData
{
	override function __fromImage(image:#if lime Image #else Dynamic #end):Void
	{
		#if lime
		if (image == null || image.buffer == null)
			return;

		this.image = image;
		width = image.width;
		height = image.height;
		rect = new Rectangle(0, 0, image.width, image.height);
		__textureWidth = width;
		__textureHeight = height;

		#if sys
		image.format = BGRA32;
		image.premultiplied = true;
		#end

		readable = true;
		__isValid = true;

		if (FlxG.stage.context3D != null)
			__uploadToGpu();
		#end
	}

	/**
	 * Uploads the current image data to the GPU and releases the CPU-side copy to save memory.
	 * After this call, `this.image` will be null — GPU texture is the sole owner of the data.
	 * See: https://github.com/CodenameCrew/CodenameEngine/blob/main/source/funkin/backend/system/OptimizedBitmapData.hx#L9L46
	 */
	private function __uploadToGpu():Void
	{
		lock();
		getTexture(FlxG.stage.context3D);
		getSurface();
		readable = true;
		// Intentionally release CPU-side image data after GPU upload to free memory.
		image = null;
	}

	override function getSurface():CairoImageSurface
	{
		#if lime
		// See: https://github.com/CodenameCrew/CodenameEngine/blob/main/source/funkin/backend/system/OptimizedBitmapData.hx#L48L61
		return __surface ??= CairoImageSurface.fromImage(image);
		#else
		return null;
		#end
	}

	/**
	 * Loads a BitmapData from a file path, optionally uploading it to the GPU on load.
	 *
	 * @param path          The image file path to load.
	 * @param allowGpuCaching  Whether GPU caching is permitted for this bitmap. Defaults to true.
	 * @return The loaded BitmapData, or null on js/html5 targets (not supported).
	 */
	public static function fromFile(path:String, allowGpuCaching:Bool = true):BitmapData
	{
		var data:BitmapData;
		#if (js && html5)
		data = new BitmapData(0, 0, true, 0);
		#else
		if (ClientPrefs.data.cacheOnGPU)
		{
			data = new BetterBitmapData(0, 0, true, 0);
		}
		else
		{
			data = new BitmapData(0, 0, true, 0);
		}
		#end
		data.__fromFile(path);
		return data;
	}
}
