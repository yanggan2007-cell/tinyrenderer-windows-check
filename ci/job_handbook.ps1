# Part C/D/E: every code snippet of the handbook, the recommended project files, timings and Windows-specific diagnostics.
. "$PSScriptRoot\common.ps1"
$env:JOBNAME = 'handbook'
Enter-VS
Get-Ref
$HB = Join-Path $ROOT 'handbook'
if (-not (Test-Path "$HB\obj")) { New-Item -ItemType Junction -Path "$HB\obj" -Target $OBJ | Out-Null }
$rows = @()
$m2 = 'obj/diablo3_pose/diablo3_pose.obj obj/floor.obj'
$m1 = 'obj/diablo3_pose/diablo3_pose.obj'
$logd = Join-Path $RES 'handbook'
New-Item -ItemType Directory -Force $logd | Out-Null

# ---------- C1: build the harness with the presets the handbook recommends ----------
Push-Location $HB
$presetRows = @()
foreach ($p in @('x64-release', 'x64-debug', 'x64-release-clang')) {
    $log = Join-Path $logd "preset-$p.txt"
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $rc1 = Invoke-Logged $CMAKE @('--preset', $p) $log
    $rc2 = Invoke-Logged $CMAKE @('--build', "out/build/$p") $log -append
    $sw.Stop()
    $t = Get-Content -Raw $log
    $presetRows += [pscustomobject]@{ preset = $p; configure_rc = $rc1; build_rc = $rc2
        errors = ([regex]::Matches($t, '(error C\d+|error LNK\d+|: error:|fatal error)')).Count
        warnings = ([regex]::Matches($t, '(warning C\d+|: warning:)')).Count; sec = [math]::Round($sw.Elapsed.TotalSeconds, 1) }
}
Save-Csv $presetRows 'handbook-presets.csv'

# ---------- C2: run every snippet program (Release) ----------
function RunHB($exeRel, $argList, $tag, $timeout = 600) {
    $exe = Join-Path $HB "out\build\x64-release\$exeRel.exe"
    $dir = Join-Path $ROOT "hbrun\$tag"
    New-Item -ItemType Directory -Force $dir | Out-Null
    if (-not (Test-Path "$dir\obj")) { New-Item -ItemType Junction -Path "$dir\obj" -Target $OBJ | Out-Null }
    if (-not (Test-Path $exe)) { return [pscustomobject]@{ prog = $tag; exit = 'NOT BUILT'; sec = '' } }
    $r = Run-Exe $exe $argList $dir $timeout (Join-Path $logd "run-$tag.txt")
    Convert-Tgas $dir (Join-Path $RES "img\hb-$tag")
    return [pscustomobject]@{ prog = $tag; exit = $r.exit; sec = $r.sec }
}
$runs = @(
    @('early\s1_gradient', '', 's1_gradient'), @('early\s1_gray', '', 's1_gray'),
    @('early\s2_lines_test', '', 's2_lines'), @('early\s2_wire', $m1, 's2_wire_diablo'),
    @('early\s2_wire', 'obj/african_head/african_head.obj', 's2_wire_head'),
    @('early\s3_test', $m1, 's3_nocull'), @('early\s3_test_cull', $m1, 's3_cull'),
    @('early\s3_color_test', '', 's3_color'), @('early\s3_fat_test', '', 's3_fat'),
    @('early\s4_painter_test', $m1, 's4_painter'), @('early\s4_test', $m1, 's4_zbuffer'),
    @('early\s4_myvec', '', 's4_myvec'), @('early\s4_test_math', '', 's4_math'),
    @('early\rot_test', '', 's5_rot'), @('early\s5_dropz_test', '', 's5_dropz'), @('early\s5_test', $m2, 's5_camera'),
    @('late\rnd_test', $m1, 's6_random'), @('late\r_flat', $m2, 's6_flat'), @('late\r_smooth', $m2, 's6_smooth'),
    @('late\r_texture', $m2, 's7_texture'), @('late\r_tangent', $m2, 's7_tangent'),
    @('late\persp_demo', 'corr.tga', 's7_persp_corr'), @('late\persp_demo_nocorr', 'nocorr.tga', 's7_persp_nocorr'),
    @('late\shadow_2048', $m2, 's7_shadow'), @('late\shadow_bias0', $m2, 's7_shadow_bias0'),
    @('late\png_ssaa_test', $m1, 's7_ssaa')
)
foreach ($x in $runs) { $rows += RunHB $x[0] $x[1] $x[2] }
# PNG files written by png_ssaa_test
Copy-Item -Force (Join-Path $ROOT 'hbrun\s7_ssaa\*.png') (Join-Path $RES 'img\hb-s7_ssaa') -ErrorAction SilentlyContinue
Save-Csv $rows 'handbook-runs.csv'

# ---------- D: timings ----------
$t = @()
foreach ($i in 1..3) { foreach ($sz in 1024, 2048, 4096, 8000) { $r = RunHB "late\shadow_$sz" $m2 "timing-shadow-$sz-$i"; $t += [pscustomobject]@{ what = "shadow map $sz"; run = $i; exit = $r.exit; sec = $r.sec } } }
$r = RunHB 'rt\rt' '' 'rt-brute' 1200; $t += [pscustomobject]@{ what = 'ray tracer brute force'; run = 1; exit = $r.exit; sec = $r.sec }
foreach ($i in 1..3) { $r = RunHB 'rt\rt' 'bvh' "rt-bvh-$i"; $t += [pscustomobject]@{ what = 'ray tracer BVH'; run = $i; exit = $r.exit; sec = $r.sec } }
foreach ($i in 1..3) { $r = RunHB 'late\r_tangent' $m2 "timing-tangent-release-$i"; $t += [pscustomobject]@{ what = 'handbook final renderer Release'; run = $i; exit = $r.exit; sec = $r.sec } }
foreach ($i in 1..2) {
    $exe = Join-Path $HB 'out\build\x64-debug\late\r_tangent.exe'
    $dir = Join-Path $ROOT 'hbrun\s7_tangent'
    if (Test-Path $exe) { $r = Run-Exe $exe $m2 $dir 900 (Join-Path $logd "timing-tangent-debug-$i.txt"); $t += [pscustomobject]@{ what = 'handbook final renderer Debug'; run = $i; exit = $r.exit; sec = $r.sec } }
}
foreach ($i in 1..2) {
    $exe = Join-Path $HB 'out\build\x64-release-clang\late\r_tangent.exe'
    $dir = Join-Path $ROOT 'hbrun\s7_tangent'
    if (Test-Path $exe) { $r = Run-Exe $exe $m2 $dir 900 (Join-Path $logd "timing-tangent-clang-$i.txt"); $t += [pscustomobject]@{ what = 'handbook final renderer Release clang-cl'; run = $i; exit = $r.exit; sec = $r.sec } }
}
Save-Csv $t 'handbook-timings.csv'
Pop-Location

# ---------- E1: encoding (Chinese Windows simulated with /source-charset:.936) ----------
$enc = @()
foreach ($case in @(@{n='utf8'; e=@('-DHB_UTF8=ON','-DHB_SIM936=OFF')}, @{n='default-acp'; e=@('-DHB_UTF8=OFF','-DHB_SIM936=OFF')}, @{n='sim936'; e=@('-DHB_UTF8=OFF','-DHB_SIM936=ON')})) {
    $bld = Join-Path $ROOT "encbuild\$($case.n)"
    $b = Build-CMake $HB $bld 'msvc' 'Release' $case.e (Join-Path $logd "encoding-$($case.n).txt")
    $txt = Get-Content -Raw (Join-Path $logd "encoding-$($case.n).txt")
    $enc += [pscustomobject]@{ case = $case.n; ok = $b.ok; errors = $b.errors; warnings = $b.warnings
        c4819 = ([regex]::Matches($txt, 'C4819')).Count; c2001 = ([regex]::Matches($txt, 'C2001')).Count }
}
# the author's own sources contain a few non-ASCII characters (e.g. U+2212 in comments)
$a = Join-Path $ROOT 'encbuild\author-2054b8c'
Extract-Commit '2054b8c' $a
Copy-Item -Force "$ROOT\ci\patches\2054b8c\*" $a
$b = Build-CMake $a (Join-Path $a 'out\b') 'msvc' 'Release' @('-DCMAKE_CXX_FLAGS=/source-charset:.936 /EHsc') (Join-Path $logd 'encoding-author-sim936.txt')
$txt = Get-Content -Raw (Join-Path $logd 'encoding-author-sim936.txt')
$enc += [pscustomobject]@{ case = 'author 2054b8c sim936'; ok = $b.ok; errors = $b.errors; warnings = $b.warnings; c4819 = ([regex]::Matches($txt, 'C4819')).Count; c2001 = ([regex]::Matches($txt, 'C2001')).Count }
Save-Csv $enc 'handbook-encoding.csv'

# ---------- E2: small diagnostic programs, with cl and clang-cl ----------
$D = Join-Path $HB 'diag'
$dg = Join-Path $ROOT 'diagbuild'
New-Item -ItemType Directory -Force $dg | Out-Null
Push-Location $dg
$diagRows = @()
function Diag($name, $tool, [string[]]$flags, $src, $runArgs = '', [int]$timeout = 60) {
    $exe = Join-Path $dg "$name.exe"
    $log = Join-Path $logd "diag-$name.txt"
    $argv = @('/nologo', '/EHsc', '/std:c++20') + $flags + @((Join-Path $D $src), "/Fe:$exe")
    $rc = Invoke-Logged $tool $argv $log
    $res = [pscustomobject]@{ test = $name; compile_rc = $rc; run_exit = ''; run_sec = '' }
    if ($rc -eq 0 -and (Test-Path $exe)) {
        $r = Run-Exe $exe $runArgs $dg $timeout (Join-Path $logd "diag-$name-run.txt")
        $res.run_exit = $r.exit; $res.run_sec = $r.sec
    }
    return $res
}
$diagRows += Diag 'mpi-cl'              'cl'     @()                       'mpi_test.cpp'
$diagRows += Diag 'mpi-cl-define'       'cl'     @('/D_USE_MATH_DEFINES')  'mpi_test.cpp'
$diagRows += Diag 'mpi-clangcl'         $CLANGCL @()                       'mpi_test.cpp'
$diagRows += Diag 'numbers-pi-cl'       'cl'     @()                       'numbers_pi.cpp'
$diagRows += Diag 'constexpr-cos-cl'    'cl'     @()                       'constexpr_cos.cpp'
$diagRows += Diag 'constexpr-cos-clangcl' $CLANGCL @()                     'constexpr_cos.cpp'
$diagRows += Diag 'narrowing-cl'        'cl'     @()                       'narrowing.cpp'
$diagRows += Diag 'narrowing-clangcl'   $CLANGCL @()                       'narrowing.cpp'
$diagRows += Diag 'floatcast-cl-O2'     'cl'     @('/O2')                  'float_cast.cpp'
$diagRows += Diag 'floatcast-cl-Od'     'cl'     @('/Od')                  'float_cast.cpp'
$diagRows += Diag 'floatcast-clangcl-O2' $CLANGCL @('/O2')                 'float_cast.cpp'
$diagRows += Diag 'floatcast-clangcl-ubsan' $CLANGCL @('/O1', '-fsanitize=float-cast-overflow') 'float_cast.cpp'
$diagRows += Diag 'asan-cl'             'cl'     @('/O2', '/Zi', '/fsanitize=address') 'asan_oob.cpp'
$diagRows += Diag 'oob-cl-release'      'cl'     @('/O2', '/MD')           'asan_oob.cpp'
$diagRows += Diag 'oob-cl-debug'        'cl'     @('/Od', '/MDd', '/Zi')   'asan_oob.cpp' '' 30
$diagRows += Diag 'enc-cl-default'      'cl'     @()                       'encoding_cn.cpp'
$diagRows += Diag 'enc-cl-sim936'       'cl'     @('/source-charset:.936') 'encoding_cn.cpp'
$diagRows += Diag 'enc-cl-utf8'         'cl'     @('/utf-8')               'encoding_cn.cpp'
Save-Csv $diagRows 'handbook-diag.csv'
# bytes printed by the encoding programs (to see what ended up in the .exe)
foreach ($n in 'enc-cl-default', 'enc-cl-sim936', 'enc-cl-utf8') {
    $exe = Join-Path $dg "$n.exe"
    if (Test-Path $exe) {
        $psi = New-Object System.Diagnostics.ProcessStartInfo $exe
        $psi.RedirectStandardOutput = $true; $psi.UseShellExecute = $false
        $p = [Diagnostics.Process]::Start($psi)
        $ms = New-Object IO.MemoryStream; $p.StandardOutput.BaseStream.CopyTo($ms); $p.WaitForExit()
        ($n + ': ' + [BitConverter]::ToString($ms.ToArray())) | Out-File -Append -Encoding utf8 (Join-Path $logd 'diag-encoding-bytes.txt')
    }
}
Pop-Location

# ---------- E3: getting the starting code from Windows PowerShell 5.1 (the default "Developer PowerShell") ----------
$ps = Join-Path $ROOT 'pstest'
New-Item -ItemType Directory -Force "$ps\pipe", "$ps\zip", "$ps\tarzip" | Out-Null
$script = @"
`$ErrorActionPreference = 'Continue'
"PowerShell " + `$PSVersionTable.PSVersion
"--- A: git archive | tar -x (binary pipe)"
cd '$ps\pipe'
git -C '$REF' archive 706b2df | tar -xf - 2>&1
"exit: `$LASTEXITCODE"
(Get-ChildItem -Recurse -File | Measure-Object).Count.ToString() + ' files'
"--- B: git archive --format=zip + Expand-Archive"
cd '$ps\zip'
git -C '$REF' archive --format=zip -o ..\starter.zip 706b2df
"exit: `$LASTEXITCODE"
Expand-Archive ..\starter.zip -DestinationPath .
(Get-ChildItem -Recurse -File | Measure-Object).Count.ToString() + ' files'
"--- C: tar -xf on the zip"
cd '$ps\tarzip'
tar -xf ..\starter.zip 2>&1
"exit: `$LASTEXITCODE"
(Get-ChildItem -Recurse -File | Measure-Object).Count.ToString() + ' files'
"@
$script | Out-File -Encoding utf8 "$ps\test.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ps\test.ps1" *>&1 | Out-File -Encoding utf8 (Join-Path $logd 'powershell51-getting-code.txt')
pwsh -NoProfile -Command "cd '$ps'; New-Item -ItemType Directory -Force pipe7 | Out-Null; cd pipe7; git -C '$REF' archive 706b2df | tar -xf - 2>&1; 'exit: ' + `$LASTEXITCODE; (Get-ChildItem -Recurse -File | Measure-Object).Count.ToString() + ' files'" *>&1 | Out-File -Encoding utf8 (Join-Path $logd 'powershell7-pipe.txt')

# ---------- E4: the student project template (starter code + recommended CMakeLists / presets) ----------
$st = Join-Path $ROOT 'studentproj'
Extract-Commit '706b2df' $st
Copy-Item -Force "$HB\student\CMakeLists.txt", "$HB\student\CMakePresets.json" $st
Push-Location $st
$sr = @()
foreach ($p in 'x64-debug', 'x64-release') {
    $log = Join-Path $logd "student-$p.txt"
    $rc1 = Invoke-Logged $CMAKE @('--preset', $p) $log
    $rc2 = Invoke-Logged $CMAKE @('--build', "out/build/$p") $log -append
    $exe = Join-Path $st "out\build\$p\tinyrenderer.exe"
    $r = $null
    if (Test-Path $exe) { $r = Run-Exe $exe '' $st 60 (Join-Path $logd "student-$p-run.txt") }
    $sr += [pscustomobject]@{ preset = $p; configure_rc = $rc1; build_rc = $rc2; run_exit = if ($r) { $r.exit } else { '' }; tga = (Test-Path "$st\framebuffer.tga") }
}
Save-Csv $sr 'handbook-student.csv'
Pop-Location
