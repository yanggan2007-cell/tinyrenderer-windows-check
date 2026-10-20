param([string]$part = 'smoke')
New-Item -ItemType Directory -Force "$PSScriptRoot\..\results" | Out-Null
Start-Transcript -Path "$PSScriptRoot\..\results\transcript-$part.txt" | Out-Null
switch ($part) {
    'authors-msvc'  { & "$PSScriptRoot\job_authors.ps1" -compiler msvc -run }
    'authors-clang' { & "$PSScriptRoot\job_authors.ps1" -compiler clang }
    'authors-clang-noomp' { & "$PSScriptRoot\job_authors.ps1" -compiler clang -noomp }
    'authors-extra' { & "$PSScriptRoot\job_authors.ps1" -compiler msvc -run -list commits_extra.txt -suffix '-extra'; & "$PSScriptRoot\job_authors.ps1" -compiler clang -noomp -list commits_extra.txt -suffix '-extra' }
    'flow'          { & "$PSScriptRoot\job_flow.ps1" }
    'handbook'      { & "$PSScriptRoot\job_handbook.ps1" }
    default         { "unknown part $part" }
}
Stop-Transcript | Out-Null
