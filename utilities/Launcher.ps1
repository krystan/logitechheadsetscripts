# Launcher.ps1
# --------------------------------------------
# Simple menu launcher for the Logitech Headset Recovery scripts.
# Run this script in PowerShell (preferably as Administrator).
# It will execute the selected tool from the same folder.

function Require-PS7 {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Host "⚠️  PowerShell 7+ is recommended. You're on $($PSVersionTable.PSVersion). Continuing anyway..." -ForegroundColor Yellow
    }
}

function Is-Admin {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($current)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Run-Tool($scriptName) {
    $path = Join-Path $PSScriptRoot $scriptName
    if (-not (Test-Path $path)) {
        Write-Host "❌ Can't find $scriptName in $PSScriptRoot" -ForegroundColor Red
        return
    }
    Write-Host "`n▶ Running $scriptName ..." -ForegroundColor Cyan
    # Use same host/session for clearer output
    & $path
    Write-Host "`n✔ Done." -ForegroundColor Green
    Pause
}

Clear-Host
Write-Host "Logitech Headset Recovery Toolkit" -ForegroundColor Cyan
Write-Host "================================="

if (-not (Is-Admin)) {
    Write-Host "⚠️  Not running as Administrator. Some actions may fail (service control, uninstall, registry)." -ForegroundColor Yellow
}

Require-PS7

$menu = @(
    @{ n = 1; t = "Fix-LogitechGHUB (clean uninstall/cleanup)"; s = "Fix-LogitechGHUB.ps1" },
    @{ n = 2; t = "Live USB Monitor (see plug/unplug + VID/PID)"; s = "live-monitor.ps1" },
    @{ n = 3; t = "Check MMDevices (endpoints present)"; s = "Check-MMDevices.ps1" },
    @{ n = 4; t = "Force Agent Logging (enable logging + restart)"; s = "Force-Agent-Logging.ps1" },
    @{ N = 5; t = "List USB Devices By Class"; s = "ListDevicesByClass.ps1" },
    @{ n = 0; t = "Exit"; s = "" }
)

function Show-Menu {
    Write-Host ""
    foreach ($item in $menu) {
        Write-Host (" {0}) {1}" -f $item.n, $item.t)
    }
}

do {
    Show-Menu
    $choice = Read-Host "`nSelect an option"
    if ($choice -match '^\d+$') {
        $num = [int]$choice
        $selected = $menu | Where-Object { $_.n -eq $num }
        if ($selected) {
            if ($num -eq 0) { break }
            Run-Tool $selected.s
        }
        else {
            Write-Host "Invalid option." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Please enter a number from the menu." -ForegroundColor Yellow
    }
} while ($true)

Write-Host "`nGoodbye!" -ForegroundColor Cyan
