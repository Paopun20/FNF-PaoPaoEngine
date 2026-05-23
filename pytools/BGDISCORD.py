import moderngl
import numpy as np
from PIL import Image

WIDTH = 680
HEIGHT = 240

ctx = moderngl.create_standalone_context()

prog = ctx.program(
    vertex_shader="""
        #version 330

        in vec2 in_vert;
        out vec2 uv;

        void main() {
            uv = (in_vert + 1.0) * 0.5;
            gl_Position = vec4(in_vert, 0.0, 1.0);
        }
    """,
    fragment_shader="""
        #version 330

        in vec2 uv;
        out vec4 fragColor;

        const float AMP_A = 40.0;  // was 40
        const float AMP_B = 20.0;  // was 20
        const float AMP_C = 60.0;  // was 60

        uniform float areaWidth;
        uniform float areaHeight;

        uniform float uTime1;
        uniform float uTime2;
        uniform float uTime3;
        uniform float uTime4;
        uniform float uTime5;

        uniform float uOffsetY1;
        uniform float uOffsetY2;
        uniform float uOffsetY3;
        uniform float uOffsetY4;
        uniform float uOffsetY5;

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
            float px = uv.x * areaWidth;
            float py = uv.y * areaHeight;
            vec4 color = uColor5;

            if (py < waveY(px, uFreq5, uTime5, uOffsetY5)) color = uColor4;
            if (py < waveY(px, uFreq4, uTime4, uOffsetY4)) color = uColor3;
            if (py < waveY(px, uFreq3, uTime3, uOffsetY3)) color = uColor2;
            if (py < waveY(px, uFreq2, uTime2, uOffsetY2)) color = uColor1;
            if (py < waveY(px, uFreq1, uTime1, uOffsetY1)) color = uColor0;

            fragColor = color;
        }
    """,
)

quad = np.array(
    [-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, 1.0],
    dtype="f4",
)

vbo = ctx.buffer(quad.tobytes())
vao = ctx.simple_vertex_array(prog, vbo, "in_vert")

fbo = ctx.simple_framebuffer((WIDTH, HEIGHT))
fbo.use()

prog["areaWidth"].value = float(WIDTH)
prog["areaHeight"].value = float(HEIGHT)

hex_colors = [0x714A9A, 0xAD5492, 0xD56985, 0xEC897C, 0xF5AE7D, 0xF4D48E]

for i, h in enumerate(hex_colors):
    r = ((h >> 16) & 0xFF) / 255.0
    g = ((h >> 8) & 0xFF) / 255.0
    b = ((h >> 0) & 0xFF) / 255.0
    prog[f"uColor{i}"].value = (r, g, b, 1.0)

# Vertical band positions (pixels from top)
section = HEIGHT / 6
for i in range(1, 6):
    prog[f"uOffsetY{i}"].value = section * i

# Frequencies and time offsets
times = [0.0, 2, 1.0, 4, 2.0]
import random
def map_range(x, old_min, old_max, new_min, new_max):
    return ((x - old_min) / (old_max - old_min)) * (new_max - new_min) + new_min

for i, t in enumerate(times, start=1):
    prog[f"uFreq{i}"].value = 0.01 + i * 0.001
    prog[f"uTime{i}"].value = map_range(random.random(), 0, 1, -5, 5)

ctx.clear(0.0, 0.0, 0.0, 1.0)
vao.render(moderngl.TRIANGLE_STRIP)

data = fbo.read(components=3)
img = Image.frombytes("RGB", (WIDTH, HEIGHT), data)
img = img.transpose(Image.FLIP_TOP_BOTTOM)
img.save("geo_shader.png")
print("Saved geo_shader.png")
