package funkin.frontend.transition;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.helper.StateCapture;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;

class CoolTransition extends BaseTransition
{
    private var currentStateSprite:FlxSprite;
    private var nextStateSprite:FlxSprite;
    private var blackBg:FlxSprite;
    
    private var transitionSprite:FlxSprite;
    
    private var rotationProgress:Float = 0.0;
    private static inline var SWAP_POINT:Float = 0.5;
    
    override function create()
    {
        super.create();
        
        var width:Int = FlxG.width;
        var height:Int = FlxG.height;
        
        blackBg = new FlxSprite().makeGraphic(width, height, FlxColor.BLACK);
        blackBg.scrollFactor.set();
        add(blackBg);
        
        currentStateSprite = StateCapture.captureFrame();
        currentStateSprite.scrollFactor.set();
        add(currentStateSprite);
        
        if (BaseTransition.nextState != null)
            nextStateSprite = StateCapture.captureFrame(BaseTransition.nextState);
        else
            nextStateSprite = new FlxSprite().makeGraphic(width, height, FlxColor.GREEN);
            
        nextStateSprite.scrollFactor.set();
        nextStateSprite.visible = false;
        add(nextStateSprite);

        try {
			transitionSprite = new FlxSprite().loadGraphic(Paths.image('cool_transition'));
		} catch(e:Dynamic) {
			transitionSprite = new FlxSprite().makeGraphic(400, 150, FlxColor.RED);
		}
    }
    
    override private function updateTransition(elapsed:Float):Void
    {
        rotationProgress = getProgress();
        
        var scaleX:Float = 0.0;
        var currentObj:FlxSprite;

        if (rotationProgress < SWAP_POINT) {
            scaleX = Math.abs(Math.cos(rotationProgress * Math.PI)); 
            currentObj = currentStateSprite;
            currentStateSprite.visible = true;
            nextStateSprite.visible = false;
        } else {
            scaleX = Math.abs(Math.cos(rotationProgress * Math.PI));
            currentObj = nextStateSprite;
            currentStateSprite.visible = false;
            nextStateSprite.visible = true;
        }

        currentObj.scale.x = scaleX;
        currentObj.screenCenter();

        transitionSprite.scale.x = scaleX;
        transitionSprite.screenCenter();
        
        var halfWidth = (FlxG.width * scaleX) / 2;
        transitionSprite.x = (FlxG.width / 2) - halfWidth;
        
        var alphaEffect = FlxMath.lerp(1.0, 0.2, 1 - scaleX);
        transitionSprite.alpha = alphaEffect;
    }
}