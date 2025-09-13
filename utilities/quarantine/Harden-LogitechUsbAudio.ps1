<# 
.SYNOPSIS
  Harden against G HUB "Recover" re-injecting Logitech OEM audio drivers.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$DeviceNamePattern = "PRO X 2",
  [string]$BackupDir = "$PSScriptRoot\BackupDrivers",
  [switch]$AllLogitechAudio
)

function Require-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Please run this script as Administrator."
  }
}

function Exec {
  param([string]$cmd,[switch]$Quiet)
  Write-Verbose ">> $cmd"
  $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmd" -NoNewWindow -PassThru -Wait
  if (-not $Quiet) { Write-Host "ExitCode=$($p.ExitCode)" }
  return $p.ExitCode
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

Require-Admin
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

$lgServices = @("LGHUB Updater Service","LGHUB Agent Service")
Write-Host "Stopping Logitech services (if present)..."
foreach ($s in $lgServices) {
  Get-Service -ErrorAction SilentlyContinue $s | Where-Object {$_.Status -ne 'Stopped'} | Stop-Service -Force -ErrorAction SilentlyContinue
}

Write-Host "Enumerating Logitech audio-related drivers (Win32_PnPSignedDriver)..."
$drivers = Get-CimInstance Win32_PnPSignedDriver |
  Where-Object { $_.DriverProviderName -match 'Logitech' -or $_.DeviceName -match 'Logitech|PRO X 2' }

$audioClasses = @('MEDIA','AUDIOENDPOINT','Sound, video and game controllers')
$lgAudio = $drivers | Where-Object { $_.DeviceClass -in $audioClasses -or $_.ClassGuid -ne $null }

$infNames = $lgAudio | Select-Object -ExpandProperty InfName -Unique | Where-Object { $_ -match '^oem\d+\.inf$' }

if (-not $infNames) {
  Write-Host "No Logitech audio OEM INF packages found. Nothing to remove."
} else {
  Write-Host "Found Logitech OEM packages:"
  $infNames | ForEach-Object { Write-Host " - $_" }

  foreach ($inf in $infNames) {
    $infLower = $inf.ToLowerInvariant()
    $infPath = Join-Path $env:WINDIR "INF\$infLower"
    $pnfPath = [System.IO.Path]::ChangeExtension($infPath, ".pnf")

    Write-Host "`nBacking up $infLower (best-effort) to $BackupDir"
    try {
      if (Test-Path $infPath) { Copy-Item -Path $infPath -Destination (Join-Path $BackupDir $infLower) -Force -ErrorAction SilentlyContinue }
      if (Test-Path $pnfPath) { Copy-Item -Path $pnfPath -Destination (Join-Path $BackupDir ([IO.Path]::GetFileName($pnfPath))) -Force -ErrorAction SilentlyContinue }
      $null = Exec "pnputil /export-driver $infLower `"$BackupDir`"" -Quiet
    } catch {}

    Write-Host "Deleting driver package $infLower from the driver store..."
    $ec = Exec "pnputil /delete-driver $infLower /uninstall /force"
    if ($ec -ne 0) {
      Write-Warning "Failed to delete $infLower. It may be in use or protected. Retry after unplugging the dongle and powering off the headset."
    }
  }
}

# Cycle MEDIA devices to rebind
$expectedMediaInfs = @("usbaudio2.inf","wdma_usb.inf")
$media = Get-PnpDevice -PresentOnly | Where-Object { $_.Class -eq "MEDIA" }
if (-not $AllLogitechAudio) {
  $media = $media | Where-Object { $_.FriendlyName -match $DeviceNamePattern }
}

if ($media) {
  Write-Host "`nCycling MEDIA devices to force rebind..."
  foreach ($dev in $media) {
    $iid = $dev.InstanceId
    Write-Host " - Disabling $iid"
    Exec "pnputil /disable-device `"$iid`"" | Out-Null
    Start-Sleep -Seconds 2
    Write-Host " - Enabling  $iid"
    Exec "pnputil /enable-device `"$iid`"" | Out-Null
    Start-Sleep -Seconds 2
  }
} else {
  Write-Host "No MEDIA devices matched pattern '$DeviceNamePattern'."
}

# Verify binding
function Check-Binding {
  $ok = $true
  $mediaNow = Get-PnpDevice -PresentOnly | Where-Object { $_.Class -eq "MEDIA" }
  if (-not $AllLogitechAudio) {
    $mediaNow = $mediaNow | Where-Object { $_.FriendlyName -match $DeviceNamePattern }
  }
  foreach ($d in $mediaNow) {
    $inf = Normalize-INF (Get-PropValue $d 'DEVPKEY_Device_DriverInfPath')
    Write-Host "MEDIA: $($d.FriendlyName) -> $inf"
    if (-not $expectedMediaInfs -contains $inf) { $ok = $false }
  }
  return $ok
}

$verified = Check-Binding
if ($verified) {
  Write-Host "`n✅ Verified: MEDIA bound to Microsoft USB audio driver."
} else {
  Write-Warning "`nMEDIA still bound to a non-Microsoft INF. Consider unplug/replug and re-run this script."
}

Write-Host "`nRestarting Logitech services (if present)..."
foreach ($s in $lgServices) {
  Get-Service -ErrorAction SilentlyContinue $s | Where-Object {$_.Status -ne 'Running'} | Start-Service -ErrorAction SilentlyContinue
}

Write-Host "`nDone. Avoid clicking 'Recover' in G HUB to stay on Microsoft drivers."
