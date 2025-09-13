<# 
.SYNOPSIS
  Removes ONLY non-present (greyed-out) HID devices — including "USB Input Device" —
  from Device Manager. Does NOT touch disks, controllers, NICs, etc.

.USAGE
  1) Run PowerShell as Administrator.
  2) Preview (no changes):    .\Clean-GhostHID.ps1
  3) Execute removal:         .\Clean-GhostHID.ps1 -Apply

.NOTES
  - Targets devices where Present=$false AND (Class='HIDClass' OR FriendlyName starts with 'USB Input Device').
  - Safe for Logitech/G HUB cleanup; current/active devices are NOT removed.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [switch]$Apply,                 # Actually remove; otherwise just preview
  [string]$LogPath = "$env:PUBLIC\Clean-GhostHID.log"
)

function Assert-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Please run this script in an elevated PowerShell (Run as Administrator)."
  }
}

try {
  Assert-Admin
  # Get all PnP devices (including non-present), then filter to greyed-out HID only
  $targets = Get-PnpDevice -PresentOnly:$false |
    Where-Object {
      -not $_.Present -and (
        $_.Class -eq 'HIDClass' -or
        ($_.FriendlyName -like 'USB Input Device*')
      )
    } |
    Sort-Object FriendlyName, InstanceId

  if (-not $targets) {
    Write-Host "No non-present HID devices found." -ForegroundColor Green
    return
  }

  # Log + preview
  "`n===== $(Get-Date -Format s) =====" | Out-File -FilePath $LogPath -Append
  "Found $($targets.Count) non-present HID devices:" | Tee-Object -FilePath $LogPath -Append
  $targets | Select-Object Class, FriendlyName, InstanceId | Tee-Object -FilePath $LogPath -Append | Format-Table -AutoSize

  if ($Apply) {
    Write-Host "`nRemoving $($targets.Count) devices..." -ForegroundColor Yellow
    foreach ($dev in $targets) {
      try {
        if ($PSCmdlet.ShouldProcess($dev.InstanceId, "Remove-PnpDevice")) {
          Remove-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction Stop
          "REMOVED: $($dev.Class) | $($dev.FriendlyName) | $($dev.InstanceId)" | Out-File -FilePath $LogPath -Append
        }
      } catch {
        "FAILED : $($dev.InstanceId) -> $($_.Exception.Message)" | Out-File -FilePath $LogPath -Append
      }
    }
    Write-Host "Done. A reboot is recommended. Log: $LogPath" -ForegroundColor Green
  } else {
    Write-Host "`nPreview only. No changes made." -ForegroundColor Cyan
    Write-Host "Run again with -Apply to remove them." -ForegroundColor Cyan
    Write-Host "Log: $LogPath"
  }
}
catch {
  Write-Error $_.Exception.Message
}
