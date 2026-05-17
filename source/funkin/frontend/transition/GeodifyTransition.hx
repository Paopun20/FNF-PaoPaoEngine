package funkin.frontend.transition;

import funkin.ds.Geodify;

/**
 * Geometry Dash inspired transition
 * Uses shader layer offsets instead of moving the sprite itself
 */
class GeodifyTransition extends BaseTransition {
	private var geodify:Geodify;

	/**
	 * Original Y offsets for each layer
	 */
	private var layerOffsets:Array<Float> = [];

	public function new(duration:Float = 0.6, isTransIn:Bool = false) {
		super(duration, isTransIn);
	}

	override function create() {
		super.create();

		var width:Int = getScreenWidth();
		var height:Int = getScreenHeight();

		geodify = new Geodify(0, 0, width, height);
		geodify.scrollFactor.set();

		add(geodify);

		var layerCount = Geodify.DEFAULT_LAYER_COLORS.length;
		var step:Float = height / layerCount;

		for (i in 0...layerCount) {
			layerOffsets.push((step * i) - 5.0);
		}

		// Apply initial state immediately
		updateTransition(0);
	}

	override private function updateTransition(elapsed:Float):Void {
		var progress = getProgress();
		var height = getScreenHeight();

		for (i in 0...layerOffsets.length) {
			var baseOffset = layerOffsets[i];

			var y:Float;

			if (isTransIn) {
				// full -> down
				y = lerp(baseOffset, height + baseOffset, progress);
			} else {
				// down -> full
				y = lerp(height + baseOffset, baseOffset, progress);
			}

			@:privateAccess {
				// Move layer vertically
				geodify.geoShader.setOffsetY(i, y);

				// Animate wave movement
				geodify.geoShader.setTime(i, (elapsedTime * 2.0) + (i * 0.3));
			}
		}
	}

	override private function shouldComplete():Bool {
		return elapsedTime >= duration;
	}

	private inline function lerp(a:Float, b:Float, t:Float):Float {
		return a + (b - a) * t;
	}
}