<# 
Launcher.ps1
Master entry point for Logitech Audio Binding Toolkit.
#>

param(
  [ValidateSet('check','assert','repair','scan')]
  [string]$Action = 'check',

  # Options passed through to sub-scripts
  [string]$DevicePattern = 'PRO X 2|Logitech.*PRO X 2',
  [switch]$WarnOnLegacy,
  [switch]$Strict,
  [switch]$ForceUsbAudio2,
  [string]$Path
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

switch ($Action) {
  'check' {
    & (Join-Path $scriptRoot 'Check-LogitechAudioBinding.ps1') -DevicePattern $DevicePattern -WarnOnLegacy:$WarnOnLegacy -Strict:$Strict
  }
  'assert' {
    & (Join-Path $scriptRoot 'Assert-UsbAudioBinding.ps1') -DevicePattern $DevicePattern -WarnOnLegacy:$WarnOnLegacy -Strict:$Strict
  }
  'repair' {
    & (Join-Path $scriptRoot 'Repair-LogitechAudioBinding.ps1') -DevicePattern $DevicePattern -ForceUsbAudio2:$ForceUsbAudio2
  }
  'scan' {
    if (-not $Path) {
      Write-Error "You must specify -Path when using -Action scan"
      exit 1
    }
    & (Join-Path $scriptRoot 'Scan-And-Fix-Scripts.ps1') -Path $Path
  }
}
