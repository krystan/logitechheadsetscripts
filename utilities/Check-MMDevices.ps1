# Check-MMDevices.ps1
# --------------------------------------------
# This script inspects the Windows registry MMDevices entries.
# It checks if a PRO X 2 Lightspeed endpoint is registered under Audio\Render.
# Use when: You want to confirm that Windows has created a proper audio endpoint for the headset.

$base = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
$found = $false

Get-ChildItem $base -Recurse | ForEach-Object {
    $props = Get-ItemProperty $_.PsPath -ErrorAction SilentlyContinue
    if ($props.FriendlyName -match "PRO X 2 LIGHTSPEED") {
        Write-Host "✅ Found PRO X 2 endpoint:" -ForegroundColor Green
        Write-Host "   $($props.FriendlyName) at $($_.PsPath)"
        $found = $true
    }
}

if (-not $found) {
    Write-Host "⚠️ No PRO X 2 Lightspeed endpoints found in MMDevices." -ForegroundColor Yellow
}
