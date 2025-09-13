<# 
.SYNOPSIS
  Scans a directory of PowerShell scripts for brittle checks that ONLY accept 'usbaudio2.inf'
  and rewrites them to accept both 'usbaudio2.inf' and 'wdma_usb.inf'.
.DESCRIPTION
  - Creates a .bak of any modified file.
  - Handles common patterns:
      * -eq 'usbaudio2.inf'
      * .ToLower() -eq 'usbaudio2.inf'
      * -contains 'usbaudio2.inf'
      * hard-coded arrays missing wdma_usb.inf
#>
param(
  [Parameter(Mandatory)][string]$Path,
  [switch]$WhatIf
)

$files = Get-ChildItem -Path $Path -Recurse -Include *.ps1,*.psm1 -File
if (-not $files) {
  Write-Host "No PowerShell files found under $Path"
  exit 0
}

$replacements = @(
  @{
    Name = "EqLiteral";
    Pattern = "(?i)(-eq\s*['""]usbaudio2\.inf['""])";
    Replace = "-in @('usbaudio2.inf','wdma_usb.inf')"
  },
  @{
    Name = "ToLowerEq";
    Pattern = "(?i)(\.ToLower\(\)\s*-eq\s*['""]usbaudio2\.inf['""])";
    Replace = ".ToLower() -in @('usbaudio2.inf','wdma_usb.inf')"
  },
  @{
    Name = "ContainsLiteral";
    Pattern = "(?i)(-contains\s*['""]usbaudio2\.inf['""])";
    Replace = "-in @('usbaudio2.inf','wdma_usb.inf')"
  },
  @{
    Name = "ArrayMissingLegacy";
    Pattern = "(?i)@\(('|"")usbaudio2\.inf('|"")\)";
    Replace = "@('usbaudio2.inf','wdma_usb.inf')"
  }
)

[int]$modified = 0
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw
  $orig = $text
  foreach ($r in $replacements) {
    $text = [regex]::Replace($text, $r.Pattern, $r.Replace)
  }
  if ($text -ne $orig) {
    if ($WhatIf) {
      Write-Host "Would modify: $($f.FullName)"
    } else {
      Copy-Item -LiteralPath $f.FullName -Destination ($f.FullName + '.bak') -Force
      Set-Content -LiteralPath $f.FullName -Value $text -Encoding UTF8
      Write-Host "Modified: $($f.FullName)"
      $modified++
    }
  }
}

Write-Host ("Done. {0} file(s) {1}." -f $modified, ($WhatIf ? 'would be modified' : 'modified'))
exit 0
