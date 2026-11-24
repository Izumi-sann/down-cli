#!/usr/bin/env python3
# down-cli for a-Shell (iOS). a-Shell has no real bash, so down-cli.sh can't
# run there — this calls yt-dlp's library entry point in-process instead.
import sys

MUSIC_FORMATS = {"aac", "alac", "flac", "m4a", "mp3", "opus", "vorbis", "wav"}
VIDEO_FORMATS = {"avi", "flv", "m4v", "mkv", "mov", "mp4", "ts", "webm"}

USAGE = """Usage: down-cli-ash.py [OPTIONS] URL [URL ...]

Options:
  -M, --music              Extract audio (defaults to mp3)
  -V, --video              Download video (default)
  -D, --directory DIR      Download into DIR
  -f, --format EXT         Audio format in music mode; container in video mode
  -h, --help                Show this help
"""


def error(msg):
    sys.stderr.write(f"Error: {msg}\n\n{USAGE}")
    raise SystemExit(2)


def main(argv):
    mode = "video"
    directory = "."
    file_format = None
    urls = []

    args = list(argv)
    while args:
        arg = args.pop(0)
        if arg in ("-M", "--music"):
            mode = "music"
        elif arg in ("-V", "--video"):
            mode = "video"
        elif arg in ("-D", "--directory"):
            if not args:
                error(f"Missing directory after {arg}")
            directory = args.pop(0)
        elif arg.startswith("--directory="):
            directory = arg.split("=", 1)[1]
        elif arg in ("-f", "--format"):
            if not args:
                error(f"Missing format after {arg}")
            file_format = args.pop(0)
        elif arg.startswith("--format="):
            file_format = arg.split("=", 1)[1]
        elif arg in ("-h", "--help"):
            print(USAGE)
            return 0
        elif arg == "--":
            urls.extend(args)
            break
        elif arg.startswith("-") and arg != "-":
            error(f"Unknown option: {arg}")
        else:
            urls.append(arg)

    if not urls:
        error("Provide at least one URL")

    if mode == "music":
        file_format = file_format or "mp3"
        if file_format not in MUSIC_FORMATS:
            error(f"Unsupported audio extension: {file_format}")
    elif file_format and file_format not in VIDEO_FORMATS:
        error(f"Unsupported video extension: {file_format}")

    try:
        import yt_dlp
    except ImportError:
        error("yt-dlp is not installed. Run: pip install yt-dlp")

    yt_dlp_args = [
        "--quiet",
        "--progress",
        "--no-warnings",
        "--print", "after_move:File location: %(filepath)s",
        "--paths", directory,
    ]
    if mode == "music":
        yt_dlp_args += ["--extract-audio", "--audio-format", file_format]
    elif file_format:
        yt_dlp_args += ["--remux-video", file_format]
    yt_dlp_args += ["--", *urls]

    return yt_dlp.main(yt_dlp_args)


if __name__ == "__main__":
    main(sys.argv[1:])
