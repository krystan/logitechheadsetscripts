# Fix-LogitechGHUB.ps1
# --------------------------------------------
# This script:
#   - Stops all Logitech G HUB services and processes
#   - Uninstalls Logitech G HUB via winget
#   - Cleans leftover Logitech G HUB directories
#   - Recreates the logs directories to ensure they exist
# Use when: You need a clean reinstall of G HUB to fix device recovery issues.

Write-Host "Stopping Logitech services..."
Stop-Service LGHUBAgentService -Force -ErrorAction SilentlyContinue
Stop-Service LGHUBUpdaterService -Force -ErrorAction SilentlyContinue
Get-Process lghub* -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Uninstalling Logitech G HUB..."
winget uninstall --id Logitech.GHUB -h --silent --force

Write-Host "Cleaning directories..."
Remove-Item -Recurse -Force "$env:APPDATA\LGHUB" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\LGHUB" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "C:\ProgramData\LGHUB" -ErrorAction SilentlyContinue

Write-Host "Recreating logs directories..."
New-Item -ItemType Directory -Force -Path "$env:APPDATA\LGHUB\logs" | Out-Null
New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\LGHUB\logs" | Out-Null
New-Item -ItemType Directory -Force -Path "C:\ProgramData\LGHUB\logs" | Out-Null

Write-Host "Now reinstall Logitech G HUB manually."
