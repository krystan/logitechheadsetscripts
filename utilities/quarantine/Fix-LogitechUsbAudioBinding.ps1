<# 
.SYNOPSIS
  Attempts to rebind the MEDIA function from an OEM INF to Microsoft's USB audio driver.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$DeviceNamePattern = "PRO X 2",
  [switch]$AllMediaDevices,
  [switch]$WhatIfDelete,
  [switch]$Force
)

function Require-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as Administrator."
    exit 2
  }
}

function Get-PropValue {
  param($dev,$key)
  try {
    $p = $dev | Get-PnpDeviceProperty -KeyName $key -ErrorAction Stop
    if ($p -and $p.Data) { return [string]$p.Data }
  } catch {}
  return $null
}

function Normalize-INF($inf) {
  if (-not $inf) { return $null }
  return ($inf | ForEach-Object { $_.ToString().Trim().ToLowerInvariant() })
}

function Exec {
  param([string]$cmd, [switch]$Quiet)
  Write-Verbose ">> $cmd"
  $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmd" -NoNewWindow -PassThru -Wait
  if (-not $Quiet) { Write-Host "ExitCode=$($p.ExitCode)" }
  return $p.ExitCode
}

Require-Admin

$expectedMediaInfs = @("usbaudio2.inf","wdma_usb.inf")
$media = Get-PnpDevice -PresentOnly | Where-Object { $_.Class -eq "MEDIA" }

if (-not $AllMediaDevices) {
  $media = $media | Where-Object { $_.FriendlyName -match $DeviceNamePattern }
}

if (-not $media) {
  Write-Host "No MEDIA devices matched pattern '$DeviceNamePattern'."
  exit 0
}

Write-Host "Found MEDIA devices:"
$media | ForEach-Object { Write-Host " - $($_.FriendlyName) [$($_.InstanceId)]" }

foreach ($dev in $media) {
  $inf = Normalize-INF (Get-PropValue $dev 'DEVPKEY_Device_DriverInfPath')
  $iid = $dev.InstanceId
  $isExpected = $inf -and ($expectedMediaInfs -contains $inf)

  if ($isExpected) {
    Write-Host "`n[$($dev.FriendlyName)] already bound to $inf (OK)."
    continue
  }

  Write-Host "`n[$($dev.FriendlyName)] is bound to '$inf' (NOT expected)."

  $oemMatch = $inf -match '^oem\d+\.inf$'
  if ($oemMatch) {
    Write-Host "Attempting to remove conflicting driver package: $inf"
    $cmd = "pnputil /delete-driver $inf /uninstall /force"
    if ($WhatIfDelete) {
      Write-Host "(WhatIf) Would run: $cmd"
    } else {
      $ec = Exec $cmd
      if ($ec -ne 0 -and -not $Force) {
        Write-Warning "Failed to delete $inf. Re-run with -Force or try manually via Device Manager."
      }
    }
  } else {
    Write-Host "INF is not an OEM package or could not be determined. Will try cycling the device."
  }

  Write-Host "Disabling device: $iid"
  Exec "pnputil /disable-device `"$iid`"" | Out-Null
  Start-Sleep -Seconds 2
  Write-Host "Enabling device: $iid"
  Exec "pnputil /enable-device `"$iid`"" | Out-Null
  Start-Sleep -Seconds 3

  $dev2 = Get-PnpDevice -InstanceId $iid -ErrorAction SilentlyContinue
  $inf2 = Normalize-INF (Get-PropValue $dev2 'DEVPKEY_Device_DriverInfPath')
  if ($inf2 -and ($expectedMediaInfs -contains $inf2)) {
    Write-Host "Rebind success: $inf2"
  } else {
    Write-Warning "Still bound to '$inf2'. Consider unplug/replug or removing additional OEM packages with: pnputil /enum-drivers"
  }
}

Write-Host "`nDone."
exit 0
