# Force-Agent-Logging.ps1
# --------------------------------------------
# This script stops Logitech G HUB services and processes, then restarts lghub_agent.exe with logging enabled.
# Use when: You want to generate logs to debug G HUB device detection issues.

Stop-Service LGHUBAgentService -Force -ErrorAction SilentlyContinue
Stop-Service LGHUBUpdaterService -Force -ErrorAction SilentlyContinue
Get-Process lghub* -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Process -FilePath "C:\Program Files\LGHUB\lghub_agent.exe" -ArgumentList "--enable-logging"
Write-Host "✅ Logitech G HUB Agent restarted with logging enabled." -ForegroundColor Green
