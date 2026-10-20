# Smoke test: environment versions
$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Force results | Out-Null
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = & $vswhere -latest -products * -property installationPath
"VS path: $vs" | Out-File results/env.txt
& $vswhere -latest -products * -format text | Out-File -Append results/env.txt
Import-Module "$vs\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Enter-VsDevShell -VsInstallPath $vs -DevCmdArguments '-arch=x64 -host_arch=x64' -SkipAutomaticLocation | Out-Null
"--- OS" | Out-File -Append results/env.txt
[System.Environment]::OSVersion.VersionString | Out-File -Append results/env.txt
(Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSLanguage | Format-List | Out-String) | Out-File -Append results/env.txt
"CPU cores: $([Environment]::ProcessorCount)" | Out-File -Append results/env.txt
"--- cl" | Out-File -Append results/env.txt
cmd /c "cl 2>&1" | Out-File -Append results/env.txt
"--- clang-cl" | Out-File -Append results/env.txt
cmd /c "clang-cl --version 2>&1" | Out-File -Append results/env.txt
"--- cmake (first on PATH)" | Out-File -Append results/env.txt
(Get-Command cmake).Source | Out-File -Append results/env.txt
cmake --version | Out-File -Append results/env.txt
"--- ninja" | Out-File -Append results/env.txt
(Get-Command ninja -ErrorAction SilentlyContinue).Source | Out-File -Append results/env.txt
ninja --version | Out-File -Append results/env.txt
"--- git" | Out-File -Append results/env.txt
git --version | Out-File -Append results/env.txt
"--- PowerShell" | Out-File -Append results/env.txt
$PSVersionTable.PSVersion.ToString() | Out-File -Append results/env.txt
powershell -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' | Out-File -Append results/env.txt
"--- python" | Out-File -Append results/env.txt
python --version 2>&1 | Out-File -Append results/env.txt
"--- code page" | Out-File -Append results/env.txt
cmd /c chcp | Out-File -Append results/env.txt
"--- cmake default generator (cmake --help tail)" | Out-File -Append results/env.txt
cmake --help | Select-String -Pattern '^\*' | Out-File -Append results/env.txt
