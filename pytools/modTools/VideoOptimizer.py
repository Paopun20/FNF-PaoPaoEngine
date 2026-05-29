"""Optimize mod video files with ffmpeg.

This tool is intentionally a thin CLI wrapper. It does not ship ffmpeg; install
ffmpeg separately and make sure it is available on PATH.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path

from rich.console import Console


console = Console()
VIDEO_EXTENSIONS = {".mp4", ".mov", ".mkv", ".avi", ".webm"}


def find_video_files(path: Path, recursive: bool) -> list[Path]:
    """Return video files from a file or directory."""
    if path.is_file():
        return [path] if path.suffix.lower() in VIDEO_EXTENSIONS else []

    globber = path.rglob if recursive else path.glob
    return sorted(
        file
        for file in globber("*")
        if file.is_file() and file.suffix.lower() in VIDEO_EXTENSIONS
    )


def build_output_path(source: Path, output: Path | None, extension: str) -> Path:
    """Choose an output path for one optimized video."""
    if output is None:
        return source.with_name(f"{source.stem}_optimized{extension}")

    if output.suffix:
        return output

    output.mkdir(parents=True, exist_ok=True)
    return output / f"{source.stem}_optimized{extension}"


def build_ffmpeg_command(
    source: Path, destination: Path, args: argparse.Namespace
) -> list[str]:
    """Build the ffmpeg command for one file."""
    video_codec = "libvpx-vp9" if args.format == "webm" else "libx264"
    audio_codec = "libopus" if args.format == "webm" else "aac"
    command = [
        "ffmpeg",
        "-hide_banner",
        "-y" if args.overwrite else "-n",
        "-i",
        str(source),
        "-c:v",
        video_codec,
        "-crf",
        str(args.crf),
        "-b:v",
        "0" if args.format == "webm" else args.video_bitrate,
        "-c:a",
        audio_codec,
        "-b:a",
        args.audio_bitrate,
    ]

    filters: list[str] = []
    if args.max_width > 0:
        filters.append(f"scale='min({args.max_width},iw)':-2")
    if args.fps > 0:
        filters.append(f"fps={args.fps}")
    if filters:
        command.extend(["-vf", ",".join(filters)])

    command.append(str(destination))
    return command


def optimize_video(source: Path, destination: Path, args: argparse.Namespace) -> int:
    """Run ffmpeg for one source video."""
    if destination.exists() and not args.overwrite:
        console.print(f"[yellow]skip[/yellow]: {destination} exists (use --overwrite)")
        return 0

    destination.parent.mkdir(parents=True, exist_ok=True)
    command = build_ffmpeg_command(source, destination, args)
    if args.dry_run:
        console.print("[cyan]dry-run[/cyan]:", " ".join(command))
        return 0

    console.print(f"[cyan]optimize[/cyan]: {source} -> {destination}")
    completed = subprocess.run(command, check=False)
    return completed.returncode


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Optimize mod videos for smaller downloads."
    )
    parser.add_argument("input", type=Path, help="Video file or folder to optimize.")
    parser.add_argument("-o", "--output", type=Path, help="Output file or folder.")
    parser.add_argument(
        "-r", "--recursive", action="store_true", help="Scan folders recursively."
    )
    parser.add_argument(
        "--format", choices=("webm", "mp4"), default="webm", help="Output container."
    )
    parser.add_argument(
        "--crf",
        type=int,
        default=32,
        help="Quality value. Lower is better, larger files.",
    )
    parser.add_argument(
        "--max-width",
        type=int,
        default=1280,
        help="Downscale wider videos. Use 0 to disable.",
    )
    parser.add_argument(
        "--fps",
        type=int,
        default=60,
        help="Clamp frame rate. Use 0 to keep source FPS.",
    )
    parser.add_argument("--audio-bitrate", default="128k", help="Audio bitrate.")
    parser.add_argument(
        "--video-bitrate", default="2500k", help="MP4 video bitrate fallback."
    )
    parser.add_argument(
        "--overwrite", action="store_true", help="Overwrite existing optimized files."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print ffmpeg commands without running them.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if shutil.which("ffmpeg") is None:
        console.print("[bold red]error[/bold red]: ffmpeg was not found on PATH")
        return 2

    videos = find_video_files(args.input, args.recursive)
    if not videos:
        console.print("[bold red]error[/bold red]: no video files found")
        return 1

    extension = f".{args.format}"
    failures = 0
    for source in videos:
        destination = build_output_path(source, args.output, extension)
        failures += 1 if optimize_video(source, destination, args) != 0 else 0

    console.print(
        f"[bold green]done[/bold green]: {len(videos) - failures} optimized, {failures} failed"
    )
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
