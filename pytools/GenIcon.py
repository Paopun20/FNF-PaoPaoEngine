"""
Generate multiple icon sizes from BaseIcon.png
and create a multi-size .ico file.
"""

from PIL import Image
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from typing import List, Final
from rich.console import Console

from RootFile import ROOT_DIR

console = Console()

console.print("[bold green]Generating icons...[/bold green]")

SCRIPT_DIR: Final[Path] = ROOT_DIR / "art" / "icons"
INPUT_IMAGE: Final[Path] = SCRIPT_DIR / "BaseIcon.png"
OUTPUT_DIR: Final[Path] = SCRIPT_DIR / "genIcon"

OUTPUT_DIR.mkdir(exist_ok=True)

# icon sizes want I need
SIZES: List[int] = [16, 24, 32, 40, 64, 96, 128, 196, 256, 512, 768, 1024, 2048, 4096]

def resize_and_save(size: int) -> None:
    """Resize the input image to the specified size and save it as a PNG"""
    with Image.open(INPUT_IMAGE).convert("RGBA") as img:
        resized = img.resize((size, size), Image.Resampling.LANCZOS)

        output_path = OUTPUT_DIR / f"icon{size}.png"
        resized.save(output_path)

        console.print(f"[bold blue]Saved:[/bold blue] {output_path}")

console.print(f"[bold yellow]Resizing images to sizes:[/bold yellow] {SIZES}")

with ThreadPoolExecutor() as executor:
    executor.map(resize_and_save, SIZES)

console.print("[bold green]Creating multi-size .ico file...[/bold green]")

with Image.open(INPUT_IMAGE).convert("RGBA") as img:
    ico_path = OUTPUT_DIR / "icon.ico"

    img.save(
        ico_path,
        format="ICO",
        resample=Image.Resampling.LANCZOS,
        sizes=[(s, s) for s in SIZES]
    )

    console.print(f"[bold blue]Saved:[/bold blue] {ico_path}")

    # Save original PNG
    og_path = OUTPUT_DIR / "iconOG.png"
    img.save(og_path, format="PNG")

    console.print(f"[bold blue]Saved:[/bold blue] {og_path}")
