package funkin.helper;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;

/**
 * Helper class for capturing state screenshots
 */
class StateCapture
{
	/**
	 * Captures the current state as a FlxSprite
	 * Call this in the state's create() function after super.create()
	 * @param state The FlxState to capture (defaults to current state)
	 * @return FlxSprite containing the captured frame
	 */
	public static function captureFrame(?state:FlxState):FlxSprite
	{
		if (state == null)
			state = FlxG.state;
		
		var camera = FlxG.camera;
		
		// Create bitmap to hold the capture
		var bitmapData:BitmapData = new BitmapData(
			FlxG.width,
			FlxG.height,
			true,
			0x00000000
		);
		
		// Draw the state to the bitmap
		camera.fill(camera.bgColor.to24Bit(), camera.useBgAlphaBlending, camera.bgColor.alphaFloat);
		state.draw();
		bitmapData.draw(camera.canvas);
		
		// Create sprite from bitmap
		var sprite:FlxSprite = new FlxSprite();
		sprite.loadGraphic(FlxGraphic.fromBitmapData(bitmapData));
		sprite.scrollFactor.set();
		
		return sprite;
	}
	
	
}