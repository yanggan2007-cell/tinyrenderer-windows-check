# Step 9 of stage 1 as now printed: model paths in an array variable, Measure-Command, Restricted policy, 32-bit Developer PowerShell
. "$PSScriptRoot\common.ps1"
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$VSI = & $vswhere -latest -products * -property installationPath
$IID = & $vswhere -latest -products * -property instanceId
$out = Join-Path $RES 'arch4'
New-Item -ItemType Directory -Force $out | Out-Null
Get-Ref
$src = 'C:\code\master'
Extract-Commit 'master' $src
Copy-Item -Force "$ROOT\handbook\student\CMakePresets.json" $src
$cleanPath = ((([Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')).Split(';')) |
    Where-Object { $_ -and ($_ -notmatch 'CMake|Chocolatey|ninja|LLVM|Strawberry') }) -join ';'
$code = @"
`$ErrorActionPreference = 'Continue'
`$env:PATH = '$cleanPath'
Import-Module "$VSI\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"; Enter-VsDevShell $IID
Enter-VsDevShell -VsInstallPath `$env:VSINSTALLDIR -SkipAutomaticLocation -Arch amd64 -HostArch amd64
cd $src
cmake --preset x64-release 2>&1 | Select-Object -Last 1
cmake --build out/build/x64-release 2>&1 | Select-Object -Last 1
cmake --preset x64-debug 2>&1 | Select-Object -Last 1
cmake --build out/build/x64-debug 2>&1 | Select-Object -Last 1
"### direct run with the array variable"
`$m = "obj/diablo3_pose/diablo3_pose.obj", "obj/floor.obj"     # comment as in the handbook
.\out\build\x64-release\tinyrenderer.exe `$m 2>&1 | Select-String '# v#'
"### Measure-Command (default output)"
Measure-Command { .\out\build\x64-debug\tinyrenderer.exe `$m }
Measure-Command { .\out\build\x64-release\tinyrenderer.exe `$m }
"@
$enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
& "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Restricted -EncodedCommand $enc 2>&1 | Out-File -Encoding utf8 "$out\measure.txt"
