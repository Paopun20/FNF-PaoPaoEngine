import numpy as np
from PIL import Image
import math
import sys

W, H = 1024, 576

AMP_A = 40.0
AMP_B = 20.0
AMP_C = 60.0

TIME = int(sys.argv[1]) if len(sys.argv) > 1 else 0

DEFAULT_LAYER_COLORS = [0x714A9A, 0xAD5492, 0xD56985, 0xEC897C, 0xF5AE7D, 0xF4D48E]


def hex_to_rgb(h):
    return ((h >> 16 & 255) / 255.0, (h >> 8 & 255) / 255.0, (h & 255) / 255.0)


colors = [hex_to_rgb(c) for c in DEFAULT_LAYER_COLORS]


def wave_y(px, freq, t, offset_y):
    return (
        offset_y
        + math.sin(px * freq + t) * AMP_A
        + math.sin(px * freq * 2.0 + t * 1.5) * AMP_B
        + math.sin(px * freq * 0.5 + t * 0.7) * AMP_C
    )


times = [0, 1, 2, 3, 4, 5]
offsets = [0, 60, 120, 180, 240, 300]
freqs = [0, 0.01, 0.012, 0.014, 0.016, 0.018]

px = np.arange(W, dtype=np.float32)  # (W,)
py = np.arange(H, dtype=np.float32)  # (H,)

img = np.full((H, W, 3), colors[0], dtype=np.float32)

for i in range(1, 6):
    f, t, o = freqs[i], times[i], offsets[i]
    wx = (
        o
        + np.sin((px + TIME * 20) * f) * AMP_A
        + np.sin((px + TIME * 15) * f * 2.0) * AMP_B
        + np.sin((px + TIME * 10) * f * 0.5) * AMP_C
    )

    mask = py[:, None] >= wx[None, :]  # shape (H, W) — the core trick
    img[mask] = colors[i]

img = (img * 255).astype(np.uint8)
Image.fromarray(img, "RGB").save("geo_shader.png")
