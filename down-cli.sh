#!/usr/bin/env bash

set -euo pipefail

mode=video
directory=.
file_format=
urls=()

usage() {
	cat <<'EOF'
Usage: down-cli.sh [OPTIONS] URL [URL ...]

Options:
  -M, --music                    Extract audio (defaults to mp3)
  -V, --video                    Download video (default)
  -D, --direcctory DIR           Download into DIR (--directory also works)
  -f, --format EXT               Audio format in music mode; container in video mode
  -h, --help                     Show this help
EOF
}

error() {
	printf 'Error: %s\n\n' "$1" >&2
	usage >&2
	exit 2
}

while (($#)); do
	case "$1" in
		-M|--music)
			mode=music
			shift
			;;
		-V|--video)
			mode=video
			shift
			;;
		-D|--direcctory|--directory)
			(($# >= 2)) || error "Missing directory after $1"
			directory=$2
			shift 2
			;;
		--direcctory=*|--directory=*)
			directory=${1#*=}
			shift
			;;
		-f|--format|--audio-format)
			(($# >= 2)) || error "Missing format after $1"
			file_format=$2
			shift 2
			;;
		--format=*|--audio-format=*)
			file_format=${1#*=}
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		--)
			shift
			urls+=("$@")
			break
			;;
		-*)
			error "Unknown option: $1"
			;;
		*)
			urls+=("$1")
			shift
			;;
	esac
done

((${#urls[@]} > 0)) || error "Provide at least one URL"

if [[ $mode == music ]]; then
	file_format=${file_format:-mp3}
	case "$file_format" in
		aac|alac|flac|m4a|mp3|opus|vorbis|wav) ;;
		*) error "Unsupported audio extension: $file_format" ;;
	esac
else
	if [[ -n $file_format ]]; then
		case "$file_format" in
			avi|flv|m4v|mkv|mov|mp4|ts|webm) ;;
			*) error "Unsupported video extension: $file_format" ;;
		esac
	fi
fi

command -v yt-dlp >/dev/null 2>&1 || error "yt-dlp is not installed"

if [[ $mode == music || -n $file_format ]]; then
	command -v ffmpeg >/dev/null 2>&1 || error "ffmpeg is required for audio conversion or video remuxing"
fi

mkdir -p -- "$directory" || error "Could not create download directory: $directory"

if [[ $mode == music ]]; then
	exec yt-dlp --extract-audio --audio-format "$file_format" --paths "$directory" -- "${urls[@]}"
elif [[ -n $file_format ]]; then
	exec yt-dlp --remux-video "$file_format" --paths "$directory" -- "${urls[@]}"
else
	exec yt-dlp --paths "$directory" -- "${urls[@]}"
fi