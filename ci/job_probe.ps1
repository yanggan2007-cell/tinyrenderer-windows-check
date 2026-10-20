# Which cmake / ninja does a Developer PowerShell use on a machine WITHOUT a separately installed CMake?
. "$PSScriptRoot\common.ps1"
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$VS = & $vswhere -latest -products * -property installationPath
$probe = @"
`$ErrorActionPreference = 'Continue'
`$keep = ([Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')).Split(';') | Where-Object { `$_ -and (`$_ -notmatch 'CMake|Chocolatey|ninja|LLVM') }
`$env:PATH = (`$keep -join ';')
"before Enter-VsDevShell: cmake found = " + [bool](Get-Command cmake -ErrorAction SilentlyContinue)
Import-Module '$VS\Common7\Tools\Microsoft.VisualStudio.DevShell.dll'
Enter-VsDevShell -VsInstallPath '$VS' -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64' | Out-Null
"after:  cmake = " + (Get-Command cmake -ErrorAction SilentlyContinue).Source
"after:  ninja = " + (Get-Command ninja -ErrorAction SilentlyContinue).Source
"after:  cl    = " + (Get-Command cl -ErrorAction SilentlyContinue).Source
"after:  clang-cl = " + (Get-Command clang-cl -ErrorAction SilentlyContinue).Source
"cmake --version: " + ((cmake --version) | Select-Object -First 1)
"PATH entries mentioning CMake / Ninja / Llvm, in order:"
`$i = 0; foreach (`$p in `$env:PATH.Split(';')) { `$i++; if (`$p -match 'CMake|Ninja|Llvm') { "  [`$i] `$p" } }
"@
$probe | Out-File -Encoding utf8 "$ROOT\probe2.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ROOT\probe2.ps1" *>&1 | Out-File -Encoding utf8 (Join-Path $RES 'devshell-path-clean.txt')
