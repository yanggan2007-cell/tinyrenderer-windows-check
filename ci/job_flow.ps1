# Part B: what happens when a Windows user follows the README literally, or opens the folder in Visual Studio
# without any presets; plus Debug / Release / OpenMP timings of the author's final renderer.
. "$PSScriptRoot\common.ps1"
$env:JOBNAME = 'flow'
Enter-VS
Get-Ref
$rows = @()
$args2 = 'obj/diablo3_pose/diablo3_pose.obj obj/floor.obj'

# ---- B1: README commands, verbatim (default generator on Windows = Visual Studio, multi-config) ----
$m = Join-Path $ROOT 'flow\readme'
Extract-Commit 'master' $m
Push-Location $m
Invoke-Logged $CMAKE @('-Bbuild') (Join-Path $RES 'flow\readme-configure.txt') | Out-Null
Invoke-Logged $CMAKE @('--build', 'build', '-j') (Join-Path $RES 'flow\readme-build-default.txt') | Out-Null
Get-ChildItem -Recurse -Filter tinyrenderer.exe build | ForEach-Object { $_.FullName.Substring($m.Length) } | Out-File -Encoding utf8 (Join-Path $RES 'flow\readme-exe-paths.txt')
$exeDbg = Join-Path $m 'build\Debug\tinyrenderer.exe'
foreach ($i in 1..2) {
    if (Test-Path $exeDbg) { $r = Run-Exe $exeDbg $args2 $m 900 (Join-Path $RES "flow\readme-run-debug-$i.txt"); $rows += [pscustomobject]@{ what = 'readme default build (VS generator, Debug)'; run = $i; exit = $r.exit; sec = $r.sec } }
}
Invoke-Logged $CMAKE @('--build', 'build', '--config', 'Release', '-j') (Join-Path $RES 'flow\readme-build-release.txt') | Out-Null
$exeRel = Join-Path $m 'build\Release\tinyrenderer.exe'
foreach ($i in 1..3) {
    if (Test-Path $exeRel) { $r = Run-Exe $exeRel $args2 $m 900 (Join-Path $RES "flow\readme-run-release-$i.txt"); $rows += [pscustomobject]@{ what = 'readme --config Release (VS generator)'; run = $i; exit = $r.exit; sec = $r.sec } }
}
# The README's literal run command uses a Unix path
"build/tinyrenderer exists: $(Test-Path (Join-Path $m 'build/tinyrenderer'))" | Out-File -Encoding utf8 (Join-Path $RES 'flow\readme-unix-path.txt')
Convert-Tgas $m (Join-Path $RES 'img\flow-master')
Pop-Location

# ---- B2: Visual Studio "Open Folder" defaults without presets: Ninja + cl, Debug, out/build/x64-Debug,
#          working directory = folder of the exe ----
foreach ($case in @(@{c='706b2df'; n='start'; a=''}, @{c='1e1d339'; n='wireframe'; a='obj/diablo3_pose/diablo3_pose.obj'}, @{c='master'; n='final'; a=$args2})) {
    $src = Join-Path $ROOT "flow\vsdefault-$($case.n)"
    Extract-Commit $case.c $src
    $bld = Join-Path $src 'out\build\x64-Debug'
    $b = Build-CMake $src $bld 'msvc' 'Debug' @() (Join-Path $RES "flow\vsdefault-$($case.n)-build.txt")
    $exe = Join-Path $bld 'tinyrenderer.exe'
    if (Test-Path $exe) {
        # (1) default working directory = build folder, relative paths as in the README
        $r1 = Run-Exe $exe $case.a $bld 900 (Join-Path $RES "flow\vsdefault-$($case.n)-cwd-build.txt")
        "tga files in build folder: " + ((Get-ChildItem $bld -Filter *.tga -File | ForEach-Object Name) -join ', ') | Out-File -Append -Encoding utf8 (Join-Path $RES "flow\vsdefault-$($case.n)-cwd-build.txt")
        Convert-Tgas $bld (Join-Path $RES "img\flow-vsdefault-$($case.n)-cwd-build")
        # (2) working directory = project root (what launch.vs.json "currentDir" fixes)
        $r2 = Run-Exe $exe $case.a $src 900 (Join-Path $RES "flow\vsdefault-$($case.n)-cwd-root.txt")
        Convert-Tgas $src (Join-Path $RES "img\flow-vsdefault-$($case.n)-cwd-root")
        $rows += [pscustomobject]@{ what = "vs-default Debug $($case.n) cwd=build"; run = 1; exit = $r1.exit; sec = $r1.sec }
        $rows += [pscustomobject]@{ what = "vs-default Debug $($case.n) cwd=root"; run = 1; exit = $r2.exit; sec = $r2.sec }
    }
}

# ---- B3: Debug vs Release vs Release-without-OpenMP (Ninja + cl), author's final code ----
$src = Join-Path $ROOT 'flow\timing'
Extract-Commit 'master' $src
$variants = @(
    @{ n = 'Debug';            cfg = 'Debug';   extra = @() },
    @{ n = 'Release';          cfg = 'Release'; extra = @() },
    @{ n = 'Release-noOpenMP'; cfg = 'Release'; extra = @('-DCMAKE_DISABLE_FIND_PACKAGE_OpenMP=ON') },
    @{ n = 'RelWithDebInfo';   cfg = 'RelWithDebInfo'; extra = @() }
)
foreach ($v in $variants) {
    $bld = Join-Path $src "out\build\$($v.n)"
    $b = Build-CMake $src $bld 'msvc' $v.cfg $v.extra (Join-Path $RES "flow\timing-$($v.n)-build.txt")
    $exe = Join-Path $bld 'tinyrenderer.exe'
    $n = if ($v.n -eq 'Debug') { 2 } else { 3 }
    foreach ($i in 1..$n) {
        if (Test-Path $exe) { $r = Run-Exe $exe $args2 $src 900 (Join-Path $RES "flow\timing-$($v.n)-$i.txt"); $rows += [pscustomobject]@{ what = "master $($v.n) (Ninja+cl)"; run = $i; exit = $r.exit; sec = $r.sec } }
    }
}
# same with clang-cl, Release
$bld = Join-Path $src 'out\build\clang-Release'
$b = Build-CMake $src $bld 'clang' 'Release' @() (Join-Path $RES 'flow\timing-clang-Release-build.txt')
foreach ($i in 1..3) {
    $exe = Join-Path $bld 'tinyrenderer.exe'
    if (Test-Path $exe) { $r = Run-Exe $exe $args2 $src 900 (Join-Path $RES "flow\timing-clang-Release-$i.txt"); $rows += [pscustomobject]@{ what = 'master Release (Ninja+clang-cl)'; run = $i; exit = $r.exit; sec = $r.sec } }
}
Save-Csv $rows 'flow-timings.csv'

# ---- B4: Bresenham timing experiment of the course (2^24 random lines), Release, 3 runs each ----
$rows2 = @()
foreach ($c in @('2054b8c', '5c3a810', 'dbd11a9', '477b3cd', '5c8360e')) {
    $s = Join-Path $ROOT "flow\bres-$c"
    Extract-Commit $c $s
    if (Test-Path "$ROOT\ci\patches\$c") { Copy-Item -Force "$ROOT\ci\patches\$c\*" $s }
    $bld = Join-Path $s 'out\build\x64-release'
    $b = Build-CMake $s $bld 'msvc' 'Release' @() (Join-Path $RES "flow\bres-$c-build.txt")
    foreach ($i in 1..3) {
        $exe = Join-Path $bld 'tinyrenderer.exe'
        if (Test-Path $exe) { $r = Run-Exe $exe '' $s 600 (Join-Path $RES "flow\bres-$c-$i.txt"); $rows2 += [pscustomobject]@{ commit = $c; run = $i; exit = $r.exit; sec = $r.sec } }
    }
}
Save-Csv $rows2 'flow-bresenham.csv'
