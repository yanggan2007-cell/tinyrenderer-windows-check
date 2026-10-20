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
    return [pscustomobject]@{ prog = $tag; exit = $r.exit; sec = $r.sec; peak_mb = $r.peak_mb }
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
    @('late\png_ssaa_test', $m1, 's7_ssaa'), @('early\checks', '', 'checks')
)
foreach ($x in $runs) { $rows += RunHB $x[0] $x[1] $x[2] }
# PNG files written by png_ssaa_test
Copy-Item -Force (Join-Path $ROOT 'hbrun\s7_ssaa\*.png') (Join-Path $RES 'img\hb-s7_ssaa') -ErrorAction SilentlyContinue
Save-Csv $rows 'handbook-runs.csv'

# ---------- D: timings ----------
$t = @()
foreach ($i in 1..3) { foreach ($sz in 1024, 2048, 4096, 8000) { $r = RunHB "late\shadow_$sz" $m2 "timing-shadow-$sz-$i"; $t += [pscustomobject]@{ what = "shadow map $sz"; run = $i; exit = $r.exit; sec = $r.sec; peak_mb = $r.peak_mb } } }
$r = RunHB 'rt\rt' '' 'rt-brute' 1200; $t += [pscustomobject]@{ what = 'ray tracer brute force'; run = 1; exit = $r.exit; sec = $r.sec }
foreach ($i in 1..3) { $r = RunHB 'rt\rt' 'bvh' "rt-bvh-$i"; $t += [pscustomobject]@{ what = 'ray tracer BVH'; run = $i; exit = $r.exit; sec = $r.sec } }
$r = RunHB 'rt\rt' 'bvhnaive' 'rt-bvhnaive' 1200; $t += [pscustomobject]@{ what = 'ray tracer BVH, naive split (triangle bounds)'; run = 1; exit = $r.exit; sec = $r.sec }
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
New-Item -ItemType Directory -Force $ps | Out-Null
$script = @"
`$ErrorActionPreference = 'Continue'
"PowerShell " + `$PSVersionTable.PSVersion
`$HOMEDIR = '$ps'
"--- A: pipe git archive into tar (works on Linux/macOS shells, NOT in Windows PowerShell 5.1)"
New-Item -ItemType Directory -Force `$HOMEDIR\pipe | Out-Null
cd `$HOMEDIR\pipe
git -C '$REF' archive 706b2df | tar -xf - 2>&1
"exit: `$LASTEXITCODE"
(Get-ChildItem -Recurse -File | Measure-Object).Count.ToString() + ' files'
"--- B: the handbook's commands"
mkdir `$HOMEDIR\code | Out-Null
cd `$HOMEDIR\code
git clone -q '$REF' tinyrenderer-ref
mkdir my-renderer | Out-Null
cd my-renderer
git init -q
cd ..\tinyrenderer-ref
git archive --format=zip -o ..\starter.zip 706b2df
"git archive exit: `$LASTEXITCODE"
cd ..\my-renderer
Expand-Archive ..\starter.zip -DestinationPath .
Copy-Item ..\tinyrenderer-ref\LICENSE.txt .
Get-ChildItem -Name
(Get-ChildItem -Recurse -File | Measure-Object).Count.ToString() + ' files'
"--- C: tar can also unpack the zip"
New-Item -ItemType Directory -Force `$HOMEDIR\tarzip | Out-Null
cd `$HOMEDIR\tarzip
tar -xf ..\code\starter.zip 2>&1
"exit: `$LASTEXITCODE"
(Get-ChildItem -Recurse -File | Measure-Object).Count.ToString() + ' files'
"--- D: git show of one file from another commit"
cd `$HOMEDIR\code\my-renderer
git -C ..\tinyrenderer-ref show 6aa8824:geometry.h > geometry.h
"geometry.h first bytes: " + ([BitConverter]::ToString([IO.File]::ReadAllBytes("`$PWD\geometry.h")[0..5]))
git -C ..\tinyrenderer-ref show 6aa8824:geometry.h | Out-File -Encoding ascii geometry2.h
"geometry2.h first bytes: " + ([BitConverter]::ToString([IO.File]::ReadAllBytes("`$PWD\geometry2.h")[0..5]))
"@
$script | Out-File -Encoding utf8 "$ps\test.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ps\test.ps1" *>&1 | Out-File -Encoding utf8 (Join-Path $logd 'powershell51-getting-code.txt')
pwsh -NoProfile -Command "cd '$ps'; New-Item -ItemType Directory -Force pipe7 | Out-Null; cd pipe7; git -C '$REF' archive 706b2df | tar -xf - 2>&1; 'exit: ' + `$LASTEXITCODE; (Get-ChildItem -Recurse -File | Measure-Object).Count.ToString() + ' files'" *>&1 | Out-File -Encoding utf8 (Join-Path $logd 'powershell7-pipe.txt')
# does the redirected geometry.h (UTF-16 in PS 5.1) still compile?
$gtest = Join-Path $ps 'code\my-renderer'
"#include `"geometry.h`"`nint main(){ vec3 v{1,2,3}; return (int)v.x - 1; }" | Out-File -Encoding ascii "$gtest\gtest.cpp"
Push-Location $gtest
Invoke-Logged 'cl' @('/nologo', '/EHsc', '/std:c++20', 'gtest.cpp') (Join-Path $logd 'powershell51-redirect-compile.txt') | Out-Null
Pop-Location

# ---------- E2b: more diagnostics ----------
Push-Location $dg
$more = @()
$more += Diag 'lnk2019-cl' 'cl' @() 'lnk_main.cpp'
$more += Diag 'oob-cl-debug-report' 'cl' @('/Od', '/MDd', '/Zi') 'oob_report.cpp' '' 30
$more += Diag 'omp-binding-clangcl' $CLANGCL @('/O2', '-openmp') 'omp_binding.cpp'
$more += Diag 'omp-binding-cl' 'cl' @('/O2', '/openmp') 'omp_binding.cpp'
Save-Csv $more 'handbook-diag2.csv'
Pop-Location

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

# ---------- E5: sanitizers on the author's real code ----------
$san = @()
# (a) clang-cl + UBSan float-cast-overflow on the "central projection" commit (the hand-disappears bug of stage 5)
$u = Join-Path $ROOT 'sanit\a34b13b'
Extract-Commit 'a34b13b' $u
Copy-Item -Force "$ROOT\ci\patches\a34b13b\*" $u
Push-Location $u
$rc = Invoke-Logged $CLANGCL @('/nologo', '/EHsc', '/std:c++20', '/O1', '-fsanitize=float-cast-overflow', 'main.cpp', 'tgaimage.cpp', 'model.cpp', '/Fe:ubsan.exe') (Join-Path $logd 'sanit-ubsan-a34b13b-build.txt')
$r = if (Test-Path "$u\ubsan.exe") { Run-Exe "$u\ubsan.exe" $m1 $u 300 (Join-Path $logd 'sanit-ubsan-a34b13b-run.txt') } else { $null }
$san += [pscustomobject]@{ test = 'clang-cl UBSan float-cast-overflow, a34b13b'; compile_rc = $rc; run_exit = if ($r) { $r.exit } else { '' } }
Convert-Tgas $u (Join-Path $RES 'img\sanit-ubsan-a34b13b')
Pop-Location
# (b) MSVC AddressSanitizer on the author's final code, exactly the command line printed in the handbook
$a = Join-Path $ROOT 'sanit\master'
Extract-Commit 'master' $a
Push-Location $a
$rc = Invoke-Logged 'cl' @('/nologo', '/EHsc', '/std:c++20', '/utf-8', '/D_USE_MATH_DEFINES', '/Zi', '/fsanitize=address', '*.cpp', '/Fe:asan.exe') (Join-Path $logd 'sanit-asan-master-build.txt')
$r = if (Test-Path "$a\asan.exe") { Run-Exe "$a\asan.exe" $m2 $a 600 (Join-Path $logd 'sanit-asan-master-run.txt') } else { $null }
$san += [pscustomobject]@{ test = 'cl /fsanitize=address, master (no bug expected)'; compile_rc = $rc; run_exit = if ($r) { $r.exit } else { '' } }
Pop-Location
Save-Csv $san 'handbook-sanitizers.csv'

# ---------- E6: can Windows' own imaging stack (WIC, used by Photos / Explorer thumbnails) decode TGA? ----------
$wic = Join-Path $logd 'wic-tga.txt'
Add-Type -AssemblyName PresentationCore
foreach ($f in @((Join-Path $ROOT 'hbrun\s1_gradient\gradient.tga'), (Join-Path $RES 'img\hb-s1_gradient\gradient.png'))) {
    try {
        $dec = [Windows.Media.Imaging.BitmapDecoder]::Create([Uri]$f, [Windows.Media.Imaging.BitmapCreateOptions]::None, [Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
        "$([IO.Path]::GetFileName($f)): decoded by WIC, codec = $($dec.CodecInfo.FriendlyName), $($dec.Frames[0].PixelWidth)x$($dec.Frames[0].PixelHeight)" | Out-File -Append -Encoding utf8 $wic
    } catch {
        "$([IO.Path]::GetFileName($f)): WIC error: $($_.Exception.Message)" | Out-File -Append -Encoding utf8 $wic
    }
}
"installed WIC decoders:" | Out-File -Append -Encoding utf8 $wic
Get-ChildItem 'Registry::HKEY_CLASSES_ROOT\CLSID\{7ED96837-96F0-4812-B211-F13C24117ED3}\Instance' -ErrorAction SilentlyContinue | ForEach-Object {
    $clsid = $_.PSChildName
    $k = Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\CLSID\$clsid" -ErrorAction SilentlyContinue
    "  $($k.FriendlyName): $($k.FileExtensions)" } | Out-File -Append -Encoding utf8 $wic

# ---------- E7: Git on a fresh machine, in Windows PowerShell 5.1 (identity, line endings, .gitignore, one-file checkout) ----------
$g = Join-Path $ROOT 'gittest'
New-Item -ItemType Directory -Force $g | Out-Null
$gscript = @"
`$ErrorActionPreference = 'Continue'
`$env:GIT_CONFIG_GLOBAL = '$g\fresh-global.gitconfig'   # empty global config = a machine where git was just installed
New-Item -ItemType File -Force `$env:GIT_CONFIG_GLOBAL | Out-Null
"git version: " + (git --version)
"system core.autocrlf: " + (git config --system core.autocrlf)
cd '$g'
git clone -q '$REF' tinyrenderer-ref
mkdir my-renderer | Out-Null
cd my-renderer
git init -q
cd ..\tinyrenderer-ref
git archive --format=zip -o ..\starter.zip 706b2df
cd ..\my-renderer
Expand-Archive ..\starter.zip -DestinationPath .
Copy-Item ..\tinyrenderer-ref\LICENSE.txt .
"--- git add ."
git add . 2>&1 | Select-Object -First 3
"--- git commit without user.name / user.email"
git commit -q -m "Stage 0: starting point from tinyrenderer 706b2df" 2>&1
"exit: `$LASTEXITCODE"
"--- after git config --global user.name / user.email"
git config --global user.name "Zhang San"
git config --global user.email "zhangsan@example.com"
git commit -q -m "Stage 0: starting point from tinyrenderer 706b2df" 2>&1
"exit: `$LASTEXITCODE"
git log --oneline
"--- .gitignore for Visual Studio + output images"
Set-Content -Path .gitignore -Value ".vs/", "out/", "/*.tga" -Encoding ascii
New-Item -ItemType Directory -Force .vs, out\build\x64-release | Out-Null
Set-Content .vs\dummy.txt 'x'
Set-Content out\build\x64-release\dummy.txt 'x'
Set-Content framebuffer.tga 'x'
git status --porcelain
"--- one file from another commit: cmd /c redirect keeps the bytes"
cmd /c "git -C ..\tinyrenderer-ref show 6aa8824:geometry.h > geometry.h"
"geometry.h first bytes: " + ([BitConverter]::ToString([IO.File]::ReadAllBytes("`$PWD\geometry.h")[0..5]))
"same as in the repository: " + ((git -C ..\tinyrenderer-ref rev-parse 6aa8824:geometry.h) -eq (git hash-object geometry.h))
"--- counting lines of code"
(Get-Content *.cpp, *.h | Measure-Object -Line).Lines
"@
$gscript | Out-File -Encoding utf8 "$g\test.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$g\test.ps1" *>&1 | Out-File -Encoding utf8 (Join-Path $logd 'powershell51-git.txt')

# ---------- E8: more small checks ----------
Push-Location $dg
$more2 = @()
$more2 += Diag 'omp-unsigned-cl' 'cl' @('/O2', '/openmp') 'omp_unsigned.cpp'
$more2 += Diag 'omp-pragma-no-openmp-W4' 'cl' @('/O2', '/W4') 'omp_binding.cpp'
Save-Csv $more2 'handbook-diag3.csv'
Pop-Location
# Pillow (a strict TGA reader) on TGAImage's default RLE output vs. uncompressed output
$pt = Join-Path $ROOT 'pillowtest'
New-Item -ItemType Directory -Force $pt | Out-Null
"#include `"tgaimage.h`"`nint main(){ TGAImage a(256,256,TGAImage::RGB); for(int y=0;y<256;y++) for(int x=0;x<256;x++){ TGAColor c={0,0,0,255}; c[2]=x; c[1]=y; a.set(x,y,c);} a.write_tga_file(`"rle.tga`"); a.write_tga_file(`"raw.tga`", true, false); return 0; }" | Out-File -Encoding ascii "$pt\mk.cpp"
Push-Location $pt
Invoke-Logged 'cl' @('/nologo', '/EHsc', '/std:c++20', '/O2', "/I$HB\early", 'mk.cpp', "$HB\early\tgaimage.cpp", '/Fe:mk.exe') (Join-Path $logd 'pillow-mk-build.txt') | Out-Null
& .\mk.exe
$py = @'
import sys, PIL
from PIL import Image
print("Pillow", PIL.__version__)
for f in ("rle.tga", "raw.tga"):
    try:
        im = Image.open(f); im.load(); print(f, "OK", im.size, im.mode)
    except Exception as e:
        print(f, "FAILED:", type(e).__name__, e)
'@
$py | Out-File -Encoding ascii "$pt\t.py"
python "$pt\t.py" *>&1 | Out-File -Encoding utf8 (Join-Path $logd 'pillow-rle.txt')
"sizes: rle.tga=$((Get-Item rle.tga).Length) raw.tga=$((Get-Item raw.tga).Length)" | Out-File -Append -Encoding utf8 (Join-Path $logd 'pillow-rle.txt')
Pop-Location
# Student project: a second executable via add_executable, and Measure-Command as printed in the handbook
Push-Location $st
Copy-Item -Force "$HB\early\s1_gradient.cpp" (Join-Path $st 'gradient.cpp')
Add-Content -Path (Join-Path $st 'CMakeLists.txt') -Value 'add_executable(gradient gradient.cpp tgaimage.cpp)'
$log = Join-Path $logd 'student-gradient.txt'
Invoke-Logged $CMAKE @('--build', 'out/build/x64-release') $log | Out-Null
$r = Run-Exe (Join-Path $st 'out\build\x64-release\gradient.exe') '' $st 60 (Join-Path $logd 'student-gradient-run.txt')
"gradient.tga exists: $(Test-Path (Join-Path $st 'gradient.tga'))" | Out-File -Append -Encoding utf8 $log
$mc = Measure-Command { .\out\build\x64-release\tinyrenderer.exe }
"Measure-Command TotalSeconds: $($mc.TotalSeconds)" | Out-File -Append -Encoding utf8 $log
Pop-Location

# ---------- E9: Debug runs of the tests (assert is active only in Debug) and a failing assert ----------
$dbgRows = @()
foreach ($x in @(@('early\s4_test_math', 's4_math-debug'), @('early\checks', 'checks-debug'))) {
    $exe = Join-Path $HB "out\build\x64-debug\$($x[0]).exe"
    if (Test-Path $exe) { $r = Run-Exe $exe '' $HB 120 (Join-Path $logd "run-$($x[1]).txt"); $dbgRows += [pscustomobject]@{ prog = $x[1]; exit = $r.exit; sec = $r.sec } }
}
Push-Location $dg
$dbgRows += Diag 'assert-cl-debug' 'cl' @('/Od', '/MDd', '/Zi') 'assert_fail.cpp' '' 20
$dbgRows += Diag 'assert-cl-release' 'cl' @('/O2', '/MD', '/DNDEBUG') 'assert_fail.cpp' '' 20
Pop-Location
Save-Csv $dbgRows 'handbook-debugruns.csv'

# ---------- E10: narrowing, aggregate init vs braced assignment ----------
Push-Location $dg
$n2 = @()
$n2 += Diag 'narrowing2-cl' 'cl' @() 'narrowing2.cpp'
Save-Csv $n2 'handbook-diag4.csv'
Pop-Location
