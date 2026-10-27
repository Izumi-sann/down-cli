#!/usr/bin/env bash

set -euo pipefail

mode=video
directory=.
file_format=
urls=()

usage() {
	cat <<'EOF'
Usage: down-cli [OPTIONS] URL [URL ...]

Options:
  -M, --music                    Extract audio (defaults to mp3)
  -V, --video                    Download video (default)
  -D, --direcctory DIR           Download into DIR (--directory also works)
  -f, --format EXT               Audio format in music mode; container in video mode
  -U, --update                   Update down-cli and exit
  -h, --help                     Show this help
EOF
}

error() {
	printf 'Error: %s\n\n' "$1" >&2
	usage >&2
	exit 2
}

update_script() {
	local script_path script_dir temp_path update_url
	update_url='https://raw.githubusercontent.com/Izumi-sann/down-cli/main/down-cli.sh'
	script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || {
		printf 'Error: Could not locate down-cli.\n' >&2
		return 1
	}
	script_path="$script_dir/$(basename -- "${BASH_SOURCE[0]}")"
	temp_path=$(mktemp "${script_path}.XXXXXX") || {
		printf 'Error: Could not create a temporary update file.\n' >&2
		return 1
	}

	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --output "$temp_path" "$update_url" || {
			rm -f -- "$temp_path"
			printf 'Error: Could not download the update.\n' >&2
			return 1
		}
	elif command -v wget >/dev/null 2>&1; then
		wget -q -O "$temp_path" "$update_url" || {
			rm -f -- "$temp_path"
			printf 'Error: Could not download the update.\n' >&2
			return 1
		}
	else
		rm -f -- "$temp_path"
		printf 'Error: Install curl or wget to update down-cli.\n' >&2
		return 1
	fi

	if ! bash -n "$temp_path"; then
		rm -f -- "$temp_path"
		printf 'Error: The downloaded update failed its syntax check.\n' >&2
		return 1
	fi

	chmod +x "$temp_path" && mv -f -- "$temp_path" "$script_path" || {
		rm -f -- "$temp_path"
		printf 'Error: Could not install the update.\n' >&2
		return 1
	}
	printf 'Updated down-cli: %s\n' "$script_path"
}

if (($# == 1)) && [[ $1 == -U || $1 == --update ]]; then
	update_script
	exit $?
fi

while (($#)); do
	case "$1" in
		-U|--update)
			error "Use --update by itself, without other options or URLs"
			;;
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

yt_dlp_options=(
	--quiet
	--progress
	--no-warnings
	--print 'after_move:File location: %(filepath)s'
	--paths "$directory"
)

if [[ $mode == music ]]; then
	exec yt-dlp "${yt_dlp_options[@]}" --extract-audio --audio-format "$file_format" -- "${urls[@]}"
elif [[ -n $file_format ]]; then
	exec yt-dlp "${yt_dlp_options[@]}" --remux-video "$file_format" -- "${urls[@]}"
else
	exec yt-dlp "${yt_dlp_options[@]}" -- "${urls[@]}"
fi