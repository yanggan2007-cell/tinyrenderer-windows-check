# Follow-up checks, all in a Developer PowerShell started like the Start-menu shortcut (32-bit PowerShell, Restricted policy)
# and switched to x64 with the handbook's one-liner:
#  (1) Debug vs Release with a warm-up run first (the very first run of a fresh exe is slow)
#  (2) ASan / UBSan command lines with the source files in an array variable; which files are left behind; bare clang-cl on PATH?
#  (3) with VS's own CMake and the full log: re-running `cmake --preset` in a default (x86) window on an x64-configured folder
. "$PSScriptRoot\common.ps1"
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$VSI = & $vswhere -latest -products * -property installationPath
$IID = & $vswhere -latest -products * -property instanceId
$out = Join-Path $RES 'arch5'
New-Item -ItemType Directory -Force $out | Out-Null
Get-Ref
$cleanPath = ((([Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')).Split(';')) |
    Where-Object { $_ -and ($_ -notmatch 'CMake|Chocolatey|ninja|LLVM|Strawberry') }) -join ';'
$ps32 = "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"
$ps64 = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$enter = "Import-Module `"$VSI\Common7\Tools\Microsoft.VisualStudio.DevShell.dll`"; Enter-VsDevShell $IID"
$fix = 'Enter-VsDevShell -VsInstallPath $env:VSINSTALLDIR -SkipAutomaticLocation -Arch amd64 -HostArch amd64'
function Child($exe, $code, $name) {
    $full = "`$ErrorActionPreference = 'Continue'`n`$env:PATH = '$cleanPath'`n" + $code
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($full))
    & $exe -NoProfile -ExecutionPolicy Restricted -EncodedCommand $enc 2>$null | Out-File -Encoding utf8 "$out\$name.txt"
}

# (1) + (2a) author's final code
$m1 = 'C:\code\master'
Extract-Commit 'master' $m1
Copy-Item -Force "$ROOT\handbook\student\CMakePresets.json" $m1
$code1 = @"
$enter
$fix
cd $m1
cmake --preset x64-release | Select-Object -Last 1
cmake --build out/build/x64-release | Select-Object -Last 1
cmake --preset x64-debug | Select-Object -Last 1
cmake --build out/build/x64-debug | Select-Object -Last 1
`$m = "obj/diablo3_pose/diablo3_pose.obj", "obj/floor.obj"
foreach (`$i in 1..3) {
  "debug   run `$i : " + (Measure-Command { .\out\build\x64-debug\tinyrenderer.exe `$m }).TotalSeconds
  "release run `$i : " + (Measure-Command { .\out\build\x64-release\tinyrenderer.exe `$m }).TotalSeconds
}
"--- ASan with the file list in a variable"
Remove-Item -ErrorAction SilentlyContinue *.pdb, *.obj -Exclude obj
`$src = "main.cpp", "our_gl.cpp", "model.cpp", "tgaimage.cpp"
cl /nologo /EHsc /std:c++20 /utf-8 /D_USE_MATH_DEFINES /Zi /fsanitize=address `$src /Fe:asan.exe
"cl rc=`$LASTEXITCODE"
.\asan.exe `$m
"asan run rc=`$LASTEXITCODE"
"files left in the root: " + ((Get-ChildItem -File -Name | Where-Object { `$_ -match '\.(pdb|obj|exe|ilk|exp|lib)$' }) -join ', ')
"@
Child $ps32 $code1 'a-timing-asan'

# (2b) UBSan on the patched a34b13b with bare clang-cl
$u = 'C:\code\a34b13b'
Extract-Commit 'a34b13b' $u
Copy-Item -Force "$ROOT\ci\patches\a34b13b\*" $u
$code2 = @"
$enter
$fix
cd $u
"clang-cl on PATH: " + (Get-Command clang-cl -ErrorAction SilentlyContinue).Source
`$src = "main.cpp", "tgaimage.cpp", "model.cpp"
clang-cl /nologo /EHsc /std:c++20 /O1 -fsanitize=float-cast-overflow `$src /Fe:ubsan.exe 2>&1 | Select-Object -Last 2
"clang-cl rc=`$LASTEXITCODE"
.\ubsan.exe obj/diablo3_pose/diablo3_pose.obj 2>&1 | Select-String 'runtime error' | Select-Object -First 1
"@
Child $ps32 $code2 'b-ubsan'

# (3) x64-configured folder, then `cmake --preset` again in a default (x86) window: full log, VS CMake
$p = 'C:\code\mix'
Extract-Commit '706b2df' $p
Copy-Item -Force "$ROOT\handbook\student\CMakeLists.txt", "$ROOT\handbook\student\CMakePresets.json" $p
Child $ps64 "$enter`n$fix`ncd $p`ncmake --preset x64-release`ncmake --build out/build/x64-release" 'c1-x64-configure'
$code3 = @"
$enter
cd $p
"cl banner: " + ((cmd /c "cl 2>&1") | Select-Object -First 1)
"cmake: " + (Get-Command cmake).Source
"--- cmake --preset x64-release (full output)"
cmake --preset x64-release 2>&1 | ForEach-Object { "`$_" }
"rc=`$LASTEXITCODE"
"--- cmake --build out/build/x64-release (full output)"
cmake --build out/build/x64-release 2>&1 | ForEach-Object { "`$_" }
"rc=`$LASTEXITCODE"
"machine: " + ((dumpbin /headers out\build\x64-release\tinyrenderer.exe | Select-String 'machine \(') -join ' | ')
"@
Child $ps64 $code3 'c2-x86-reconfigure'
$code4 = @"
$enter
$fix
cd $p
(Get-Item main.cpp).LastWriteTime = Get-Date
cmake --build out/build/x64-release 2>&1 | Select-String -Pattern 'operator new|LNK1120' | Select-Object -First 3 | ForEach-Object { "`$_" }
"rc=`$LASTEXITCODE"
"@
Child $ps64 $code4 'c3-x64-build-after-x86'
