package funkin.shaders;

import flixel.system.FlxAssets.FlxShader;

/*
Rawdogging Shader lol
*/
class GeoShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header

        const float AMP_A = 40.0;
        const float AMP_B = 20.0;
        const float AMP_C = 60.0;

        uniform float areaWidth;
        uniform float areaHeight;

        uniform float uTime0; // be dummy variable
        uniform float uTime1;
        uniform float uTime2;
        uniform float uTime3;
        uniform float uTime4;
        uniform float uTime5;

        uniform float uOffsetY0; // be dummy variable
        uniform float uOffsetY1;
        uniform float uOffsetY2;
        uniform float uOffsetY3;
        uniform float uOffsetY4;
        uniform float uOffsetY5;

        uniform float uFreq0; // be dummy variable
        uniform float uFreq1;
        uniform float uFreq2;
        uniform float uFreq3;
        uniform float uFreq4;
        uniform float uFreq5;

        uniform vec4 uColor0;
        uniform vec4 uColor1;
        uniform vec4 uColor2;
        uniform vec4 uColor3;
        uniform vec4 uColor4;
        uniform vec4 uColor5;

        float waveY(float px, float freq, float t, float offsetY)
        {
            return offsetY
                + sin(px * freq + t) * AMP_A
                + sin(px * freq * 2.0 + t * 1.5) * AMP_B
                + sin(px * freq * 0.5 + t * 0.7) * AMP_C;
        }

        void main()
        {
            float px = openfl_TextureCoordv.x * areaWidth;
            float py = openfl_TextureCoordv.y * areaHeight;

            vec4 color = uColor0;

            if (py >= waveY(px, uFreq1, uTime1, uOffsetY1)) color = uColor1;
            if (py >= waveY(px, uFreq2, uTime2, uOffsetY2)) color = uColor2;
            if (py >= waveY(px, uFreq3, uTime3, uOffsetY3)) color = uColor3;
            if (py >= waveY(px, uFreq4, uTime4, uOffsetY4)) color = uColor4;
            if (py >= waveY(px, uFreq5, uTime5, uOffsetY5)) color = uColor5;

            gl_FragColor = color;
        }
    ')
    public function new()
    {
        super();
    }
}