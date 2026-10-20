# Follow-up: switching an already-open (x86) Developer PowerShell to x64 exactly as the handbook tells the student,
# under the Windows 11 client default execution policy (Restricted), with VS's own CMake; plus a few small checks.
. "$PSScriptRoot\common.ps1"
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$VSI = & $vswhere -latest -products * -property installationPath
$IID = & $vswhere -latest -products * -property instanceId
$out = Join-Path $RES 'arch2'
New-Item -ItemType Directory -Force $out | Out-Null
$ps32 = "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"   # what the Start menu shortcut runs
$ps64 = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

Get-Content "$VSI\Common7\IDE\CommonExtensions\Microsoft\Terminal\UnifiedSettings\terminal.registration.json" -ErrorAction SilentlyContinue |
    Select-Object -First 80 | Out-File -Encoding utf8 "$out\terminal.registration.json.txt"

# PATH of a machine without any separately installed CMake / Ninja / LLVM (Strawberry Perl ships a cmake too)
$cleanPath = ((([Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')).Split(';')) |
    Where-Object { $_ -and ($_ -notmatch 'CMake|Chocolatey|ninja|LLVM|Strawberry') }) -join ';'
$shortcutLine = "Import-Module `"$VSI\Common7\Tools\Microsoft.VisualStudio.DevShell.dll`"; Enter-VsDevShell $IID"
$ideLine = "Import-Module `"$VSI\Common7\Tools\Microsoft.VisualStudio.DevShell.dll`"; Enter-VsDevShell -SkipAutomaticLocation -SetDefaultWindowTitle -InstallPath `"$VSI`""
$fixLine = 'Enter-VsDevShell -VsInstallPath $env:VSINSTALLDIR -SkipAutomaticLocation -Arch amd64 -HostArch amd64'
$banner = @'
"Get-ExecutionPolicy: " + (Get-ExecutionPolicy)
"process is 64-bit: " + [Environment]::Is64BitProcess
"VSINSTALLDIR=$env:VSINSTALLDIR"
"VSCMD_ARG_TGT_ARCH=$env:VSCMD_ARG_TGT_ARCH  VSCMD_ARG_HOST_ARCH=$env:VSCMD_ARG_HOST_ARCH"
"cl banner: " + ((cmd /c "cl 2>&1") | Select-Object -First 1)
"cmake: " + (Get-Command cmake -ErrorAction SilentlyContinue).Source + "  |  " + ((cmake --version) | Select-Object -First 1)
"ninja: " + (Get-Command ninja -ErrorAction SilentlyContinue).Source
'@
$build = @'
"--- cmake --preset x64-release ---"
cmake --preset x64-release 2>&1 | Select-Object -Last 3
"rc=$LASTEXITCODE"
"--- cmake --build out/build/x64-release ---"
cmake --build out/build/x64-release 2>&1 | Select-Object -Last 12
"rc=$LASTEXITCODE"
if (Test-Path out\build\x64-release\tinyrenderer.exe) { "machine: " + ((dumpbin /headers out\build\x64-release\tinyrenderer.exe | Select-String 'machine \(') -join ' | ') }
Remove-Item -ErrorAction SilentlyContinue framebuffer.tga
if (Test-Path out\build\x64-release\tinyrenderer.exe) { & .\out\build\x64-release\tinyrenderer.exe; "run rc=$LASTEXITCODE  framebuffer.tga exists: $(Test-Path framebuffer.tga)" }
'@
function Child($exe, $policy, $dir, $code, $name) {
    $full = "`$ErrorActionPreference = 'Continue'`n`$env:PATH = '$cleanPath'`nSet-Location '$dir'`n" + $code
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($full))
    & $exe -NoProfile -ExecutionPolicy $policy -EncodedCommand $enc *>&1 | Out-File -Encoding utf8 "$out\$name.txt"
    $code | Out-File -Encoding utf8 "$out\$name.code.txt"
}

Get-Ref
$P = @{}
foreach ($n in 'p1', 'p2', 'p3', 'p4') {
    $P[$n] = Join-Path $ROOT "arch2-$n"
    Extract-Commit '706b2df' $P[$n]
    Copy-Item -Force "$ROOT\handbook\student\CMakeLists.txt", "$ROOT\handbook\student\CMakePresets.json" $P[$n]
}
# (1) Start menu shortcut (32-bit PowerShell, Restricted), then the one-line fix from the handbook, then build
Child $ps32 'Restricted' $P.p1 ($shortcutLine + "`n" + "Set-Location '$($P.p1)'`n" + $banner + "`n`"=== after: $fixLine`"`n" + $fixLine + "`n" + $banner + "`n" + $build) 'a-shortcut-fix-build'
# (2) VS terminal profile (64-bit PowerShell, Restricted), then the fix, then build
Child $ps64 'Restricted' $P.p2 ($ideLine + "`n" + $banner + "`n" + $fixLine + "`n" + $banner + "`n" + $build) 'b-ideprofile-fix-build'
# (3) the Launch-VsDevShell.ps1 script under Restricted (expected to be blocked)
Child $ps64 'Restricted' $P.p3 ($ideLine + "`n& `"`$env:VSINSTALLDIR\Common7\Tools\Launch-VsDevShell.ps1`" -Arch amd64 -HostArch amd64 -SkipAutomaticLocation`n" + $banner) 'c-launchscript-restricted'
# (4) mixing: configure + build in x64, then build in a default (x86) shell -> error text; then the recovery
Child $ps64 'Restricted' $P.p4 ($ideLine + "`n" + $fixLine + "`n" + $build) 'd1-x64-configure'
Child $ps64 'Restricted' $P.p4 ($ideLine + "`n" + $banner + "`n(Get-Item main.cpp).LastWriteTime = Get-Date`ncmake --build out/build/x64-release 2>&1 | Select-String -Pattern 'LNK|error|FAILED' | Select-Object -First 4`ncmake --build out/build/x64-release 2>&1 | Select-Object -Last 2`n`"rc=`$LASTEXITCODE`"") 'd2-x86-build-error'
Child $ps64 'Restricted' $P.p4 ($ideLine + "`n" + $fixLine + "`nRemove-Item -Recurse -Force out\build\x64-release`n" + $build) 'd3-recover'
# (5) alternative: x64 Native Tools Command Prompt, then "powershell"
$enc5 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($banner))
cmd /c "set PATH=$cleanPath&& call `"$VSI\VC\Auxiliary\Build\vcvars64.bat`" >nul && powershell -NoProfile -ExecutionPolicy Restricted -EncodedCommand $enc5" *>&1 | Out-File -Encoding utf8 "$out\e-x64-native-prompt-powershell.txt"

# ---- small checks ----
# (6) a plain PowerShell (no dev shell): what does it say for cmake?
Child $ps64 'Restricted' $P.p1 'cmake --version' 'f-plain-powershell-cmake'
# (7) Git: does the dev shell provide git when no other Git is installed?
$noGit = ($cleanPath.Split(';') | Where-Object { $_ -notmatch '\\Git\\' }) -join ';'
$code7 = "`$env:PATH = '$noGit'`n" + '"before: git = " + (Get-Command git -ErrorAction SilentlyContinue).Source' + "`n" + $ideLine + "`n" + '"after:  git = " + (Get-Command git -ErrorAction SilentlyContinue).Source' + "`n" + "`"VS Git component folder exists: `" + (Test-Path `"$VSI\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\cmd\git.exe`")"
Child $ps64 'Restricted' $P.p1 $code7 'g-git-from-vs'
# (8) a GBK (code page 936) source file compiled with /utf-8; and the float loop of the course's first line version
$env:JOBNAME = 'arch2'
Enter-VS
$d = Join-Path $ROOT 'arch2-small'
New-Item -ItemType Directory -Force $d | Out-Null
Push-Location $d
$gbk = [Text.Encoding]::GetEncoding(936)
[IO.File]::WriteAllText("$d\gbk.cpp", "// 中文注释：顶点`nint main() { return 0; }`n", $gbk)
Invoke-Logged 'cl' @('/nologo', '/utf-8', '/c', 'gbk.cpp') "$out\h-gbk-utf8.txt" | Out-Null
@'
#include <cstdio>
int main() {
    int n = 0; float t = 0.;
    for (t = 0.; t < 1.; t += .02) n++;          // the course's first version (dd938ce)
    std::printf("float t<1 loop runs %d times, final t = %.9g\n", n, t);
}
'@ | Out-File -Encoding ascii floop.cpp
Invoke-Logged 'cl' @('/nologo', '/O2', 'floop.cpp') "$out\i-floop-build.txt" | Out-Null
& .\floop.exe *>&1 | Out-File -Encoding utf8 "$out\i-floop-run.txt"
# (9) save_png in its own .cpp: calling it without / with a declaration
Copy-Item "$ROOT\handbook\late\stb_image_write.h", "$ROOT\handbook\late\tgaimage.h", "$ROOT\handbook\late\tgaimage.cpp" $d
Copy-Item "$ROOT\handbook\late\s7_savepng.inc" save_png.cpp
@'
#include "tgaimage.h"
int main() {
    TGAImage img(64, 64, TGAImage::RGB);
    for (int x = 0; x < 64; x++) img.set(x, x, {255, 255, 255, 255});
    return save_png(img, "test.png") ? 0 : 1;
}
'@ | Out-File -Encoding utf8 nodecl.cpp
@'
#include "tgaimage.h"
bool save_png(const TGAImage &img, const char *filename);
int main() {
    TGAImage img(64, 64, TGAImage::RGB);
    for (int x = 0; x < 64; x++) img.set(x, x, {255, 255, 255, 255});
    return save_png(img, "test.png") ? 0 : 1;
}
'@ | Out-File -Encoding utf8 withdecl.cpp
Invoke-Logged 'cl' @('/nologo', '/EHsc', '/std:c++20', '/utf-8', 'nodecl.cpp', 'save_png.cpp', 'tgaimage.cpp', '/Fe:nodecl.exe') "$out\j-savepng-nodecl.txt" | Out-Null
Invoke-Logged 'cl' @('/nologo', '/EHsc', '/std:c++20', '/utf-8', 'withdecl.cpp', 'save_png.cpp', 'tgaimage.cpp', '/Fe:withdecl.exe') "$out\j-savepng-withdecl.txt" | Out-Null
& .\withdecl.exe; "withdecl exit=$LASTEXITCODE  test.png exists: $(Test-Path test.png)  size: $((Get-Item test.png -ErrorAction SilentlyContinue).Length)" | Out-File -Append -Encoding utf8 "$out\j-savepng-withdecl.txt"
Pop-Location
