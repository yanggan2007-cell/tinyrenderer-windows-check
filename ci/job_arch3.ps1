# The student's whole command-line flow of stage 1, typed into a Developer PowerShell exactly as the handbook prints it,
# under the Windows 11 client default execution policy (Restricted): Start-menu shortcut (32-bit PowerShell) and
# the VS terminal profile (64-bit PowerShell).
. "$PSScriptRoot\common.ps1"
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$VSI = & $vswhere -latest -products * -property installationPath
$IID = & $vswhere -latest -products * -property instanceId
$out = Join-Path $RES 'arch3'
New-Item -ItemType Directory -Force $out | Out-Null
$ps32 = "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"
$ps64 = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$cleanPath = ((([Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')).Split(';')) |
    Where-Object { $_ -and ($_ -notmatch 'CMake|Chocolatey|ninja|LLVM|Strawberry') }) -join ';'
$cm = (Get-Content -Raw "$ROOT\handbook\student\CMakeLists.txt").Replace("'", "''")
$cp = (Get-Content -Raw "$ROOT\handbook\student\CMakePresets.json").Replace("'", "''")

function Flow($exe, $enter, $root, $name) {
    $code = @"
`$ErrorActionPreference = 'Continue'
`$env:PATH = '$cleanPath'
$enter
"### policy: " + (Get-ExecutionPolicy) + "   64-bit process: " + [Environment]::Is64BitProcess
Enter-VsDevShell -VsInstallPath `$env:VSINSTALLDIR -SkipAutomaticLocation -Arch amd64 -HostArch amd64
"### cl: " + ((cmd /c "cl 2>&1") | Select-Object -First 1)
git --version
cmake --version
git config --global user.name "Test Student"
git config --global user.email "student@example.com"
"### step 2"
mkdir $root
cd $root
git clone -q https://github.com/ssloy/tinyrenderer.git tinyrenderer-ref
mkdir my-renderer
cd my-renderer
git init
cd ..\tinyrenderer-ref
git archive --format=zip -o ..\starter.zip 706b2df
cd ..\my-renderer
Expand-Archive ..\starter.zip -DestinationPath .
"### Expand-Archive ok: `$?"
Copy-Item ..\tinyrenderer-ref\LICENSE.txt .
"### files after step 2: " + ((Get-ChildItem -Name) -join ', ')
"### tar alternative"
mkdir ..\tartest | Out-Null
cd ..\tartest
tar -xf ..\starter.zip
"### tar rc=`$LASTEXITCODE files: " + ((Get-ChildItem -Name) -join ', ')
cd ..\my-renderer
if (-not (Test-Path main.cpp)) { tar -xf ..\starter.zip }
"### step 3"
Set-Content -Encoding ascii CMakeLists.txt -Value '$cm'
Set-Content -Encoding ascii CMakePresets.json -Value '$cp'
Set-Content -Encoding ascii .gitignore -Value "framebuffer.tga``n.vs/``nout/``n/*.tga"
"### step 6"
cmake --preset x64-release 2>&1 | Select-Object -Last 2
cmake --build out/build/x64-release 2>&1 | Select-Object -Last 2
.\out\build\x64-release\tinyrenderer.exe
"### run rc=`$LASTEXITCODE  framebuffer.tga: " + (Test-Path framebuffer.tga)
cmake --preset x64-debug 2>&1 | Select-Object -Last 1
cmake --build out/build/x64-debug 2>&1 | Select-Object -Last 1
"### step 9"
Measure-Command { .\out\build\x64-debug\tinyrenderer.exe   obj/diablo3_pose/diablo3_pose.obj obj/floor.obj } | Select-Object -ExpandProperty TotalSeconds
Measure-Command { .\out\build\x64-release\tinyrenderer.exe obj/diablo3_pose/diablo3_pose.obj obj/floor.obj } | Select-Object -ExpandProperty TotalSeconds
"### step 10"
git add .
git commit -q -m "Stage 1: starting point + TGAImage exercises"
git status
"### stage 2 / 6: one file from a commit"
cmd /c "git -C ..\tinyrenderer-ref show 6aa8824:geometry.h > geometry.h"
"### geometry.h first bytes: " + ((Get-Content -Encoding Byte -TotalCount 4 geometry.h) -join ' ')
"### stage 8: line count"
(Get-Content *.cpp, *.h | Measure-Object -Line).Lines
"### done"
"@
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
    & $exe -NoProfile -ExecutionPolicy Restricted -EncodedCommand $enc *>&1 | Out-File -Encoding utf8 "$out\$name.txt"
}
$shortcutLine = "Import-Module `"$VSI\Common7\Tools\Microsoft.VisualStudio.DevShell.dll`"; Enter-VsDevShell $IID"
$ideLine = "Import-Module `"$VSI\Common7\Tools\Microsoft.VisualStudio.DevShell.dll`"; Enter-VsDevShell -SkipAutomaticLocation -SetDefaultWindowTitle -InstallPath `"$VSI`""
Flow $ps32 $shortcutLine 'C:\code' 'flow-shortcut-ps32'
Flow $ps64 $ideLine 'C:\code64' 'flow-ideprofile-ps64'
