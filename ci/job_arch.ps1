# Developer PowerShell target architecture (x86 by default?) and what happens when the command line and the IDE mix;
# plus: does the author's final renderer produce the same image with and without OpenMP?
. "$PSScriptRoot\common.ps1"
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$VSI = & $vswhere -latest -products * -property installationPath
$out = Join-Path $RES 'arch'
New-Item -ItemType Directory -Force $out | Out-Null

# ---- (1) Start menu shortcuts that VS installs ----
$sh = New-Object -ComObject WScript.Shell
$lnks = Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter *.lnk -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Developer|Native Tools|Cross Tools' }
$shortcutInner = $null
$lnkText = foreach ($f in $lnks) {
    $l = $sh.CreateShortcut($f.FullName)
    "$($f.FullName)`n  target: $($l.TargetPath)`n  args:   $($l.Arguments)`n"
    if ($f.Name -match 'Developer PowerShell' -and $l.Arguments -match '&\{(.*)\}') { $shortcutInner = $Matches[1].Replace('"""', '"') }
}
$lnkText | Out-File -Encoding utf8 "$out\shortcuts.txt"

# ---- (2) how does the IDE's "Tools > Command Line > Developer PowerShell" start the shell? ----
Get-ChildItem "$VSI\Common7\IDE" -Recurse -Include *.pkgdef, *.json -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -lt 2MB } |
    Select-String -Pattern 'Enter-VsDevShell|Launch-VsDevShell' -ErrorAction SilentlyContinue |
    Select-Object -First 40 | ForEach-Object { "$($_.Path):$($_.LineNumber): $($_.Line.Trim())" } |
    Out-File -Encoding utf8 "$out\ide-devshell-refs.txt"

# ---- (3) child shells: a machine without a separately installed CMake (PATH filtered), different ways to enter the dev shell ----
$headers = @{
    'default'  = "Import-Module '$VSI\Common7\Tools\Microsoft.VisualStudio.DevShell.dll'; Enter-VsDevShell -VsInstallPath '$VSI' -SkipAutomaticLocation | Out-Null"
    'launch64' = "& '$VSI\Common7\Tools\Launch-VsDevShell.ps1' -Arch amd64 -HostArch amd64 -SkipAutomaticLocation | Out-Null"
    'shortcut' = if ($shortcutInner) { $shortcutInner + ' | Out-Null' } else { '"no Developer PowerShell shortcut found"' }
}
function Child($mode, $dir, $body, $name) {
    $s = @"
`$ErrorActionPreference = 'Continue'
`$keep = ([Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')).Split(';') | Where-Object { `$_ -and (`$_ -notmatch 'CMake|Chocolatey|ninja|LLVM') }
`$env:PATH = (`$keep -join ';')
$($headers[$mode])
Set-Location '$dir'
"mode: $mode"
"VSCMD_ARG_TGT_ARCH=`$env:VSCMD_ARG_TGT_ARCH  VSCMD_ARG_HOST_ARCH=`$env:VSCMD_ARG_HOST_ARCH"
"cl banner: " + ((cmd /c "cl 2>&1") | Select-Object -First 1)
"cl path: " + (Get-Command cl -ErrorAction SilentlyContinue).Source
"cmake path: " + (Get-Command cmake -ErrorAction SilentlyContinue).Source
"cwd: " + (Get-Location).Path
$body
"@
    $f = Join-Path $ROOT "arch-$name.ps1"
    $s | Out-File -Encoding utf8 $f
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File $f *>&1 | Out-File -Encoding utf8 "$out\$name.txt"
}
$build = @'
"--- cmake --preset x64-release ---"
cmake --preset x64-release 2>&1 | Select-Object -Last 6
"rc=$LASTEXITCODE"
"--- cmake --build out/build/x64-release ---"
cmake --build out/build/x64-release 2>&1
"rc=$LASTEXITCODE"
if (Test-Path out\build\x64-release\tinyrenderer.exe) { "machine: " + ((dumpbin /headers out\build\x64-release\tinyrenderer.exe | Select-String 'machine') -join ' | ') }
"CMAKE_CXX_COMPILER in cache: " + ((Select-String -Path out\build\x64-release\CMakeCache.txt -Pattern '^CMAKE_CXX_COMPILER:') -join '')
'@
$buildOnly = @'
(Get-Item main.cpp).LastWriteTime = Get-Date
"--- cmake --build out/build/x64-release (after touching main.cpp) ---"
cmake --build out/build/x64-release 2>&1
"rc=$LASTEXITCODE"
if (Test-Path out\build\x64-release\tinyrenderer.exe) { "machine: " + ((dumpbin /headers out\build\x64-release\tinyrenderer.exe | Select-String 'machine') -join ' | ') }
'@
$run = @'
Remove-Item -ErrorAction SilentlyContinue framebuffer.tga
& .\out\build\x64-release\tinyrenderer.exe
"run rc=$LASTEXITCODE  framebuffer.tga exists: $(Test-Path framebuffer.tga)"
'@

Get-Ref
$P1 = Join-Path $ROOT 'archproj1'
$P2 = Join-Path $ROOT 'archproj2'
foreach ($p in $P1, $P2) {
    Extract-Commit '706b2df' $p
    Copy-Item -Force "$ROOT\handbook\student\CMakeLists.txt", "$ROOT\handbook\student\CMakePresets.json" $p
}
Child 'default'  $P1 '' 'a-default-banner'
Child 'shortcut' $P1 '' 'b-shortcut-banner'
Child 'launch64' $P1 ($build + "`n" + $run) 'c-launch64-configure-build'
Child 'default'  $P1 $buildOnly 'd-default-build-into-x64-dir'
Child 'default'  $P1 ($build + "`n" + $run) 'e-default-configure-again'
Child 'launch64' $P1 ($buildOnly + "`n" + $run) 'f-launch64-build-again'
Child 'default'  $P2 ($build + "`n" + $run) 'g-default-fresh-configure'

# ---- (4) author's final renderer: OpenMP on vs off, same image? ----
$env:JOBNAME = 'arch'
Enter-VS
$src = Join-Path $ROOT 'omp-master'
Extract-Commit 'master' $src
$args2 = 'obj/diablo3_pose/diablo3_pose.obj obj/floor.obj'
$lines = @()
foreach ($v in @(@{ n = 'omp'; e = @() }, @{ n = 'noomp'; e = @('-DCMAKE_DISABLE_FIND_PACKAGE_OpenMP=ON') })) {
    $bld = Join-Path $src "out\build\$($v.n)"
    $b = Build-CMake $src $bld 'msvc' 'Release' $v.e (Join-Path $out "omp-$($v.n)-build.txt")
    foreach ($i in 1..2) {
        Get-ChildItem $src -Filter *.tga -File | Remove-Item
        $r = Run-Exe (Join-Path $bld 'tinyrenderer.exe') $args2 $src 600 (Join-Path $out "omp-$($v.n)-run$i.txt")
        foreach ($t in Get-ChildItem $src -Filter *.tga -File) {
            $dst = Join-Path $out "omp-$($v.n)-run$i-$($t.Name)"
            Copy-Item $t.FullName $dst
            $lines += "$($v.n) run$i $($t.Name) sha256=$((Get-FileHash $dst).Hash) sec=$($r.sec) exit=$($r.exit)"
        }
    }
}
$lines | Out-File -Encoding utf8 "$out\omp-compare.txt"
python "$ROOT\ci\tga2png.py" (Join-Path $out 'omp-omp-run1-framebuffer.tga') (Join-Path $out 'omp-omp-run1-framebuffer.png') 2>&1 | Out-Null
Get-ChildItem $out -Filter *.tga | Remove-Item
