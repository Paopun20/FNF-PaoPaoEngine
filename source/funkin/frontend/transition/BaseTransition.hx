package funkin.frontend.transition;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxColor;

/**
 * Base class for screen transitions in Funkin'
 * Provides common functionality and structure for all transition types
 */
class BaseTransition extends MusicBeatSubstate {
	/**
	 * Callback function executed when transition completes
	 */
	public static var finishCallback:Void->Void;

	/**
	 * Reference to the next state for transitions that need it
	 */
	public static var nextState:FlxState;

	/**
	 * Whether this is a transition in (true) or transition out (false)
	 */
	public var isTransIn:Bool = false;

	/**
	 * Duration of the transition in seconds
	 */
	public var duration:Float;

	/**
	 * Whether the transition has completed
	 */
	private var isComplete:Bool = false;

	/**
	 * Elapsed time since transition started
	 */
	private var elapsedTime:Float = 0;

	/**
	 * Creates a new base transition
	 * @param duration Length of transition in seconds
	 * @param isTransIn Whether transitioning in (true) or out (false)
	 */
	public function new(duration:Float = 0.5, isTransIn:Bool = false) {
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create() {
		// Use the topmost camera for transitions
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!isComplete) {
			elapsedTime += elapsed;
			updateTransition(elapsed);

			if (shouldComplete()) {
				completeTransition();
			}
		}
	}

	/**
	 * Override this to implement custom transition logic
	 * Called every frame until transition completes
	 * @param elapsed Time since last frame
	 */
	private function updateTransition(elapsed:Float):Void {
		// To be overridden by child classes
	}

	/**
	 * Override this to define completion condition
	 * @return Whether the transition should complete
	 */
	private function shouldComplete():Bool {
		return elapsedTime >= duration;
	}

	/**
	 * Called when transition completes
	 * Can be overridden for cleanup or final effects
	 */
	private function completeTransition():Void {
		isComplete = true;
		close();
	}

	/**
	 * Gets the width of the screen accounting for camera zoom
	 * @return Screen width in pixels
	 */
	private function getScreenWidth():Int {
		return Std.int(FlxG.width / Math.max(camera.zoom, 0.001));
	}

	/**
	 * Gets the height of the screen accounting for camera zoom
	 * @return Screen height in pixels
	 */
	private function getScreenHeight():Int {
		return Std.int(FlxG.height / Math.max(camera.zoom, 0.001));
	}

	/**
	 * Gets the progress of the transition (0.0 to 1.0)
	 * @return Normalized progress value
	 */
	private function getProgress():Float {
		if (duration <= 0)
			return 1.0;
		return Math.min(elapsedTime / duration, 1.0);
	}

	/**
	 * Finalizes and closes the transition
	 * Executes the finish callback if set
	 */
	override function close():Void {
		super.close();

		if (finishCallback != null) {
			finishCallback();
			finishCallback = null;
		}
	}
}
