# live-monitor.ps1
# --------------------------------------------
# This script monitors USB device changes in real-time.
# It prints devices that are added or removed, highlighting Logitech devices by VID/PID.
# Use when: You want to confirm that your headset or dongle is detected when plugged in.

Write-Host "Monitoring USB device changes... press Ctrl+C to stop." -ForegroundColor Cyan
$baseline = Get-PnpDevice | Select-Object -Property PNPDeviceID, Name

Register-CimIndicationEvent -Query "SELECT * FROM Win32_DeviceChangeEvent" -SourceIdentifier USBChange

while ($true) {
    Wait-Event -SourceIdentifier USBChange | Out-Null
    $current = Get-PnpDevice | Select-Object -Property PNPDeviceID, Name
    $added   = Compare-Object $baseline $current -Property PNPDeviceID -PassThru | Where-Object {$_.SideIndicator -eq "=>"}
    $removed = Compare-Object $baseline $current -Property PNPDeviceID -PassThru | Where-Object {$_.SideIndicator -eq "<="}

    foreach ($dev in $added) {
        Write-Host "[+] $($dev.Name)" -ForegroundColor Green
        Write-Host "    PNPDeviceID : $($dev.PNPDeviceID)"
    }
    foreach ($dev in $removed) {
        Write-Host "[-] $($dev.Name)" -ForegroundColor Red
        Write-Host "    PNPDeviceID : $($dev.PNPDeviceID)"
    }

    $baseline = $current
}
