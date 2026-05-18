package funkin.shaders;

import flixel.system.FlxAssets.FlxShader;

class GreenScreenRemover extends FlxShader {
	@:glFragmentSource('
    #extension GL_OES_standard_derivatives : enable
    #pragma header
    uniform vec4 uGreenColor;
    uniform float uThreshold;
    void main()
    {
        vec4 color = texture2D(openfl_Texture, openfl_TextureCoordv);
        float dist = distance(color.rgb, uGreenColor.rgb);
        float alpha = smoothstep(uThreshold, uThreshold + 0.08, dist);
        gl_FragColor = vec4(color.rgb, color.a * alpha);
    ')
	public function new() {
		super();
	}

	public function setGreenColor(color:FlxColor) {
		Reflect.field(this, 'uGreenColor').value = [color.redFloat, color.greenFloat, color.blueFloat, 1.0];
	}

	public function setThreshold(threshold:Float) {
		Reflect.field(this, 'uThreshold').value = [threshold];
	}
}
