# Mod Tools

CLI-only helpers for PaoPao/FNF mod developers. Run them with uv from the
repository root or from this folder.

## Tools

### VideoOptimizer.py

Optimizes `.mp4`, `.mov`, `.mkv`, `.avi`, and `.webm` files through `ffmpeg`.
Install `ffmpeg` separately and make sure it is available on `PATH`.

```bash
uv run pytools/modTools/VideoOptimizer.py "example_mods/My Mod/videos" --recursive
uv run pytools/modTools/VideoOptimizer.py cutscene.mp4 --format mp4 --crf 28 --max-width 1280
uv run pytools/modTools/VideoOptimizer.py videos --recursive --dry-run
```

## Notes

- `VideoOptimizer.py` requires the external `ffmpeg` command.
