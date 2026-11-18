# Changelog

What changed in each release. `tools\Release.ps1` moves the lines under **Unreleased** into the new version and uses
them as the GitHub release notes, which SauceStore shows as the app's version history.

## [Unreleased]

- Fixed backups not keeping an older version of folders deleted since the last backup
- Fixed the Health Check marking a disk whose health is "Unknown" (often in a USB enclosure) as a problem; it now shows N/A
- Fixed: firewall, SMB1, Guest account, time source and wake-device changes can now also be undone from the Computer Doctor app

## [1.11.0] - 2026-11-11

- Added Computer Doctor to SauceStore
- Added Recovery > Readiness: BitLocker recovery key, Secure Boot 2023 certificates, Windows RE and Quick Machine Recovery
- Added the Old files tab to find unused files across your folders
- Space Map, Large Files, Startup and the right-click menu now follow the remote PC you pick
- Renamed from AWiper to Computer Doctor; settings, saved connections, scheduled tasks and backups move across on first start
