# Changelog

What changed in each release. `tools\Release.ps1` moves the lines under **Unreleased** into the new version and uses
them as the GitHub release notes, which SauceStore shows as the app's version history.

## [Unreleased]

- Added cleaner rules that need no admin rights: Internet cache, Store app caches, browser service worker caches, Visual Studio Code, Slack, Spotify, OneDrive logs, and npm, pip, NuGet and Yarn caches
- Added "Other apps' logs and temp files" (on by default, files older than 7 days) and "Other apps' caches", found by looking in your profile and shown per app in Analyze
- Added "Program logs (all users)": old ProgramData logs (admin, on by default); "Setup and CBS logs" is now "Windows logs" (older than 30 days, on by default)
- Added Automatic cleanup in the Cleaner: the rules you choose run on a schedule for your account, without admin rights (also -AutoClean)
- Added a prompt to close apps that hold back a cleanup (they close normally, never forced); automatic cleanup asks in a small popup
- Added "Report for an administrator" in the Cleaner: a page with the cleanups that need admin rights and short steps, also copied as text
- Added "Highlight what you can clean" on the Space Map: green for junk you can clean, red for folders your account can't delete
- Added an "installed for" filter to Programs (All, Just me, All users)

## [1.11.1] - 2026-11-18

- Fixed backups not keeping an older version of folders deleted since the last backup
- Fixed the Health Check marking a disk whose health is "Unknown" (often in a USB enclosure) as a problem; it now shows N/A
- Fixed: firewall, SMB1, Guest account, time source and wake-device changes can now also be undone from the Computer Doctor app

## [1.11.0] - 2026-11-11

- Added Computer Doctor to SauceStore
- Added Recovery > Readiness: BitLocker recovery key, Secure Boot 2023 certificates, Windows RE and Quick Machine Recovery
- Added the Old files tab to find unused files across your folders
- Space Map, Large Files, Startup and the right-click menu now follow the remote PC you pick
- Renamed from AWiper to Computer Doctor; settings, saved connections, scheduled tasks and backups move across on first start
