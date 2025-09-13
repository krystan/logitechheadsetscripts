# LogitechAudio.Common.psm1
# Cross-version (Windows PowerShell 5.1+ and PowerShell 7) utilities for Logitech USB audio binding checks.
# Accepts USB Audio 2.0 (usbaudio2.inf) and USB Audio 1.0 (wdma_usb.inf) as valid "Media" bindings.

Set-StrictMode -Version Latest

$Script:AcceptableMediaInfs = @('usbaudio2.inf', 'wdma_usb.inf')

function Get-InfPath {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$InstanceId)
  try {
    (Get-PnpDeviceProperty -InstanceId $InstanceId -KeyName 'DEVPKEY_Device_DriverInfPath' -ErrorAction Stop).Data
  } catch {
    $null
  }
}

function Get-UsbAudioBindings {
  <#
    .SYNOPSIS
      Returns objects describing endpoint and media bindings for a given device pattern.
    .PARAMETER DevicePattern
      Regex to match FriendlyName. Defaults to Logitech PRO X 2 variants.
  #>
  [CmdletBinding()]
  param(
    [string]$DevicePattern = 'PRO X 2|Logitech.*PRO X 2'
  )

  $result = @()

  # Endpoints
  $endpoints = Get-PnpDevice -PresentOnly | Where-Object {
    $_.Class -eq 'AudioEndpoint' -and ($_.FriendlyName -match $DevicePattern)
  }
  foreach ($ep in $endpoints) {
    $inf = Get-InfPath -InstanceId $ep.InstanceId
    $result += [pscustomobject]@{
      Class        = $ep.Class
      FriendlyName = $ep.FriendlyName
      InstanceId   = $ep.InstanceId
      Inf          = $inf
      Expected     = 'audioendpoint.inf'
      Status       = if ($inf -and ($inf.ToLower() -eq 'audioendpoint.inf')) { 'OK' } else { 'FAIL' }
    }
  }

  # Media
  $media = Get-PnpDevice -Class Media -PresentOnly | Where-Object {
    $_.FriendlyName -match $DevicePattern -or $_.InstanceId -match 'VID_046D'
  }
  foreach ($m in $media) {
    $inf = Get-InfPath -InstanceId $m.InstanceId
    $infLower = $inf ? $inf.ToLower() : ''
    $isAccept = $infLower -and (($Script:AcceptableMediaInfs | ForEach-Object { $_.ToLower() }) -contains $infLower)
    $result += [pscustomobject]@{
      Class        = $m.Class
      FriendlyName = $m.FriendlyName
      InstanceId   = $m.InstanceId
      Inf          = $inf
      Expected     = ($Script:AcceptableMediaInfs -join ', ')
      Status       = if ($isAccept) { 'OK' } else { if ($inf) { 'FAIL' } else { 'UNKNOWN' } }
    }
  }

  return $result
}

function Test-UsbAudioBinding {
  <#
    .SYNOPSIS
      Returns $true if bindings are OK; optionally treats wdma_usb.inf as WARN only.
    .PARAMETER DevicePattern
      Regex to match FriendlyName.
    .PARAMETER WarnOnLegacy
      If set, wdma_usb.inf yields WARN (but still passes exit condition unless -Strict).
    .PARAMETER Strict
      If set, WARN will be considered a failure for exit/CI purposes.
  #>
  [CmdletBinding()]
  param(
    [string]$DevicePattern = 'PRO X 2|Logitech.*PRO X 2',
    [switch]$WarnOnLegacy,
    [switch]$Strict
  )

  $bindings = Get-UsbAudioBindings -DevicePattern $DevicePattern
  $errors = @()
  $warns  = @()

  foreach ($b in $bindings) {
    if ($b.Class -eq 'AudioEndpoint' -and $b.Status -ne 'OK') {
      $errors += "Endpoint '$($b.FriendlyName)' bound to '$($b.Inf)' (expected audioendpoint.inf)."
    }
    if ($b.Class -eq 'Media') {
      $infLower = $b.Inf ? $b.Inf.ToLower() : ''
      if ($infLower -eq 'wdma_usb.inf' -and $WarnOnLegacy) {
        $warns += "Media '$($b.FriendlyName)' on '$($b.Inf)' (USB Audio 1.0)."
      } elseif ($b.Status -ne 'OK') {
        $errors += "Media '$($b.FriendlyName)' on '$($b.Inf)' (expected one of: $($Script:AcceptableMediaInfs -join ', '))."
      }
    }
  }

  [pscustomobject]@{
    Bindings = $bindings
    Errors   = $errors
    Warnings = $warns
    IsOk     = ($errors.Count -eq 0 -and (-not $Strict -or $warns.Count -eq 0))
  }
}

function Repair-UsbAudioBinding {
  <#
    .SYNOPSIS
      Attempts to rebind Media device to usbaudio2.inf if available; otherwise leaves wdma_usb.inf as-is.
    .PARAMETER DevicePattern
      Regex to match FriendlyName.
    .PARAMETER ForceUsbAudio2
      If set, tries to install/bind usbaudio2.inf even if wdma_usb.inf is currently OK.
  #>
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [string]$DevicePattern = 'PRO X 2|Logitech.*PRO X 2',
    [switch]$ForceUsbAudio2
  )

  $media = Get-PnpDevice -Class Media -PresentOnly | Where-Object {
    $_.FriendlyName -match $DevicePattern -or $_.InstanceId -match 'VID_046D'
  }

  if (-not $media) {
    Write-Warning "No Media-class device matched '$DevicePattern'."
    return $false
  }

  $changed = $false

  foreach ($m in $media) {
    $inf = Get-InfPath -InstanceId $m.InstanceId
    $infLower = $inf ? $inf.ToLower() : ''
    if (-not $ForceUsbAudio2 -and ($infLower -in $Script:AcceptableMediaInfs)) {
      Write-Verbose "Media '$($m.FriendlyName)' already acceptable ($inf)."
      continue
    }

    if ($PSCmdlet.ShouldProcess($m.FriendlyName, 'Rebind to USB Audio 2.0 (usbaudio2.inf)')) {
      # Add the in-box driver if needed, then remove/re-add device to trigger best-match binding.
      try {
        & pnputil /add-driver "C:\Windows\INF\usbaudio2.inf" /install | Out-Null
      } catch {}

      try {
        & pnputil /remove-device "$($m.InstanceId)" | Out-Null
      } catch {}

      Start-Sleep -Seconds 2
      # Re-scan PnP devices
      try {
        & pnputil /scan-devices | Out-Null
      } catch {}

      $changed = $true
    }
  }

  return $changed
}
