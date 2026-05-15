"""
Generate multiple icon sizes from BaseIcon.png
and create a multi-size .ico file.
"""

from PIL import Image
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

SCRIPT_DIR = Path(__file__).parent
INPUT_IMAGE = SCRIPT_DIR / "BaseIcon.png"
OUTPUT_DIR = SCRIPT_DIR / "genIcon"

# Create output folder if missing
OUTPUT_DIR.mkdir(exist_ok=True)

# Recommended icon sizes
SIZES = [16, 24, 32, 40, 64, 96, 128, 196, 256, 512, 768, 1024, 2048, 4096]

def resize_and_save(size: int):
    with Image.open(INPUT_IMAGE).convert("RGBA") as img:
        resized = img.resize((size, size), Image.Resampling.LANCZOS)

        output_path = OUTPUT_DIR / f"icon{size}.png"
        resized.save(output_path)

# Generate PNG icons in parallel
with ThreadPoolExecutor() as executor:
    executor.map(resize_and_save, SIZES)

# Create ICO file
with Image.open(INPUT_IMAGE).convert("RGBA") as img:
    ico_path = OUTPUT_DIR / "icon.ico"

    img.save(
        ico_path,
        format="ICO",
        sizes=[(s, s) for s in SIZES]
    )

    # Save original PNG
    og_path = OUTPUT_DIR / "iconOG.png"
    img.save(og_path, format="PNG")