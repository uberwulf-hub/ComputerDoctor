# Computer Doctor

System cleanup, health check, debloat, recovery and repair toolkit for Windows, with a WPF interface — written as a single PowerShell script. Works on this PC or on a remote computer over PowerShell remoting, with or without a window, and **with or without internet**.

| View         | What it does |
|--------------|--------------|
| Dashboard    | Drive usage gauges, system summary, quick actions |
| Health Check | Checks (disks incl. NVMe health, crashes, hardware errors, stability, devices, battery, antivirus...), Events, Startup time, Security, Privacy, Crashes, Sleep |
| Cleaner      | Analyze / clean temp files, caches, error reports, crash dumps, update and Delivery Optimization caches, GPU and Steam shader caches (every Steam library), Recycle Bin. Emptying the Recycle Bin (permanent) and deleting blue-screen memory dumps (needed by Crashes) are off by default |
| Space Map    | SpaceMonger-style nested treemap of any drive or folder (drill down, recycle), with totals by kind (videos, pictures, installers, archives...) and by extension |
| Large Files  | **Largest** — the 1,000 largest files from the last scan. **Old files** — files in your Downloads, Desktop, Documents, Pictures, Videos, Music or any folder you add, not modified or opened for 30 days to 2 years, filtered by size and kind; only obvious leftovers (installers and disk images in Downloads, archives already extracted) are pre-ticked, and OneDrive files are labelled. **Duplicates** — exact copies (size, then a hash of the first 64 KB, then full SHA-256) or similar photos (perceptual hash). Searchable, recycle or export |
| Recovery     | Recycle Bin restore, previous versions, native NTFS undelete, restore points, versioned folder backup, deep scan with Windows File Recovery. **Readiness**: BitLocker recovery key, Secure Boot 2023 certificates, Windows RE / Quick Machine Recovery, restore points and backup |
| Startup      | Enable / disable startup entries (same `StartupApproved` switches Task Manager uses). **Right-click menu** tab: turn off menu entries programs added (shell extensions and commands), with undo |
| Programs     | Installed software list with size, search and uninstall |
| Drivers      | Installed drivers with vendor, age and problems; updates from Windows Update; vendor and PC-maker download pages; driver backup / restore. **Windows updates** tab: missing-update scan online or offline, install from Resources |
| IT Admin     | User profiles, printers, helpdesk actions, software push, security baseline audit, time sync and LAN speed test |
| BIOS         | Firmware version, boot mode, Secure Boot, TPM, virtualization, boot order, and full BIOS setup options on Dell / HP / Lenovo business PCs - view only |
| Debloat      | Remove preinstalled Store apps; turn off ads, suggestions, Bing in Start, Copilot, Recall, Widgets and more |
| Rebloat      | Put back removed apps, set debloat tweaks back to Windows defaults, undo history |
| Tools        | Offline kit, quick fixes, repair and maintenance (see below), plus the activity log |

### Health Check

A read-only check that works offline and on remote PCs: disk health and reliability counters, SATA SMART failure prediction, free space, blue screens and unexpected shutdowns (30 days), WHEA hardware errors, the last memory-test result, Reliability Monitor's stability index, devices with driver problems, battery wear, Defender status and definition age (or a third-party antivirus), pending restart and uptime, and whether the local gateway answers. It also checks the **Secure Boot 2023 certificate** rollover, whether the **BitLocker recovery key** is backed up, and whether **Windows RE** is enabled (see Recovery > Readiness). On Windows 10 it checks **Windows 11 readiness** (processor, memory, disk, UEFI, Secure Boot, TPM 2.0) and **Extended Security Updates** eligibility (KB5126256, latest update, account and join state). Fleet inventory reports the same. Each row has a status, the evidence and — where it helps — a button (Cleaner, Reliability Monitor, memory test, Device Manager, Defender update). Checks whose data isn't available on the hardware show **N/A** and are never counted as healthy. Reports save as HTML or JSON. NVMe drives are read through their own SMART / health log (percentage used, spare capacity, temperature, media errors, unsafe shutdowns, data written) via the in-box Windows driver — no extra software.

The other Health Check tabs:

- **Events** — groups the last 7 or 30 days of event-log trouble (blue screens, unexpected restarts, disk and file-system errors, hardware errors, crashing apps and services, failed updates, time-sync and Group Policy failures, failed sign-ins) with what each means and what to do. **Create support bundle** zips the System / Application logs, system and network info, drivers, programs and Computer Doctor's reports for a technician.
- **Startup time** — a chart of recent startups (time to desktop vs. settling) and the apps, drivers and services Windows says slowed them, linked to the Startup manager (needs admin).
- **Security** — about 20 checks (firewall, Defender, SMB1, LLMNR, Guest, admins, Remote Desktop / NLA, PowerShell logging, AutoRun, UAC, LSA protection, Credential Guard, BitLocker, LAPS, shares, open ports, expiring certificates, USB storage). A short list of safe, reversible fixes can be applied — each goes into the undo history; settings enforced by Group Policy are labelled.
- **Crashes** — reads the blue-screen dumps (and the event log when a dump wasn't kept), names each bug check in plain English (e.g. *0x124 = the hardware reported a fatal error*) and links the suggested fix: memory test, drivers, disk check, system-file repair, BIOS update.
- **Sleep** — what woke the PC and when, which devices may wake it (with a reversible *stop this one waking it*), what's keeping it awake right now, wake timers and available sleep states, plus the battery and sleep-study reports.
- **Privacy** — which apps last used the camera, microphone or location (and whether they're using them now), plus a report-only sweep for forced browser extensions, hijacked search / home-page policies, unsigned startup programs and scheduled tasks in user folders, proxies and hosts-file redirects.

### Drivers

Lists every installed driver with the company it comes from, its version and date, and devices Windows reports problems for. Built-in Windows drivers are hidden by default; third-party drivers older than three years are flagged.

- **Check for updates** asks **Windows Update** which driver updates this PC is offered (including BIOS/firmware updates the PC maker publishes there) and matches them to devices by hardware ID. **Install checked updates** installs them through Windows Update only — Microsoft-signed, with a restore point first. Computer Doctor deliberately doesn't use third-party "driver updater" databases.
- **Where a driver comes from** — *Vendor's site* opens the chip maker's download page (Intel, NVIDIA, AMD, Realtek, Qualcomm, Samsung, Logitech); the header button opens **the PC maker's driver page for this exact model** (Dell, HP, Lenovo, MSI, ASUS, Acer, Gigabyte, Surface, Framework). On laptops the maker's page is usually the right source for audio, touchpad and power drivers. Installed maker tools (MSI Center, Dell Command Update, Lenovo Vantage, NVIDIA App...) are listed.
- **Search Update Catalog** looks the device's hardware ID up in the Microsoft Update Catalog; **Copy hardware ID** helps on an offline PC.
- **Back up drivers** exports every third-party driver (`pnputil /export-driver`) — into `Resources\drivers\<Maker>_<Model>` when a Resources folder exists — and **Install from folder** puts them back (`pnputil /add-driver /subdirs /install`), e.g. after reinstalling Windows with no internet.

### BIOS

A view-only look at the firmware: maker, version and age, UEFI or legacy boot, Secure Boot, TPM version and state, virtualization-based security, CPU virtualization (VT-x / AMD-V), and the UEFI boot order. On Dell, HP and Lenovo business PCs, which publish their setup options to Windows, **every BIOS setup option and its current value** is listed too. Exports to CSV or JSON. **Restart into BIOS setup** reboots straight into the UEFI setup screen. Computer Doctor never changes BIOS settings.

**BIOS updates** — **Find BIOS update** opens the PC maker's support page for this exact model (or the motherboard maker's for custom-built PCs), **Check Windows Update** shows whether Windows Update already offers a BIOS / firmware update, and when BitLocker is on, **Suspend BitLocker for 1 restart** prevents the recovery-key prompt after flashing.

### IT Admin

- **User profiles** — every profile with its real last sign-in, size and status (temporary / corrupted profiles flagged); check the ones unused for N days and remove them (typed confirmation; profiles in use can't be selected).
- **Printers** — printers, ports and drivers, with leftovers no printer uses; remove checked items, add a printer by IP address, reset the print spooler and clear stuck jobs.
- **Helpdesk** — signed-in sessions and the heaviest processes: send a message, sign a user out, end a process, schedule or cancel a restart with a countdown, and launch Remote Assistance or a Remote Desktop shadow (the user is asked to allow it).
- **Software push** — installs an `.msi` or `.exe` on several PCs: the file is copied to each one, hash-checked and run silently there (no file share or credential double-hop), with plain-English results for each MSI exit code.
- **Baseline audit** — checks the PC against a security baseline in [HardeningKitty](https://github.com/scipag/HardeningKitty) CSV format (Microsoft, CIS, BSI, DoD lists): compliance score, failed settings by severity, CSV export. Audit only.
- **Time and network** — time-sync status, point PCs at a local time server (undoable), and a LAN speed test that copies 256 MB to another PC and back.

Most of these work on the remote PC selected in the title bar.

### Tools

- **Offline kit** — find, create, verify and hash a Resources folder (see [Offline use](#offline-use)); update Defender from `Resources\defs`.
- **Automation** — **Scheduled maintenance** runs a profile daily or weekly as SYSTEM from an admin-only copy of Computer Doctor, saving each run's JSON results (e.g. to a shared folder for central collection).
- **Fleet** — inventory several PCs over WinRM (hardware, serial, BIOS, Windows build, security state, programs) into one HTML / CSV / JSON report, with changes since the previous run.
- **Quick fixes** — flush DNS, Group Policy update (`gpupdate /force`), restart Explorer, reset default app associations, empty Recycle Bin
- **Repair** — System File Checker (`sfc /scannow`), DISM `/RestoreHealth` (from Windows Update, or offline from Windows media), .NET Framework 3.5, reset Windows Update, repair the Configuration Manager client (Software Center)
- **Maintenance** — component store cleanup, restore points, disable hibernation, Disk Cleanup, Storage Sense

### Debloat

Apps are matched against a curated list; recommended removals are pre-checked and anything you might still use (Outlook, Teams for work, Phone Link, Xbox, Quick Assist...) is left unchecked with a note. **Show all apps** lists every removable Store app except a protected core set (Store, App Installer, Photos, Calculator, codecs, runtimes...). When running as admin, apps are removed for all users and, optionally, the provisioned copy is removed so new accounts don't get it.

Tweaks show an **ON** badge when they're already applied. By default a restore point is created first (see Restore points).

### Rebloat

Changed your mind? **Rebloat** lists every catalog app that's missing for your account and puts it back:

- **Windows copy** — if the app is still on disk (provisioned, or installed for another user), it's re-registered instantly with no download (needs admin to find these copies). Works offline.
- **Microsoft Store** — otherwise it's reinstalled with `winget` using the app's verified Store ID.
- **Store search** — apps without a known ID open in the Microsoft Store so you can install them there. Apps Microsoft has retired (Cortana, People, Skype...) are only offered if a copy is still on disk.

The right-hand panel lists the debloat tweaks currently in effect and sets the checked ones back to Windows defaults. **Undo history** puts settings back *exactly* as they were before any tweak Computer Doctor applied — from the window or the command line.

### Recovery

- **Drive check** — every drive gets a recoverability rating from its media type, bus and TRIM setting. Internal SSDs with TRIM (the Windows default) usually erase deleted data within minutes; USB sticks, SD cards and hard disks are good candidates.
- **Recycle Bin** — reads the `$Recycle.Bin` folders directly, so it shows every user's deleted items (as admin) and works on remote PCs. Restore to the original location or another folder; nothing is ever overwritten.
- **Previous versions** — lists Volume Shadow Copy snapshots (System Protection / restore points), opens one in Explorer, or compares a folder against a snapshot to list files that have since been deleted or changed, then restores them.
- **Undelete** — Computer Doctor's own NTFS undelete. It reads the drive's master file table directly (read-only, needs admin), lists deleted files with their original folders (including deleted folders), and rates each one — *Excellent* (data stored in the file record), *Good* (all clusters still free), *Poor* (partly overwritten), *Overwritten*. Recovered files keep their folder layout and timestamps, must go to a different drive, and never overwrite anything. It can also scan a raw NTFS volume image (`.img`/`.dd`) — the safe way to work on a failing drive.
- **Backup** — keeps chosen folders (one click adds Documents, Pictures, Desktop, Videos, Music) mirrored on an external drive under `ComputerDoctor-Backup\<PC>`, and moves files that change or get deleted into dated version folders first (keeps the last N runs). The drive is identified by its volume ID, so a different drive that later takes the same letter is never written to. Optional daily schedule (a scheduled task running `ComputerDoctor.ps1 -Backup -Yes`).
- **Restore points** — list, create (without Windows' one-per-24-hours limit), delete, turn System Protection on, and set how much space restore points may use. Optionally creates one automatically before removing apps or applying tweaks.
- **Readiness** — *if this PC won't start tomorrow, can you get it back?*
  - **BitLocker recovery key:** shows which drives are encrypted (including 24H2's automatic device encryption), whether a recovery password exists and whether Windows recorded a backup to Active Directory or Entra ID. You can save the key to a file you choose and print it, add a missing recovery password, or back it up to AD / Entra. The key is never written to Computer Doctor's logs.
  - **Secure Boot certificates:** Microsoft's 2011 Secure Boot certificates expire in 2026, the last on Oct 19. Computer Doctor shows the 2023 certificate status from Windows' servicing keys, TPM-WMI events and (as admin) the firmware's DB and KEK, and explains blocks such as "a BIOS update is needed first". It can start Microsoft's documented update after confirming the BitLocker key is saved, suspending BitLocker for two restarts first.
  - **Recovery environment:** Windows RE (with a button to turn it back on), Quick Machine Recovery and Point-in-time Restore.
  - **Restore points and backup:** restore point age and the last Computer Doctor backup.
  - **Windows 10:** eligibility for consumer Extended Security Updates, which now run through Oct 12, 2027.
  - **Advanced Startup:** a button to restart into the Windows recovery menu.

  The same checks appear in the Health Check and fleet inventory.
- **Deep scan** — a front-end for Microsoft's free [Windows File Recovery](https://apps.microsoft.com/detail/9N26S50LN705) (`winfr`): installs it if needed, builds the command, refuses to save to the drive being scanned, and streams progress to the activity log. Offline, Computer Doctor points you to Undelete instead.

## Offline use

Computer Doctor checks for internet at startup using the result Windows' own connectivity check (NCSI) already has. The title-bar button shows **Online**, **No internet** or **Offline mode** — click it to force offline mode (also `-Offline`). Internet-only actions are then disabled with a tooltip naming the offline alternative.

Offline alternatives come from a **Resources folder**, found automatically next to `ComputerDoctor.ps1`, at `<any drive>:\ComputerDoctor\Resources` (so a USB stick becomes a repair kit), or wherever you point it in Tools → Offline kit:

| Folder     | Used for |
|------------|----------|
| `ISO\`     | Windows install media (`.iso` or extracted files) for **DISM repair** and **.NET 3.5** with `/LimitAccess`. Computer Doctor picks the image matching this PC's edition and warns when the media is older than the PC's updates. |
| `defs\`    | Microsoft Defender offline definitions (`x64\mpam-fe.exe`) — the Health Check's Defender button installs them. |
| `drivers\`, `updates\`, `apps\`, `appx\`, `LOF\`, `tools\` | Reserved for upcoming offline driver, update and app features; bring your own tools (Sysinternals can't be redistributed). |

**Build manifest** hashes every file into `manifest.json` (SHA-256); **Verify Resources** checks a stick against it before use.

**The air-gap round trip** keeps an isolated PC current with one USB stick:

1. On the offline PC: **Drivers > Windows updates > Scan offline** (uses `updates\wsusscn2.cab`), then **Export needs list** — missing updates, problem devices, Defender age and apps to put back go to `needs\<PC>.json`.
2. On any connected PC: **Tools > Fetch downloads** (or `ComputerDoctor.ps1 -Fetch -Yes`) downloads exactly that — update packages from the Microsoft Update Catalog (prerequisites included), drivers for the problem devices, Store app packages, fresh Defender definitions and scan file, and baseline lists — and refreshes the manifest.
3. Back on the offline PC: **Install from Resources**, Defender offline update, **Install from folder** for drivers, and Rebloat (staged apps show as *Resources*).

## Command line (headless)

Any of these parameters runs Computer Doctor without a window — from a script, a scheduled task, or against other PCs. Changes are **only previewed unless `-Yes` is given**.

```powershell
.\ComputerDoctor.ps1 -HealthCheck                                   # health check in the console
.\ComputerDoctor.ps1 -HealthCheck -Format Json -OutFile health.json # machine-readable
.\ComputerDoctor.ps1 -Analyze -Clean Default                        # how much would be cleaned
.\ComputerDoctor.ps1 -Clean Default -ApplyTweak AdId,Suggestions -Yes
.\ComputerDoctor.ps1 -RemoveApp Recommended -Yes                    # recommended Store app removals
.\ComputerDoctor.ps1 -Config .\monthly.json -Yes                    # everything from a profile
.\ComputerDoctor.ps1 -ComputerName PC042 -UseSavedCredential -Clean WinTemp,WerSys -Yes
.\ComputerDoctor.ps1 -CheckDrivers                                  # driver problems, Windows Update driver offers, maker page
.\ComputerDoctor.ps1 -Inventory PC01,PC02,localhost                 # fleet inventory report + changes since last run
.\ComputerDoctor.ps1 -Backup -Yes                                   # run the backup set up in the window
.\ComputerDoctor.ps1 -ExportNeeds                                   # offline PC: save what it's missing to Resources\needs
.\ComputerDoctor.ps1 -Fetch -Yes                                    # connected PC: download it all into Resources
.\ComputerDoctor.ps1 -Config p.json -Yes -OutFile \\srv\drop\{computer}-{date}.json   # tokens expand per run
.\ComputerDoctor.ps1 -ListRules    # also -ListTweaks, -ListApps
```

A profile is plain JSON and may only reference built-in IDs:

```json
{ "RestorePoint": "Monthly maintenance", "Clean": ["Default"], "ApplyTweaks": ["AdId", "Suggestions"],
  "RemoveApps": ["Recommended"], "HealthCheck": true }
```

Exit codes: `0` OK · `1` a step failed · `2` bad arguments · `3` health warnings · `4` health problems · `5` PowerShell is in ConstrainedLanguage mode. Headless runs never show a UAC prompt; run them from an elevated prompt (or as SYSTEM in a scheduled task) for admin-only items.

## Remote computers

Click **This PC** in the title bar to target another computer by hostname, FQDN or IP address (or use `-ComputerName` on the command line).

- **Domain (optional)** is appended to short hostnames and to usernames without a domain.
- **Current credentials** uses your Windows sign-in (Kerberos — use the computer name, not an IP).
- **Other credentials** accepts `DOMAIN\user` or `user@domain`. Tick **Save to Windows Credential Manager** to store them as a generic credential named `ComputerDoctor:<host>`; they're filled in automatically next time and can be removed from the dialog or from Credential Manager.
- Connecting by IP address or to a non-domain PC needs the target in WinRM `TrustedHosts`; the dialog offers to add it.

The remote PC needs PowerShell remoting enabled (`Enable-PSRemoting -Force`) and your account must be an administrator there.

When a remote computer is targeted, these run on it:
- Health Check (and its Events, Startup time and Security tabs)
- the driver list and update check
- the BIOS view
- IT Admin
- Tools (except Explorer, Recycle Bin, Disk Cleanup, Storage Sense, and offline media repair)
- machine-wide Cleaner rules, Debloat apps and machine-wide tweaks
- the Programs list, Recycle Bin restore and Recovery > Readiness

**Space Map and Large Files** scan the remote PC's drives:
- **How:** through its admin share (`\\PC\C$`, using the saved credentials), so the treemap, drill-down and Largest list work as they do locally. If the share isn't reachable (for example, File and Printer Sharing is blocked), Computer Doctor runs the scan on that PC over WinRM and brings back a trimmed tree: everything down to about 0.0025% of the scanned size, plus the 1,000 largest files and totals by type.
- **Deleting:** files on another PC can't go to a Recycle Bin, so removing them there is permanent and asks first. System locations are refused.
- **Switching:** a banner shows which PC is being scanned, with a switch back to this PC.

**Startup and the Right-click menu** list and change the remote PC's all-users entries. Each user's own entries are only shown when Computer Doctor runs on that PC, because over WinRM "current user" is the account Computer Doctor connected with.

Dashboard, per-user Cleaner rules, Old files and Duplicates always stay on this PC. Every view's title says which PC it's showing.

## Safety and audit trail

- Nothing is deleted without an Analyze / confirm step; headless runs need `-Yes`.
- Files removed from the Space Map and Large Files views go to the Recycle Bin. Duplicates won't let you recycle every copy in a group, and cloud-only (OneDrive "free up space") files are skipped so nothing gets downloaded.
- Right-click menu changes are registry values recorded in the undo history.
- Browser history, cookies and saved passwords are never touched.
- A restore point is created before app removal and tweaks (can be turned off), and every tweak's previous values go to the undo journal.
- **Action log** — every change (who, when, which computer, what, result) is appended to `%ProgramData%\ComputerDoctor\Logs\actions-<yyyy-MM>.jsonl` and, when elevated, to the Application event log (source `ComputerDoctor`) for event forwarding or a SIEM.
- **Locked-down PCs** — under App Control (WDAC) or AppLocker, unsigned scripts run in ConstrainedLanguage mode, which blocks the features Computer Doctor needs. Computer Doctor detects this and explains that the script must be signed by a publisher the policy trusts (keep settings in JSON profiles — editing a signed script breaks its signature).

## Tests

```powershell
.\tests\Test-Cli.ps1                                      # no admin: exercises the headless mode
.\tests\Test-AirGap.ps1                                   # internet: needs list -> catalog driver + baselines -> manifest
.\tests\Test-Backup.ps1                                   # no admin: backup versions, mirror and drive guard
.\tests\Test-OldFiles.ps1                                 # no admin: old-files age / size limits, skipped folders, extracted archives
.\tests\Test-UndeleteSynthetic.ps1                        # no admin: builds a tiny NTFS image and checks the undelete engine
.\tests\Test-UndeleteLive.ps1 -Drive H: -Dest C:\Temp\R   # admin: deletes a test file on H:, recovers it, compares hashes
```

## Releasing (SauceStore)

Computer Doctor is listed in SauceStore through `saucestore.json` (name, description, `store\icon.png`, requirements
and the release file, `ComputerDoctor.ps1`). Add what changed under **Unreleased** in [CHANGELOG.md](CHANGELOG.md), then:

```powershell
.\tools\Release.ps1 -Version X.Y.Z
```

It runs the no-admin checks (`Test-Cli`, `Test-Backup`, `Test-OldFiles`), writes the version into the script, moves
the changelog lines into the new version, commits and tags `vX.Y.Z`, and makes the GitHub release with
`ComputerDoctor.ps1` attached (needs `gh`). SauceStore lists it within about 10 minutes and shows the changelog lines as
the version history. `-WhatIf` runs the checks and copies the script into `build\` only.

## Requirements

- Windows 10 or 11
- Windows PowerShell 5.1, or PowerShell 7+ on Windows

## Usage

```powershell
.\ComputerDoctor.ps1
```

On launch Computer Doctor asks for administrator rights (UAC). If the prompt is declined or elevation isn't possible, it keeps running with standard permissions and disables the items that need admin rights.

If script execution is blocked by policy:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\ComputerDoctor.ps1
```

| Parameter      | Description |
|----------------|-------------|
| `-NoElevate`   | Skip the UAC prompt and run with the current permissions. |
| `-ShowConsole` | Keep the PowerShell console window visible (useful for troubleshooting). |
| `-Offline`     | Never use the internet; use the Resources folder. |
| `-Resources`   | Path to a Resources folder. |

See [Command line](#command-line-headless) for the headless parameters, or `Get-Help .\ComputerDoctor.ps1 -Full`.

## Data

- `%LOCALAPPDATA%\ComputerDoctor\ComputerDoctor.log` — activity log
- `%LOCALAPPDATA%\ComputerDoctor\state.json` — settings, running totals, recently used remote computers
- `%LOCALAPPDATA%\ComputerDoctor\undo.json` — undo journal (previous values of every tweak)
- `%ProgramData%\ComputerDoctor\Logs\actions-*.jsonl` — action log

Saved remote credentials live in Windows Credential Manager, never in Computer Doctor's own files.

### Upgrading from AWiper

Computer Doctor used to be called AWiper. The first time it starts, it brings everything across and leaves the old copies in place:

- `%LOCALAPPDATA%\AWiper` is copied to `%LOCALAPPDATA%\ComputerDoctor` (`AWiper.log` becomes `ComputerDoctor.log`; open snapshot links are skipped), and `%ProgramData%\AWiper\Logs` to `%ProgramData%\ComputerDoctor\Logs`.
- Saved connections (`AWiper:<host>` in Credential Manager) move to `ComputerDoctor:<host>`.
- The **AWiper Backup** and **AWiper Maintenance** scheduled tasks are replaced by **ComputerDoctor Backup** and **ComputerDoctor Maintenance** with the same schedule (maintenance needs Computer Doctor to run as administrator once).
- The next backup moves `AWiper-Backup\<PC>` on the backup drive to `ComputerDoctor-Backup\<PC>`, older versions included.
- A Resources folder at `<drive>:\AWiper\Resources` is still found.
- The old `AWiper` event log source is left in place so earlier entries stay readable.

## Roadmap

What's planned next is in [ROADMAP.md](ROADMAP.md), with one [GitHub issue](https://github.com/uberwulf-hub/ComputerDoctor/issues) per item.

## Credits

The Debloat view was inspired by [Win11Debloat](https://github.com/Raphire/Win11Debloat).

## License

[MIT](LICENSE)
