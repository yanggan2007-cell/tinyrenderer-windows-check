# The author's brute-force ambient occlusion (974424b): n light positions, each with an 8000x8000 shadow map.
param([int]$n = 1000, [int]$timeout = 10000)
. "$PSScriptRoot\common.ps1"
$env:JOBNAME = "ao-$n"
Enter-VS
Get-Ref
$src = Join-Path $ROOT "ao-$n"
Extract-Commit '974424b' $src
Copy-Item -Force "$ROOT\ci\patches\974424b\*" $src
$main = Join-Path $src 'main.cpp'
(Get-Content -Raw $main).Replace('constexpr int n = 1000;', "constexpr int n = $n;") | Set-Content -NoNewline -Encoding utf8 $main
"n line: " + (Select-String -Path $main -Pattern 'constexpr int n =').Line | Out-File -Encoding utf8 (Join-Path $RES "ao-$n-info.txt")
$bld = Join-Path $src 'out\build\x64-release'
$b = Build-CMake $src $bld 'msvc' 'Release' @() (Join-Path $RES "ao-$n-build.txt")
$exe = Join-Path $bld 'tinyrenderer.exe'
$r = Run-Exe $exe 'obj/diablo3_pose/diablo3_pose.obj obj/floor.obj' $src $timeout (Join-Path $RES "ao-$n-run.txt")
Convert-Tgas $src (Join-Path $RES "img\ao-$n")
Save-Csv @([pscustomobject]@{ n = $n; build_ok = $b.ok; run_exit = $r.exit; sec = $r.sec; peak_mb = $r.peak_mb }) "ao-$n.csv"
