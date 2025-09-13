# Logitech Headset Recovery Scripts

This bundle contains helper PowerShell scripts for troubleshooting **Logitech PRO X 2 Lightspeed** recovery issues in G HUB.

## Scripts

- **Fix-LogitechGHUB.ps1**  
  Cleans out Logitech G HUB completely, stops services, removes leftovers, and prepares for a clean reinstall.

- **live-monitor.ps1**  
  Monitors USB plug/unplug events in real time, showing devices that appear or disappear. Useful to confirm dongle/headset detection.

- **Check-MMDevices.ps1**  
  Looks in the Windows registry (MMDevices) to see if PRO X 2 endpoints are created.

- **Check-Binding.ps1**  
  Confirms whether the headset is bound to `usbaudio2.inf` (the Microsoft USB Audio 2.0 driver).

- **Force-Agent-Logging.ps1**  
  Stops all Logitech processes/services and restarts `lghub_agent.exe` with `--enable-logging` enabled to generate logs.

## Usage
1. Right-click the `.ps1` file → Run with PowerShell (Admin recommended).
2. Follow on-screen messages or check console output.
3. Use these scripts one at a time depending on the issue you're diagnosing.


## Launcher
- **Launcher.ps1** — Simple menu to run any of the included tools from one place. Run this first if you prefer a guided flow.
