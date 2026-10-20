param([string]$part = 'smoke')
switch ($part) {
    'authors-msvc'  { & "$PSScriptRoot\job_authors.ps1" -compiler msvc -run }
    'authors-clang' { & "$PSScriptRoot\job_authors.ps1" -compiler clang }
    'flow'          { & "$PSScriptRoot\job_flow.ps1" }
    'handbook'      { & "$PSScriptRoot\job_handbook.ps1" }
    default         { "unknown part $part" }
}
