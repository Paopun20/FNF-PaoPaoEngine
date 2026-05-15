package funkin.ds;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.shaders.GeoShader;

class Geodify extends FlxSprite {
	public static final DEFAULT_LAYER_COLORS:Array<FlxColor> = [
		FlxColor.fromRGB(26, 26, 26),
		FlxColor.fromRGB(42, 42, 42),
		FlxColor.fromRGB(58, 58, 58),
		FlxColor.fromRGB(74, 74, 74),
		FlxColor.fromRGB(106, 106, 106),
		FlxColor.fromRGB(255, 255, 255),
	];

	var geo:GeoShader;

	var timers:Array<Float> = [];
	var speeds:Array<Float> = [];

	public function new(x:Float = 0, y:Float = 0, width:Int = 1280, height:Int = 720, widthMult:Float = 1.0, heightMult:Float = 1.0, minSpeed:Float = 0.3,
			maxSpeed:Float = 0.9, ?colors:Array<FlxColor>) {
		super(x, y);

		makeGraphic(width, height, FlxColor.WHITE);

		var layerColors = colors ?? DEFAULT_LAYER_COLORS;

		geo = new GeoShader();

		geo.areaWidth.value = [width];
		geo.areaHeight.value = [height];

		var n = layerColors.length;
		var step = height / n;

		for (i in 0...n) {
			var speed = FlxG.random.float(minSpeed, maxSpeed);

			if (FlxG.random.bool())
				speed = -speed;

			speeds.push(speed);
			timers.push(0.0);

			var offsetY = (step * i) - 5.0;
			var freq = (0.003 + i * 0.001) / widthMult;

			setFloat('uOffsetY$i', offsetY);
			setFloat('uFreq$i', freq);
			setFloat('uTime$i', 0.0);

			var c = layerColors[i];

			setVec4('uColor$i', [c.redFloat, c.greenFloat, c.blueFloat, 1.0]);
		}

		shader = geo;
	}

	public function setLayerColor(layer:Int, color:FlxColor):Void {
		if (layer < 0 || layer >= 6)
			return;

		setVec4('uColor$layer', [color.redFloat, color.greenFloat, color.blueFloat, 1.0]);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (i in 0...speeds.length) {
			timers[i] += elapsed * speeds[i];

			setFloat('uTime$i', timers[i]);
		}
	}

	inline function setFloat(name:String, value:Float):Void {
		Reflect.field(geo.data, name).value = [value];
	}

	inline function setVec4(name:String, value:Array<Float>):Void {
		Reflect.field(geo.data, name).value = value;
	}

	public function recolor(colors:Array<FlxColor>):Void {
		for (i in 0...colors.length) {
			var c = colors[i];

			setVec4('uColor$i', [c.redFloat, c.greenFloat, c.blueFloat, 1.0]);
		}
	}
}
