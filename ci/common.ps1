# Shared helpers for the Windows checks. Dot-source this file.
$ErrorActionPreference = 'Continue'
$global:ROOT = (Resolve-Path "$PSScriptRoot\..").Path
$global:RES  = Join-Path $ROOT 'results'
New-Item -ItemType Directory -Force $RES | Out-Null

function Enter-VS {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $global:VS = & $vswhere -latest -products * -property installationPath
    Import-Module "$VS\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    Enter-VsDevShell -VsInstallPath $VS -DevCmdArguments '-arch=x64 -host_arch=x64' -SkipAutomaticLocation | Out-Null
    # Use the CMake / Ninja / clang-cl that ship WITH Visual Studio (what the IDE uses), not other copies on PATH
    $global:CMAKE = "$VS\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
    $global:NINJA = "$VS\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
    $global:CLANGCL = "$VS\VC\Tools\Llvm\x64\bin\clang-cl.exe"
    $note = ''
    if (-not (Test-Path $CMAKE))   { $note += "VS cmake missing; "; $global:CMAKE = (Get-Command cmake).Source }
    if (-not (Test-Path $NINJA))   { $note += "VS ninja missing; "; $global:NINJA = (Get-Command ninja).Source }
    if (-not (Test-Path $CLANGCL)) { $note += "VS clang-cl missing; "; $global:CLANGCL = 'C:\Program Files\LLVM\bin\clang-cl.exe' }
    $env:PATH = (Split-Path $CMAKE) + ';' + (Split-Path $NINJA) + ';' + $env:PATH
    $v = [ordered]@{
        vs_path = $VS
        vs_version = (& $vswhere -latest -products * -property catalog_productDisplayVersion)
        vs_name = (& $vswhere -latest -products * -property displayName)
        cl = ((cmd /c "cl 2>&1") | Select-Object -First 1)
        clangcl_path = $CLANGCL
        clangcl = ((& $CLANGCL --version) | Select-Object -First 1)
        cmake_path = $CMAKE
        cmake = ((& $CMAKE --version) | Select-Object -First 1)
        ninja_path = $NINJA
        ninja = (& $NINJA --version)
        os = (Get-CimInstance Win32_OperatingSystem).Caption + ' ' + (Get-CimInstance Win32_OperatingSystem).Version
        cpu_cores = [Environment]::ProcessorCount
        cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
        ram_gb = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
        acp = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage').ACP
        note = $note
    }
    $v | ConvertTo-Json | Out-File -Encoding utf8 (Join-Path $RES "env-$env:JOBNAME.json")
}

function Get-Ref {
    # the original course repository, with all branches
    $global:REF = Join-Path $ROOT 'ref'
    if (-not (Test-Path $REF)) { git clone -q https://github.com/ssloy/tinyrenderer.git $REF }
    $global:OBJ = Join-Path $REF 'obj'
}

function Extract-Commit($commit, $dest) {
    # source files of a commit without the (identical, 60 MB) obj folder, plus a junction to the shared obj folder
    New-Item -ItemType Directory -Force $dest | Out-Null
    $zip = "$dest.zip"
    git -C $REF archive --format=zip -o $zip $commit ':!obj'
    Expand-Archive -Force $zip -DestinationPath $dest
    Remove-Item $zip
    if (-not (Test-Path "$dest\obj")) { New-Item -ItemType Junction -Path "$dest\obj" -Target $OBJ | Out-Null }
}

function Invoke-Logged($exe, [string[]]$argv, $log, [switch]$append) {
    New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
    if ($append) { & $exe @argv *>&1 | Out-File -Append -Encoding utf8 $log }
    else         { & $exe @argv *>&1 | Out-File -Encoding utf8 $log }
    return $LASTEXITCODE
}

function Build-CMake($src, $bld, $compiler, $config, [string[]]$extra, $log) {
    $cc = if ($compiler -eq 'clang') { $CLANGCL } else { 'cl' }
    $argv = @('-S', $src, '-B', $bld, '-G', 'Ninja', "-DCMAKE_MAKE_PROGRAM=$NINJA",
              "-DCMAKE_BUILD_TYPE=$config", "-DCMAKE_CXX_COMPILER=$cc") + $extra
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $rc1 = Invoke-Logged $CMAKE $argv $log
    $rc2 = 1
    if ($rc1 -eq 0) { $rc2 = Invoke-Logged $CMAKE @('--build', $bld) $log -append }
    $sw.Stop()
    $text = Get-Content -Raw $log
    $errs = ([regex]::Matches($text, '(?m)(error C\d+|error LNK\d+|: error:|fatal error)')).Count
    $warns = ([regex]::Matches($text, '(?m)(warning C\d+|: warning:)')).Count
    return [pscustomobject]@{ ok = ($rc1 -eq 0 -and $rc2 -eq 0); errors = $errs; warnings = $warns; build_sec = [math]::Round($sw.Elapsed.TotalSeconds, 1) }
}

function Run-Exe($exe, [string]$argList, $cwd, $timeoutSec, $log) {
    New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe; $psi.Arguments = $argList; $psi.WorkingDirectory = $cwd
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $p = [Diagnostics.Process]::Start($psi)
    $o = $p.StandardOutput.ReadToEndAsync(); $e = $p.StandardError.ReadToEndAsync()
    # poll every 20 ms so that the peak working set (memory) can be recorded as well
    $peak = 0; $done = $false
    while ($true) {
        if ($p.WaitForExit(20)) { $done = $true; break }
        try { $p.Refresh(); $peak = [math]::Max($peak, $p.PeakWorkingSet64) } catch {}
        if ($sw.Elapsed.TotalSeconds -gt $timeoutSec) { break }
    }
    if (-not $done) { try { $p.Kill($true) } catch {} ; $p.WaitForExit() }
    $p.WaitForExit()
    $sw.Stop()
    $code = if ($done) { $p.ExitCode } else { 'TIMEOUT' }
    $peakMB = [math]::Round($peak / 1MB, 1)
    ("exit: $code`nseconds: " + $sw.Elapsed.TotalSeconds + "`npeak_working_set_MiB: $peakMB`n--- stdout ---`n" + $o.Result + "`n--- stderr ---`n" + $e.Result) | Out-File -Encoding utf8 $log
    return [pscustomobject]@{ exit = $code; sec = [math]::Round($sw.Elapsed.TotalSeconds, 3); peak_mb = $peakMB }
}

function Convert-Tgas($dir, $outdir) {
    New-Item -ItemType Directory -Force $outdir | Out-Null
    Get-ChildItem -Path $dir -Filter *.tga -File -ErrorAction SilentlyContinue | ForEach-Object {
        python "$ROOT\ci\tga2png.py" $_.FullName (Join-Path $outdir ($_.BaseName + '.png')) 2>&1 | Out-Null
    }
}

function Save-Csv($rows, $name) {
    $rows | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $RES $name)
}
