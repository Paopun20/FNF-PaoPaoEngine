package funkin.frontend.transition;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;

/**
 * Gradient fade transition effect
 * Creates a smooth fade using a gradient overlay
 */
class CustomFadeTransition extends BaseTransition
{
	private var transBlack:FlxSprite;
	private var transGradient:FlxSprite;
	
	public function new(duration:Float, isTransIn:Bool)
	{
		super(duration, isTransIn);
	}
	
	override function create()
	{
		super.create();
		
		var width:Int = getScreenWidth();
		var height:Int = getScreenHeight();
		
		// Create gradient sprite
		transGradient = FlxGradient.createGradientFlxSprite(
			1, 
			height, 
			isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]
		);
		transGradient.scale.x = width;
		transGradient.updateHitbox();
		transGradient.scrollFactor.set();
		transGradient.screenCenter(X);
		add(transGradient);
		
		// Create black backdrop
		transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		transBlack.scale.set(width, height + 400);
		transBlack.updateHitbox();
		transBlack.scrollFactor.set();
		transBlack.screenCenter(X);
		add(transBlack);
		
		// Position elements based on transition direction
		if (isTransIn)
			transGradient.y = transBlack.y - transBlack.height;
		else
			transGradient.y = -transGradient.height;
	}
	
	override private function updateTransition(elapsed:Float):Void
	{
		final height:Float = FlxG.height * Math.max(camera.zoom, 0.001);
		final targetPos:Float = transGradient.height + 50 * Math.max(camera.zoom, 0.001);
		
		// Move gradient based on duration
		if (duration > 0)
			transGradient.y += (height + targetPos) * elapsed / duration;
		else
			transGradient.y = (targetPos) * elapsed;
		
		// Update black backdrop position
		if (isTransIn)
			transBlack.y = transGradient.y + transGradient.height;
		else
			transBlack.y = transGradient.y - transBlack.height;
	}
	
	override private function shouldComplete():Bool
	{
		final targetPos:Float = transGradient.height + 50 * Math.max(camera.zoom, 0.001);
		return transGradient.y >= targetPos;
	}
}