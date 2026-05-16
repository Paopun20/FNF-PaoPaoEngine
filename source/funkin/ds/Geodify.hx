package funkin.ds;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.shaders.GeoShader;

class Geodify extends FlxSprite {
	public static final DEFAULT_LAYER_COLORS:Array<FlxColor> = [
		0x714A9A,
		0xAD5492,
		0xD56985,
		0xEC897C,
		0xF5AE7D,
		0xF4D48E
	];

	var geoShader:GeoShader;

	var timers:Array<Float> = [];
	var speeds:Array<Float> = [];

	public function new(x:Float = 0, y:Float = 0, width:Int = 1280, height:Int = 720, widthMult:Float = 1.0, heightMult:Float = 1.0, minSpeed:Float = 0.3,
			maxSpeed:Float = 0.9, ?colors:Array<FlxColor>) {
		super(x, y);

		makeGraphic(width, height, FlxColor.TRANSPARENT);

		var layerColors = colors ?? DEFAULT_LAYER_COLORS;

		geoShader = new GeoShader(); // Initialize shader

		geoShader.areaWidth.value = [width];
		geoShader.areaHeight.value = [height];

		var n = layerColors.length;
		var step = height / n;

		for (i in 0...n) {
			var c = layerColors[i]; // Get color for this layer

			geoShader.setColor(i, c); // Set shader color for this layer

			var speed:Float = FlxG.random.float(minSpeed, maxSpeed);

			if (FlxG.random.bool())
				speed = -speed;

			speeds.push(speed);
			timers.push(0.0);

			var offsetY = (step * i) - 5.0;
			var freq = (0.003 + i * 0.001) / widthMult;

			geoShader.setOffsetY(i, offsetY);
			geoShader.setFreq(i, freq);
			geoShader.setTime(i, 0.0);
		}

		shader = geoShader;
	}

	public function setLayerColor(layer:Int, color:FlxColor):Void {
		if (layer < 0 || layer >= 6)
			return;

		geoShader.setColor(layer, color);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (i in 0...speeds.length) {
			timers[i] += elapsed * speeds[i];

			geoShader.setTime(i, timers[i]);
		}
	}
	public function recolor(colors:Array<FlxColor>):Void {
		for (i in 0...colors.length) {
			var c = colors[i];

			geoShader.setColor(i, c);
		}
	}
}
