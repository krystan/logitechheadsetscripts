param(
  [string]$DevicePattern = 'PRO X 2|Logitech.*PRO X 2',
  [switch]$WarnOnLegacy,
  [switch]$Strict
)

Import-Module -Force -Name (Join-Path $PSScriptRoot 'LogitechAudio.Common.psm1')
$result = Test-UsbAudioBinding -DevicePattern $DevicePattern -WarnOnLegacy:$WarnOnLegacy -Strict:$Strict
if (-not $result.IsOk) {
  $result.Errors + $result.Warnings | ForEach-Object { Write-Host $_ }
  exit 1
}
exit 0
