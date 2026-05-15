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

        uniform float uTime0;
        uniform float uTime1;
        uniform float uTime2;
        uniform float uTime3;
        uniform float uTime4;
        uniform float uTime5;

        uniform float uOffsetY0;
        uniform float uOffsetY1;
        uniform float uOffsetY2;
        uniform float uOffsetY3;
        uniform float uOffsetY4;
        uniform float uOffsetY5;

        uniform float uFreq0;
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

        void main()
        {
            float px = openfl_TextureCoordv.x * areaWidth;
            float py = openfl_TextureCoordv.y * areaHeight;

            vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

            for (int i = 0; i < 6; i++)
            {
                float t = 0.0;
                float oy = 0.0;
                float freq = 0.0;
                vec4 col = vec4(1.0);

                if (i == 0)
                {
                    t = uTime0;
                    oy = uOffsetY0;
                    freq = uFreq0;
                    col = uColor0;
                }
                else if (i == 1)
                {
                    t = uTime1;
                    oy = uOffsetY1;
                    freq = uFreq1;
                    col = uColor1;
                }
                else if (i == 2)
                {
                    t = uTime2;
                    oy = uOffsetY2;
                    freq = uFreq2;
                    col = uColor2;
                }
                else if (i == 3)
                {
                    t = uTime3;
                    oy = uOffsetY3;
                    freq = uFreq3;
                    col = uColor3;
                }
                else if (i == 4)
                {
                    t = uTime4;
                    oy = uOffsetY4;
                    freq = uFreq4;
                    col = uColor4;
                }
                else
                {
                    t = uTime5;
                    oy = uOffsetY5;
                    freq = uFreq5;
                    col = uColor5;
                }

                float waveY =
                      oy
                    + sin(px * freq + t) * AMP_A
                    + sin(px * freq * 2.0 + t * 1.5) * AMP_B
                    + sin(px * freq * 0.5 + t * 0.7) * AMP_C;

                if (py >= waveY)
                {
                    color = col;
                }
            }

            gl_FragColor = color;
        }
    ')
    public function new()
    {
        super();
    }
}