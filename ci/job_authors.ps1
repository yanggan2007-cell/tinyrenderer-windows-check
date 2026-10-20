# Part A: build (and run) every course commit with MSVC or clang-cl, as Visual Studio would (CMake + Ninja).
param([string]$compiler = 'msvc', [switch]$run, [switch]$noomp)
. "$PSScriptRoot\common.ps1"
$tag = if ($noomp) { "$compiler-noomp" } else { $compiler }
$env:JOBNAME = "authors-$tag"
$extra = if ($noomp) { @('-DCMAKE_DISABLE_FIND_PACKAGE_OpenMP=ON') } else { @() }
Enter-VS
Get-Ref
$work = Join-Path $ROOT "work-$tag"
$rows = @()
foreach ($line in Get-Content "$ROOT\ci\commits.txt") {
    if (-not $line.Trim()) { continue }
    $parts = $line -split '\s+'
    $stage = $parts[0]; $c = $parts[1]; $name = $parts[2]
    $src = Join-Path $work "$c-$name"
    Extract-Commit $c $src
    $bld = Join-Path $src 'out\build\x64-release'
    $log = Join-Path $RES "build\$tag\$c-$name.txt"
    New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
    $b = Build-CMake $src $bld $compiler 'Release' $extra $log
    $patched = $false
    if (-not $b.ok -and (Test-Path "$ROOT\ci\patches\$c")) {
        Copy-Item -Force "$ROOT\ci\patches\$c\*" $src
        Remove-Item -Recurse -Force $bld
        $log2 = Join-Path $RES "build\$tag\$c-$name-patched.txt"
        $b2 = Build-CMake $src $bld $compiler 'Release' $extra $log2
        $patched = $true
    } else { $b2 = $null }
    $r = $null
    $exe = Join-Path $bld 'tinyrenderer.exe'
    if ($run -and (Test-Path $exe)) {
        $argsLine = (Get-Content "$ROOT\ci\args.txt" | Where-Object { $_ -like "$c *" } | Select-Object -First 1)
        $a = ''
        if ($argsLine) { $a = ($argsLine -split '\|', 2)[1].Trim() }
        Get-ChildItem $src -Filter *.tga -File | Remove-Item
        $timeout = if ($name -eq 'ao-bruteforce') { 3600 } else { 600 }
        $r = Run-Exe $exe $a $src $timeout (Join-Path $RES "run\$compiler\$c-$name.txt")
        Convert-Tgas $src (Join-Path $RES "img\$c-$name")
    }
    $rows += [pscustomobject]@{
        stage = $stage; commit = $c; name = $name; compiler = $tag
        build_ok = $b.ok; errors = $b.errors; warnings = $b.warnings; build_sec = $b.build_sec
        patched = $patched; patched_ok = if ($b2) { $b2.ok } else { '' }; patched_errors = if ($b2) { $b2.errors } else { '' }
        run_exit = if ($r) { $r.exit } else { '' }; run_sec = if ($r) { $r.sec } else { '' }
    }
    Save-Csv $rows "authors-$tag.csv"
}
