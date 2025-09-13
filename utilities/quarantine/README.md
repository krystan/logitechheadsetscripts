
# Logitech USB Audio Binding Toolkit (v2)

Tools to keep PRO X 2 LIGHTSPEED (and similar) on Microsoft's USB audio driver, avoiding G HUB's recover loop.

## Files
- **Check-LogitechUsbAudioBinding.ps1** — Inspect bindings (MEDIA vs AUDIOENDPOINT).
- **Fix-LogitechUsbAudioBinding.ps1** — Remove a conflicting OEM INF and rebind.
- **Harden-LogitechUsbAudio.ps1** — Stop G HUB, quarantine Logitech OEM audio INFs, rebind, restart services.
- **Restore-LogitechUsbAudio.ps1** — Restore OEM audio drivers from `BackupDrivers`.
- **Run-Logitech-Audio-Fix.cmd** — Elevated launcher.
- **Run-Logitech-Audio-Harden.cmd** — Elevated launcher.
- **Run-Logitech-Audio-Restore.cmd** — Elevated launcher.

## Quick Start
1. Run **Run-Logitech-Audio-Harden.cmd** (Admin).
2. Unplug/replug the dongle if prompted.
3. Verify with:
   ```powershell
   .\Check-LogitechUsbAudioBinding.ps1
   ```
   Expect MEDIA → `wdma_usb.inf` or `usbaudio2.inf`; endpoints → `audioendpoint.inf`.

## Notes
- Backup is best-effort: script copies INF/PNF and tries `pnputil /export-driver`. If your OS doesn't support single-INF export, you may need to reinstall via the Logitech installer to truly restore.
- Avoid clicking **Recover** in G HUB to remain on Microsoft’s driver. If an update re-adds a new `oem###.inf`, just run the harden script again.
