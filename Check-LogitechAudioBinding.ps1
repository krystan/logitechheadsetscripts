param(
  [string]$DevicePattern = 'PRO X 2|Logitech.*PRO X 2',
  [switch]$WarnOnLegacy,
  [switch]$Strict
)

Import-Module -Force -Name (Join-Path $PSScriptRoot 'LogitechAudio.Common.psm1')

$result = Test-UsbAudioBinding -DevicePattern $DevicePattern -WarnOnLegacy:$WarnOnLegacy -Strict:$Strict

Write-Host "== Logitech USB Audio Binding Check ==" -ForegroundColor Cyan
$result.Bindings | ForEach-Object {
  "{0,-11} {1,-40} -> {2} [{3}]" -f $_.Class, $_.FriendlyName, ($_.Inf ?? '<unknown>'), $_.Status
} | Write-Host

if ($result.Errors.Count) {
  Write-Host "`nErrors:" -ForegroundColor Red
  $result.Errors | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
}
if ($result.Warnings.Count) {
  Write-Host "`nWarnings:" -ForegroundColor DarkYellow
  $result.Warnings | ForEach-Object { Write-Host " - $_" -ForegroundColor DarkYellow }
}

if ($result.IsOk) {
  Write-Host "`nRESULT: PASS" -ForegroundColor Green
  exit 0
} else {
  Write-Host "`nRESULT: FAIL" -ForegroundColor Red
  exit 2
}
