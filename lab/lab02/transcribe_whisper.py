#!/opt/homebrew/Caskroom/miniforge/base/envs/matlab_ai/bin/python3
"""Standalone Whisper transcription helper for MATLAB workflows."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from pathlib import Path

import whisper


DEFAULT_MODEL = "base"
DEFAULT_FFMPEG = "/opt/homebrew/bin/ffmpeg"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Transcribe one WAV file with Whisper and save plain text or JSON output."
    )
    parser.add_argument("audio_file", help="Path to the input audio file.")
    parser.add_argument(
        "--output",
        help="Optional output text file path. Defaults to <audio_file>.txt",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Whisper model name to load. Default: {DEFAULT_MODEL}",
    )
    parser.add_argument(
        "--language",
        default=None,
        help="Optional language hint such as en or zh.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print JSON to stdout instead of plain transcript text.",
    )
    return parser.parse_args()


def ensure_ffmpeg() -> str:
    ffmpeg_path = os.environ.get("FFMPEG_BINARY", DEFAULT_FFMPEG)
    if Path(ffmpeg_path).is_file():
        os.environ["FFMPEG_BINARY"] = ffmpeg_path
        ffmpeg_dir = str(Path(ffmpeg_path).parent)
        os.environ["PATH"] = ffmpeg_dir + os.pathsep + os.environ.get("PATH", "")
        return ffmpeg_path

    discovered = shutil.which("ffmpeg")
    if discovered:
        os.environ["FFMPEG_BINARY"] = discovered
        return discovered

    raise FileNotFoundError(
        f"ffmpeg not found. Checked {ffmpeg_path!r} and current PATH."
    )


def main() -> int:
    args = parse_args()
    audio_path = Path(args.audio_file).expanduser().resolve()
    if not audio_path.is_file():
        print(f"Audio file not found: {audio_path}", file=sys.stderr)
        return 1

    output_path = (
        Path(args.output).expanduser().resolve()
        if args.output
        else audio_path.with_suffix(".txt")
    )

    try:
        ffmpeg_path = ensure_ffmpeg()
        model = whisper.load_model(args.model)
        transcribe_kwargs: dict[str, str] = {}
        if args.language:
            transcribe_kwargs["language"] = args.language
        result = model.transcribe(str(audio_path), **transcribe_kwargs)
    except Exception as exc:
        print(f"Transcription failed: {exc}", file=sys.stderr)
        return 2

    transcript = (result.get("text") or "").strip()
    if not transcript:
        transcript = "Noise detected (no speech)"

    output_path.write_text(transcript + "\n", encoding="utf-8")

    if args.json:
        payload = {
            "audio_file": str(audio_path),
            "output_file": str(output_path),
            "model": args.model,
            "ffmpeg": ffmpeg_path,
            "text": transcript,
        }
        print(json.dumps(payload, ensure_ascii=False))
    else:
        print(transcript)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
