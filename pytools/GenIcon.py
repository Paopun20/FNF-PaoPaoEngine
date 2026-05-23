from concurrent.futures import ThreadPoolExecutor
from typing import Final

from PIL import Image
from rich.console import Console

from RootFile import ROOT_DIR

console = Console()

console.print("[bold green]Generating icons...[/bold green]")

SCRIPT_DIR: Final = ROOT_DIR / "art" / "icons"
INPUT_IMAGE: Final = SCRIPT_DIR / "BaseIcon.png"
OUTPUT_DIR: Final = SCRIPT_DIR / "genIcon"

OUTPUT_DIR.mkdir(exist_ok=True)

SIZES: Final[list[int]] = sorted(
    {
        *(2**x for x in range(4, 13)),
        24,
        40,
        96,
        196,
    }
)

console.print(f"[bold yellow]Generating sizes:[/bold yellow] {SIZES}")

with Image.open(INPUT_IMAGE) as base_img:
    base_img = base_img.convert("RGBA")

    def resize_and_save(size: int) -> None:
        resized = base_img.resize((size, size), Image.Resampling.LANCZOS)

        output_path = OUTPUT_DIR / f"icon{size}.png"

        resized.save(output_path)

        console.print(f"[bold blue]Saved:[/bold blue] {output_path}")

    with ThreadPoolExecutor() as executor:
        list(executor.map(resize_and_save, SIZES))

    console.print("[bold green]Creating multi-size ICO...[/bold green]")

    ico_path = OUTPUT_DIR / "icon.ico"

    base_img.save(
        ico_path,
        format="ICO",
        sizes=[(s, s) for s in SIZES],
    )

    console.print(f"[bold blue]Saved:[/bold blue] {ico_path}")

    og_path = OUTPUT_DIR / "iconOG.png"

    base_img.save(og_path)

    console.print(f"[bold blue]Saved:[/bold blue] {og_path}")
