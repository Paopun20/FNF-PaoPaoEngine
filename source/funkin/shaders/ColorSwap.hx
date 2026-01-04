package funkin.shaders;

import flixel.system.FlxAssets.FlxShader;

class ColorSwap
{
	public var shader(default, null):ColorSwapShader = new ColorSwapShader();
	public var hue(default, set):Float = 0;
	public var saturation(default, set):Float = 0;
	public var brightness(default, set):Float = 0;

	private function set_hue(value:Float)
	{
		shader.uTime.value[0] = hue = value;
		return value;
	}

	private function set_saturation(value:Float)
	{
		shader.uTime.value[1] = saturation = value;
		return value;
	}

	private function set_brightness(value:Float)
	{
		shader.uTime.value[2] = brightness = value;
		return value;
	}

	public function new()
	{
		shader.uTime.value = [0, 0, 0];
		shader.awesomeOutline.value = [false];
	}
}

class ColorSwapShader extends FlxShader
{
	@:glFragmentSource('
		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;
		uniform sampler2D bitmap;
		uniform bool hasTransform;
		uniform bool hasColorTransform;

		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) {
			vec4 color = texture2D(bitmap, coord);
			if (!hasTransform || color.a == 0.0) return vec4(0.0);
			if (!hasColorTransform) return color * openfl_Alphav;

			color.rgb /= color.a;
			color = clamp(openfl_ColorOffsetv + color * mat4(
				openfl_ColorMultiplierv.x, 0, 0, 0,
				0, openfl_ColorMultiplierv.y, 0, 0,
				0, 0, openfl_ColorMultiplierv.z, 0,
				0, 0, 0, openfl_ColorMultiplierv.w
			), 0.0, 1.0);

			return color.a > 0.0 ? vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav) : vec4(0.0);
		}

		uniform vec3 uTime;
		uniform bool awesomeOutline;

		vec3 rgb2hsv(vec3 c) {
			vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
			vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
			vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
			float d = q.x - min(q.w, q.y);
			return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1.0e-10)), d / (q.x + 1.0e-10), q.x);
		}

		vec3 hsv2rgb(vec3 c) {
			vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
			return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
		}

		void main() {
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
			vec3 hsv = rgb2hsv(color.rgb);
			
			hsv.x += uTime.x;
			hsv.y = clamp(hsv.y + uTime.y, 0.0, 1.0);
			hsv.z *= 1.0 + uTime.z;
			
			color.rgb = hsv2rgb(hsv);

			if (awesomeOutline && color.a <= 0.5) {
				vec2 offset = vec2(3.0) / openfl_TextureSize;
				if (flixel_texture2D(bitmap, openfl_TextureCoordv + vec2(offset.x, 0)).a > 0.0 ||
					flixel_texture2D(bitmap, openfl_TextureCoordv - vec2(offset.x, 0)).a > 0.0 ||
					flixel_texture2D(bitmap, openfl_TextureCoordv + vec2(0, offset.y)).a > 0.0 ||
					flixel_texture2D(bitmap, openfl_TextureCoordv - vec2(0, offset.y)).a > 0.0)
					color = vec4(1.0);
			}
			
			gl_FragColor = color;
		}')
	@:glVertexSource('
		attribute float openfl_Alpha;
		attribute vec4 openfl_ColorMultiplier;
		attribute vec4 openfl_ColorOffset;
		attribute vec4 openfl_Position;
		attribute vec2 openfl_TextureCoord;

		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform mat4 openfl_Matrix;
		uniform bool openfl_HasColorTransform;
		uniform bool hasColorTransform;

		attribute float alpha;
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		
		void main() {
			openfl_Alphav = openfl_Alpha * alpha;
			openfl_TextureCoordv = openfl_TextureCoord;

			if (openfl_HasColorTransform) {
				openfl_ColorMultiplierv = openfl_ColorMultiplier;
				openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
			}

			if (hasColorTransform) {
				openfl_ColorOffsetv = colorOffset / 255.0;
				openfl_ColorMultiplierv = colorMultiplier;
			}

			gl_Position = openfl_Matrix * openfl_Position;
		}')
	public function new()
	{
		super();
	}
}
