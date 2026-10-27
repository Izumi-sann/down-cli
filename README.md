# Download
### Termux
``` sh
tmp=$(mktemp) &&
curl -fsSL https://raw.githubusercontent.com/Izumi-sann/down-cli/main/down-cli.sh -o "$tmp" &&
install -m 755 "$tmp" "$PREFIX/bin/down-cli" &&
rm "$tmp"
```

### Windows
execute the following powershell script to download.
Then down-cli can be run from any cli environment
``` PS
$installDir = Join-Path $env:LOCALAPPDATA 'Programs\down-cli'
$gitRoot = 'C:\Program Files\Git'
$bash = Join-Path $gitRoot 'bin\bash.exe'
$cygpath = Join-Path $gitRoot 'usr\bin\cygpath.exe'
$scriptPath = Join-Path $installDir 'down-cli.sh'
$scriptPosix = (& $cygpath -u $scriptPath).Trim()
$cmdContent = @"
@echo off
"$bash" "$scriptPosix" %*
"@
Set-Content -Encoding ASCII (Join-Path $installDir 'down-cli.cmd') $cmdContent
$wrapperPath = Join-Path $installDir 'down-cli'
$wrapperContent = @'
#!/usr/bin/env bash
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$script_dir/down-cli.sh" "$@"
'@
Set-Content -Encoding ASCII $wrapperPath $wrapperContent
$wrapperPosix = (& $cygpath -u $wrapperPath).Trim()
& $bash -c 'chmod +x "$1"' _ $wrapperPosix
```

## Usage  
down-cli [OPTIONS] URL [URL ...]

Options:
  -M, --music                    Extract audio (defaults to mp3)
  -V, --video                    Download video (default)
  -D, --direcctory DIR           Download into DIR (--directory also works)
  -f, --format EXT               Audio format in music mode; container in video mode
  -h, --help                     Show this help

Example

**Music:**
down-cli -M "https://music.youtube.com/watch?v=4b1SS91KkV4&si=-nkK9o3tZrt-2yzN"

**Video:**
down-cli -V -D ./media/videos "https://www.youtube.com/watch?v=SMKiELjUrlI"
