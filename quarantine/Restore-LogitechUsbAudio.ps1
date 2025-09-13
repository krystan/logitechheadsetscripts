<# 
.SYNOPSIS
  Restore previously quarantined Logitech OEM audio drivers from BackupDrivers.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$BackupDir = "$PSScriptRoot\BackupDrivers"
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

Require-Admin

if (-not (Test-Path $BackupDir)) {
  throw "Backup directory '$BackupDir' not found."
}

$infs = Get-ChildItem -Path $BackupDir -Filter "oem*.inf" -File -ErrorAction SilentlyContinue
if (-not $infs) {
  throw "No oem*.inf files found in '$BackupDir'. If export wasn't captured, reinstall via G HUB/Logitech installer."
}

Write-Host "Attempting to restore:"
$infs | ForEach-Object { Write-Host " - $($_.FullName)" }

foreach ($inf in $infs) {
  $ec = Exec "pnputil /add-driver `"$($inf.FullName)`" /install"
  if ($ec -ne 0) {
    Write-Warning "Failed to add $($inf.Name). If export wasn't captured, reinstall via the Logitech installer."
  }
}

$lgServices = @("LGHUB Updater Service","LGHUB Agent Service")
foreach ($s in $lgServices) {
  Get-Service -ErrorAction SilentlyContinue $s | Where-Object {$_.Status -ne 'Running'} | Start-Service -ErrorAction SilentlyContinue
}

Write-Host "`nDone. You may need to unplug/replug the dongle and click 'Recover' to use Logitech's audio stack."
