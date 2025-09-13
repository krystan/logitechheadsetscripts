param(
  [string]$DevicePattern = 'PRO X 2|Logitech.*PRO X 2',
  [switch]$ForceUsbAudio2
)

Import-Module -Force -Name (Join-Path $PSScriptRoot 'LogitechAudio.Common.psm1')
Write-Host "Attempting repair..." -ForegroundColor Cyan
$changed = Repair-UsbAudioBinding -DevicePattern $DevicePattern -ForceUsbAudio2:$ForceUsbAudio2 -Verbose:$false -WhatIf:$false
if ($changed) {
  Write-Host "Repair attempted. Re-run check after re-enumeration (unplug/replug dongle or reboot if needed)." -ForegroundColor Yellow
} else {
  Write-Host "No changes made (already acceptable or no device found)." -ForegroundColor Green
}
