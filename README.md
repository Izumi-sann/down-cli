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
$ErrorActionPreference = 'Stop'
$installDir = Join-Path $env:LOCALAPPDATA 'Programs\down-cli'
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
$gitPath = (Get-Command git.exe -ErrorAction Stop).Source
$gitRoot = Split-Path (Split-Path $gitPath -Parent) -Parent
$bash = Join-Path $gitRoot 'bin\bash.exe'
$cygpath = Join-Path $gitRoot 'usr\bin\cygpath.exe'
if (-not (Test-Path $bash)) {
    throw "Git Bash non trovato: $bash"
}
$scriptPath = Join-Path $installDir 'down-cli.sh'
Invoke-WebRequest `
    -Uri 'https://raw.githubusercontent.com/Izumi-sann/down-cli/main/down-cli.sh' `
    -OutFile $scriptPath
$scriptPosix = (& $cygpath -u $scriptPath).Trim()
$cmdContent = "@echo off`r`n`"$bash`" `"$scriptPosix`" %*"
Set-Content -Encoding ASCII -Path (Join-Path $installDir 'down-cli.cmd') -Value $cmdContent
$wrapperContent = @'
#!/usr/bin/env bash
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$script_dir/down-cli.sh" "$@"
'@
$wrapperPath = Join-Path $installDir 'down-cli'
Set-Content -Encoding ASCII -Path $wrapperPath -Value $wrapperContent
$wrapperPosix = (& $cygpath -u $wrapperPath).Trim()
& $bash -c 'chmod +x "$1"' _ $wrapperPosix
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathEntries = @($userPath -split ';' | Where-Object { $_ })
if ($pathEntries -notcontains $installDir) {
    $pathEntries += $installDir
    [Environment]::SetEnvironmentVariable('Path', ($pathEntries -join ';'), 'User')
}
if (($env:Path -split ';') -notcontains $installDir) {
    $env:Path = "$installDir;$env:Path"
}
Get-Command down-cli
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
