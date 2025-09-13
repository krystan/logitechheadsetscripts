<# 
.SYNOPSIS
  Checks driver bindings for Logitech PRO X 2 LIGHTSPEED (and similar) and reports INF usage.
#>
[CmdletBinding()]
param(
  [string]$DeviceNamePattern = "PRO X 2",
  [switch]$ShowAll
)

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

$expectedMediaInfs = @("usbaudio2.inf","wdma_usb.inf")
$expectedEndpointInf = "audioendpoint.inf"

$results = @()
$devices = Get-PnpDevice -PresentOnly | Where-Object {
  $_.FriendlyName -match $DeviceNamePattern -or $_.InstanceId -match "VID_046D|VID_0B05|VID_3434"
}

if (-not $devices -or $ShowAll) {
  $devices += Get-PnpDevice -PresentOnly | Where-Object { $_.Class -in @("MEDIA","AUDIOENDPOINT") }
  $devices = $devices | Sort-Object -Unique InstanceId
}

foreach ($d in $devices) {
  $inf = Normalize-INF (Get-PropValue $d 'DEVPKEY_Device_DriverInfPath')
  $class = $d.Class
  $fn = $d.FriendlyName
  $iid = $d.InstanceId

  $status = "UNKNOWN"
  $note = ""

  if ($class -eq "AUDIOENDPOINT") {
    if ($inf -eq $expectedEndpointInf) { $status = "OK" }
    elseif ($inf) { $status = "WARN"; $note = "Expected $expectedEndpointInf" }
    else { $status = "WARN"; $note = "INF missing" }
  }
  elseif ($class -eq "MEDIA") {
    if ($inf -and ($expectedMediaInfs -contains $inf)) { $status = "OK" }
    elseif ($inf) { $status = "FAIL"; $note = "Bound to $inf; expected one of: " + ($expectedMediaInfs -join ", ") }
    else { $status = "FAIL"; $note = "INF missing (driver not fully installed?)" }
  }

  $results += [pscustomobject]@{
    Class        = $class
    FriendlyName = $fn
    InstanceId   = $iid
    InfPath      = $inf
    Status       = $status
    Note         = $note
  }
}

$summary = $results | Group-Object Status | ForEach-Object {
  '{0}: {1}' -f $_.Name, ($_.Count)
}

Write-Host "== Logitech USB Audio Binding Check =="
$results | Sort-Object Class, FriendlyName | Format-Table -AutoSize Class, FriendlyName, InfPath, Status, Note

Write-Host ""
Write-Host "Summary: " ($summary -join " | ")
Write-Host ""

if ($results.Status -contains "FAIL") { exit 1 } else { exit 0 }
