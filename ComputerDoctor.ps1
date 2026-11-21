<#
.SYNOPSIS
    Computer Doctor - system cleanup and disk space analyzer with a WPF interface.

.DESCRIPTION
    Computer Doctor bundles the most useful parts of tools like CCleaner and SpaceMonger:

      * Dashboard    - drive usage gauges, system summary, quick actions
      * Health Check - disks (incl. the NVMe health log), crashes, hardware errors, stability, devices, battery,
                       antivirus, pending restart, network; tabs for event-log triage + support bundle, startup-time
                       history, a security scorecard with reversible fixes, camera / mic / location use + adware sweep,
                       blue-screen dump analysis, and sleep / wake troubleshooting
      * Cleaner      - analyze / clean temp files, caches, update leftovers, dumps, recycle bin
      * Space Map    - SpaceMonger-style nested treemap of any drive or folder (drill down, recycle)
      * Large Files  - the 1,000 largest files from the last scan, searchable, recycle or export
      * Recovery     - restore from any user's Recycle Bin, find deleted files in shadow-copy snapshots,
                       native NTFS undelete (reads the MFT directly), restore-point manager, versioned folder backup, deep scan with
                       Windows File Recovery, per-drive recoverability (SSD/TRIM) check
      * Startup      - enable / disable startup entries (same StartupApproved switches Task Manager uses)
      * Programs     - installed software list with size, search and uninstall
      * Drivers      - installed drivers with their vendor, age and problems; updates from Windows Update;
                       vendor / PC maker download pages, Update Catalog lookup, driver backup and restore
      * Drivers also has a Windows updates tab: missing-update scan online or offline (wsusscn2.cab) and install
                       of .msu packages from the Resources folder
      * IT Admin     - user profiles (stale-profile cleanup), printers (add by IP, leftovers, spooler), helpdesk (sessions,
                       messages, restart, Remote Assistance), software push, security baseline audit, time sync, LAN speed
      * BIOS         - firmware version, boot mode, Secure Boot, TPM, virtualization, boot order and (Dell, HP,
                       Lenovo business PCs) every BIOS setup option - view only; restart into BIOS setup
      * Debloat      - remove preinstalled Store apps, turn off ads, suggestions, Copilot and other extras
      * Rebloat      - reinstall removed apps (from the copy on disk or the Microsoft Store), restore default settings
      * Tools        - quick fixes (DNS, Group Policy, Explorer), repair (SFC, DISM, Windows Update reset,
                       ConfigMgr client), maintenance (component store, restore point, hibernation), activity log

    Computer Doctor can also work on another computer over PowerShell remoting (WinRM). Pick the target from
    the button in the title bar; credentials can be saved to Windows Credential Manager.

    Offline: Computer Doctor detects whether the internet is reachable (or use offline mode / -Offline) and then
    uses a Resources folder (next to the script, or <drive>:\ComputerDoctor\Resources on a USB stick) for
    Windows repair media, Defender definitions and more. Every change is written to an action log
    (%ProgramData%\ComputerDoctor\Logs, plus the Application event log when elevated) and tweaks can be undone.

    Headless: pass any of the command-line parameters below to run without a window, e.g. from a
    scheduled task or across a fleet with -ComputerName. Changes are only previewed unless -Yes is given.
    Exit codes: 0 OK, 1 a step failed, 2 bad arguments, 3 health warnings, 4 health problems,
    5 PowerShell is in ConstrainedLanguage mode (App Control / AppLocker; sign the script).

    On launch Computer Doctor asks for administrator rights (UAC). If the prompt is declined or
    elevation is not possible, it keeps running with standard permissions and simply
    disables the items that need admin rights.

    Nothing is deleted without an Analyze/confirm step. Files removed from the Space Map
    and Large Files views go to the Recycle Bin. Browser history, cookies and saved
    passwords are never touched.

.PARAMETER NoElevate
    Skip the UAC prompt and run with the current permissions.

.PARAMETER ShowConsole
    Keep the PowerShell console window visible (useful for troubleshooting).

.PARAMETER Elevated
    Internal - set when Computer Doctor relaunches itself elevated, prevents a prompt loop.

.PARAMETER Config
    Headless: a JSON profile, e.g. {"Clean":["Default"],"ApplyTweaks":["AdId","FileExt"],"RemoveApps":["Recommended"],
    "RestorePoint":"Monthly maintenance","HealthCheck":true}. Only built-in rule / tweak IDs are accepted.

.PARAMETER Analyze
    Headless: measure cleaning rules (the -Clean list, or the defaults). Nothing is deleted.

.PARAMETER Clean
    Headless: cleaning rule IDs (see -ListRules), or Default / All.

.PARAMETER HealthCheck
    Headless: run the health check. Exit code 3 = warnings, 4 = problems.

.PARAMETER ApplyTweak
    Headless: tweak IDs to apply (see -ListTweaks). The previous values are saved for undo.

.PARAMETER RevertTweak
    Headless: tweak IDs to set back to the Windows default.

.PARAMETER RemoveApp
    Headless: Store package names or wildcards (see -ListApps), or Recommended.

.PARAMETER RestorePoint
    Headless: create a restore point with this description before the other changes.

.PARAMETER CheckDrivers
    Headless: list devices with driver problems, driver updates Windows Update offers, and old third-party drivers.

.PARAMETER Backup
    Headless: run the folder backup set up in Recovery > Backup (what the daily schedule runs). Needs -Yes.

.PARAMETER Inventory
    Headless: fleet inventory of these PCs over WinRM (saved credentials are used). Writes an HTML / CSV / JSON report
    to %LOCALAPPDATA%\ComputerDoctor\Inventory and lists changes since the previous run.

.PARAMETER ExportNeeds
    Headless, offline PC: scan for missing updates (offline scan file if present) and save a needs list to <Resources>\needs.

.PARAMETER Fetch
    Headless, connected PC: download what the needs lists ask for (updates, Store apps, drivers, Defender definitions,
    scan file, baseline lists) into the Resources folder. Needs -Yes.

.PARAMETER ComputerName
    Headless: run against another PC over WinRM. Use with -Credential or -UseSavedCredential.

.PARAMETER Offline
    Never use the internet; use the Resources folder instead.

.PARAMETER Format
    Headless output: Text (default) or Json.

.PARAMETER OutFile
    Headless: also save the results as JSON to this file.

.PARAMETER Yes
    Headless: actually make the changes. Without it they're only listed.

.EXAMPLE
    .\ComputerDoctor.ps1
    Prompts for admin rights, then opens the Computer Doctor window.

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\ComputerDoctor.ps1 -NoElevate

.EXAMPLE
    .\ComputerDoctor.ps1 -HealthCheck -Format Json -OutFile C:\Reports\health.json
    Runs the health check without a window and saves the result.

.EXAMPLE
    .\ComputerDoctor.ps1 -Clean Default -ApplyTweak AdId,Suggestions -Yes
    Cleans with the default rules and applies two tweaks (from an elevated prompt for the admin-only items).

.EXAMPLE
    .\ComputerDoctor.ps1 -ComputerName PC042 -UseSavedCredential -Clean WinTemp,WerSys -Yes
    Cleans machine-wide junk on another PC over WinRM.

.NOTES
    Name    : ComputerDoctor.ps1
    Version : 1.11.1
    Author  : Andrew Saulls
    Requires: Windows 10/11, Windows PowerShell 5.1 or PowerShell 7+ (Windows)
    Log     : %LOCALAPPDATA%\ComputerDoctor\ComputerDoctor.log
#>
[CmdletBinding()]
param(
    [switch]$NoElevate,
    [switch]$ShowConsole,
    [switch]$Elevated,

    # ---- Headless (command-line) mode. Any of these runs Computer Doctor without a window.
    [string]$Config,                 # JSON profile: Clean, ApplyTweaks, RevertTweaks, RemoveApps, RestorePoint, HealthCheck
    [switch]$Analyze,                # measure cleaning rules (nothing is deleted)
    [string[]]$Clean,                # rule IDs to clean, or 'Default' / 'All'
    [switch]$HealthCheck,            # run the health check
    [string[]]$ApplyTweak,           # tweak IDs to apply
    [string[]]$RevertTweak,          # tweak IDs to set back to Windows defaults
    [string[]]$RemoveApp,            # Store package names / patterns, or 'Recommended'
    [string]$RestorePoint,           # create a restore point with this description
    [switch]$ListRules,
    [switch]$ListTweaks,
    [switch]$ListApps,
    [switch]$CheckDrivers,           # list driver problems and updates Windows Update offers
    [switch]$Backup,                 # run the folder backup set up in the window (used by the schedule)
    [switch]$AutoClean,              # run the automatic cleanup set up in Cleaner (used by its schedule; no admin, no prompts)
    [string[]]$Inventory,            # fleet inventory of these PCs (names / addresses, 'localhost' for this one)
    [switch]$ExportNeeds,            # offline PC: write what it is missing to <Resources>\needs\<PC>.json
    [switch]$Fetch,                  # connected PC: download everything the needs lists in <Resources> ask for
    [string]$ComputerName,           # run against a remote PC over WinRM
    [pscredential]$Credential,
    [switch]$UseSavedCredential,     # use credentials saved for -ComputerName in Credential Manager
    [switch]$Offline,                # never use the internet
    [string]$Resources,              # path to a Computer Doctor Resources folder
    [ValidateSet('Text', 'Json')][string]$Format = 'Text',
    [string]$OutFile,                # also write the results (JSON) to this file
    [switch]$Yes                     # actually make changes (without it, changes are only listed)
)

$ErrorActionPreference = 'Stop'
$script:AppVersion = '1.11.1'
$script:CliMode = [bool]($Config -or $Analyze -or $Clean -or $HealthCheck -or $ApplyTweak -or $RevertTweak -or $RemoveApp -or
                         $RestorePoint -or $ListRules -or $ListTweaks -or $ListApps -or $CheckDrivers -or $Backup -or $AutoClean -or $Inventory -or $ExportNeeds -or $Fetch)

# Under App Control / AppLocker, unsigned scripts run in ConstrainedLanguage mode, which blocks WPF,
# embedded C# and most .NET/COM use. Explain instead of failing with a wall of red text.
if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    Write-Host ''
    Write-Host "Computer Doctor can't run here: PowerShell is in $($ExecutionContext.SessionState.LanguageMode) mode." -ForegroundColor Yellow
    Write-Host 'This PC enforces App Control (WDAC) or AppLocker, which only allows trusted, signed scripts to use'
    Write-Host 'the features Computer Doctor needs. Ask your administrator to sign ComputerDoctor.ps1 with a certificate the policy'
    Write-Host 'trusts (keep settings in separate JSON profiles - editing a signed script breaks its signature).'
    if (-not $script:CliMode -and [Environment]::UserInteractive) { try { [void](Read-Host 'Press Enter to close') } catch { } }
    exit 5
}

#region ---------------------------------------------------------------- Elevation / STA
function Test-AWAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AWRelaunchArgs {
    param([switch]$AddElevated, [switch]$AddNoElevate)
    $list = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', "`"$PSCommandPath`"")
    if ($AddElevated)  { $list += '-Elevated' }
    if ($AddNoElevate) { $list += '-NoElevate' }
    if ($ShowConsole)  { $list += '-ShowConsole' }
    $list
}

function Invoke-AWElevation {
    # Returns $true if an elevated copy was started, $false if UAC was declined / unavailable.
    if (-not $PSCommandPath) { return $false }
    $exe = (Get-Process -Id $PID).Path
    $style = if ($ShowConsole) { 'Normal' } else { 'Hidden' }
    try {
        Start-Process -FilePath $exe -ArgumentList (Get-AWRelaunchArgs -AddElevated) -Verb RunAs -WindowStyle $style -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

$script:IsAdmin = Test-AWAdmin
$script:ElevationNote = ''

if ($script:CliMode) {
    # Headless runs never pop a UAC prompt (output would land in a hidden window); admin-only work is skipped.
    if (-not $script:IsAdmin) { $script:ElevationNote = 'Not elevated - items that need administrator rights are skipped.' }
}
elseif (-not $script:IsAdmin -and -not $Elevated -and -not $NoElevate) {
    if (Invoke-AWElevation) { exit }
    $script:ElevationNote = 'Admin prompt was declined or unavailable - running with standard permissions.'
}
elseif (-not $script:IsAdmin -and $Elevated) {
    $script:ElevationNote = 'Elevation did not grant admin rights - running with standard permissions.'
}
elseif (-not $script:IsAdmin) {
    $script:ElevationNote = 'Running with standard permissions (-NoElevate).'
}

# WPF needs a single-threaded apartment. Relaunch with -STA if needed (same permission level).
if (-not $script:CliMode -and [System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    if ($PSCommandPath) {
        $exe = (Get-Process -Id $PID).Path
        Start-Process -FilePath $exe -ArgumentList (Get-AWRelaunchArgs -AddNoElevate) | Out-Null
        exit
    }
    throw 'Computer Doctor must run in an STA thread. Start PowerShell with -STA.'
}
#endregion

#region ---------------------------------------------------------------- Assemblies + native helpers
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic

if (-not ('ComputerDoctor.DiskScanner' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;

namespace ComputerDoctor
{
    public static class Fmt
    {
        public static string Size(long bytes)
        {
            if (bytes < 1024) return bytes + " B";
            string[] u = { "KB", "MB", "GB", "TB", "PB" };
            double d = bytes / 1024.0; int i = 0;
            while (d >= 1024 && i < u.Length - 1) { d /= 1024; i++; }
            string f = d >= 100 ? "0" : (d >= 10 ? "0.0" : "0.00");
            return d.ToString(f, CultureInfo.InvariantCulture) + " " + u[i];
        }
    }

    public class DiskNode
    {
        public DiskNode() { Children = new List<DiskNode>(); }
        public string Name { get; set; }
        public string FullPath { get; set; }
        public long Size { get; set; }
        public long FileCount { get; set; }
        public bool IsDir { get; set; }
        public bool IsGroup { get; set; }
        public DateTime Modified { get; set; }      // files only
        public bool Denied { get; set; }            // folder the scan couldn't read
        public DiskNode Parent { get; set; }
        public List<DiskNode> Children { get; set; }
        public string SizeText { get { return Fmt.Size(Size); } }
        public double PercentOfParent
        {
            get { return (Parent == null || Parent.Size <= 0) ? 100.0 : Size * 100.0 / Parent.Size; }
        }
        public string Kind { get { return IsGroup ? "Small files" : (IsDir ? "Folder" : "File"); } }
    }

    public class FileEntry
    {
        public string Name { get; set; }
        public string FullPath { get; set; }
        public string Folder { get; set; }
        public string Extension { get; set; }
        public long Size { get; set; }
        public DateTime Modified { get; set; }
        public bool IsChecked { get; set; }
        public string Status { get; set; }
        public string SizeText { get { return Fmt.Size(Size); } }
        public string ModifiedText { get { return Modified == DateTime.MinValue ? "" : Modified.ToString("yyyy-MM-dd HH:mm"); } }
    }

    public class DriverEntry
    {
        public bool IsChecked { get; set; }
        public string Name { get; set; }
        public string Class { get; set; }
        public string Provider { get; set; }
        public string Version { get; set; }
        public DateTime Date { get; set; }
        public string Inf { get; set; }
        public string DeviceId { get; set; }
        public string HardwareId { get; set; }
        public string Vendor { get; set; }
        public string VendorUrl { get; set; }
        public string Status { get; set; }
        public string UpdateText { get; set; }
        public string UpdateId { get; set; }
        public string Note { get; set; }
        public int ErrorCode { get; set; }
        public bool IsMicrosoft { get; set; }
        public bool HasUpdate { get; set; }
        public string DateText { get { return Date == DateTime.MinValue ? "" : Date.ToString("yyyy-MM-dd"); } }
        public int SortRank { get { return ErrorCode != 0 ? 0 : (HasUpdate ? 1 : 2); } }
    }

    public class SecItem
    {
        public bool IsChecked { get; set; }
        public string Id { get; set; }
        public string Name { get; set; }
        public string Status { get; set; }
        public string Detail { get; set; }
        public string Fix { get; set; }
        public bool Policy { get; set; }
        public bool CanFix { get { return !string.IsNullOrEmpty(Fix); } }
        public string StatusText { get { return Status == "NA" ? "N/A" : Status; } }
        public string PolicyText { get { return Policy ? "policy" : ""; } }
    }

    // General checkable row for the IT Admin and update lists.
    public class AdminRow
    {
        public bool IsChecked { get; set; }
        public bool CanCheck { get; set; }
        public string Kind { get; set; }
        public string Name { get; set; }
        public string Status { get; set; }
        public string Detail { get; set; }
        public string Key { get; set; }
        public string Path { get; set; }
        public long Size { get; set; }
        public DateTime When { get; set; }
        public string SizeText { get { return Size > 0 ? Fmt.Size(Size) : ""; } }
        public string WhenText { get { return When == DateTime.MinValue ? "" : When.ToString("yyyy-MM-dd HH:mm"); } }
        public int AgeDays { get { return When == DateTime.MinValue ? 99999 : (int)(DateTime.Now - When).TotalDays; } }
    }

    public class RecycleEntry
    {
        public bool IsChecked { get; set; }
        public string Name { get; set; }
        public string OriginalPath { get; set; }
        public string Folder { get; set; }
        public string Owner { get; set; }
        public string IPath { get; set; }
        public string RPath { get; set; }
        public bool IsDir { get; set; }
        public long Size { get; set; }
        public DateTime Deleted { get; set; }
        public string SizeText { get { return Fmt.Size(Size); } }
        public string DeletedText { get { return Deleted == DateTime.MinValue ? "" : Deleted.ToString("yyyy-MM-dd HH:mm"); } }
        public string Kind { get { return IsDir ? "Folder" : "File"; } }
    }

    public class AppEntry
    {
        public string Name { get; set; }
        public string Package { get; set; }
        public string FullName { get; set; }
        public string Version { get; set; }
        public string Publisher { get; set; }
        public string Category { get; set; }
        public string Note { get; set; }
        public bool Recommended { get; set; }
        public bool Provisioned { get; set; }
        public bool IsChecked { get; set; }
        public string Source { get; set; }
        public string Manifest { get; set; }
        public string StoreId { get; set; }
    }

    public class ExtStat
    {
        public string Extension { get; set; }
        public long Size { get; set; }
        public long Count { get; set; }
        public double Percent { get; set; }
        public double RelPercent { get; set; }
        public string SizeText { get { return Fmt.Size(Size); } }
        public string PercentText { get { return Percent.ToString("0.0", CultureInfo.InvariantCulture) + "%"; } }
    }

    public class TreeRect
    {
        public DiskNode Node { get; set; }
        public double X { get; set; }
        public double Y { get; set; }
        public double W { get; set; }
        public double H { get; set; }
    }

    public class DiskScanner
    {
        public long FilesScanned;
        public long FoldersScanned;
        public long BytesScanned;
        public long Errors;
        public long DeniedFolders;
        public volatile bool Cancel;
        public volatile string CurrentPath = "";
        public long SmallFileThreshold = 1048576;
        public int TopCount = 1000;
        public double ElapsedSeconds;
        public bool Completed;
        public DiskNode Root;
        public List<FileEntry> TopFiles = new List<FileEntry>();
        public List<ExtStat> ExtensionList = new List<ExtStat>();

        private List<FileEntry> top = new List<FileEntry>();
        private long topMin = 0;
        private Dictionary<string, ExtStat> ext = new Dictionary<string, ExtStat>(StringComparer.OrdinalIgnoreCase);

        private static int CompareFiles(FileEntry a, FileEntry b) { return b.Size.CompareTo(a.Size); }
        private static int CompareNodes(DiskNode a, DiskNode b) { return b.Size.CompareTo(a.Size); }

        public DiskNode Scan(string path)
        {
            var sw = System.Diagnostics.Stopwatch.StartNew();
            var di = new DirectoryInfo(path);
            var root = new DiskNode();
            root.Name = di.FullName; root.FullPath = di.FullName; root.IsDir = true;
            Root = root;
            try { ScanDir(di, root, 0); }
            finally
            {
                top.Sort(CompareFiles);
                if (top.Count > TopCount) top.RemoveRange(TopCount, top.Count - TopCount);
                TopFiles = top;
                var list = new List<ExtStat>(ext.Values);
                list.Sort(delegate (ExtStat a, ExtStat b) { return b.Size.CompareTo(a.Size); });
                long max = list.Count > 0 ? list[0].Size : 0;
                foreach (var e in list)
                {
                    e.Percent = root.Size > 0 ? e.Size * 100.0 / root.Size : 0;
                    e.RelPercent = max > 0 ? e.Size * 100.0 / max : 0;
                }
                ExtensionList = list;
                ElapsedSeconds = sw.Elapsed.TotalSeconds;
                Completed = !Cancel;
            }
            return root;
        }

        private void AddTop(FileInfo f, long len)
        {
            if (top.Count >= TopCount && len <= topMin) return;
            var fe = new FileEntry();
            fe.Name = f.Name; fe.FullPath = f.FullName; fe.Size = len;
            try { fe.Folder = f.DirectoryName; } catch { fe.Folder = ""; }
            try { fe.Extension = f.Extension.ToLowerInvariant(); } catch { fe.Extension = ""; }
            try { fe.Modified = f.LastWriteTime; } catch { fe.Modified = DateTime.MinValue; }
            top.Add(fe);
            if (top.Count >= TopCount * 2)
            {
                top.Sort(CompareFiles);
                top.RemoveRange(TopCount, top.Count - TopCount);
                topMin = top[top.Count - 1].Size;
            }
        }

        private void ScanDir(DirectoryInfo di, DiskNode node, int depth)
        {
            if (Cancel || depth > 256) return;
            CurrentPath = di.FullName;
            FoldersScanned++;
            FileSystemInfo[] entries;
            try { entries = di.GetFileSystemInfos(); }
            catch (UnauthorizedAccessException) { Errors++; DeniedFolders++; node.Denied = true; return; }
            catch { Errors++; return; }

            long smallSize = 0; long smallCount = 0;
            foreach (FileSystemInfo e in entries)
            {
                if (Cancel) break;
                var d = e as DirectoryInfo;
                if (d != null)
                {
                    FileAttributes attr;
                    try { attr = d.Attributes; } catch { Errors++; continue; }
                    if ((attr & FileAttributes.ReparsePoint) != 0) continue;   // junctions / symlinks
                    var child = new DiskNode();
                    child.Name = d.Name; child.FullPath = d.FullName; child.IsDir = true; child.Parent = node;
                    ScanDir(d, child, depth + 1);
                    node.Children.Add(child);
                    node.Size += child.Size; node.FileCount += child.FileCount;
                    continue;
                }
                var f = e as FileInfo;
                if (f == null) continue;
                long len;
                try { len = f.Length; } catch { Errors++; continue; }
                FilesScanned++; BytesScanned += len;
                node.Size += len; node.FileCount++;

                string x;
                try { x = f.Extension; } catch { x = ""; }
                if (string.IsNullOrEmpty(x)) x = "(none)";
                ExtStat st;
                if (!ext.TryGetValue(x, out st)) { st = new ExtStat(); st.Extension = x.ToLowerInvariant(); ext[x] = st; }
                st.Size += len; st.Count++;

                AddTop(f, len);

                if (len >= SmallFileThreshold)
                {
                    var fn = new DiskNode();
                    fn.Name = f.Name; fn.FullPath = f.FullName; fn.Size = len; fn.FileCount = 1; fn.Parent = node;
                    try { fn.Modified = f.LastWriteTime; } catch { }
                    node.Children.Add(fn);
                }
                else { smallSize += len; smallCount++; }
            }
            if (smallCount > 0)
            {
                var g = new DiskNode();
                g.Name = smallCount + (smallCount == 1 ? " small file" : " small files");
                g.FullPath = di.FullName; g.Size = smallSize; g.FileCount = smallCount; g.IsGroup = true; g.Parent = node;
                node.Children.Add(g);
            }
            node.Children.Sort(CompareNodes);
        }

        // Compact text form of a finished scan, so a scan run on another PC (over WinRM) can be sent
        // back and rebuilt. Items smaller than minSize are folded into one "smaller items" group per folder.
        private static string Clean(string s) { return (s ?? "").Replace('\t', ' ').Replace('\r', ' ').Replace('\n', ' '); }
        public string Export(long minSize)
        {
            var sb = new System.Text.StringBuilder();
            sb.Append("H\t").Append(FilesScanned).Append('\t').Append(FoldersScanned).Append('\t').Append(BytesScanned).Append('\t').Append(Errors)
              .Append('\t').Append(ElapsedSeconds.ToString(CultureInfo.InvariantCulture)).Append('\t').Append(Completed ? 1 : 0).Append('\n');
            if (Root != null) ExportNode(sb, Root, 0, minSize);
            foreach (var f in TopFiles) sb.Append("T\t").Append(f.Size).Append('\t').Append(f.Modified.Ticks).Append('\t').Append(Clean(f.FullPath)).Append('\n');
            foreach (var e in ExtensionList) sb.Append("E\t").Append(Clean(e.Extension)).Append('\t').Append(e.Size).Append('\t').Append(e.Count).Append('\n');
            return sb.ToString();
        }
        private static void ExportNode(System.Text.StringBuilder sb, DiskNode n, int depth, long minSize)
        {
            sb.Append("N\t").Append(depth).Append('\t').Append(n.IsDir ? 1 : 0).Append('\t').Append(n.IsGroup ? 1 : 0).Append('\t').Append(n.Size).Append('\t').Append(n.FileCount)
              .Append('\t').Append(Clean(depth == 0 ? n.FullPath : n.Name)).Append('\n');
            long restSize = 0, restCount = 0;
            foreach (var c in n.Children)
            {
                if (c.Size >= minSize && !c.IsGroup) ExportNode(sb, c, depth + 1, minSize);
                else { restSize += c.Size; restCount += c.FileCount; }
            }
            if (restCount > 0)
                sb.Append("N\t").Append(depth + 1).Append("\t0\t1\t").Append(restSize).Append('\t').Append(restCount).Append('\t')
                  .Append(restCount).Append(restCount == 1 ? " smaller item" : " smaller items").Append('\n');
        }
        public static DiskScanner Import(string text)
        {
            var s = new DiskScanner();
            var stack = new List<DiskNode>();
            foreach (var line in text.Split('\n'))
            {
                if (line.Length < 2) continue;
                var p = line.Split('\t');
                if (p[0] == "H" && p.Length >= 7)
                {
                    s.FilesScanned = long.Parse(p[1]); s.FoldersScanned = long.Parse(p[2]); s.BytesScanned = long.Parse(p[3]); s.Errors = long.Parse(p[4]);
                    s.ElapsedSeconds = double.Parse(p[5], CultureInfo.InvariantCulture); s.Completed = p[6] == "1";
                }
                else if (p[0] == "N" && p.Length >= 7)
                {
                    int depth = int.Parse(p[1]);
                    var n = new DiskNode(); n.IsDir = p[2] == "1"; n.IsGroup = p[3] == "1"; n.Size = long.Parse(p[4]); n.FileCount = long.Parse(p[5]); n.Name = p[6];
                    if (depth == 0) { n.FullPath = p[6]; s.Root = n; stack.Clear(); stack.Add(n); continue; }
                    while (stack.Count > depth) stack.RemoveAt(stack.Count - 1);
                    var parent = stack[stack.Count - 1];
                    n.Parent = parent; n.FullPath = n.IsGroup ? parent.FullPath : Path.Combine(parent.FullPath, n.Name);
                    parent.Children.Add(n);
                    stack.Add(n);
                }
                else if (p[0] == "T" && p.Length >= 4)
                {
                    var f = new FileEntry(); f.Size = long.Parse(p[1]); f.Modified = new DateTime(long.Parse(p[2])); f.FullPath = p[3];
                    f.Name = Path.GetFileName(p[3]); try { f.Folder = Path.GetDirectoryName(p[3]); } catch { f.Folder = ""; }
                    try { f.Extension = Path.GetExtension(p[3]).ToLowerInvariant(); } catch { f.Extension = ""; }
                    s.TopFiles.Add(f);
                }
                else if (p[0] == "E" && p.Length >= 4)
                {
                    var e = new ExtStat(); e.Extension = p[1]; e.Size = long.Parse(p[2]); e.Count = long.Parse(p[3]);
                    s.ExtensionList.Add(e);
                }
            }
            long max = s.ExtensionList.Count > 0 ? s.ExtensionList[0].Size : 0;
            foreach (var e in s.ExtensionList) { e.Percent = s.Root != null && s.Root.Size > 0 ? e.Size * 100.0 / s.Root.Size : 0; e.RelPercent = max > 0 ? e.Size * 100.0 / max : 0; }
            return s;
        }
    }

    // Can the signed-in account delete or list a folder? Read from the folder's (and its parent's) access
    // rules against the user's SID and group SIDs. Results are cached per path; Get() never blocks the
    // caller: unknown paths are queued and checked on a background thread (Version goes up when done).
    public static class FolderRights
    {
        public const int Unknown = 0, Ok = 1, CantDelete = 2, CantList = 3;
        private static readonly Dictionary<string, int> cache = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        private static readonly Queue<string> queue = new Queue<string>();
        private static readonly Dictionary<string, bool> queued = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);   // no HashSet: System.Core isn't referenced
        private static readonly object gate = new object();
        private static bool running;
        private static List<System.Security.Principal.SecurityIdentifier> sids;
        public static volatile int Version;
        public static int Pending { get { lock (gate) { return queue.Count + (running ? 1 : 0); } } }

        public static void Clear() { lock (gate) { cache.Clear(); queue.Clear(); queued.Clear(); } }

        public static int Get(string path)
        {
            if (string.IsNullOrEmpty(path)) return Unknown;
            lock (gate)
            {
                int v;
                if (cache.TryGetValue(path, out v)) return v;
                if (!queued.ContainsKey(path)) { queued[path] = true; queue.Enqueue(path); }
                if (!running)
                {
                    running = true;
                    System.Threading.ThreadPool.QueueUserWorkItem(Work);
                }
            }
            return Unknown;
        }

        private static void Work(object state)
        {
            while (true)
            {
                string p;
                lock (gate)
                {
                    if (queue.Count == 0) { running = false; Version++; return; }
                    p = queue.Dequeue();
                }
                int v;
                try { v = Check(p); } catch { v = Ok; }
                lock (gate) { cache[p] = v; queued.Remove(p); }
            }
        }

        private static List<System.Security.Principal.SecurityIdentifier> Sids()
        {
            if (sids != null) return sids;
            var list = new List<System.Security.Principal.SecurityIdentifier>();
            var id = System.Security.Principal.WindowsIdentity.GetCurrent();
            if (id.User != null) list.Add(id.User);
            if (id.Groups != null)
                foreach (var g in id.Groups)
                {
                    var sid = g as System.Security.Principal.SecurityIdentifier;
                    if (sid == null) { try { sid = (System.Security.Principal.SecurityIdentifier)g.Translate(typeof(System.Security.Principal.SecurityIdentifier)); } catch { } }
                    if (sid != null) list.Add(sid);
                }
            sids = list;
            return sids;
        }

        // Effective rights from the folder's own (non-inherit-only) access rules; -1 when they can't be read.
        public static int Rights(string path)
        {
            System.Security.AccessControl.DirectorySecurity sec;
            try { sec = new DirectoryInfo(path).GetAccessControl(System.Security.AccessControl.AccessControlSections.Access); }
            catch { return -1; }
            var mine = Sids();
            int allow = 0, deny = 0;
            foreach (System.Security.AccessControl.FileSystemAccessRule r in sec.GetAccessRules(true, true, typeof(System.Security.Principal.SecurityIdentifier)))
            {
                if ((r.PropagationFlags & System.Security.AccessControl.PropagationFlags.InheritOnly) != 0) continue;
                var sid = r.IdentityReference as System.Security.Principal.SecurityIdentifier;
                if (sid == null || !mine.Contains(sid)) continue;
                int m = (int)r.FileSystemRights;
                if ((m & 0x10000000) != 0) m |= 0x1F01FF;                 // GENERIC_ALL
                if ((m & 0x40000000) != 0) m |= 0x116;                    // GENERIC_WRITE
                if ((m & unchecked((int)0x80000000)) != 0) m |= 0x89;     // GENERIC_READ
                if (r.AccessControlType == System.Security.AccessControl.AccessControlType.Deny) deny |= m; else allow |= m;
            }
            return allow & ~deny;
        }

        public static int Check(string path)
        {
            const int ListDirectory = 0x1, DeleteChild = 0x40, Delete = 0x10000;
            int own = Rights(path);
            if (own == -1)
            {
                // The rules themselves can't be read: try listing the folder.
                try { using (var e = Directory.EnumerateFileSystemEntries(path).GetEnumerator()) { e.MoveNext(); } }
                catch (UnauthorizedAccessException) { return CantList; }
                catch { return Ok; }
                own = 0;
            }
            else if ((own & ListDirectory) == 0) return CantList;
            if ((own & Delete) != 0) return Ok;
            string parent = null;
            try { var pi = Directory.GetParent(path); if (pi != null) parent = pi.FullName; } catch { }
            if (parent == null) return CantDelete;                        // a drive root can't be deleted
            int up = Rights(parent);
            if (up != -1 && (up & DeleteChild) != 0) return Ok;
            return CantDelete;
        }
    }

    // Folders and files a cleaner rule would remove, for the Space Map. Add() each rule target
    // (already expanded); Match() walks up from a path and returns the reason, or null.
    public static class CleanMap
    {
        private class Entry { public string Filter; public bool Recurse; public string Reason; }
        private static Dictionary<string, List<Entry>> map = new Dictionary<string, List<Entry>>(StringComparer.OrdinalIgnoreCase);
        public static int Count { get { return map.Count; } }

        public static void Clear() { map = new Dictionary<string, List<Entry>>(StringComparer.OrdinalIgnoreCase); }

        public static void Add(string path, string filter, bool recurse, string reason)
        {
            if (string.IsNullOrEmpty(path)) return;
            path = path.TrimEnd('\\');
            List<Entry> l;
            if (!map.TryGetValue(path, out l)) { l = new List<Entry>(); map[path] = l; }
            var e = new Entry(); e.Filter = string.IsNullOrEmpty(filter) ? "*" : filter; e.Recurse = recurse; e.Reason = reason;
            l.Add(e);
        }

        private static bool Like(string name, string pattern)
        {
            if (pattern == "*") return true;
            var rx = "^" + System.Text.RegularExpressions.Regex.Escape(pattern).Replace("\\*", ".*").Replace("\\?", ".") + "$";
            return System.Text.RegularExpressions.Regex.IsMatch(name, rx, System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        }

        // isDir: a folder (or a group of small files, matched as its folder).
        public static string Match(string path, bool isDir)
        {
            if (string.IsNullOrEmpty(path) || map.Count == 0) return null;
            string p = path.TrimEnd('\\');
            string name = p.Substring(p.LastIndexOf('\\') + 1);
            int level = 0;                                                  // 0 = the item itself, 1 = its folder, ...
            while (!string.IsNullOrEmpty(p))
            {
                List<Entry> l;
                if (map.TryGetValue(p, out l))
                {
                    foreach (var e in l)
                    {
                        if (level == 0) { if (isDir && e.Filter == "*" && e.Recurse) return e.Reason; continue; }
                        if (!e.Recurse && level > 1) continue;
                        if (e.Filter == "*") { if (e.Recurse || !isDir) return e.Reason; continue; }
                        if (!isDir && level == 1 && Like(name, e.Filter)) return e.Reason;
                        if (!isDir && e.Recurse && Like(name, e.Filter)) return e.Reason;
                    }
                }
                int i = p.LastIndexOf('\\');
                if (i <= 0) break;
                p = p.Substring(0, i);
                level++;
            }
            return null;
        }
    }

    public static class Treemap
    {
        // Squarified treemap (Bruls, Huizing, van Wijk).
        public static List<TreeRect> Layout(List<DiskNode> nodes, double x, double y, double w, double h)
        {
            var result = new List<TreeRect>();
            if (nodes == null || w <= 1 || h <= 1) return result;
            var items = new List<DiskNode>();
            double total = 0;
            foreach (var n in nodes) { if (n.Size > 0) { items.Add(n); total += n.Size; } }
            if (items.Count == 0 || total <= 0) return result;
            items.Sort(delegate (DiskNode a, DiskNode b) { return b.Size.CompareTo(a.Size); });

            double scale = (w * h) / total;
            var areas = new double[items.Count];
            for (int i = 0; i < items.Count; i++) areas[i] = items[i].Size * scale;

            int start = 0;
            while (start < items.Count && w > 0.5 && h > 0.5)
            {
                double side = Math.Min(w, h);
                int end = start; double rowSum = 0; double worst = double.MaxValue;
                while (end < items.Count)
                {
                    double s = rowSum + areas[end];
                    double wv = Worst(areas, start, end, s, side);
                    if (end > start && wv > worst) break;
                    rowSum = s; worst = wv; end++;
                }
                if (w >= h)
                {
                    double colW = rowSum / h; double cy = y;
                    for (int i = start; i < end; i++)
                    {
                        double ih = areas[i] / colW;
                        result.Add(Make(items[i], x, cy, colW, ih)); cy += ih;
                    }
                    x += colW; w -= colW;
                }
                else
                {
                    double rowH = rowSum / w; double cx = x;
                    for (int i = start; i < end; i++)
                    {
                        double iw = areas[i] / rowH;
                        result.Add(Make(items[i], cx, y, iw, rowH)); cx += iw;
                    }
                    y += rowH; h -= rowH;
                }
                start = end;
            }
            return result;
        }

        private static double Worst(double[] a, int s, int e, double sum, double side)
        {
            double max = 0, min = double.MaxValue;
            for (int i = s; i <= e; i++) { if (a[i] > max) max = a[i]; if (a[i] < min) min = a[i]; }
            double s2 = sum * sum, w2 = side * side;
            return Math.Max(w2 * max / s2, s2 / (w2 * min));
        }

        private static TreeRect Make(DiskNode n, double x, double y, double w, double h)
        {
            var r = new TreeRect(); r.Node = n; r.X = x; r.Y = y; r.W = w; r.H = h; return r;
        }
    }

    // ------------------------------------------------------------------ Duplicate files
    // Same size -> same hash of the first 64 KB -> same full SHA-256. Cloud-only placeholders
    // (OneDrive "free up space") are skipped so the scan never triggers downloads.
    public class DuplicateFinder
    {
        public volatile bool Cancel;
        public long FilesSeen, Candidates, Hashed, Groups, WastedBytes;
        public volatile string Status = "";
        public bool Completed;
        public string Error;
        public List<FileEntry> Results = new List<FileEntry>();

        private static string HashFile(string path, long limit)
        {
            using (var sha = System.Security.Cryptography.SHA256.Create())
            using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete, 1 << 16))
            {
                if (limit <= 0) return BitConverter.ToString(sha.ComputeHash(fs));
                byte[] buf = new byte[(int)Math.Min(limit, fs.Length)];
                int read = 0, n;
                while (read < buf.Length && (n = fs.Read(buf, read, buf.Length - read)) > 0) read += n;
                return BitConverter.ToString(sha.ComputeHash(buf, 0, read));
            }
        }

        public void Scan(string root, long minSize)
        {
            try
            {
                var bySize = new Dictionary<long, List<FileInfo>>();
                var stack = new Stack<DirectoryInfo>();
                stack.Push(new DirectoryInfo(root));
                while (stack.Count > 0 && !Cancel)
                {
                    var d = stack.Pop();
                    Status = d.FullName;
                    FileSystemInfo[] entries;
                    try { entries = d.GetFileSystemInfos(); } catch { continue; }
                    foreach (var e in entries)
                    {
                        FileAttributes a;
                        try { a = e.Attributes; } catch { continue; }
                        if ((a & FileAttributes.ReparsePoint) != 0) continue;
                        if ((a & FileAttributes.Directory) != 0) { stack.Push((DirectoryInfo)e); continue; }
                        if ((a & FileAttributes.Offline) != 0 || ((int)a & 0x400000) != 0 || ((int)a & 0x40000) != 0) continue;
                        var f = (FileInfo)e;
                        long len;
                        try { len = f.Length; } catch { continue; }
                        if (len < minSize || len == 0) continue;
                        FilesSeen++;
                        List<FileInfo> l;
                        if (!bySize.TryGetValue(len, out l)) { l = new List<FileInfo>(); bySize[len] = l; }
                        l.Add(f);
                    }
                }
                int group = 0;
                foreach (var kv in bySize)
                {
                    if (Cancel) break;
                    if (kv.Value.Count < 2) continue;
                    Candidates += kv.Value.Count;
                    var byPartial = new Dictionary<string, List<FileInfo>>();
                    foreach (var f in kv.Value)
                    {
                        if (Cancel) break;
                        try
                        {
                            Status = f.FullName;
                            string h = HashFile(f.FullName, 65536);
                            List<FileInfo> l;
                            if (!byPartial.TryGetValue(h, out l)) { l = new List<FileInfo>(); byPartial[h] = l; }
                            l.Add(f);
                        }
                        catch { }
                    }
                    foreach (var p in byPartial.Values)
                    {
                        if (p.Count < 2) continue;
                        var byFull = new Dictionary<string, List<FileInfo>>();
                        foreach (var f in p)
                        {
                            if (Cancel) break;
                            try
                            {
                                Status = f.FullName;
                                string h = kv.Key <= 65536 ? "small" : HashFile(f.FullName, 0);
                                Hashed++;
                                List<FileInfo> l;
                                if (!byFull.TryGetValue(h, out l)) { l = new List<FileInfo>(); byFull[h] = l; }
                                l.Add(f);
                            }
                            catch { }
                        }
                        foreach (var g in byFull.Values)
                        {
                            if (g.Count < 2) continue;
                            group++; Groups++;
                            WastedBytes += kv.Key * (g.Count - 1);
                            foreach (var f in g)
                            {
                                var fe = new FileEntry();
                                fe.Name = f.Name; fe.FullPath = f.FullName; fe.Size = kv.Key; fe.Extension = f.Extension.ToLowerInvariant();
                                try { fe.Folder = f.DirectoryName; fe.Modified = f.LastWriteTime; } catch { }
                                fe.Status = "Group " + group + " (" + g.Count + " copies)";
                                Results.Add(fe);
                            }
                        }
                    }
                }
                Completed = !Cancel;
            }
            catch (Exception ex) { Error = ex.Message; }
        }
    }

    // Groups 64-bit perceptual hashes (dHash) whose Hamming distance is small: visually similar photos.
    public static class PhotoMatch
    {
        private static int Bits(ulong v) { int c = 0; while (v != 0) { v &= v - 1; c++; } return c; }
        public static int[] Group(ulong[] hashes, int maxDistance)
        {
            int n = hashes.Length;
            int[] parent = new int[n];
            for (int i = 0; i < n; i++) parent[i] = i;
            Func<int, int> find = null;
            find = x => { while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; } return x; };
            for (int i = 0; i < n; i++)
                for (int j = i + 1; j < n; j++)
                    if (Bits(hashes[i] ^ hashes[j]) <= maxDistance) { int a = find(i), b = find(j); if (a != b) parent[b] = a; }
            int[] g = new int[n];
            for (int i = 0; i < n; i++) g[i] = find(i);
            return g;
        }
    }

    // ------------------------------------------------------------------ NVMe SMART / health log
    // Reads log page 0x02 (SMART / Health Information) through the in-box StorNVMe driver with
    // IOCTL_STORAGE_QUERY_PROPERTY + StorageDeviceProtocolSpecificProperty. Read-only; needs admin.
    public class NvmeHealth
    {
        public int Disk; public int CriticalWarning; public int TemperatureC; public int AvailableSpare; public int SpareThreshold;
        public int PercentUsed; public double ReadTB; public double WrittenTB; public long PowerCycles; public long PowerOnHours;
        public long UnsafeShutdowns; public long MediaErrors; public long ErrorLogEntries; public long WarningTempMinutes; public long CriticalTempMinutes;
    }

    public static class StorageHealth
    {
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern Microsoft.Win32.SafeHandles.SafeFileHandle CreateFile(string name, uint access, uint share, IntPtr sec, uint disposition, uint flags, IntPtr template);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool DeviceIoControl(Microsoft.Win32.SafeHandles.SafeFileHandle h, uint code, byte[] inBuf, int inSize, byte[] outBuf, int outSize, out int returned, IntPtr overlapped);

        public static NvmeHealth ReadNvme(int diskNumber)
        {
            const int headerSize = 8, protocolSize = 40, logSize = 512;
            byte[] buf = new byte[headerSize + protocolSize + logSize];
            BitConverter.GetBytes(50).CopyTo(buf, 0);              // StorageDeviceProtocolSpecificProperty
            BitConverter.GetBytes(0).CopyTo(buf, 4);               // PropertyStandardQuery
            BitConverter.GetBytes(3).CopyTo(buf, 8);               // ProtocolTypeNvme
            BitConverter.GetBytes(2).CopyTo(buf, 12);              // NVMeDataTypeLogPage
            BitConverter.GetBytes(2).CopyTo(buf, 16);              // NVME_LOG_PAGE_HEALTH_INFO
            BitConverter.GetBytes(0).CopyTo(buf, 20);              // sub value
            BitConverter.GetBytes(protocolSize).CopyTo(buf, 24);   // ProtocolDataOffset (from the protocol block)
            BitConverter.GetBytes(logSize).CopyTo(buf, 28);        // ProtocolDataLength

            Microsoft.Win32.SafeHandles.SafeFileHandle h = null;
            foreach (uint access in new uint[] { 0xC0000000, 0x80000000, 0 })
            {
                h = CreateFile("\\\\.\\PhysicalDrive" + diskNumber, access, 3, IntPtr.Zero, 3, 0, IntPtr.Zero);
                if (!h.IsInvalid) break;
            }
            if (h == null || h.IsInvalid) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error(), "Could not open disk " + diskNumber);
            using (h)
            {
                int returned;
                if (!DeviceIoControl(h, 0x002D1400 /* IOCTL_STORAGE_QUERY_PROPERTY */, buf, buf.Length, buf, buf.Length, out returned, IntPtr.Zero))
                    throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error(), "The drive did not return its NVMe health log");
            }
            // Output: STORAGE_PROTOCOL_DATA_DESCRIPTOR (Version, Size, protocol block); data at 8 + ProtocolDataOffset.
            int at = 8 + BitConverter.ToInt32(buf, 8 + 16);
            if (at < 8 || at + logSize > buf.Length) at = headerSize + protocolSize;
            var n = new NvmeHealth();
            n.Disk = diskNumber;
            n.CriticalWarning = buf[at];
            int kelvin = BitConverter.ToUInt16(buf, at + 1);
            n.TemperatureC = kelvin > 0 ? kelvin - 273 : 0;
            n.AvailableSpare = buf[at + 3];
            n.SpareThreshold = buf[at + 4];
            n.PercentUsed = buf[at + 5];
            n.ReadTB = BitConverter.ToUInt64(buf, at + 32) * 512000.0 / 1e12;     // data units are 1000 x 512 bytes
            n.WrittenTB = BitConverter.ToUInt64(buf, at + 48) * 512000.0 / 1e12;
            n.PowerCycles = (long)BitConverter.ToUInt64(buf, at + 112);
            n.PowerOnHours = (long)BitConverter.ToUInt64(buf, at + 128);
            n.UnsafeShutdowns = (long)BitConverter.ToUInt64(buf, at + 144);
            n.MediaErrors = (long)BitConverter.ToUInt64(buf, at + 160);
            n.ErrorLogEntries = (long)BitConverter.ToUInt64(buf, at + 176);
            n.WarningTempMinutes = BitConverter.ToUInt32(buf, at + 192);
            n.CriticalTempMinutes = BitConverter.ToUInt32(buf, at + 196);
            return n;
        }
    }

    // ------------------------------------------------------------------ NTFS undelete
    public class DeletedFile
    {
        public bool IsChecked { get; set; }
        public long Record { get; set; }
        public string Name { get; set; }
        public string Folder { get; set; }
        public long Size { get; set; }
        public DateTime Created { get; set; }
        public DateTime Modified { get; set; }
        public string Chance { get; set; }
        public int Score { get; set; }
        public string Note { get; set; }
        public bool Resident { get; set; }
        public bool Unsupported { get; set; }
        public byte[] ResidentData;
        public List<long[]> Runs;      // { lcn (-1 = sparse), cluster count }
        public string SizeText { get { return Fmt.Size(Size); } }
        public string ModifiedText { get { return Modified == DateTime.MinValue ? "" : Modified.ToString("yyyy-MM-dd HH:mm"); } }
        public string FullPath { get { return Folder.EndsWith("\\") ? Folder + Name : Folder + "\\" + Name; } }
    }

    // Read-only scanner for deleted files on an NTFS volume (\\.\C:) or a raw NTFS volume image.
    // It reads the boot sector, follows $MFT's data runs, parses every FILE record, and keeps
    // records whose in-use flag is clear. Recoverability is rated against the live cluster bitmap.
    // The device is only ever opened with GENERIC_READ.
    public class NtfsUndelete : IDisposable
    {
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern Microsoft.Win32.SafeHandles.SafeFileHandle CreateFile(string name, uint access, uint share, IntPtr sec, uint disposition, uint flags, IntPtr template);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool ReadFile(Microsoft.Win32.SafeHandles.SafeFileHandle h, byte[] buffer, int toRead, out int read, IntPtr overlapped);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool SetFilePointerEx(Microsoft.Win32.SafeHandles.SafeFileHandle h, long distance, out long newPos, uint method);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool DeviceIoControl(Microsoft.Win32.SafeHandles.SafeFileHandle h, uint code, byte[] inBuf, int inSize, byte[] outBuf, int outSize, out int returned, IntPtr overlapped);

        private class DirEntry { public string Name; public long Parent; public int ParentSeq; public int Seq; public bool InUse; }

        public volatile bool Cancel;
        public long RecordsTotal;
        public long RecordsScanned;
        public long DeletedFound;
        public bool Completed;
        public string Error;
        public string Source;
        public bool IsImage;
        public int BytesPerCluster;
        public int BytesPerSector;
        public long TotalClusters;

        private Microsoft.Win32.SafeHandles.SafeFileHandle handle;
        private int recordSize;
        private long mftLcn;
        private List<long[]> mftRuns;
        private byte[] bitmap;
        private Dictionary<long, DirEntry> dirs = new Dictionary<long, DirEntry>();
        private Dictionary<long, string> pathCache = new Dictionary<long, string>();
        private List<DeletedFile> all = new List<DeletedFile>();
        private List<long> parents = new List<long>();     // parallel to 'all': parent record | (seq << 48)
        private string rootLabel;

        // source: "C:" for a live volume, or the full path of a raw NTFS volume image.
        public NtfsUndelete(string source)
        {
            Source = source;
            IsImage = !(source.Length == 2 && source[1] == ':');
            rootLabel = IsImage ? "[image]" : source.ToUpperInvariant();
        }

        public void Open()
        {
            string path = IsImage ? Source : "\\\\.\\" + Source;
            handle = CreateFile(path, 0x80000000 /* GENERIC_READ only */, 0x1 | 0x2, IntPtr.Zero, 3, 0, IntPtr.Zero);
            if (handle.IsInvalid) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error(), "Could not open " + path + " for reading");

            byte[] boot = new byte[4096];
            ReadAt(0, boot, boot.Length);
            if (System.Text.Encoding.ASCII.GetString(boot, 3, 8) != "NTFS    ") throw new InvalidOperationException("This is not an NTFS volume.");
            BytesPerSector = BitConverter.ToUInt16(boot, 0x0B);
            int spc = boot[0x0D];
            if (spc > 0x80) spc = 1 << (256 - spc);
            BytesPerCluster = BytesPerSector * spc;
            TotalClusters = BitConverter.ToInt64(boot, 0x28) / spc;
            mftLcn = BitConverter.ToInt64(boot, 0x30);
            int cpr = (sbyte)boot[0x40];
            recordSize = cpr > 0 ? cpr * BytesPerCluster : 1 << -cpr;
            if (BytesPerSector < 512 || BytesPerCluster < BytesPerSector || recordSize < 512 || recordSize > 65536)
                throw new InvalidOperationException("Unexpected NTFS geometry in the boot sector.");

            byte[] rec0 = ReadAligned(mftLcn * BytesPerCluster, recordSize);
            if (!Fixup(rec0)) throw new InvalidOperationException("The $MFT record is damaged.");
            DataInfo d = ParseRecord(rec0).Data;
            if (d == null || d.Runs == null) throw new InvalidOperationException("Could not locate the master file table.");
            mftRuns = d.Runs;
            RecordsTotal = d.Size / recordSize;
            LoadBitmap();
        }

        // ---------------- raw I/O (offsets and lengths are kept sector-aligned)
        private void ReadAt(long offset, byte[] buffer, int count)
        {
            long pos;
            if (!SetFilePointerEx(handle, offset, out pos, 0)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            int done = 0;
            while (done < count)
            {
                int read;
                byte[] target = done == 0 ? buffer : new byte[count - done];
                if (!ReadFile(handle, target, count - done, out read, IntPtr.Zero)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
                if (read == 0) { Array.Clear(buffer, done, count - done); return; }
                if (done > 0) Buffer.BlockCopy(target, 0, buffer, done, read);
                done += read;
            }
        }

        private byte[] ReadAligned(long offset, int count)
        {
            long start = offset - (offset % BytesPerSector);
            long end = offset + count;
            if (end % BytesPerSector != 0) end += BytesPerSector - (end % BytesPerSector);
            byte[] tmp = new byte[end - start];
            ReadAt(start, tmp, tmp.Length);
            byte[] result = new byte[count];
            Buffer.BlockCopy(tmp, (int)(offset - start), result, 0, count);
            return result;
        }

        // Live allocation state. For an image file it falls back to the volume's own $Bitmap file.
        public void LoadBitmap()
        {
            long bytes = (TotalClusters + 7) / 8;
            bitmap = new byte[bytes];
            if (IsImage) { LoadBitmapFromFile(); return; }
            long start = 0;
            const int chunk = 8 * 1024 * 1024;
            while (start < TotalClusters)
            {
                byte[] input = BitConverter.GetBytes(start);
                byte[] output = new byte[16 + chunk];
                int returned;
                bool ok = DeviceIoControl(handle, 0x0009006F /* FSCTL_GET_VOLUME_BITMAP */, input, 8, output, output.Length, out returned, IntPtr.Zero);
                int err = Marshal.GetLastWin32Error();
                if (!ok && err != 234 /* ERROR_MORE_DATA */) throw new System.ComponentModel.Win32Exception(err, "Could not read the volume bitmap");
                long startLcn = BitConverter.ToInt64(output, 0);
                int got = returned - 16;
                long at = startLcn / 8;
                if (got <= 0 || at >= bitmap.Length) break;
                Buffer.BlockCopy(output, 16, bitmap, (int)at, (int)Math.Min(got, bitmap.Length - at));
                if (ok) break;
                start = startLcn + (long)got * 8;
            }
        }

        private void LoadBitmapFromFile()
        {
            byte[] rec = ReadRecord(6);
            DataInfo d = rec == null ? null : ParseRecord(rec).Data;
            if (d == null || d.Runs == null) return;   // leave as "all free"
            long pos = 0;
            foreach (long[] run in d.Runs)
            {
                if (run[0] < 0) { pos += run[1] * BytesPerCluster; continue; }
                for (long c = 0; c < run[1] && pos < bitmap.Length; c++)
                {
                    byte[] cl = new byte[BytesPerCluster];
                    ReadAt((run[0] + c) * BytesPerCluster, cl, cl.Length);
                    int n = (int)Math.Min(cl.Length, bitmap.Length - pos);
                    Buffer.BlockCopy(cl, 0, bitmap, (int)pos, n);
                    pos += n;
                }
            }
        }

        private bool IsAllocated(long lcn)
        {
            if (lcn < 0 || (lcn >> 3) >= bitmap.Length) return true;
            return (bitmap[lcn >> 3] & (1 << (int)(lcn & 7))) != 0;
        }

        private byte[] ReadRecord(long number)
        {
            long vcnByte = number * recordSize;
            long pos = 0;
            foreach (long[] run in mftRuns)
            {
                long len = run[1] * BytesPerCluster;
                if (vcnByte < pos + len)
                {
                    if (run[0] < 0) return null;
                    byte[] r = ReadAligned(run[0] * BytesPerCluster + (vcnByte - pos), recordSize);
                    return Fixup(r) ? r : null;
                }
                pos += len;
            }
            return null;
        }

        // ---------------- record parsing
        private bool Fixup(byte[] r)
        {
            if (r.Length < 48 || BitConverter.ToUInt32(r, 0) != 0x454C4946 /* "FILE" */) return false;
            int usaOfs = BitConverter.ToUInt16(r, 4), usaCount = BitConverter.ToUInt16(r, 6);
            if (usaOfs + usaCount * 2 > r.Length) return false;
            for (int i = 1; i < usaCount; i++)
            {
                int p = i * 512 - 2;               // the update-sequence stride is always 512 bytes
                if (p + 1 >= r.Length) break;
                if (r[p] != r[usaOfs] || r[p + 1] != r[usaOfs + 1]) return false;
                r[p] = r[usaOfs + 2 * i]; r[p + 1] = r[usaOfs + 2 * i + 1];
            }
            return true;
        }

        private class DataInfo
        {
            public long Size; public bool Resident; public byte[] Bytes; public List<long[]> Runs;
            public bool Compressed; public bool Encrypted; public bool Partial;
        }
        private class RecordInfo
        {
            public bool InUse; public bool IsDir; public int Seq; public long BaseRef;
            public string Name; public int NameSpace = 99; public long Parent; public int ParentSeq;
            public DateTime Created = DateTime.MinValue; public DateTime Modified = DateTime.MinValue;
            public DataInfo Data; public bool HasAttrList;
        }

        private static DateTime FromFt(long ft)
        {
            if (ft <= 0 || ft > 2650467743999999999L) return DateTime.MinValue;
            try { return DateTime.FromFileTime(ft); } catch { return DateTime.MinValue; }
        }

        private RecordInfo ParseRecord(byte[] r)
        {
            var info = new RecordInfo();
            int flags = BitConverter.ToUInt16(r, 0x16);
            info.InUse = (flags & 1) != 0;
            info.IsDir = (flags & 2) != 0;
            info.Seq = BitConverter.ToUInt16(r, 0x10);
            info.BaseRef = BitConverter.ToInt64(r, 0x20) & 0xFFFFFFFFFFFFL;
            int a = BitConverter.ToUInt16(r, 0x14);
            while (a + 16 <= r.Length)
            {
                uint type = BitConverter.ToUInt32(r, a);
                if (type == 0xFFFFFFFF) break;
                int len = BitConverter.ToInt32(r, a + 4);
                if (len < 16 || a + len > r.Length) break;
                bool nonRes = r[a + 8] != 0;
                int nameLen = r[a + 9];
                if (!nonRes && (type == 0x10 || type == 0x30))
                {
                    int vlen = BitConverter.ToInt32(r, a + 0x10), v = a + BitConverter.ToUInt16(r, a + 0x14);
                    if (v + vlen <= r.Length)
                    {
                        if (type == 0x10 && vlen >= 32)
                        {
                            info.Created = FromFt(BitConverter.ToInt64(r, v));
                            info.Modified = FromFt(BitConverter.ToInt64(r, v + 8));
                        }
                        else if (type == 0x30 && vlen >= 66)
                        {
                            int nl = r[v + 64], ns = r[v + 65];
                            // Prefer the long (Win32 / POSIX) name over the 8.3 DOS alias.
                            int rank = ns == 2 ? 3 : (ns == 0 ? 2 : 1);
                            if (v + 66 + nl * 2 <= r.Length && rank < info.NameSpace)
                            {
                                info.NameSpace = rank;
                                info.Name = System.Text.Encoding.Unicode.GetString(r, v + 66, nl * 2);
                                long pref = BitConverter.ToInt64(r, v);
                                info.Parent = pref & 0xFFFFFFFFFFFFL;
                                info.ParentSeq = (int)((pref >> 48) & 0xFFFF);
                            }
                        }
                    }
                }
                else if (type == 0x20) info.HasAttrList = true;
                else if (type == 0x80 && nameLen == 0 && info.Data == null)
                {
                    var d = new DataInfo();
                    int aflags = BitConverter.ToUInt16(r, a + 0x0C);
                    d.Compressed = (aflags & 0x00FF) != 0;
                    d.Encrypted = (aflags & 0x4000) != 0;
                    if (!nonRes)
                    {
                        int vlen = BitConverter.ToInt32(r, a + 0x10), v = a + BitConverter.ToUInt16(r, a + 0x14);
                        if (v + vlen <= r.Length && vlen >= 0)
                        {
                            d.Resident = true; d.Size = vlen; d.Bytes = new byte[vlen];
                            Buffer.BlockCopy(r, v, d.Bytes, 0, vlen);
                        }
                    }
                    else
                    {
                        long startVcn = BitConverter.ToInt64(r, a + 0x10);
                        d.Partial = startVcn != 0;
                        d.Size = BitConverter.ToInt64(r, a + 0x30);
                        d.Runs = DecodeRuns(r, a + BitConverter.ToUInt16(r, a + 0x20), a + len);
                        if (d.Runs != null)
                        {
                            long clusters = 0;
                            foreach (long[] run in d.Runs) clusters += run[1];
                            if (clusters * BytesPerCluster < d.Size) d.Partial = true;   // rest lives in an extension record
                        }
                    }
                    info.Data = d;
                }
                a += len;
            }
            return info;
        }

        private List<long[]> DecodeRuns(byte[] r, int p, int end)
        {
            var runs = new List<long[]>();
            long lcn = 0;
            while (p < end && p < r.Length)
            {
                int h = r[p];
                if (h == 0) break;
                int lenSize = h & 0x0F, offSize = h >> 4;
                p++;
                if (lenSize == 0 || lenSize > 8 || offSize > 8 || p + lenSize + offSize > r.Length) return null;
                long len = 0;
                for (int i = 0; i < lenSize; i++) len |= (long)r[p + i] << (8 * i);
                p += lenSize;
                if (offSize == 0) runs.Add(new long[] { -1, len });
                else
                {
                    long off = 0;
                    for (int i = 0; i < offSize; i++) off |= (long)r[p + i] << (8 * i);
                    if (offSize < 8 && (r[p + offSize - 1] & 0x80) != 0) off |= -1L << (8 * offSize);
                    lcn += off;
                    if (lcn < 0 || lcn + len > TotalClusters || len <= 0) return null;
                    runs.Add(new long[] { lcn, len });
                }
                p += offSize;
            }
            return runs;
        }

        // ---------------- scanning
        public void Scan()
        {
            try
            {
                long number = 0;
                int perChunk = Math.Max(1, (4 * 1024 * 1024) / recordSize);
                foreach (long[] run in mftRuns)
                {
                    if (run[0] < 0) { number += run[1] * BytesPerCluster / recordSize; continue; }
                    long runBytes = run[1] * BytesPerCluster;
                    for (long off = 0; off < runBytes && number < RecordsTotal; )
                    {
                        if (Cancel) return;
                        int bytes = (int)Math.Min((long)perChunk * recordSize, runBytes - off);
                        byte[] buf = new byte[bytes];
                        ReadAt(run[0] * BytesPerCluster + off, buf, bytes);
                        for (int i = 0; i + recordSize <= bytes && number < RecordsTotal; i += recordSize, number++)
                        {
                            byte[] rec = new byte[recordSize];
                            Buffer.BlockCopy(buf, i, rec, 0, recordSize);
                            Process(rec, number);
                            RecordsScanned = number + 1;
                        }
                        off += bytes;
                    }
                }
                BuildPaths();
                Completed = !Cancel;
            }
            catch (Exception ex) { Error = ex.Message; }
        }

        private void Process(byte[] rec, long number)
        {
            if (!Fixup(rec)) return;
            RecordInfo info = ParseRecord(rec);
            if (info.BaseRef != 0) return;               // extension record of another file
            if (info.IsDir)
            {
                if (info.Name != null || number == 5)
                    dirs[number] = new DirEntry { Name = number == 5 ? "" : info.Name, Parent = info.Parent, ParentSeq = info.ParentSeq, Seq = info.Seq, InUse = info.InUse };
                return;
            }
            if (info.InUse || number < 24 || info.Name == null) return;
            if (all.Count >= 1000000) return;

            var f = new DeletedFile();
            f.Record = number; f.Name = info.Name; f.Created = info.Created; f.Modified = info.Modified;
            DataInfo d = info.Data;
            if (d == null)
            {
                if (!info.HasAttrList) return;
                f.Chance = "Poor"; f.Score = 1; f.Note = "Data is described in another record"; f.Unsupported = true;
            }
            else
            {
                f.Size = d.Size;
                if (d.Resident) { f.Resident = true; f.ResidentData = d.Bytes; }
                else f.Runs = d.Runs;
                if (d.Encrypted) { f.Unsupported = true; f.Note = "Encrypted (EFS)"; }
                else if (d.Compressed) { f.Unsupported = true; f.Note = "NTFS-compressed"; }
                else if (!d.Resident && d.Runs == null) { f.Unsupported = true; f.Note = "Damaged record"; }
                else if (d.Partial) f.Note = "Very fragmented - may be incomplete";
            }
            all.Add(f);
            parents.Add(info.Parent | ((long)info.ParentSeq << 48));
            DeletedFound++;
        }

        private string PathFor(long parent, int parentSeq, int depth)
        {
            if (parent == 5) return rootLabel + "\\";
            long key = parent | ((long)parentSeq << 48);
            string cached;
            if (pathCache.TryGetValue(key, out cached)) return cached;
            DirEntry d;
            string result;
            if (depth > 64 || !dirs.TryGetValue(parent, out d)) result = rootLabel + "\\[unknown folder]\\";
            else if (d.InUse ? d.Seq != parentSeq : Math.Abs(d.Seq - parentSeq) > 1) result = rootLabel + "\\[folder no longer exists]\\";
            else result = PathFor(d.Parent, d.ParentSeq, depth + 1) + d.Name + (d.InUse ? "" : " [deleted]") + "\\";
            pathCache[key] = result;
            return result;
        }

        private void BuildPaths()
        {
            for (int i = 0; i < all.Count; i++)
            {
                long p = parents[i];
                string folder = PathFor(p & 0xFFFFFFFFFFFFL, (int)((p >> 48) & 0xFFFF), 0);
                all[i].Folder = folder.Length > 3 ? folder.TrimEnd('\\') : folder;
                Rate(all[i]);
            }
        }

        private void Rate(DeletedFile f)
        {
            if (f.Unsupported) { f.Chance = "Not supported"; f.Score = 1; return; }
            if (f.Size == 0) { f.Chance = "Empty"; f.Score = 0; return; }
            if (f.Resident) { f.Chance = "Excellent"; f.Score = 4; if (f.Note == null) f.Note = "Stored inside the file table"; return; }
            long total = 0, used = 0;
            foreach (long[] run in f.Runs)
            {
                if (run[0] < 0) continue;
                for (long c = 0; c < run[1]; c++) { total++; if (IsAllocated(run[0] + c)) used++; }
            }
            if (total == 0) { f.Chance = "Empty"; f.Score = 0; }
            else if (used == 0) { f.Chance = f.Note == null ? "Good" : "Fair"; f.Score = f.Note == null ? 3 : 2; }
            else if (used < total)
            {
                f.Chance = "Poor"; f.Score = 1;
                f.Note = (used * 100 / total) + "% has been overwritten";
            }
            else { f.Chance = "Overwritten"; f.Score = 0; f.Note = "Its space is in use by other files"; }
        }

        // Re-reads cluster allocation (call right before recovering) and re-rates every result.
        public void Refresh()
        {
            LoadBitmap();
            foreach (DeletedFile f in all) Rate(f);
        }

        public List<DeletedFile> Filter(string query, int minScore, int max, out int matched)
        {
            var list = new List<DeletedFile>();
            matched = 0;
            string q = string.IsNullOrEmpty(query) ? null : query.ToLowerInvariant();
            foreach (DeletedFile f in all)
            {
                if (f.Score < minScore) continue;
                if (q != null && f.Name.ToLowerInvariant().IndexOf(q) < 0 && (f.Folder == null || f.Folder.ToLowerInvariant().IndexOf(q) < 0)) continue;
                matched++;
                list.Add(f);
            }
            list.Sort(delegate (DeletedFile a, DeletedFile b)
            {
                int c = b.Score.CompareTo(a.Score);
                return c != 0 ? c : b.Modified.CompareTo(a.Modified);
            });
            if (list.Count > max) list.RemoveRange(max, list.Count - max);
            return list;
        }

        public int CountAtLeast(int minScore)
        {
            int n = 0;
            foreach (DeletedFile f in all) if (f.Score >= minScore) n++;
            return n;
        }

        // Copies a deleted file's data out to destPath (on another volume). Returns null on success,
        // or a short warning. Never overwrites: the destination must not exist.
        public string Recover(DeletedFile f, string destPath)
        {
            if (f.Unsupported) throw new InvalidOperationException(f.Note ?? "This file can't be recovered by Computer Doctor.");
            bool anyData = false;
            using (var fs = new FileStream(destPath, FileMode.CreateNew, FileAccess.Write))
            {
                if (f.Resident)
                {
                    fs.Write(f.ResidentData, 0, f.ResidentData.Length);
                    anyData = f.ResidentData.Length > 0;
                }
                else
                {
                    long remaining = f.Size;
                    int chunkClusters = Math.Max(1, (1024 * 1024) / BytesPerCluster);
                    byte[] buf = new byte[chunkClusters * BytesPerCluster];
                    foreach (long[] run in f.Runs)
                    {
                        for (long c = 0; c < run[1] && remaining > 0; c += chunkClusters)
                        {
                            int n = (int)Math.Min(chunkClusters, run[1] - c);
                            int bytes = n * BytesPerCluster;
                            if (run[0] < 0) Array.Clear(buf, 0, bytes);
                            else ReadAt((run[0] + c) * BytesPerCluster, buf, bytes);
                            int write = (int)Math.Min(bytes, remaining);
                            if (!anyData) for (int i = 0; i < write; i++) if (buf[i] != 0) { anyData = true; break; }
                            fs.Write(buf, 0, write);
                            remaining -= write;
                        }
                        if (remaining <= 0) break;
                    }
                    if (remaining > 0) fs.SetLength(f.Size);
                }
            }
            try
            {
                if (f.Created != DateTime.MinValue) File.SetCreationTime(destPath, f.Created);
                if (f.Modified != DateTime.MinValue) File.SetLastWriteTime(destPath, f.Modified);
            }
            catch { }
            if (!anyData && f.Size > 0) return "contains only zeros - the drive has probably already erased it (TRIM)";
            return f.Note;
        }

        public void Dispose() { if (handle != null) handle.Dispose(); }
    }

    // Windows Credential Manager (generic credentials), used for saved remote connections.
    public static class CredMan
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct CREDENTIAL
        {
            public uint Flags; public uint Type; public string TargetName; public string Comment;
            public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
            public uint CredentialBlobSize; public IntPtr CredentialBlob; public uint Persist;
            public uint AttributeCount; public IntPtr Attributes; public string TargetAlias; public string UserName;
        }
        [DllImport("advapi32.dll", EntryPoint = "CredWriteW", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CredWrite(ref CREDENTIAL cred, uint flags);
        [DllImport("advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CredRead(string target, uint type, uint flags, out IntPtr cred);
        [DllImport("advapi32.dll", EntryPoint = "CredDeleteW", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CredDelete(string target, uint type, uint flags);
        [DllImport("advapi32.dll", EntryPoint = "CredEnumerateW", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CredEnumerate(string filter, uint flags, out uint count, out IntPtr creds);
        [DllImport("advapi32.dll")] private static extern void CredFree(IntPtr buffer);

        private const uint Generic = 1, PersistLocalMachine = 2;

        public static void Write(string target, string user, string password)
        {
            byte[] blob = System.Text.Encoding.Unicode.GetBytes(password ?? "");
            var c = new CREDENTIAL();
            c.Type = Generic; c.TargetName = target; c.UserName = user; c.Persist = PersistLocalMachine;
            c.Comment = "Saved by Computer Doctor for remote connections";
            c.CredentialBlobSize = (uint)blob.Length;
            c.CredentialBlob = Marshal.AllocHGlobal(Math.Max(1, blob.Length));
            try
            {
                Marshal.Copy(blob, 0, c.CredentialBlob, blob.Length);
                if (!CredWrite(ref c, 0)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            }
            finally { Marshal.FreeHGlobal(c.CredentialBlob); }
        }

        // Returns { user, password } or null.
        public static string[] Read(string target)
        {
            IntPtr p;
            if (!CredRead(target, Generic, 0, out p)) return null;
            try
            {
                var c = (CREDENTIAL)Marshal.PtrToStructure(p, typeof(CREDENTIAL));
                string pw = c.CredentialBlobSize > 0 ? Marshal.PtrToStringUni(c.CredentialBlob, (int)c.CredentialBlobSize / 2) : "";
                return new string[] { c.UserName, pw };
            }
            finally { CredFree(p); }
        }

        public static bool Delete(string target) { return CredDelete(target, Generic, 0); }

        // Saved connections are stored as "<Prefix><host>". Before the rename to Computer Doctor the
        // prefix was "AWiper:", so those are still read and moved over by MoveOld().
        public const string Prefix = "ComputerDoctor:";
        public const string OldPrefix = "AWiper:";

        public static string[] ReadHost(string host)
        {
            string h = (host ?? "").ToLowerInvariant();
            return Read(Prefix + h) ?? Read(OldPrefix + h);
        }

        // Copies credentials saved under the old prefix to the new one and removes the old entries.
        // Returns how many were moved.
        public static int MoveOld()
        {
            int moved = 0;
            foreach (string oldTarget in List(OldPrefix + "*"))
            {
                if (!oldTarget.StartsWith(OldPrefix, StringComparison.OrdinalIgnoreCase)) continue;
                string h = oldTarget.Substring(OldPrefix.Length);
                string[] c = Read(oldTarget);
                if (c == null) continue;
                if (Read(Prefix + h) == null) Write(Prefix + h, c[0], c[1]);
                Delete(oldTarget);
                moved++;
            }
            return moved;
        }

        public static string[] List(string filter)
        {
            uint n; IntPtr arr;
            var names = new List<string>();
            if (!CredEnumerate(filter, 0, out n, out arr)) return names.ToArray();
            try
            {
                for (int i = 0; i < n; i++)
                {
                    IntPtr cp = Marshal.ReadIntPtr(arr, i * IntPtr.Size);
                    var c = (CREDENTIAL)Marshal.PtrToStructure(cp, typeof(CREDENTIAL));
                    names.Add(c.TargetName);
                }
            }
            finally { CredFree(arr); }
            return names.ToArray();
        }
    }

    public static class Native
    {
        [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
        [DllImport("kernel32.dll")] public static extern uint GetConsoleProcessList(uint[] list, uint count);
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport("shell32.dll", CharSet = CharSet.Unicode)] public static extern int SHEmptyRecycleBin(IntPtr hwnd, string root, uint flags);

        // Authenticates to a remote share (e.g. \\PC\C$) for this logon session, without a drive letter.
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private class NETRESOURCE { public int dwScope; public int dwType = 1; public int dwDisplayType; public int dwUsage; public string lpLocalName; public string lpRemoteName; public string lpComment; public string lpProvider; }
        [DllImport("mpr.dll", CharSet = CharSet.Unicode)] private static extern int WNetAddConnection2(NETRESOURCE res, string password, string user, int flags);
        [DllImport("mpr.dll", CharSet = CharSet.Unicode)] private static extern int WNetCancelConnection2(string name, int flags, bool force);
        // Returns 0 on success; 1219 means a connection with other credentials already exists (it is still usable).
        public static int ConnectShare(string unc, string user, string password)
        {
            var r = new NETRESOURCE(); r.lpRemoteName = unc;
            return WNetAddConnection2(r, password, user, 4 /* CONNECT_TEMPORARY */);
        }
        public static int DisconnectShare(string unc) { return WNetCancelConnection2(unc, 0, true); }
        // Deletes one System Restore point by sequence number (the API System Properties uses). Returns 0 on success.
        [DllImport("srclient.dll")] public static extern int SRRemoveRestorePoint(int sequenceNumber);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool GetVolumePathName(string fileName, System.Text.StringBuilder volumePath, uint length);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool GetVolumeNameForVolumeMountPoint(string mountPoint, System.Text.StringBuilder volumeName, uint length);

        // Stable identity of the volume holding a path (\\?\Volume{GUID}\), so two drive letters or a
        // mounted folder pointing at the same volume are still detected as the same disk.
        public static string VolumeId(string path)
        {
            var root = new System.Text.StringBuilder(1024);
            if (!GetVolumePathName(path, root, 1024)) return null;
            var name = new System.Text.StringBuilder(1024);
            if (!GetVolumeNameForVolumeMountPoint(root.ToString(), name, 1024)) return root.ToString().ToUpperInvariant();
            return name.ToString().ToUpperInvariant();
        }

        // Asks the given processes to close the way clicking X does: WM_CLOSE to each of their visible top-level
        // windows. Nothing is force-closed; an app can still ask about unsaved work. Returns the windows asked.
        private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
        [DllImport("user32.dll")] private static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] private static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
        [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll")] private static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
        public static int CloseWindows(int[] pids)
        {
            var want = new Dictionary<uint, bool>();
            foreach (var p in pids) want[(uint)p] = true;
            var found = new List<IntPtr>();
            EnumWindows(delegate (IntPtr h, IntPtr l)
            {
                uint pid;
                GetWindowThreadProcessId(h, out pid);
                if (want.ContainsKey(pid) && IsWindowVisible(h) && GetWindow(h, 4 /* GW_OWNER */) == IntPtr.Zero) found.Add(h);
                return true;
            }, IntPtr.Zero);
            foreach (var h in found) PostMessage(h, 0x0010 /* WM_CLOSE */, IntPtr.Zero, IntPtr.Zero);
            return found.Count;
        }

        // Long form of a path that may hold 8.3 short names (%TEMP% often does), or the path itself.
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] private static extern uint GetLongPathName(string shortPath, System.Text.StringBuilder longPath, uint size);
        public static string LongPath(string path)
        {
            if (string.IsNullOrEmpty(path) || path.IndexOf('~') < 0) return path;
            var sb = new System.Text.StringBuilder(1024);
            uint n = GetLongPathName(path, sb, 1024);
            return (n > 0 && n < 1024) ? sb.ToString() : path;
        }

        public static bool OwnsConsole()
        {
            try { var l = new uint[8]; return GetConsoleProcessList(l, 8) <= 1; } catch { return false; }
        }
    }
}
'@
}

# Hide the console only when Computer Doctor owns it (double-click / elevated relaunch), never a shared terminal.
if (-not $script:CliMode -and -not $ShowConsole -and [ComputerDoctor.Native]::OwnsConsole()) {
    $hwnd = [ComputerDoctor.Native]::GetConsoleWindow()
    if ($hwnd -ne [IntPtr]::Zero) { [void][ComputerDoctor.Native]::ShowWindow($hwnd, 0) }
}
#endregion

#region ---------------------------------------------------------------- Paths, state, logging
# Computer Doctor used to be called AWiper. On the first start after the rename, copy the old data
# folders across (the old folders are left in place). Snapshot links are never copied: they point
# into shadow copies of whole drives.
function Copy-AWOldData {
    $new = Join-Path $env:LOCALAPPDATA 'ComputerDoctor'
    $old = Join-Path $env:LOCALAPPDATA 'AWiper'
    if (-not (Test-Path -LiteralPath $new) -and (Test-Path -LiteralPath $old -PathType Container)) {
        try {
            New-Item -ItemType Directory -Path $new -Force | Out-Null
            foreach ($item in @(Get-ChildItem -LiteralPath $old -Force -ErrorAction Stop)) {
                if ($item.Name -eq 'Snapshots' -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
                $name = if ($item.Name -eq 'AWiper.log') { 'ComputerDoctor.log' } else { $item.Name }
                Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $new $name) -Recurse -Force -ErrorAction Stop
            }
        } catch { }
    }
    # The action log. %ProgramData% may need admin rights; if the copy fails, the old log stays where it is.
    $new = Join-Path $env:ProgramData 'ComputerDoctor\Logs'
    $old = Join-Path $env:ProgramData 'AWiper\Logs'
    if (-not (Test-Path -LiteralPath $new) -and (Test-Path -LiteralPath $old -PathType Container)) {
        try {
            New-Item -ItemType Directory -Path $new -Force | Out-Null
            Copy-Item -Path (Join-Path $old '*') -Destination $new -Recurse -Force -ErrorAction Stop
        } catch { }
    }
}
Copy-AWOldData

$script:DataDir   = Join-Path $env:LOCALAPPDATA 'ComputerDoctor'
$script:LogFile   = Join-Path $script:DataDir 'ComputerDoctor.log'
$script:StateFile = Join-Path $script:DataDir 'state.json'
if (-not (Test-Path -LiteralPath $script:DataDir)) { New-Item -ItemType Directory -Path $script:DataDir -Force | Out-Null }

function Read-AWAutoCleanState($j) {
    $a = $j.AutoClean
    if (-not $a) { return }
    $ac = $script:State.AutoClean
    $ac.Enabled = [bool]$a.Enabled
    $ac.Rules = @($a.Rules | Where-Object { $_ } | ForEach-Object { [string]$_ })
    if ($a.Day -in 'Daily', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') { $ac.Day = [string]$a.Day }
    if ([string]$a.Time -match '^([01]?\d|2[0-3]):[0-5]\d$') { $ac.Time = [string]$a.Time }
    $ac.LastRun = if ($a.LastRun -is [datetime]) { $a.LastRun.ToString('o') } elseif ($a.LastRun) { [string]$a.LastRun } else { $null }
    $ac.LastFreed = [long]$a.LastFreed
    $ac.LastResult = [string]$a.LastResult
}

$script:State = @{ TotalFreed = [long]0; Cleans = 0; LastClean = ''; RecentTargets = @(); AutoRestorePoint = $true; ResourcesPath = ''; ForceOffline = $false
                   FleetHosts = ''; OldFolders = @('Downloads'); Backup = @{ Sources = @(); Dest = ''; DestVolumeId = ''; Keep = 10; Daily = $false; Time = '19:00'; LastRun = ''; LastResult = '' }
                   AutoClean = [ordered]@{ Enabled = $false; Rules = @(); Day = 'Sunday'; Time = '12:00'; LastRun = $null; LastFreed = [long]0; LastResult = '' }
                   MapHighlight = $true; ProgramsScope = 'All' }
# Keys this edition doesn't know (the Windows app shares state.json) are kept as they are.
$script:StateExtra = [ordered]@{}
try {
    if (Test-Path -LiteralPath $script:StateFile) {
        $j = Get-Content -LiteralPath $script:StateFile -Raw | ConvertFrom-Json
        $script:State.TotalFreed = [long]$j.TotalFreed
        $script:State.Cleans     = [int]$j.Cleans
        $script:State.LastClean  = if ($j.LastClean -is [datetime]) { $j.LastClean.ToString('o') } else { [string]$j.LastClean }
        if ($j.RecentTargets) { $script:State.RecentTargets = @($j.RecentTargets | ForEach-Object { [string]$_ }) }
        if ($null -ne $j.AutoRestorePoint) { $script:State.AutoRestorePoint = [bool]$j.AutoRestorePoint }
        if ($j.ResourcesPath) { $script:State.ResourcesPath = [string]$j.ResourcesPath }
        if ($null -ne $j.ForceOffline) { $script:State.ForceOffline = [bool]$j.ForceOffline }
        if ($j.FleetHosts) { $script:State.FleetHosts = [string]$j.FleetHosts }
        if ($j.OldFolders) { $script:State.OldFolders = @($j.OldFolders | ForEach-Object { [string]$_ }) }
        if ($j.Backup) {
            foreach ($k in 'Dest', 'DestVolumeId', 'Time', 'LastRun', 'LastResult') { if ($j.Backup.$k) { $script:State.Backup[$k] = [string]$j.Backup.$k } }
            if ($j.Backup.Sources) { $script:State.Backup.Sources = @($j.Backup.Sources | ForEach-Object { [string]$_ }) }
            if ($j.Backup.Keep) { $script:State.Backup.Keep = [int]$j.Backup.Keep }
            $script:State.Backup.Daily = [bool]$j.Backup.Daily
        }
        Read-AWAutoCleanState $j
        if ($null -ne $j.MapHighlight) { $script:State.MapHighlight = [bool]$j.MapHighlight }
        if ($j.ProgramsScope -in 'All', 'Just me', 'All users') { $script:State.ProgramsScope = [string]$j.ProgramsScope }
        foreach ($pr in $j.PSObject.Properties) { if (-not $script:State.ContainsKey($pr.Name)) { $script:StateExtra[$pr.Name] = $pr.Value } }
    }
} catch { }

function Save-AWState {
    $out = [ordered]@{}
    foreach ($k in $script:StateExtra.Keys) { $out[$k] = $script:StateExtra[$k] }
    foreach ($k in $script:State.Keys) { $out[$k] = $script:State[$k] }
    try { ConvertTo-Json -InputObject $out -Depth 8 | Set-Content -LiteralPath $script:StateFile -Encoding UTF8 } catch { }
}

# Re-reads only AutoClean from state.json (the scheduled run, or the other edition, may have written it since).
function Update-AWAutoCleanFromDisk {
    try { if (Test-Path -LiteralPath $script:StateFile) { Read-AWAutoCleanState (Get-Content -LiteralPath $script:StateFile -Raw | ConvertFrom-Json) } } catch { }
}

$Sync = [hashtable]::Synchronized(@{})
$Sync.Log      = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$Sync.Status   = ''
$Sync.Progress = -1
$Sync.Scanning = $false

function Write-AWLog {
    param([string]$Message, [string]$Level = 'INFO')
    $Sync.Log.Enqueue(('{0:HH:mm:ss}  {1,-5}  {2}' -f (Get-Date), $Level, $Message))
}

function Format-AWSize([long]$Bytes) { [ComputerDoctor.Fmt]::Size($Bytes) }

# ---------------- Action log (append-only JSON lines) and undo journal
# Every change Computer Doctor makes is recorded: who, when, which computer, what, and the result.
# Lines go to %ProgramData%\ComputerDoctor\Logs\actions-<yyyy-MM>.jsonl and, when running as admin,
# to the Application event log (source "ComputerDoctor") so event forwarding / SIEM can pick them up.
$script:ActionLogDir = Join-Path $env:ProgramData 'ComputerDoctor\Logs'
$script:UndoFile = Join-Path $script:DataDir 'undo.json'

function Write-AWAction([string]$Action, $Items = @(), [hashtable]$Details = @{}, [string]$Result = 'Started', [string]$UndoId = '') {
    $target = if ($script:Target) { $script:Target.ComputerName } else { $env:COMPUTERNAME }
    $entry = [ordered]@{
        Time = (Get-Date).ToString('o'); User = "$env:USERDOMAIN\$env:USERNAME"; Computer = $env:COMPUTERNAME; Target = $target
        Action = $Action; Items = @($Items | ForEach-Object { "$_" }); Details = $Details; Result = $Result; UndoId = $UndoId
        Mode = $(if ($script:CliMode) { 'CLI' } else { 'GUI' }); Version = $script:AppVersion
    }
    $line = ConvertTo-Json -InputObject $entry -Compress -Depth 6
    foreach ($dir in @($script:ActionLogDir, (Join-Path $script:DataDir 'Logs'))) {
        try {
            if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            [IO.File]::AppendAllText((Join-Path $dir ('actions-{0:yyyy-MM}.jsonl' -f (Get-Date))), $line + "`n")
            break
        } catch { }
    }
    if ($script:IsAdmin) {
        try {
            if (-not [Diagnostics.EventLog]::SourceExists('ComputerDoctor')) { [Diagnostics.EventLog]::CreateEventSource('ComputerDoctor', 'Application') }
            $msg = "Computer Doctor $Action on $target by $($entry.User): $Result`n" + (($entry.Items | Select-Object -First 50) -join "`n")
            [Diagnostics.EventLog]::WriteEntry('ComputerDoctor', $msg, $(if ($Result -match 'fail|error') { 'Warning' } else { 'Information' }), 1000)
        } catch { }
    }
}

function Get-AWUndoJournal {
    try {
        if (-not (Test-Path -LiteralPath $script:UndoFile)) { return @() }
        $j = Get-Content -LiteralPath $script:UndoFile -Raw | ConvertFrom-Json
        @($j)
    } catch { @() }
}

function Save-AWUndoJournal($Entries) {
    try { ConvertTo-Json -InputObject @($Entries | Select-Object -Last 200) -Depth 8 | Set-Content -LiteralPath $script:UndoFile -Encoding UTF8 } catch { }
}

# Records the "before" snapshot returned by a change (e.g. Set-WTweak) so it can be put back later.
function Add-AWUndoEntry($Capture) {
    $id = [guid]::NewGuid().ToString('N').Substring(0, 12)
    $entry = [pscustomobject]@{
        Id = $id; Time = (Get-Date).ToString('o'); Label = [string]$Capture.Label; Kind = [string]$Capture.UndoKind
        Target = $(if ($script:Target) { $script:Target.ComputerName } else { $env:COMPUTERNAME })
        TargetHost = $(if ($script:Target) { $script:Target.Host } else { '' })
        Snapshot = @($Capture.Snapshot | ForEach-Object { [pscustomobject]@{ Path = $_.Path; Name = $_.Name; Existed = $_.Existed; Prev = $_.Prev; Kind = $_.Kind } })
        RemoveKeys = @($Capture.RemoveKeys); Revert = [string]$Capture.Revert; Undone = $false
    }
    # The same undo as Windows tools (Tool + Args in System32), so the Windows app can undo it too; this edition uses Revert.
    if ($Capture.AppRevert) {
        $entry | Add-Member -NotePropertyName AppRevert -NotePropertyValue @($Capture.AppRevert | ForEach-Object { [pscustomobject]@{ Tool = [string]$_.Tool; Args = [string]$_.Args } })
    }
    Save-AWUndoJournal (@(Get-AWUndoJournal) + $entry)
    $id
}

# Description for an automatic restore point before a risky batch, or $null when the option is off.
function Get-AWAutoRP([string]$Reason) {
    if ($script:State.AutoRestorePoint -and ($script:IsAdmin -or $script:Target)) { "Computer Doctor - before $Reason" } else { $null }
}

# Things registered under the old name (AWiper) move to the new one: saved remote-connection
# credentials and the two scheduled tasks. Runs once the window is open. The old "AWiper" event log
# source is left alone so earlier entries in the Application log stay readable.
function Move-AWOldRegistrations {
    try {
        $n = [ComputerDoctor.CredMan]::MoveOld()
        if ($n) { Write-AWLog "Moved $n saved connection(s) from AWiper to Computer Doctor" }
    } catch { Write-AWLog "Could not move saved connections from AWiper: $($_.Exception.Message)" 'WARN' }
    if (-not $PSCommandPath -or -not (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue)) { return }

    # Daily folder backup (runs as the signed-in user): point it at this script.
    try {
        $old = Get-ScheduledTask -TaskName 'AWiper Backup' -ErrorAction SilentlyContinue
        if ($old) {
            if (-not (Get-ScheduledTask -TaskName 'ComputerDoctor Backup' -ErrorAction SilentlyContinue)) {
                $exe = (Get-Process -Id $PID).Path
                $action = New-ScheduledTaskAction -Execute $exe -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`" -Backup -Yes"
                Register-ScheduledTask -TaskName 'ComputerDoctor Backup' -Action $action -Trigger $old.Triggers -Settings $old.Settings `
                    -Description 'Folder backup set up in Computer Doctor (Recovery > Backup).' -Force | Out-Null
            }
            Unregister-ScheduledTask -TaskName 'AWiper Backup' -Confirm:$false
            Write-AWLog 'Moved the daily backup schedule from AWiper to Computer Doctor'
        }
    } catch { Write-AWLog "Could not move the AWiper backup schedule: $($_.Exception.Message)" 'WARN' }

    # Scheduled maintenance runs as SYSTEM from an admin-only folder, so moving it needs admin rights.
    if (-not $script:IsAdmin) { return }
    try {
        $old = Get-ScheduledTask -TaskName 'AWiper Maintenance' -ErrorAction SilentlyContinue
        if ($old) {
            if (-not (Get-ScheduledTask -TaskName 'ComputerDoctor Maintenance' -ErrorAction SilentlyContinue)) {
                $oldRoot = Join-Path $env:ProgramData 'AWiper'; $newRoot = Join-Path $env:ProgramData 'ComputerDoctor'
                $dir = Join-Path $newRoot 'Scheduled'
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                # Admins and SYSTEM full control, users read-only, no inherited write access (as in New-AWScheduledMaintenance).
                & icacls.exe $dir /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' 2>&1 | Out-Null
                $oldProfile = Join-Path $oldRoot 'Scheduled\maintenance.json'
                if (Test-Path -LiteralPath $oldProfile) { Copy-Item -LiteralPath $oldProfile -Destination (Join-Path $dir 'maintenance.json') -Force }
                Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $dir 'ComputerDoctor.ps1') -Force
                $a = @($old.Actions)[0]
                $arg = ([string]$a.Arguments) -ireplace [regex]::Escape("$oldRoot\"), "$newRoot\" -ireplace 'AWiper\.ps1', 'ComputerDoctor.ps1'
                if ($arg -like "*$newRoot\Results*") { New-Item -ItemType Directory -Path (Join-Path $newRoot 'Results') -Force | Out-Null }
                Register-ScheduledTask -TaskName 'ComputerDoctor Maintenance' -Action (New-ScheduledTaskAction -Execute $a.Execute -Argument $arg) -Trigger $old.Triggers `
                    -Principal $old.Principal -Settings $old.Settings -Description 'Computer Doctor scheduled maintenance' -Force | Out-Null
            }
            Unregister-ScheduledTask -TaskName 'AWiper Maintenance' -Confirm:$false
            Write-AWLog 'Moved scheduled maintenance from AWiper to Computer Doctor'
        }
    } catch { Write-AWLog "Could not move the AWiper maintenance schedule: $($_.Exception.Message)" 'WARN' }
}
#endregion

#region ---------------------------------------------------------------- Worker library (runs inside background runspaces)
$Sync.WorkerLib = @'
function Write-WLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0:HH:mm:ss}  {1,-5}  {2}' -f (Get-Date), $Level, $Message
    # On a remote machine the line travels back on the information stream (see Invoke-WTarget).
    if ($Sync.Remote) { Write-Information -MessageData $line -InformationAction SilentlyContinue }
    else { $Sync.Log.Enqueue($line); if ($Sync.Echo) { [Console]::Out.WriteLine($line) } }
}

function Format-WSize([long]$Bytes) {
    if ($Bytes -lt 1024) { return "$Bytes B" }
    $u = 'KB', 'MB', 'GB', 'TB', 'PB'; $d = $Bytes / 1024.0; $i = 0
    while ($d -ge 1024 -and $i -lt $u.Count - 1) { $d /= 1024; $i++ }
    $f = if ($d -ge 100) { '0' } elseif ($d -ge 10) { '0.0' } else { '0.00' }
    $d.ToString($f, [Globalization.CultureInfo]::InvariantCulture) + ' ' + $u[$i]
}

# Runs a script block on the current target: locally, or over WinRM when $Target is set.
# Remotely, this worker library is loaded first so the same helper functions are available.
function Invoke-WTarget {
    param([scriptblock]$Script, [object[]]$ArgumentList = @())
    if (-not $Target) { return & $Script @ArgumentList }
    $wrapper = {
        param($Lib, $Body, $Argz)
        $Sync = @{ Remote = $true }
        . ([scriptblock]::Create($Lib))
        & ([scriptblock]::Create($Body)) @Argz
    }
    $p = @{ ComputerName = $Target.Host; ScriptBlock = $wrapper; ArgumentList = @($Sync.WorkerLib, $Script.ToString(), $ArgumentList); ErrorAction = 'Stop' }
    if ($Target.Credential) { $p.Credential = $Target.Credential }
    Invoke-Command @p 6>&1 | ForEach-Object {
        if ($_ -is [System.Management.Automation.InformationRecord]) { $Sync.Log.Enqueue(('{0}  [{1}]' -f $_.MessageData, $Target.Host)) }
        else { $_ }
    }
}

# Every user's Recycle Bin on every local drive. Each deleted item is a $I file (metadata) plus a
# $R file or folder (content). $I v1 (Vista-8.1): fixed 520-byte path at offset 24. $I v2 (Win10+):
# path length in characters (including the null) at offset 24, path at 28.
function Get-WRecycleItems {
    $names = @{}
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
        if (-not $d.IsReady -or ($d.DriveType -ne 'Fixed' -and $d.DriveType -ne 'Removable')) { continue }
        $root = Join-Path $d.RootDirectory.FullName '$Recycle.Bin'
        $bins = @()
        try { $bins = @(Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction Stop) } catch { continue }
        foreach ($bin in $bins) {
            $ifiles = @()
            try { $ifiles = @(Get-ChildItem -LiteralPath $bin.FullName -Force -File -Filter '$I*' -ErrorAction Stop) }
            catch {
                # Other users' bins are expected to be off-limits without admin rights.
                if ($admin) { Write-WLog "Recycle Bin of $($bin.Name) on $($d.Name) is not readable: $($_.Exception.Message)" 'WARN' }
                continue
            }
            if (-not $names.ContainsKey($bin.Name)) {
                $names[$bin.Name] = try { (New-Object System.Security.Principal.SecurityIdentifier $bin.Name).Translate([System.Security.Principal.NTAccount]).Value } catch { $bin.Name }
            }
            foreach ($i in $ifiles) {
                try {
                    $b = [System.IO.File]::ReadAllBytes($i.FullName)
                    if ($b.Length -lt 28) { continue }
                    $ver = [BitConverter]::ToInt64($b, 0)
                    if ($ver -eq 1) { $path = [System.Text.Encoding]::Unicode.GetString($b, 24, [Math]::Min(520, $b.Length - 24)) }
                    elseif ($ver -eq 2) {
                        $n = [BitConverter]::ToInt32($b, 24)
                        $path = [System.Text.Encoding]::Unicode.GetString($b, 28, [Math]::Max(0, [Math]::Min($n * 2, $b.Length - 28)))
                    }
                    else { continue }
                    $path = $path.Split([char]0)[0]
                    $r = Join-Path $bin.FullName ('$R' + $i.Name.Substring(2))
                    if (-not $path -or -not (Test-Path -LiteralPath $r)) { continue }
                    $del = try { [DateTime]::FromFileTime([BitConverter]::ToInt64($b, 16)) } catch { [DateTime]::MinValue }
                    [pscustomobject]@{
                        IPath = $i.FullName; RPath = $r; OriginalPath = $path; Size = [BitConverter]::ToInt64($b, 8); Deleted = $del
                        IsDir = (Test-Path -LiteralPath $r -PathType Container); Owner = $names[$bin.Name]
                    }
                } catch { Write-WLog "Skipped $($i.FullName): $($_.Exception.Message)" 'WARN' }
            }
        }
    }
}

# Moves a recycled item back out. Never overwrites: a name clash gets " (restored)", " (restored 2)"...
function Restore-WRecycleItem([string]$IPath, [string]$RPath, [string]$Destination) {
    $dest = $Destination
    if (Test-Path -LiteralPath $dest) {
        $dir = Split-Path $Destination -Parent
        $isDir = Test-Path -LiteralPath $RPath -PathType Container
        $base = if ($isDir) { Split-Path $Destination -Leaf } else { [System.IO.Path]::GetFileNameWithoutExtension($Destination) }
        $ext  = if ($isDir) { '' } else { [System.IO.Path]::GetExtension($Destination) }
        $n = 1
        do {
            $suffix = if ($n -eq 1) { ' (restored)' } else { " (restored $n)" }
            $dest = Join-Path $dir ($base + $suffix + $ext); $n++
        } while (Test-Path -LiteralPath $dest)
    }
    $parent = Split-Path $dest -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $sameVolume = [System.IO.Path]::GetPathRoot($RPath) -eq [System.IO.Path]::GetPathRoot($dest)
    if (Test-Path -LiteralPath $RPath -PathType Container) {
        if ($sameVolume) { [System.IO.Directory]::Move($RPath, $dest) }
        else { Copy-Item -LiteralPath $RPath -Destination $dest -Recurse -ErrorAction Stop; Remove-Item -LiteralPath $RPath -Recurse -Force }
    } else {
        if ($sameVolume) { [System.IO.File]::Move($RPath, $dest) }
        else { Copy-Item -LiteralPath $RPath -Destination $dest -ErrorAction Stop; Remove-Item -LiteralPath $RPath -Force }
    }
    Remove-Item -LiteralPath $IPath -Force -ErrorAction SilentlyContinue
    Write-WLog "Restored $dest"
    $dest
}

# Drive facts that decide whether deleted data can still be on the disk.
function Get-WRecoveryDrives {
    $trim = $null
    try {
        $o = (& fsutil.exe behavior query DisableDeleteNotify 2>&1) -join "`n"
        if ($o -match 'NTFS DisableDeleteNotify\s*=\s*(\d)') { $trim = $Matches[1] -eq '0' }
    } catch { }
    $phys = @{}
    try { foreach ($p in (Get-PhysicalDisk -ErrorAction Stop)) { $phys[[string]$p.DeviceId] = $p } } catch { }
    foreach ($v in @(Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and "$($_.DriveType)" -in 'Fixed', 'Removable' } | Sort-Object DriveLetter)) {
        $p = $null
        try { $p = $phys[[string](Get-Partition -DriveLetter $v.DriveLetter -ErrorAction Stop).DiskNumber] } catch { }
        [pscustomobject]@{
            Drive = "$($v.DriveLetter):"; Label = [string]$v.FileSystemLabel; FS = [string]$(if ($v.FileSystem) { $v.FileSystem } else { $v.FileSystemType })
            Size = [long]$v.Size; Free = [long]$v.SizeRemaining; Type = [string]$v.DriveType
            Media = [string]$(if ($p) { $p.MediaType } else { '' }); Bus = [string]$(if ($p) { $p.BusType } else { '' })
            Model = [string]$(if ($p) { $p.FriendlyName } else { '' }); Trim = $trim
        }
    }
}

function Get-WRegValue([string]$Path, [string]$Name) {
    try {
        $k = Get-Item -LiteralPath $Path -ErrorAction Stop
        $k.GetValue($(if ($Name -eq '(default)') { '' } else { $Name }), $null)
    } catch { $null }
}

function Test-WTweak($Tweak) {
    foreach ($v in $Tweak.Values) {
        $cur = Get-WRegValue $v.Path $v.Name
        if ($null -eq $cur -or "$cur" -ne "$($v.Value)") { return $false }
    }
    $true
}

function Get-WRegValueKind([string]$Path, [string]$Name) {
    try { [string](Get-Item -LiteralPath $Path -ErrorAction Stop).GetValueKind($(if ($Name -eq '(default)') { '' } else { $Name })) } catch { $null }
}

# Snapshot of registry values before a change, for the undo journal.
function Get-WRegSnapshot($Values) {
    foreach ($v in $Values) {
        [pscustomobject]@{
            Path = $v.Path; Name = $v.Name; Existed = (Test-Path -LiteralPath $v.Path)
            Prev = (Get-WRegValue $v.Path $v.Name); Kind = (Get-WRegValueKind $v.Path $v.Name)
        }
    }
}

# Puts registry values back exactly as a snapshot recorded them (absent values are removed again).
function Restore-WRegSnapshot($Snapshot, $RemoveKeys = @()) {
    foreach ($s in $Snapshot) {
        if ($null -eq $s.Prev) {
            if ($s.Name -ne '(default)') { Remove-ItemProperty -LiteralPath $s.Path -Name $s.Name -ErrorAction SilentlyContinue }
            continue
        }
        if (-not (Test-Path -LiteralPath $s.Path)) { New-Item -Path $s.Path -Force | Out-Null }
        $val = $s.Prev
        switch ($s.Kind) { 'Binary' { $val = [byte[]]@($s.Prev) } 'MultiString' { $val = [string[]]@($s.Prev) } }
        if ($s.Name -eq '(default)') { Set-Item -LiteralPath $s.Path -Value $val }
        else { New-ItemProperty -LiteralPath $s.Path -Name $s.Name -PropertyType $(if ($s.Kind) { $s.Kind } else { 'String' }) -Value $val -Force | Out-Null }
    }
    # Keys the change created (e.g. the classic context-menu CLSID) are removed when nothing existed before.
    foreach ($k in $RemoveKeys) {
        $created = @($Snapshot | Where-Object { $_.Path -like "$k*" -and -not $_.Existed }).Count -gt 0
        if ($created -and $k -like 'HK*:\Software\Classes\CLSID\{*}') { Remove-Item -LiteralPath $k -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Set-WTweak($Tweak, [bool]$Apply) {
    $before = @(Get-WRegSnapshot $Tweak.Values)
    foreach ($v in $Tweak.Values) {
        if ($Apply -or $null -ne $v.Revert) {
            $val = if ($Apply) { $v.Value } else { $v.Revert }
            if (-not (Test-Path -LiteralPath $v.Path)) { New-Item -Path $v.Path -Force | Out-Null }
            if ($v.Name -eq '(default)') { Set-Item -LiteralPath $v.Path -Value $val }
            else { New-ItemProperty -LiteralPath $v.Path -Name $v.Name -PropertyType $v.Type -Value $val -Force | Out-Null }
        }
        elseif ($v.Name -ne '(default)') {
            Remove-ItemProperty -LiteralPath $v.Path -Name $v.Name -ErrorAction SilentlyContinue
        }
    }
    if (-not $Apply) {
        foreach ($k in $Tweak.RemoveKeys) { if ($k -like 'HK*:\Software\Classes\CLSID\{*}') { Remove-Item -LiteralPath $k -Recurse -Force -ErrorAction SilentlyContinue } }
    }
    Write-WLog ('{0} tweak: {1}' -f $(if ($Apply) { 'Applied' } else { 'Reverted' }), $Tweak.Name)
    [pscustomobject]@{ UndoKind = 'Registry'; TweakId = $Tweak.Id; Applied = $Apply; Label = ('{0} "{1}"' -f $(if ($Apply) { 'Applied' } else { 'Reverted' }), $Tweak.Name); Snapshot = $before; RemoveKeys = @($Tweak.RemoveKeys) }
}

# Creates a restore point even if one was made in the last 24 hours (Windows' default throttle):
# the SystemRestorePointCreationFrequency value is set to 0 for the call and put back afterwards.
function New-WRestorePoint([string]$Description) {
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    $prev = Get-WRegValue $key 'SystemRestorePointCreationFrequency'
    try {
        New-ItemProperty -LiteralPath $key -Name 'SystemRestorePointCreationFrequency' -PropertyType DWord -Value 0 -Force | Out-Null
        $r = Invoke-CimMethod -Namespace root/default -ClassName SystemRestore -MethodName CreateRestorePoint `
             -Arguments @{ Description = $Description; RestorePointType = [uint32]12; EventType = [uint32]100 } -ErrorAction Stop
        if ($r.ReturnValue -eq 0) { Write-WLog "Restore point created: $Description"; return $true }
        Write-WLog "Restore point returned code $($r.ReturnValue) - System Protection may be off for the system drive" 'WARN'
        $false
    } catch { Write-WLog "Restore point failed: $($_.Exception.Message)" 'ERROR'; $false }
    finally {
        if ($null -eq $prev) { Remove-ItemProperty -LiteralPath $key -Name 'SystemRestorePointCreationFrequency' -ErrorAction SilentlyContinue }
        else { New-ItemProperty -LiteralPath $key -Name 'SystemRestorePointCreationFrequency' -PropertyType DWord -Value $prev -Force | Out-Null }
    }
}

# Removable Store packages for this user (or all users when $AllUsers), plus whether a provisioned copy exists.
function Get-WStoreAppsRaw([bool]$AllUsers) {
    if ($PSVersionTable.PSVersion.Major -ge 7) { Import-Module Appx -UseWindowsPowerShell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue }
    $prov = @{}
    if ($AllUsers) {
        try { foreach ($p in (Get-AppxProvisionedPackage -Online -ErrorAction Stop)) { $prov[$p.DisplayName] = $true } }
        catch { Write-WLog "Could not read provisioned apps: $($_.Exception.Message)" 'WARN' }
    }
    $pk = if ($AllUsers) { Get-AppxPackage -AllUsers } else { Get-AppxPackage }
    foreach ($p in $pk) {
        if ($p.IsFramework -or $p.NonRemovable -or "$($p.SignatureKind)" -eq 'System') { continue }
        [pscustomobject]@{ Name = [string]$p.Name; FullName = [string]$p.PackageFullName; Version = [string]$p.Version; Publisher = [string]$p.Publisher; Prov = [bool]$prov[$p.Name] }
    }
}

function Remove-WStoreApp($App, [bool]$AllUsers, [bool]$Prov) {
    if ($PSVersionTable.PSVersion.Major -ge 7) { Import-Module Appx -UseWindowsPowerShell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue }
    $done = $false
    if ($AllUsers) {
        try { Get-AppxPackage -AllUsers -Name $App.Package | Remove-AppxPackage -AllUsers -ErrorAction Stop; $done = $true }
        catch { Write-WLog "$($App.Name): all-users removal failed ($($_.Exception.Message)), trying current user" 'WARN' }
    }
    if (-not $done) {
        $mine = @(Get-AppxPackage -Name $App.Package)
        if ($mine.Count) { $mine | Remove-AppxPackage -ErrorAction Stop }
        else { Write-WLog "$($App.Name): not installed for this account" 'WARN' }
    }
    if ($Prov -and $App.Provisioned) {
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $App.Package } |
            Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
        Write-WLog "$($App.Name): removed provisioned copy (new users won't get it)"
    }
    Write-WLog "Removed $($App.Name)"
}

# ---------------------------------------------------------------- Offline repair media
# Opens Windows install media (an .iso under Resources\ISO, or an extracted folder containing
# sources\install.wim|esd), picks the image index matching this PC's edition and compares builds.
# DISM can only repair from the same feature release; older update levels may repair only partly.
function Open-WRepairSource([string]$MediaPath) {
    $src = [ordered]@{ Media = $MediaPath; Root = $null; Mounted = $null; Wim = $null; Index = 0; ImageName = ''; Build = 0; Ubr = 0; Sxs = $null; Usable = $false; Warning = '' }
    if ($MediaPath -like '*.iso') {
        $img = Mount-DiskImage -ImagePath $MediaPath -PassThru -ErrorAction Stop
        $src.Mounted = $MediaPath
        $letter = $null
        for ($i = 0; $i -lt 20 -and -not $letter; $i++) { $letter = ($img | Get-Volume -ErrorAction SilentlyContinue).DriveLetter; if (-not $letter) { Start-Sleep -Milliseconds 250 } }
        if (-not $letter) { throw "Mounted $MediaPath but Windows did not give it a drive letter." }
        $src.Root = "$($letter):\"
    } else { $src.Root = $MediaPath }
    $sxs = Join-Path $src.Root 'sources\sxs'
    if (Test-Path -LiteralPath $sxs) { $src.Sxs = $sxs }
    foreach ($n in 'install.wim', 'install.esd') { $p = Join-Path $src.Root "sources\$n"; if (Test-Path -LiteralPath $p) { $src.Wim = $p; break } }
    if (-not $src.Wim) { $src.Warning = 'No sources\install.wim or install.esd on this media.'; return [pscustomobject]$src }

    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $myBuild = [int]$cv.CurrentBuild; $myUbr = [int]$cv.UBR; $myEdition = [string]$cv.EditionID
    $pick = $null
    foreach ($im in @(Get-WindowsImage -ImagePath $src.Wim -ErrorAction Stop)) {
        $info = Get-WindowsImage -ImagePath $src.Wim -Index $im.ImageIndex -ErrorAction Stop
        if (-not $pick) { $pick = $info }
        if ($info.EditionId -eq $myEdition) { $pick = $info; break }
    }
    $src.Index = [int]$pick.ImageIndex; $src.ImageName = [string]$pick.ImageName
    $src.Build = [int]$pick.Build; $src.Ubr = [int]$pick.SPBuild
    if ($src.Build -ne $myBuild) {
        $src.Warning = "This media is Windows build $($src.Build), but this PC runs build $myBuild. DISM can only repair from the same Windows version - use matching media."
    } else {
        $src.Usable = $true
        $notes = @()
        if ($pick.EditionId -ne $myEdition) { $notes += "no $myEdition image on this media, using $($pick.EditionId)" }
        if ($src.Ubr -lt $myUbr) { $notes += "the media is older ($($src.Build).$($src.Ubr)) than this PC's updates ($myBuild.$myUbr), so some files may not be repairable" }
        $src.Warning = $notes -join '; '
    }
    [pscustomobject]$src
}

function Close-WRepairSource($Source) {
    if ($Source -and $Source.Mounted) { Dismount-DiskImage -ImagePath $Source.Mounted -ErrorAction SilentlyContinue | Out-Null }
}

# DISM source argument for an install image: wim:<path>:<index> or esd:<path>:<index>.
function Get-WDismSourceArg($Source) {
    $kind = if ($Source.Wim -like '*.esd') { 'esd' } else { 'wim' }
    "/Source:$($kind):$($Source.Wim):$($Source.Index)"
}

# ---------------------------------------------------------------- Resources manifest (SHA-256)
function New-WResourceManifest([string]$Root) {
    $files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'manifest.json' })
    $i = 0
    $list = foreach ($f in $files) {
        $i++; $Sync.Status = "Hashing $($f.Name) ($i of $($files.Count))..."; $Sync.Progress = [int]($i * 100 / [Math]::Max(1, $files.Count))
        [ordered]@{ Path = $f.FullName.Substring($Root.TrimEnd('\').Length + 1); Size = $f.Length; Sha256 = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash }
    }
    $doc = [ordered]@{ Created = (Get-Date).ToString('o'); Computer = $env:COMPUTERNAME; Files = @($list) }
    ConvertTo-Json -InputObject $doc -Depth 4 | Set-Content -LiteralPath (Join-Path $Root 'manifest.json') -Encoding UTF8
    Write-WLog "Resources manifest written: $($files.Count) file(s)"
    $files.Count
}

function Test-WResourceManifest([string]$Root) {
    $mf = Join-Path $Root 'manifest.json'
    if (-not (Test-Path -LiteralPath $mf)) { Write-WLog 'No manifest.json in the Resources folder - use "Build manifest" on a trusted copy first' 'WARN'; return $null }
    $doc = Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json
    $bad = 0; $ok = 0; $i = 0; $all = @($doc.Files)
    foreach ($e in $all) {
        $i++; $Sync.Status = "Verifying $($e.Path) ($i of $($all.Count))..."; $Sync.Progress = [int]($i * 100 / [Math]::Max(1, $all.Count))
        $p = Join-Path $Root $e.Path
        if (-not (Test-Path -LiteralPath $p)) { Write-WLog "Missing: $($e.Path)" 'WARN'; $bad++; continue }
        if ((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ne $e.Sha256) { Write-WLog "Changed or corrupt: $($e.Path)" 'ERROR'; $bad++; continue }
        $ok++
    }
    Write-WLog ("Resources check: {0} file(s) OK, {1} problem(s) (manifest from {2})" -f $ok, $bad, $doc.Created) $(if ($bad) { 'WARN' } else { 'INFO' })
    [pscustomobject]@{ Ok = $ok; Bad = $bad; Created = [string]$doc.Created }
}

# ---------------------------------------------------------------- Drivers
# Installed drivers joined with each device's hardware / compatible IDs, plus the PC's make, model,
# BIOS and any maker update tools that are installed.
function Get-WDriverInventory {
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
    $csp = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
    $toolPattern = 'Dell Command \| Update|SupportAssist|HP Support Assistant|HP Image Assistant|Lenovo (System Update|Vantage|Commercial Vantage)|Driver (&|and) Support Assistant|NVIDIA App|GeForce Experience|AMD Software|MSI Center|Dragon Center|MyASUS|Armoury Crate|Acer Care Center'
    $tools = @()
    foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*') {
        $tools += @(Get-ItemProperty -Path $k -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match $toolPattern } | ForEach-Object { [string]$_.DisplayName })
    }
    try { $tools += @(Get-AppxPackage -ErrorAction Stop | Where-Object { $_.Name -match 'MSICenter|MSI\.Center|MyASUS|ArmouryCrate|LenovoVantage|LenovoCompanion|DellCommandUpdate|SupportAssist|HPSupportAssistant|NVIDIAControlPanel' } | ForEach-Object { [string]$_.Name }) } catch { }
    $system = [pscustomobject]@{
        Manufacturer = [string]$cs.Manufacturer; Model = [string]$cs.Model; Family = [string]$csp.Version
        Serial = [string]$bios.SerialNumber; Bios = [string]$bios.SMBIOSBIOSVersion
        BiosDate = $(if ($bios.ReleaseDate) { [datetime]$bios.ReleaseDate } else { [datetime]::MinValue })
        BoardMaker = [string](Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue).Manufacturer
        BoardModel = [string](Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue).Product
        Tools = @($tools | Select-Object -Unique)
    }
    $ents = @{}
    foreach ($e in @(Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue)) { $ents[[string]$e.PNPDeviceID] = $e }
    $drivers = foreach ($d in @(Get-CimInstance Win32_PnPSignedDriver -ErrorAction Stop | Where-Object { $_.DeviceName -and $_.DeviceID })) {
        $e = $ents[[string]$d.DeviceID]
        [pscustomobject]@{
            DeviceId = [string]$d.DeviceID; Name = [string]$d.DeviceName; Class = [string]$d.DeviceClass
            Provider = [string]$d.DriverProviderName; Manufacturer = [string]$d.Manufacturer; Version = [string]$d.DriverVersion
            Date = $(if ($d.DriverDate) { [datetime]$d.DriverDate } else { [datetime]::MinValue }); Inf = [string]$d.InfName
            HardwareIds = @(@($e.HardwareID) + @($e.CompatibleID) + @($d.HardWareID) | Where-Object { $_ } | ForEach-Object { [string]$_ } | Select-Object -Unique)
            ErrorCode = $(if ($e) { [int]$e.ConfigManagerErrorCode } else { 0 })
        }
    }
    [pscustomobject]@{ System = $system; Drivers = @($drivers) }
}

# Driver updates Windows Update offers this PC (needs internet; ~10-60 s). Tries Windows Update
# directly first, then whatever update service the PC is configured for (e.g. WSUS).
function Open-WDriverSearch {
    $s = New-Object -ComObject Microsoft.Update.Session
    $s.ClientApplicationID = 'ComputerDoctor'
    $q = $s.CreateUpdateSearcher(); $q.Online = $true
    $err = ''
    foreach ($sel in 2, 0) {
        try {
            $q.ServerSelection = $sel
            $res = $q.Search("IsInstalled=0 and Type='Driver' and IsHidden=0")
            return [pscustomobject]@{ Session = $s; Result = $res; Source = $(if ($sel -eq 2) { 'Windows Update' } else { 'your update service' }) }
        } catch { $err = $_.Exception.Message }
    }
    throw "Windows Update could not be searched: $err"
}

function Get-WDriverUpdates {
    $o = Open-WDriverSearch
    foreach ($u in $o.Result.Updates) {
        [pscustomobject]@{
            UpdateId = [string]$u.Identity.UpdateID; Title = [string]$u.Title; Provider = [string]$u.DriverProvider
            Manufacturer = [string]$u.DriverManufacturer; Model = [string]$u.DriverModel; Class = [string]$u.DriverClass
            HardwareId = [string]$u.DriverHardwareID; VerDate = $(try { [datetime]$u.DriverVerDate } catch { [datetime]::MinValue })
            Size = [long]$u.MaxDownloadSize; Source = $o.Source
        }
    }
}

# Downloads and installs the chosen driver updates through Windows Update (local, admin).
function Install-WDriverUpdates([string[]]$UpdateIds) {
    $o = Open-WDriverSearch
    $coll = New-Object -ComObject Microsoft.Update.UpdateColl
    foreach ($u in $o.Result.Updates) {
        if ($UpdateIds -contains [string]$u.Identity.UpdateID) {
            if (-not $u.EulaAccepted) { $u.AcceptEula() }
            [void]$coll.Add($u)
        }
    }
    if ($coll.Count -eq 0) { Write-WLog 'None of the selected updates are offered any more' 'WARN'; return [pscustomobject]@{ Installed = 0; Failed = 0; Reboot = $false } }
    $Sync.Status = "Downloading $($coll.Count) driver update(s)..."
    $dl = $o.Session.CreateUpdateDownloader(); $dl.Updates = $coll; [void]$dl.Download()
    $Sync.Status = "Installing $($coll.Count) driver update(s)..."
    $in = $o.Session.CreateUpdateInstaller(); $in.Updates = $coll
    $r = $in.Install()
    $ok = 0; $bad = 0
    for ($i = 0; $i -lt $coll.Count; $i++) {
        $code = $r.GetUpdateResult($i).ResultCode
        if ($code -eq 2 -or $code -eq 3) { $ok++; Write-WLog "Installed: $($coll.Item($i).Title)" }
        else { $bad++; Write-WLog "Failed (result $code): $($coll.Item($i).Title)" 'ERROR' }
    }
    if ($r.RebootRequired) { Write-WLog 'Restart the PC to finish installing the driver updates' 'WARN' }
    [pscustomobject]@{ Installed = $ok; Failed = $bad; Reboot = [bool]$r.RebootRequired }
}

# ---------------------------------------------------------------- BIOS / firmware (read-only)
# Firmware facts every PC exposes, plus the full BIOS setup options where the maker publishes them
# to Windows (Dell, HP and Lenovo business PCs). Nothing is ever written to the firmware.
function Get-WFirmwareInfo {
    $rows = New-Object System.Collections.Generic.List[object]
    $add = { param($Section, $Name, $Value, $Note = '', $Flag = '') $rows.Add([pscustomobject]@{ Section = $Section; Name = $Name; Value = [string]$Value; Note = [string]$Note; Flag = $Flag }) }
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $needAdmin = 'Needs administrator rights to read'

    $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $bb = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
    $date = if ($bios.ReleaseDate) { [datetime]$bios.ReleaseDate } else { $null }
    $mode = if ($env:firmware_type) { $env:firmware_type } else { try { [string](Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control' -ErrorAction Stop).PEFirmwareType -replace '^2$', 'UEFI' -replace '^1$', 'Legacy' } catch { 'Unknown' } }
    & $add 'Firmware' 'Maker' $bios.Manufacturer
    & $add 'Firmware' 'Version' $bios.SMBIOSBIOSVersion
    $age = if ($date) { [int](((Get-Date) - $date).TotalDays / 365.25 * 10) / 10 } else { 0 }
    & $add 'Firmware' 'Release date' $(if ($date) { $date.ToString('yyyy-MM-dd') } else { 'Unknown' }) $(if ($age -ge 2) { "$age years old - check the PC maker's support page for a BIOS update" } else { '' }) $(if ($age -ge 2) { 'Warn' } else { '' })
    & $add 'Firmware' 'Boot mode' $mode $(if ($mode -eq 'Legacy') { 'Legacy (CSM) boot - Windows 11 needs UEFI' } else { '' }) $(if ($mode -eq 'Legacy') { 'Warn' } else { '' })
    & $add 'Firmware' 'SMBIOS version' ('{0}.{1}' -f $bios.SMBIOSMajorVersion, $bios.SMBIOSMinorVersion)
    if ($bios.EmbeddedControllerMajorVersion -ne $null -and $bios.EmbeddedControllerMajorVersion -lt 255) { & $add 'Firmware' 'Embedded controller' ('{0}.{1}' -f $bios.EmbeddedControllerMajorVersion, $bios.EmbeddedControllerMinorVersion) }
    & $add 'Firmware' 'Serial number' $bios.SerialNumber
    & $add 'System' 'Manufacturer' $cs.Manufacturer
    & $add 'System' 'Model' $cs.Model
    if ($bb) { & $add 'System' 'Board maker' $bb.Manufacturer; & $add 'System' 'Board model' ("$($bb.Product) $($bb.Version)".Trim()) }

    # BitLocker must be suspended before a BIOS update, or the PC asks for the recovery key afterwards.
    try {
        $bl = Get-CimInstance -Namespace root/cimv2/Security/MicrosoftVolumeEncryption -ClassName Win32_EncryptableVolume -Filter "DriveLetter='$($env:SystemDrive)'" -ErrorAction Stop
        if ($bl) {
            $ps = [int]$bl.ProtectionStatus
            & $add 'Security' "BitLocker on $($env:SystemDrive)" $(switch ($ps) { 1 { 'On' } 0 { 'Off / suspended' } default { 'Unknown' } }) $(if ($ps -eq 1) { 'Suspend it for one restart before updating the BIOS, or the PC will ask for the recovery key' } else { '' }) $(if ($ps -eq 1) { 'Good' } else { '' })
        }
    } catch { & $add 'Security' "BitLocker on $($env:SystemDrive)" $(if ($isAdmin) { 'Not available' } else { $needAdmin }) '' }

    # Secure Boot (readable without admin via the registry)
    try {
        $sb = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -ErrorAction Stop).UEFISecureBootEnabled
        & $add 'Security' 'Secure Boot' $(if ($sb -eq 1) { 'On' } else { 'Off' }) $(if ($sb -ne 1) { 'Recommended: On. Windows 11 requires Secure Boot support.' } else { '' }) $(if ($sb -ne 1) { 'Warn' } else { 'Good' })
    } catch { & $add 'Security' 'Secure Boot' 'Not supported' 'This firmware has no Secure Boot (legacy BIOS)' 'Warn' }

    # TPM
    try {
        $tpm = Get-CimInstance -Namespace root/cimv2/Security/MicrosoftTpm -ClassName Win32_Tpm -ErrorAction Stop
        if ($tpm) {
            $ver = ([string]$tpm.SpecVersion).Split(',')[0].Trim()
            $on = $tpm.IsEnabled_InitialValue -and $tpm.IsActivated_InitialValue
            & $add 'Security' 'TPM' ("$ver - " + $(if ($on) { 'enabled' } else { 'disabled' })) $(if ($ver -notlike '2*') { 'Windows 11 requires TPM 2.0' } elseif (-not $on) { 'Turn the TPM on in the BIOS (often called PTT, fTPM or Security Chip)' } else { '' }) $(if ($ver -like '2*' -and $on) { 'Good' } else { 'Warn' })
            & $add 'Security' 'TPM maker' ("$($tpm.ManufacturerIdTxt) $($tpm.ManufacturerVersion)".Trim())
        } else { & $add 'Security' 'TPM' 'Not found' 'No TPM, or it is turned off in the BIOS' 'Warn' }
    } catch { & $add 'Security' 'TPM' $(if ($isAdmin) { 'Not available' } else { $needAdmin }) '' }

    # Virtualization-based security / Credential Guard / memory integrity
    try {
        $dg = Get-CimInstance -Namespace root/Microsoft/Windows/DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction Stop
        $vbs = switch ([int]$dg.VirtualizationBasedSecurityStatus) { 2 { 'Running' } 1 { 'Enabled, not running' } default { 'Off' } }
        & $add 'Security' 'Virtualization-based security' $vbs
        $svc = @($dg.SecurityServicesRunning)
        & $add 'Security' 'Credential Guard' $(if ($svc -contains 1) { 'Running' } else { 'Off' })
        & $add 'Security' 'Memory integrity (HVCI)' $(if ($svc -contains 2) { 'Running' } else { 'Off' })
    } catch { }

    # CPU virtualization (VT-x / AMD-V). When a hypervisor already runs, Windows reports it that way instead.
    try {
        $cpu = @(Get-CimInstance Win32_Processor -ErrorAction Stop)[0]
        & $add 'Processor' 'CPU' ([string]$cpu.Name).Trim()
        if ($cs.HypervisorPresent) { & $add 'Processor' 'Virtualization (VT-x / AMD-V)' 'In use by a hypervisor (Hyper-V, WSL 2 or VBS)' '' 'Good' }
        else {
            $vt = [bool]$cpu.VirtualizationFirmwareEnabled
            & $add 'Processor' 'Virtualization (VT-x / AMD-V)' $(if ($vt) { 'Enabled in firmware' } else { 'Disabled in firmware' }) $(if (-not $vt) { 'Turn it on in the BIOS to use WSL 2, Hyper-V, Windows Sandbox or Android apps' } else { '' }) $(if ($vt) { 'Good' } else { 'Warn' })
        }
    } catch { }

    # Firmware boot order (UEFI boot manager entries)
    if ($mode -eq 'UEFI') {
        if ($isAdmin) {
            try {
                $out = & bcdedit.exe /enum firmware 2>&1
                $order = @(); $desc = @{}; $cur = $null
                foreach ($l in $out) {
                    if ($l -match '^identifier\s+(\{.+\})') { $cur = $Matches[1] }
                    elseif ($l -match '^description\s+(.+)$' -and $cur) { $desc[$cur] = $Matches[1].Trim() }
                    elseif ($l -match '^displayorder\s+(\{.+\})') { $order += $Matches[1] }
                    elseif ($l -match '^\s+(\{.+\})\s*$' -and $order.Count) { $order += $Matches[1] }
                }
                $i = 0
                foreach ($id in $order) { $i++; if ($desc[$id]) { & $add 'Boot order' "#$i" $desc[$id] } }
                if (-not $i) { & $add 'Boot order' 'Boot entries' 'None reported' }
            } catch { & $add 'Boot order' 'Boot entries' $_.Exception.Message }
        } else { & $add 'Boot order' 'Boot entries' $needAdmin }
    }

    # Full BIOS setup options from maker WMI interfaces (business PCs).
    $found = $false
    try {
        $dell = @(Get-CimInstance -Namespace root/dcim/sysman/biosattributes -ClassName EnumerationAttribute -ErrorAction Stop)
        $dell += @(Get-CimInstance -Namespace root/dcim/sysman/biosattributes -ClassName IntegerAttribute -ErrorAction SilentlyContinue)
        $dell += @(Get-CimInstance -Namespace root/dcim/sysman/biosattributes -ClassName StringAttribute -ErrorAction SilentlyContinue)
        foreach ($a in $dell) { & $add 'BIOS setup (Dell)' $a.AttributeName $a.CurrentValue $(if ($a.PossibleValue) { 'Options: ' + (@($a.PossibleValue) -join ', ') } else { '' }) }
        $found = $dell.Count -gt 0
    } catch { }
    if (-not $found) {
        try {
            $hp = @(Get-CimInstance -Namespace root/HP/InstrumentedBIOS -ClassName HP_BIOSEnumeration -ErrorAction Stop)
            foreach ($a in $hp) { & $add 'BIOS setup (HP)' $a.Name $a.CurrentValue $(if ($a.PossibleValues) { 'Options: ' + (@($a.PossibleValues) -join ', ') } else { '' }) }
            foreach ($a in @(Get-CimInstance -Namespace root/HP/InstrumentedBIOS -ClassName HP_BIOSString -ErrorAction SilentlyContinue)) { & $add 'BIOS setup (HP)' $a.Name $a.Value }
            $found = $hp.Count -gt 0
        } catch { }
    }
    if (-not $found) {
        try {
            $lv = @(Get-CimInstance -Namespace root/wmi -ClassName Lenovo_BiosSetting -ErrorAction Stop | Where-Object { $_.CurrentSetting })
            foreach ($a in $lv) {
                $parts = ([string]$a.CurrentSetting) -split ';', 2
                $nv = $parts[0] -split ',', 2
                $opt = if ($parts.Count -gt 1) { $parts[1] -replace '^\[|\]$', '' -replace '^Optional:', 'Options: ' } else { '' }
                & $add 'BIOS setup (Lenovo)' $nv[0] $(if ($nv.Count -gt 1) { $nv[1] } else { '' }) $opt
            }
            $found = $lv.Count -gt 0
        } catch { }
    }
    if (-not $found) {
        & $add 'BIOS setup' 'Setup options' 'Not available from Windows' "$($cs.Manufacturer) doesn't publish BIOS setup options to Windows on this model (Dell, HP and Lenovo business PCs do). Use 'Restart into BIOS setup' to see them." 'Info'
    }
    $rows
}

# ---------------------------------------------------------------- Boot performance
# Diagnostics-Performance events: 100 = boot duration, 101/102/103 = app / driver / service that slowed it.
function Get-WBootHistory([int]$Days = 60) {
    $since = (Get-Date).AddDays(-$Days)
    $data = { param($ev) $h = @{}; foreach ($d in ([xml]$ev.ToXml()).Event.EventData.Data) { $h[[string]$d.Name] = [string]$d.'#text' }; $h }
    $boots = foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'; Id = 100; StartTime = $since } -MaxEvents 30 -ErrorAction SilentlyContinue)) {
        $d = & $data $e
        [pscustomobject]@{ Time = $e.TimeCreated; BootMs = [long]$d.BootTime; MainMs = [long]$d.MainPathBootTime; PostMs = [long]$d.BootPostBootTime }
    }
    $kinds = @{ 101 = 'App'; 102 = 'Driver'; 103 = 'Service' }
    $raw = foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'; Id = 101, 102, 103; StartTime = $since } -ErrorAction SilentlyContinue)) {
        $d = & $data $e
        $name = if ($d.FriendlyName) { $d.FriendlyName } elseif ($d.Name) { $d.Name } else { 'Unknown' }
        [pscustomobject]@{ Kind = $kinds[$e.Id]; Name = $name; File = [string]$d.Name; DegradationMs = [long]$d.DegradationTime; Time = $e.TimeCreated }
    }
    $culprits = foreach ($g in @($raw | Group-Object Kind, Name)) {
        $f = $g.Group[0]
        [pscustomobject]@{ Kind = $f.Kind; Name = $f.Name; File = $f.File; Times = $g.Count
            AvgSeconds = [Math]::Round((($g.Group | Measure-Object DegradationMs -Average).Average) / 1000, 1)
            Last = ($g.Group | Sort-Object Time -Descending | Select-Object -First 1).Time }
    }
    [pscustomobject]@{ Boots = @($boots | Sort-Object Time); Culprits = @($culprits | Sort-Object AvgSeconds -Descending) }
}

# ---------------------------------------------------------------- Event triage
# Curated events that usually explain "what's wrong with this PC", grouped with plain-language notes.
function Get-WEventTriage([int]$Days = 7) {
    $since = (Get-Date).AddDays(-$Days)
    $defs = @(
        @{ Sev = 'Problem'; Title = 'Blue screen (crash)';            Log = 'System'; Prov = 'Microsoft-Windows-WER-SystemErrorReporting'; Ids = 1001; Why = 'Windows stopped with an error. Repeated crashes usually point to a driver, memory or overheating - check Hardware errors and run a memory test.' }
        @{ Sev = 'Warning'; Title = 'Unexpected restart';             Log = 'System'; Prov = 'Microsoft-Windows-Kernel-Power'; Ids = 41;            Why = 'The PC restarted without shutting down cleanly: power loss, a forced power-off, or a hang/crash.' }
        @{ Sev = 'Warning'; Title = 'Unexpected shutdown';            Log = 'System'; Prov = 'EventLog'; Ids = 6008;                                 Why = 'The previous shutdown was not clean.' }
        @{ Sev = 'Problem'; Title = 'Hardware error (WHEA)';          Log = 'System'; Prov = 'Microsoft-Windows-WHEA-Logger'; Ids = $null;          Why = 'The CPU, memory or PCIe bus reported an error. Corrected errors are a warning sign; uncorrected ones cause crashes.' }
        @{ Sev = 'Problem'; Title = 'Disk bad block / paging error';  Log = 'System'; Prov = 'disk'; Ids = 7, 51;                                    Why = 'The drive could not read or write some data. Back up and check the disk health.' }
        @{ Sev = 'Warning'; Title = 'Disk I/O retried';               Log = 'System'; Prov = 'disk'; Ids = 153;                                      Why = 'Storage requests timed out and were retried - often a failing drive, cable or storage driver.' }
        @{ Sev = 'Warning'; Title = 'Storage controller reset';       Log = 'System'; Prov = @('stornvme', 'storahci', 'iaStorAC', 'iaStorAVC', 'iaStorA', 'nvme', 'secnvme'); Ids = 129;                                  Why = 'Storage requests timed out and were retried - often a failing drive, cable or storage driver.' }
        @{ Sev = 'Problem'; Title = 'File system corruption (NTFS)';  Log = 'System'; Prov = 'Ntfs'; Ids = 55, 98;                                  Why = 'NTFS found damage on a volume. Run chkdsk /scan on that drive.' }
        @{ Sev = 'Warning'; Title = 'Service crashed';                Log = 'System'; Prov = 'Service Control Manager'; Ids = 7031, 7034;           Why = 'A Windows service stopped unexpectedly.' }
        @{ Sev = 'Info';    Title = 'Service failed to start';        Log = 'System'; Prov = 'Service Control Manager'; Ids = 7000, 7009;           Why = 'A service could not start (often a leftover from uninstalled software).' }
        @{ Sev = 'Warning'; Title = 'Windows Update install failed';  Log = 'System'; Prov = 'Microsoft-Windows-WindowsUpdateClient'; Ids = 20;      Why = 'An update failed to install. Try Tools > Reset Windows Update, then install again.' }
        @{ Sev = 'Info';    Title = 'Time sync problem';              Log = 'System'; Prov = 'Microsoft-Windows-Time-Service'; Ids = 36, 129, 134;  Why = 'The clock could not sync. Wrong time breaks sign-ins, certificates and Kerberos.' }
        @{ Sev = 'Info';    Title = 'Group Policy failed';            Log = 'System'; Prov = 'Microsoft-Windows-GroupPolicy'; Ids = 1085, 1096, 1129; Why = 'Policy could not be applied - often no connection to a domain controller.' }
        @{ Sev = 'Info';    Title = 'DNS name resolution timeout';    Log = 'System'; Prov = 'Microsoft-Windows-DNS-Client'; Ids = 1014;            Why = 'A DNS server did not answer in time.' }
        @{ Sev = 'Warning'; Title = 'App crashed';                    Log = 'Application'; Prov = 'Application Error'; Ids = 1000;                 Why = 'A program crashed. If it is always the same one, repair or reinstall it.' }
        @{ Sev = 'Info';    Title = 'App stopped responding';         Log = 'Application'; Prov = 'Application Hang'; Ids = 1002;                  Why = 'A program froze and was closed.' }
        @{ Sev = 'Warning'; Title = '.NET app crashed';               Log = 'Application'; Prov = '.NET Runtime'; Ids = 1026;                       Why = 'A .NET program crashed with an unhandled error.' }
        @{ Sev = 'Warning'; Title = 'Failed sign-ins';                Log = 'Security'; Prov = $null; Ids = 4625;                                    Why = 'Someone (or a saved password) tried to sign in with wrong credentials. Many in a row can mean a stale password or a guessing attack.' }
        @{ Sev = 'Problem'; Title = 'Account locked out';             Log = 'Security'; Prov = $null; Ids = 4740;                                    Why = 'An account was locked after too many failed sign-ins.' }
    )
    foreach ($x in $defs) {
        $f = @{ LogName = $x.Log; StartTime = $since }
        if ($x.Prov) { $f.ProviderName = $x.Prov }
        if ($x.Ids) { $f.Id = $x.Ids }
        $ev = @(Get-WinEvent -FilterHashtable $f -MaxEvents 500 -ErrorAction SilentlyContinue)
        if ($x.Title -eq 'Hardware error (WHEA)') { $ev = @($ev | Where-Object { $_.Level -le 3 }) }
        if (-not $ev.Count) { continue }
        # Most frequent source: the crashing app for app crashes, otherwise the provider / first words.
        $src = switch -Regex ($x.Title) {
            '^\.NET' { ($ev | Group-Object { if ([string]$_.Message -match 'Application:\s*(\S+)') { $Matches[1] } else { 'unknown' } } | Sort-Object Count -Descending | Select-Object -First 3 | ForEach-Object { "$($_.Name) ($($_.Count))" }) -join ', '; break }
            'App crashed|stopped responding' { ($ev | Group-Object { [string]$_.Properties[0].Value } | Sort-Object Count -Descending | Select-Object -First 3 | ForEach-Object { "$($_.Name) ($($_.Count))" }) -join ', ' }
            'Service' { ($ev | Group-Object { [string]$_.Properties[0].Value } | Sort-Object Count -Descending | Select-Object -First 3 | ForEach-Object { "$($_.Name) ($($_.Count))" }) -join ', ' }
            default { (([string]$ev[0].Message) -split "`r?`n")[0] }
        }
        [pscustomobject]@{ Severity = $x.Sev; Title = $x.Title; Count = $ev.Count; Last = $ev[0].TimeCreated; Log = $x.Log; Ids = (@($x.Ids) -join ','); Source = $src; Why = $x.Why }
    }
}

# ---------------------------------------------------------------- Security posture
# Read-only checks. Fix = an ID from the short whitelist of safe, reversible fixes (Invoke-WSecurityFix).
function Get-WSecurityPosture {
    $rows = New-Object System.Collections.Generic.List[object]
    # On domain PCs a value under HKLM\SOFTWARE\Policies is usually set by Group Policy, which overwrites local fixes.
    $domain = [bool](Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).PartOfDomain
    $add = { param($Id, $Name, $Status, $Detail, $Fix = '', $Path = '') $rows.Add([pscustomobject]@{ Id = $Id; Name = $Name; Status = $Status; Detail = $Detail; Fix = $Fix; Policy = [bool]($domain -and $Path -like 'HKLM:\SOFTWARE\Policies*' -and (Test-Path -LiteralPath $Path)) }) }
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $reg = { param($p, $n) try { (Get-Item -LiteralPath $p -ErrorAction Stop).GetValue($n, $null) } catch { $null } }

    try {
        $fw = @(Get-NetFirewallProfile -ErrorAction Stop)
        $off = @($fw | Where-Object { -not $_.Enabled } | ForEach-Object Name)
        if ($off.Count) { & $add 'Firewall' 'Windows Firewall' 'Problem' "Off for: $($off -join ', ')" 'Firewall' } else { & $add 'Firewall' 'Windows Firewall' 'Good' 'On for all network profiles' }
    } catch { & $add 'Firewall' 'Windows Firewall' 'NA' $_.Exception.Message }

    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop
        if ($mp.RealTimeProtectionEnabled) { & $add 'Defender' 'Real-time protection' 'Good' ("On" + $(if ($mp.IsTamperProtected) { ', tamper protection on' } else { ', tamper protection off' })) }
        else { & $add 'Defender' 'Real-time protection' 'Problem' 'Microsoft Defender real-time protection is off (or another antivirus is active)' }
    } catch { & $add 'Defender' 'Real-time protection' 'NA' 'Defender status is not available' }

    try {
        $smb = Get-SmbServerConfiguration -ErrorAction Stop
        if ($smb.EnableSMB1Protocol) { & $add 'SMB1' 'SMB version 1' 'Problem' 'SMB1 is on - an old, insecure file-sharing protocol (WannaCry spread through it)' 'SMB1' }
        else { & $add 'SMB1' 'SMB version 1' 'Good' 'Off' }
    } catch { & $add 'SMB1' 'SMB version 1' 'NA' $(if ($isAdmin) { $_.Exception.Message } else { 'Needs administrator rights' }) }

    $p = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'
    if ((& $reg $p 'EnableMulticast') -eq 0) { & $add 'LLMNR' 'LLMNR name broadcasts' 'Good' 'Off' '' $p }
    else { & $add 'LLMNR' 'LLMNR name broadcasts' 'Warning' 'On - attackers on the same network can answer these and capture password hashes' 'LLMNR' $p }

    try {
        $g = Get-LocalUser -Name 'Guest' -ErrorAction Stop
        if ($g.Enabled) { & $add 'Guest' 'Guest account' 'Problem' 'Enabled' 'Guest' } else { & $add 'Guest' 'Guest account' 'Good' 'Disabled' }
    } catch { & $add 'Guest' 'Guest account' 'NA' 'Not available (domain controller or renamed)' }

    try {
        $adm = @(Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop | ForEach-Object { [string]$_.Name })
        & $add 'Admins' 'Local administrators' $(if ($adm.Count -gt 3) { 'Warning' } else { 'Info' }) ("$($adm.Count): " + ($adm -join ', '))
    } catch { & $add 'Admins' 'Local administrators' 'NA' 'Could not list members' }

    $ts = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
    $rdpOn = (& $reg $ts 'fDenyTSConnections') -eq 0
    $nla = (& $reg "$ts\WinStations\RDP-Tcp" 'UserAuthentication') -eq 1
    if (-not $rdpOn) { & $add 'RDP' 'Remote Desktop' 'Good' 'Off' }
    elseif ($nla) { & $add 'RDP' 'Remote Desktop' 'Info' 'On, with Network Level Authentication' }
    else { & $add 'RDP' 'Remote Desktop' 'Problem' 'On WITHOUT Network Level Authentication - anyone can reach the sign-in screen' 'NLA' }

    $sbl = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
    if ((& $reg $sbl 'EnableScriptBlockLogging') -eq 1) { & $add 'PSLog' 'PowerShell script logging' 'Good' 'On - scripts are recorded in the PowerShell event log' '' $sbl }
    else { & $add 'PSLog' 'PowerShell script logging' 'Info' 'Off - turning it on helps investigate malicious scripts' 'PSLog' $sbl }

    $ar = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    if ((& $reg $ar 'NoDriveTypeAutoRun') -eq 255) { & $add 'AutoRun' 'AutoRun for drives' 'Good' 'Off for all drive types' }
    else { & $add 'AutoRun' 'AutoRun for drives' 'Info' 'Not fully off - USB sticks and discs can try to start programs' 'AutoRun' }

    $uac = & $reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'EnableLUA'
    & $add 'UAC' 'User Account Control' $(if ($uac -eq 0) { 'Problem' } else { 'Good' }) $(if ($uac -eq 0) { 'Off - every program runs with full rights' } else { 'On' })

    $ppl = & $reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' 'RunAsPPL'
    & $add 'LSA' 'LSA protection' $(if ($ppl -in 1, 2) { 'Good' } else { 'Info' }) $(if ($ppl -in 1, 2) { 'On' } else { 'Off - report only: turning it on can block old smart-card or password-filter drivers' })

    try {
        $dg = Get-CimInstance -Namespace root/Microsoft/Windows/DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction Stop
        & $add 'CredGuard' 'Credential Guard' $(if (@($dg.SecurityServicesRunning) -contains 1) { 'Good' } else { 'Info' }) $(if (@($dg.SecurityServicesRunning) -contains 1) { 'Running' } else { 'Not running (report only - needs compatible hardware and policy)' })
    } catch { }

    try {
        $bl = Get-CimInstance -Namespace root/cimv2/Security/MicrosoftVolumeEncryption -ClassName Win32_EncryptableVolume -Filter "DriveLetter='$($env:SystemDrive)'" -ErrorAction Stop
        & $add 'BitLocker' "BitLocker ($($env:SystemDrive))" $(if ($bl.ProtectionStatus -eq 1) { 'Good' } else { 'Warning' }) $(if ($bl.ProtectionStatus -eq 1) { 'On' } else { 'Off - a lost or stolen PC exposes its files' })
    } catch { & $add 'BitLocker' "BitLocker ($($env:SystemDrive))" 'NA' $(if ($isAdmin) { 'Not available on this edition' } else { 'Needs administrator rights' }) }

    $laps = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\LAPS\Config') -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Policies\LAPS') -or (Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd')
    & $add 'LAPS' 'LAPS (local admin passwords)' 'Info' $(if ($laps) { 'Configured' } else { 'Not configured - fine for home PCs; workplaces should rotate local admin passwords' })

    try {
        $sh = @(Get-SmbShare -ErrorAction Stop | Where-Object { $_.Name -notmatch '^(ADMIN|IPC|print)\$$|^[A-Z]\$$' })
        & $add 'Shares' 'Shared folders' $(if ($sh.Count) { 'Info' } else { 'Good' }) $(if ($sh.Count) { ($sh | ForEach-Object { "$($_.Name) ($($_.Path))" }) -join ', ' } else { 'None besides the built-in admin shares' })
    } catch { }

    try {
        $ls = @(Get-NetTCPConnection -State Listen -ErrorAction Stop | Where-Object { $_.LocalAddress -notin '127.0.0.1', '::1' })
        $procs = @($ls | ForEach-Object { try { (Get-Process -Id $_.OwningProcess -ErrorAction Stop).ProcessName } catch { 'unknown' } } | Sort-Object -Unique)
        & $add 'Ports' 'Open network ports' 'Info' ("$(@($ls | Select-Object -ExpandProperty LocalPort -Unique).Count) port(s) listening, by: " + ($procs -join ', '))
    } catch { }

    try {
        $soon = @(Get-ChildItem Cert:\LocalMachine\My -ErrorAction Stop | Where-Object { $_.NotAfter -lt (Get-Date).AddDays(30) })
        if ($soon.Count) { & $add 'Certs' 'Computer certificates' 'Warning' ("$($soon.Count) expire within 30 days or already expired: " + (($soon | Select-Object -First 3 | ForEach-Object { "$($_.Subject) ($($_.NotAfter.ToString('yyyy-MM-dd')))" }) -join '; ')) }
        else { & $add 'Certs' 'Computer certificates' 'Good' 'None expire in the next 30 days' }
    } catch { }

    $usb = & $reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR' 'Start'
    & $add 'USB' 'USB storage' 'Info' $(if ($usb -eq 4) { 'Blocked by policy' } else { 'Allowed' })
    $rows
}

# Whitelisted, reversible fixes. Returns an undo capture (registry snapshot or a revert script).
function Invoke-WSecurityFix([string]$Id) {
    switch ($Id) {
        'Firewall' {
            $profiles = @(Get-NetFirewallProfile)
            $prev = @($profiles | ForEach-Object { "Set-NetFirewallProfile -Name '$($_.Name)' -Enabled $(if ($_.Enabled) { 'True' } else { 'False' })" }) -join '; '
            $app = @($profiles | Where-Object { -not $_.Enabled } | ForEach-Object { [pscustomobject]@{ Tool = 'netsh.exe'; Args = "advfirewall set $("$($_.Name)".ToLowerInvariant())profile state off" } })
            Set-NetFirewallProfile -All -Enabled True -ErrorAction Stop
            Write-WLog 'Windows Firewall turned on for all profiles'
            [pscustomobject]@{ UndoKind = 'Script'; Label = 'Turned on Windows Firewall'; Revert = $prev; AppRevert = $app }
        }
        'SMB1' {
            Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction Stop
            Write-WLog 'SMB1 server protocol turned off'
            [pscustomobject]@{ UndoKind = 'Script'; Label = 'Turned off SMB1'; Revert = 'Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force'
                AppRevert = @([pscustomobject]@{ Tool = 'reg.exe'; Args = 'add HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters /v SMB1 /t REG_DWORD /d 1 /f' }) }
        }
        'Guest' {
            Disable-LocalUser -Name 'Guest' -ErrorAction Stop
            Write-WLog 'Guest account disabled'
            [pscustomobject]@{ UndoKind = 'Script'; Label = 'Disabled the Guest account'; Revert = "Enable-LocalUser -Name 'Guest'"
                AppRevert = @([pscustomobject]@{ Tool = 'net.exe'; Args = 'user Guest /active:yes' }) }
        }
        default {
            $vals = switch ($Id) {
                'LLMNR'   { @(@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'; Name = 'EnableMulticast'; Type = 'DWord'; Value = 0 }) }
                'NLA'     { @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'; Name = 'UserAuthentication'; Type = 'DWord'; Value = 1 }) }
                'PSLog'   { @(@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'; Name = 'EnableScriptBlockLogging'; Type = 'DWord'; Value = 1 }) }
                'AutoRun' { @(@{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoDriveTypeAutoRun'; Type = 'DWord'; Value = 255 }) }
                default   { throw "Unknown fix '$Id'" }
            }
            $snap = @(Get-WRegSnapshot $vals)
            foreach ($v in $vals) {
                if (-not (Test-Path -LiteralPath $v.Path)) { New-Item -Path $v.Path -Force | Out-Null }
                New-ItemProperty -LiteralPath $v.Path -Name $v.Name -PropertyType $v.Type -Value $v.Value -Force | Out-Null
            }
            Write-WLog "Security fix applied: $Id"
            [pscustomobject]@{ UndoKind = 'Registry'; Label = "Security fix: $Id"; Snapshot = $snap; RemoveKeys = @() }
        }
    }
}

# ---------------------------------------------------------------- Privacy: camera / microphone / location use
# Windows records the last time each app used these (only the most recent session per app).
function Get-WPrivacyUsage {
    $caps = [ordered]@{ webcam = 'Camera'; microphone = 'Microphone'; location = 'Location' }
    $ft = { param($v) if ($v -and [long]$v -gt 0) { try { [DateTime]::FromFileTime([long]$v) } catch { $null } } else { $null } }
    foreach ($root in 'HKCU:', 'HKLM:') {
        foreach ($cap in $caps.Keys) {
            $base = "$root\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$cap"
            if (-not (Test-Path -LiteralPath $base)) { continue }
            $keys = @(Get-ChildItem -LiteralPath $base -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -ne 'NonPackaged' })
            $keys += @(Get-ChildItem -LiteralPath "$base\NonPackaged" -ErrorAction SilentlyContinue)
            foreach ($k in $keys) {
                $start = & $ft $k.GetValue('LastUsedTimeStart'); $stop = & $ft $k.GetValue('LastUsedTimeStop')
                if (-not $start) { continue }
                $app = $k.PSChildName
                if ($k.PSParentPath -like '*NonPackaged') { $app = $app -replace '#', '\' } else { $app = $app -replace '_[a-z0-9]{13}$', '' }
                [pscustomobject]@{ Capability = $caps[$cap]; App = $app; LastUsed = $start; Stopped = $stop; InUse = ($null -eq $stop -or $stop -lt $start); Scope = $(if ($root -eq 'HKCU:') { 'You' } else { 'System' }) }
            }
        }
    }
}

# Report-only sweep for adware / PUP persistence: forced browser extensions and search / homepage
# policies, startup entries and scheduled tasks that run unsigned programs from user-writable folders,
# a forced proxy, and hosts-file redirects.
function Get-WPupSweep {
    $out = New-Object System.Collections.Generic.List[object]
    $add = { param($Kind, $Item, $Detail, $Sev, $Path) $out.Add([pscustomobject]@{ Kind = $Kind; Item = [string]$Item; Detail = [string]$Detail; Severity = $Sev; Path = [string]$Path }) }
    foreach ($hive in 'HKLM:', 'HKCU:') {
        foreach ($b in @(@{ N = 'Chrome'; K = 'SOFTWARE\Policies\Google\Chrome' }, @{ N = 'Edge'; K = 'SOFTWARE\Policies\Microsoft\Edge' }, @{ N = 'Brave'; K = 'SOFTWARE\Policies\BraveSoftware\Brave' })) {
            $p = "$hive\$($b.K)"
            $fl = "$p\ExtensionInstallForcelist"
            if (Test-Path -LiteralPath $fl) {
                $k = Get-Item -LiteralPath $fl
                foreach ($n in $k.GetValueNames()) { & $add 'Forced extension' "$($b.N): $(([string]$k.GetValue($n)).Split(';')[0])" 'Installed by policy - users cannot remove it. Fine if your workplace set it, suspicious on a home PC.' 'Warning' $fl }
            }
            if (Test-Path -LiteralPath $p) {
                $k = Get-Item -LiteralPath $p
                foreach ($n in 'DefaultSearchProviderSearchURL', 'HomepageLocation', 'NewTabPageLocation') {
                    $v = $k.GetValue($n, $null)
                    if ($v) { & $add 'Browser policy' "$($b.N) $n" "$v" 'Warning' $p }
                }
            }
        }
    }
    $isRisky = { param($path)
        $x = [Environment]::ExpandEnvironmentVariables(([string]$path).Trim('"'))
        if ($x -notmatch '\\AppData\\|\\Temp\\|\\Users\\Public\\|\\ProgramData\\') { return $null }
        $exe = if ($x -match '^"?([^"]+?\.(exe|dll|vbs|js|cmd|bat|ps1|scr))') { $Matches[1] } else { $x }
        if (-not (Test-Path -LiteralPath $exe)) { return $null }
        $sig = Get-AuthenticodeSignature -LiteralPath $exe -ErrorAction SilentlyContinue
        if ($sig -and $sig.Status -eq 'Valid') { return $null }
        $exe
    }
    foreach ($rk in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') {
        if (-not (Test-Path -LiteralPath $rk)) { continue }
        $k = Get-Item -LiteralPath $rk
        foreach ($n in $k.GetValueNames()) {
            $exe = & $isRisky $k.GetValue($n)
            if ($exe) { & $add 'Startup entry' $n "Runs an unsigned program from a user-writable folder: $exe" 'Warning' $exe }
        }
    }
    try {
        foreach ($t in @(Get-ScheduledTask -ErrorAction Stop | Where-Object { $_.State -ne 'Disabled' })) {
            foreach ($a in @($t.Actions)) {
                if (-not $a.Execute) { continue }
                $exe = & $isRisky $a.Execute
                if ($exe) { & $add 'Scheduled task' "$($t.TaskPath)$($t.TaskName)" "Runs an unsigned program from a user-writable folder: $exe" 'Warning' $exe }
            }
        }
    } catch { }
    $is = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    $k = Get-Item -LiteralPath $is -ErrorAction SilentlyContinue
    if ($k) {
        if ($k.GetValue('ProxyEnable', 0) -eq 1) { & $add 'Proxy' 'Manual proxy' "All web traffic goes through $($k.GetValue('ProxyServer', ''))" 'Info' $is }
        if ($k.GetValue('AutoConfigURL', $null)) { & $add 'Proxy' 'Proxy script' "$($k.GetValue('AutoConfigURL'))" 'Info' $is }
    }
    $hosts = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
    $lines = @(Get-Content -LiteralPath $hosts -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*\d' -and $_ -notmatch '^\s*(127\.0\.0\.1|::1)\s+localhost\s*$' })
    if ($lines.Count) { & $add 'Hosts file' "$($lines.Count) redirect(s)" (($lines | Select-Object -First 3) -join '; ') $(if ($lines.Count -gt 20) { 'Info' } else { 'Info' }) $hosts }
    $out
}

# ---------------------------------------------------------------- Windows updates (online or offline scan)
# Missing updates for this PC. With a cab path, uses Microsoft's offline scan file (wsusscn2.cab) and
# never touches the network; without one, asks Windows Update. Needs admin for the offline scan.
function Get-WMissingUpdates([string]$Cab) {
    $s = New-Object -ComObject Microsoft.Update.Session
    $s.ClientApplicationID = 'ComputerDoctor'
    $q = $s.CreateUpdateSearcher()
    $svc = $null; $sm = $null
    if ($Cab) {
        $Sync.Status = 'Loading the offline scan file (this can take a few minutes and a lot of memory)...'
        $sm = New-Object -ComObject Microsoft.Update.ServiceManager
        $svc = $sm.AddScanPackageService('Computer Doctor offline scan', $Cab, 1)
        $q.ServerSelection = 3; $q.ServiceID = $svc.ServiceID
    } else { $q.ServerSelection = 2; $q.Online = $true }
    try {
        $Sync.Status = 'Checking which updates are missing...'
        $res = $q.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
        foreach ($u in $res.Updates) {
            [pscustomobject]@{
                UpdateId = [string]$u.Identity.UpdateID; Title = [string]$u.Title
                KB = $(if ($u.KBArticleIDs.Count) { 'KB' + $u.KBArticleIDs.Item(0) } else { '' })
                Severity = $(if ($u.MsrcSeverity) { [string]$u.MsrcSeverity } else { 'Unrated' })
                SizeMB = [Math]::Round($u.MaxDownloadSize / 1MB, 1); Released = $(try { [datetime]$u.LastDeploymentChangeTime } catch { $null })
                Categories = (@($u.Categories | ForEach-Object { $_.Name }) -join ', ')
            }
        }
    } finally { if ($svc) { try { $sm.RemoveService($svc.ServiceID) } catch { } } }
}

# Installs .msu / .cab packages with DISM (handles checkpoint cumulative updates when the
# prerequisite package sits in the same folder). Exit 3010 = restart needed.
function Install-WUpdatePackages([string[]]$Files) {
    $ok = 0; $bad = 0; $reboot = $false; $i = 0
    foreach ($f in ($Files | Sort-Object)) {
        $i++; $Sync.Status = "Installing $([IO.Path]::GetFileName($f)) ($i of $($Files.Count))..."; $Sync.Progress = [int]($i * 100 / [Math]::Max(1, $Files.Count))
        & dism.exe /Online /Add-Package "/PackagePath:$f" /Quiet /NoRestart 2>&1 | Out-Null
        switch ($LASTEXITCODE) {
            0 { $ok++; Write-WLog "Installed $([IO.Path]::GetFileName($f))" }
            3010 { $ok++; $reboot = $true; Write-WLog "Installed $([IO.Path]::GetFileName($f)) - restart needed" }
            -2146498530 { Write-WLog "$([IO.Path]::GetFileName($f)) doesn't apply to this PC (already installed or wrong version)" 'WARN' }
            default { $bad++; Write-WLog "$([IO.Path]::GetFileName($f)) failed (DISM exit $LASTEXITCODE)" 'ERROR' }
        }
    }
    [pscustomobject]@{ Installed = $ok; Failed = $bad; Reboot = $reboot }
}

# ---------------------------------------------------------------- Air gap: needs list + fetch
# What this (offline) PC needs from a connected PC. Written to <Resources>\needs\<COMPUTER>.json.
function Get-WNeedsList($MissingUpdates, $RebloatApps) {
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    $sig = $null; try { $sig = (Get-MpComputerStatus -ErrorAction Stop).AntivirusSignatureAge } catch { }
    $devs = @(Get-CimInstance Win32_PnPEntity -Filter 'ConfigManagerErrorCode <> 0' -ErrorAction SilentlyContinue | Where-Object { $_.ConfigManagerErrorCode -notin 22, 24, 45 } |
        ForEach-Object { [pscustomobject]@{ Name = [string]$_.Name; Code = [int]$_.ConfigManagerErrorCode; HardwareIds = @($_.HardwareID) } })
    [pscustomobject]@{
        Computer = $env:COMPUTERNAME; Created = (Get-Date).ToString('o')
        OS = [pscustomobject]@{ Product = $(if ([int]$cv.CurrentBuild -ge 22000) { ([string]$cv.ProductName) -replace 'Windows 10', 'Windows 11' } else { [string]$cv.ProductName }); DisplayVersion = [string]$cv.DisplayVersion; Build = [int]$cv.CurrentBuild; Ubr = [int]$cv.UBR; Edition = [string]$cv.EditionID
                                Arch = $(if ([Environment]::Is64BitOperatingSystem) { if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' } } else { 'x86' }) }
        MissingUpdates = @($MissingUpdates | Where-Object { $_ -and $_.KB } | ForEach-Object { [pscustomobject]@{ KB = $_.KB; Title = $_.Title; Severity = $_.Severity } })
        DefenderSignatureAgeDays = $sig
        Apps = @($RebloatApps | Where-Object { $_ -and $_.StoreId } | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Package = $_.Package; StoreId = $_.StoreId } })
        ProblemDevices = $devs
    }
}

function Save-WDownload([string]$Url, [string]$Dest) {
    New-Item -ItemType Directory -Path (Split-Path $Dest) -Force | Out-Null
    $tmp = "$Dest.partial"
    $wc = New-Object System.Net.WebClient
    try { $wc.DownloadFile($Url, $tmp) } finally { $wc.Dispose() }
    Move-Item -LiteralPath $tmp -Destination $Dest -Force
}

# Microsoft Update Catalog: search results -> download URLs (there is no official API; this is the
# same form the catalog website posts). Returns every file the update needs, prerequisites included.
function Get-WCatalogFiles([string]$Query, [scriptblock]$Pick) {
    $r = Invoke-WebRequest -Uri ('https://www.catalog.update.microsoft.com/Search.aspx?q=' + [uri]::EscapeDataString($Query)) -UseBasicParsing -TimeoutSec 60
    $rows = @([regex]::Matches($r.Content, "goToDetails\(`"([0-9a-f\-]{36})`"\);'[^>]*>\s*([^<]+?)\s*</a>") | ForEach-Object { [pscustomobject]@{ Id = $_.Groups[1].Value; Title = [System.Net.WebUtility]::HtmlDecode($_.Groups[2].Value.Trim()) } })
    $row = @($rows | Where-Object $Pick) | Select-Object -First 1
    if (-not $row) { return $null }
    $body = 'updateIDs=' + [uri]::EscapeDataString("[{`"size`":0,`"languages`":`"`",`"uidInfo`":`"$($row.Id)`",`"updateID`":`"$($row.Id)`"}]")
    $d = Invoke-WebRequest -Uri 'https://www.catalog.update.microsoft.com/DownloadDialog.aspx' -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing -TimeoutSec 60
    [pscustomobject]@{ Title = $row.Title; Urls = @([regex]::Matches($d.Content, "\.url\s*=\s*'([^']+)'") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique) }
}

# On a connected PC: fills a Resources folder with everything the needs lists in <Resources>\needs ask for.
function Invoke-WFetch([string]$Root, [bool]$IncludeScanCab = $true) {
    $sum = [ordered]@{ Updates = 0; Apps = 0; Drivers = 0; Baselines = 0; Defender = $false; ScanCab = $false; Errors = 0 }
    $needs = @(Get-ChildItem -LiteralPath (Join-Path $Root 'needs') -Filter '*.json' -ErrorAction SilentlyContinue | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json })
    Write-WLog "Fetch: $($needs.Count) needs list(s) in $Root"
    # 1) Offline scan file, refreshed when older than 7 days.
    $cab = Join-Path $Root 'updates\wsusscn2.cab'
    if ($IncludeScanCab -and (-not (Test-Path -LiteralPath $cab) -or (Get-Item -LiteralPath $cab).LastWriteTime -lt (Get-Date).AddDays(-7))) {
        $Sync.Status = 'Downloading the offline update scan file (about 650 MB)...'
        try { Save-WDownload 'https://catalog.s.download.windowsupdate.com/microsoftupdate/v6/wsusscan/wsusscn2.cab' $cab; $sum.ScanCab = $true; Write-WLog 'Fetched wsusscn2.cab' }
        catch { $sum.Errors++; Write-WLog "wsusscn2.cab download failed: $($_.Exception.Message)" 'ERROR' }
    }
    # 2) Defender definitions, refreshed daily.
    $defs = Join-Path $Root 'defs\x64\mpam-fe.exe'
    if (-not (Test-Path -LiteralPath $defs) -or (Get-Item -LiteralPath $defs).LastWriteTime -lt (Get-Date).AddHours(-20)) {
        $Sync.Status = 'Downloading Microsoft Defender definitions...'
        try { Save-WDownload 'https://go.microsoft.com/fwlink/?LinkID=121721&arch=x64' $defs; $sum.Defender = $true; Write-WLog 'Fetched Defender definitions' }
        catch { $sum.Errors++; Write-WLog "Defender download failed: $($_.Exception.Message)" 'ERROR' }
    }
    foreach ($n in $needs) {
        $arch = if ($n.OS.Arch) { $n.OS.Arch } else { 'x64' }
        # 3) Missing updates from the Microsoft Update Catalog.
        foreach ($u in @($n.MissingUpdates | Where-Object { $_.KB })) {
            $dir = Join-Path $Root "updates\$($u.KB)"
            if (Test-Path -LiteralPath $dir) { continue }
            $Sync.Status = "Finding $($u.KB) in the Update Catalog..."
            try {
                $prefix = ($u.Title -replace '\s*\(KB\d+\).*$', '')
                $files = Get-WCatalogFiles $u.KB { $_.Title -match $u.KB -and $_.Title -match $arch -and ($_.Title.StartsWith($prefix) -or $_.Title -notmatch 'Server') }
                if (-not $files -or -not $files.Urls.Count) { Write-WLog "$($u.KB): not found in the Update Catalog for $arch" 'WARN'; continue }
                foreach ($url in $files.Urls) { $Sync.Status = "Downloading $($u.KB)..."; Save-WDownload $url (Join-Path $dir ([IO.Path]::GetFileName(([uri]$url).AbsolutePath))) }
                $sum.Updates++; Write-WLog "Fetched $($u.KB): $($files.Title)"
            } catch { $sum.Errors++; Write-WLog "$($u.KB): $($_.Exception.Message)" 'ERROR' }
        }
        # 4) Store apps for offline Rebloat (unlicensed staging; see winget download docs).
        foreach ($a in @($n.Apps)) {
            $dir = Join-Path $Root "appx\$($a.Package -replace '[\\/:*?""<>|]', '_')"
            if (Test-Path -LiteralPath $dir) { continue }
            $Sync.Status = "Downloading $($a.Name) from the Microsoft Store..."
            & winget.exe download --id $a.StoreId --source msstore --skip-license --accept-package-agreements --accept-source-agreements --disable-interactivity -d $dir 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $sum.Apps++; Write-WLog "Fetched $($a.Name)" } else { $sum.Errors++; Write-WLog "$($a.Name): winget download exit $LASTEXITCODE" 'WARN' }
        }
        # 5) Drivers for devices that have problems, from the Update Catalog (expanded so 'Install from folder' can use them).
        foreach ($dv in @($n.ProblemDevices)) {
            $hw = @($dv.HardwareIds)[0]
            if (-not $hw) { continue }
            $short = if ($hw -match '^((PCI|HDAUDIO)\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}|USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4}|ACPI\\[^\\]+)') { $Matches[1] } else { $hw }
            $dir = Join-Path $Root "drivers\catalog\$($short -replace '[\\/:*?""<>|&]', '_')"
            if (Test-Path -LiteralPath $dir) { continue }
            $Sync.Status = "Finding a driver for $($dv.Name)..."
            try {
                $files = Get-WCatalogFiles $short { $true }
                if (-not $files -or -not $files.Urls.Count) { Write-WLog "No catalog driver found for $($dv.Name) ($short)" 'WARN'; continue }
                $cabFile = Join-Path $dir ([IO.Path]::GetFileName(([uri]$files.Urls[0]).AbsolutePath))
                Save-WDownload $files.Urls[0] $cabFile
                if ($cabFile -like '*.cab') { & expand.exe -F:* $cabFile $dir 2>&1 | Out-Null }
                $sum.Drivers++; Write-WLog "Fetched driver for $($dv.Name): $($files.Title)"
            } catch { $sum.Errors++; Write-WLog "Driver for $($dv.Name): $($_.Exception.Message)" 'ERROR' }
        }
    }
    # 6) Security baseline lists (HardeningKitty project, MIT licence) for IT Admin > Baseline audit.
    $bdir = Join-Path $Root 'baselines'
    if (-not @(Get-ChildItem -LiteralPath $bdir -Filter '*.csv' -ErrorAction SilentlyContinue).Count) {
        $Sync.Status = 'Downloading security baseline lists...'
        try {
            $files = (Invoke-WebRequest -Uri 'https://api.github.com/repos/scipag/HardeningKitty/contents/lists' -UseBasicParsing -TimeoutSec 60 -Headers @{ 'User-Agent' = 'ComputerDoctor' }).Content | ConvertFrom-Json
            $pick = @()
            foreach ($pat in 'msft_security_baseline_windows_11.*machine', 'cis_microsoft_windows_11_enterprise.*machine', '0x6d69636b_machine') {
                $pick += @($files | Where-Object { $_.name -match $pat } | Sort-Object name -Descending | Select-Object -First 1)
            }
            foreach ($f in $pick) { Save-WDownload $f.download_url (Join-Path $bdir $f.name); Write-WLog "Fetched baseline $($f.name)" }
            $sum.Baselines = $pick.Count
        } catch { $sum.Errors++; Write-WLog "Baseline lists: $($_.Exception.Message)" 'WARN' }
    }
    [pscustomobject]$sum
}

# ---------------------------------------------------------------- Crash dumps (blue screens)
# Plain-English meaning of the common bug check codes, and which Computer Doctor action helps.
function Get-WBugCheckInfo([uint32]$Code) {
    $t = @{
        0x0A = @('IRQL_NOT_LESS_OR_EQUAL', 'A driver touched memory it should not have.', 'Drivers')
        0x19 = @('BAD_POOL_HEADER', 'Kernel memory was corrupted, usually by a driver.', 'Drivers')
        0x1A = @('MEMORY_MANAGEMENT', 'Memory management failed - often faulty RAM.', 'Memory')
        0x1E = @('KMODE_EXCEPTION_NOT_HANDLED', 'A driver crashed.', 'Drivers')
        0x24 = @('NTFS_FILE_SYSTEM', 'The file system hit an error - check the disk.', 'Disk')
        0x3B = @('SYSTEM_SERVICE_EXCEPTION', 'A driver or system file failed during a system call.', 'Drivers')
        0x50 = @('PAGE_FAULT_IN_NONPAGED_AREA', 'Invalid memory was referenced - RAM, a driver or the disk.', 'Memory')
        0x77 = @('KERNEL_STACK_INPAGE_ERROR', 'Data could not be read back from the disk.', 'Disk')
        0x7A = @('KERNEL_DATA_INPAGE_ERROR', 'Data could not be read from the disk - failing drive or cable.', 'Disk')
        0x7B = @('INACCESSIBLE_BOOT_DEVICE', 'Windows lost access to the boot drive (storage driver or BIOS setting).', 'Disk')
        0x7E = @('SYSTEM_THREAD_EXCEPTION_NOT_HANDLED', 'A driver crashed in a system thread.', 'Drivers')
        0x7F = @('UNEXPECTED_KERNEL_MODE_TRAP', 'A CPU-level fault - hardware or overclocking.', 'Hardware')
        0x9C = @('MACHINE_CHECK_EXCEPTION', 'The CPU reported a hardware error.', 'Hardware')
        0x9F = @('DRIVER_POWER_STATE_FAILURE', 'A driver hung while sleeping or waking (often Wi-Fi, USB or graphics).', 'Drivers')
        0xA0 = @('INTERNAL_POWER_ERROR', 'Power management failed.', 'Drivers')
        0xC2 = @('BAD_POOL_CALLER', 'A driver made a bad memory request.', 'Drivers')
        0xC4 = @('DRIVER_VERIFIER_DETECTED_VIOLATION', 'Driver Verifier caught a faulty driver (Verifier is turned on).', 'Drivers')
        0xC5 = @('DRIVER_CORRUPTED_EXPOOL', 'A driver corrupted kernel memory.', 'Drivers')
        0xD1 = @('DRIVER_IRQL_NOT_LESS_OR_EQUAL', 'A driver (often network or storage) accessed bad memory.', 'Drivers')
        0xE2 = @('MANUALLY_INITIATED_CRASH', 'The crash was triggered on purpose (keyboard shortcut or debugger).', '')
        0xEF = @('CRITICAL_PROCESS_DIED', 'A critical Windows process stopped - system files may be damaged.', 'Sfc')
        0xF4 = @('CRITICAL_OBJECT_TERMINATION', 'A critical process ended - often a failing disk.', 'Disk')
        0x101 = @('CLOCK_WATCHDOG_TIMEOUT', 'A CPU core stopped responding - BIOS, overclocking or hardware.', 'Bios')
        0x116 = @('VIDEO_TDR_FAILURE', 'The graphics driver stopped responding and could not recover.', 'Drivers')
        0x117 = @('VIDEO_TDR_TIMEOUT_DETECTED', 'The graphics driver timed out.', 'Drivers')
        0x119 = @('VIDEO_SCHEDULER_INTERNAL_ERROR', 'The graphics scheduler failed - graphics driver.', 'Drivers')
        0x124 = @('WHEA_UNCORRECTABLE_ERROR', 'The hardware reported a fatal error - CPU, RAM, heat or overclocking.', 'Hardware')
        0x133 = @('DPC_WATCHDOG_VIOLATION', 'A driver took too long - often storage drivers or SSD firmware.', 'Drivers')
        0x139 = @('KERNEL_SECURITY_CHECK_FAILURE', 'Kernel data was corrupted - a driver or RAM.', 'Memory')
        0x13A = @('KERNEL_MODE_HEAP_CORRUPTION', 'A driver corrupted kernel memory.', 'Drivers')
        0x144 = @('BUGCODE_USB3_DRIVER', 'The USB 3 driver failed.', 'Drivers')
        0x154 = @('UNEXPECTED_STORE_EXCEPTION', 'Memory compression store failed - often the disk.', 'Disk')
        0x1C8 = @('MANUALLY_INITIATED_POWER_BUTTON_HOLD', 'The power button was held down to force a restart.', '')
    }
    $k = [int]$Code
    if ($t.ContainsKey($k)) { [pscustomobject]@{ Name = $t[$k][0]; Meaning = $t[$k][1]; Action = $t[$k][2] } }
    else { [pscustomobject]@{ Name = ('0x{0:X}' -f $Code); Meaning = 'Search the code online for details.'; Action = '' } }
}

function Get-WCrashDumps {
    $out = New-Object System.Collections.Generic.List[object]
    $files = @(Get-ChildItem -LiteralPath (Join-Path $env:SystemRoot 'Minidump') -Filter '*.dmp' -File -ErrorAction SilentlyContinue)
    $full = Join-Path $env:SystemRoot 'MEMORY.DMP'
    if (Test-Path -LiteralPath $full) { $files += Get-Item -LiteralPath $full }
    foreach ($f in $files) {
        try {
            $fs = [IO.File]::Open($f.FullName, 'Open', 'Read', 'ReadWrite'); $b = New-Object byte[] 0x80; [void]$fs.Read($b, 0, $b.Length); $fs.Dispose()
            $sig = [Text.Encoding]::ASCII.GetString($b, 0, 8)
            # Kernel dump header: 64-bit "PAGEDU64" code at 0x38, parameters at 0x40; 32-bit "PAGEDUMP" code at 0x28, parameters at 0x2C.
            if ($sig -eq 'PAGEDU64') { $code = [BitConverter]::ToUInt32($b, 0x38); $par = @(0..3 | ForEach-Object { '0x{0:X}' -f [BitConverter]::ToUInt64($b, 0x40 + 8 * $_) }) }
            elseif ($sig -eq 'PAGEDUMP') { $code = [BitConverter]::ToUInt32($b, 0x28); $par = @(0..3 | ForEach-Object { '0x{0:X}' -f [BitConverter]::ToUInt32($b, 0x2C + 4 * $_) }) }
            else { continue }
            $i = Get-WBugCheckInfo $code
            $out.Add([pscustomobject]@{ Time = $f.LastWriteTime; Code = ('0x{0:X8}' -f $code); Name = $i.Name; Meaning = $i.Meaning; Action = $i.Action; Parameters = ($par -join ', '); Source = $f.FullName; SizeMB = [Math]::Round($f.Length / 1MB, 1) })
        } catch { Write-WLog "Could not read $($f.FullName): $($_.Exception.Message)" 'WARN' }
    }
    # Crashes whose dump was not kept still leave an event with the bug check code.
    foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'; Id = 1001 } -MaxEvents 30 -ErrorAction SilentlyContinue)) {
        if ($e.Message -notmatch 'bugcheck was:\s*0x([0-9a-fA-F]+)') { continue }
        $code = [Convert]::ToUInt32($Matches[1], 16)
        if (@($out | Where-Object { [Math]::Abs(($_.Time - $e.TimeCreated).TotalMinutes) -lt 15 }).Count) { continue }
        $i = Get-WBugCheckInfo $code
        $out.Add([pscustomobject]@{ Time = $e.TimeCreated; Code = ('0x{0:X8}' -f $code); Name = $i.Name; Meaning = $i.Meaning; Action = $i.Action; Parameters = ''; Source = 'Event log (dump not kept)'; SizeMB = 0 })
    }
    $out | Sort-Object Time -Descending
}

# ---------------------------------------------------------------- Sleep and wake
function Get-WSleepInfo {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $wakes = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Power-Troubleshooter'; Id = 1 } -MaxEvents 15 -ErrorAction SilentlyContinue | ForEach-Object {
        $src = if ($_.Message -match 'Wake Source:\s*(.+)') { $Matches[1].Trim() } else { 'Unknown' }
        [pscustomobject]@{ Time = $_.TimeCreated; Source = $src }
    })
    $armed = @(& powercfg.exe /devicequery wake_armed 2>$null | Where-Object { $_ -and $_ -notmatch '^NONE$' } | ForEach-Object { $_.Trim() })
    $requests = @(); $timers = @()
    if ($isAdmin) {
        $kind = ''
        foreach ($l in (& powercfg.exe /requests 2>$null)) {
            if ($l -match '^([A-Z]+):\s*$') { $kind = $Matches[1]; continue }
            if ($l.Trim() -and $l.Trim() -ne 'None.' -and $kind) { $requests += [pscustomobject]@{ Kind = $kind; Requester = $l.Trim() } }
        }
        $timers = @(& powercfg.exe /waketimers 2>$null | Where-Object { $_ -match 'Timer set by|Reason' } | ForEach-Object { $_.Trim() })
    }
    $states = @(& powercfg.exe /a 2>$null)
    $avail = @(); $inSection = $false
    foreach ($l in $states) { if ($l -match 'not available') { break }; if ($l -match 'available on this system:') { $inSection = $true; continue }; if ($inSection -and $l.Trim()) { $avail += $l.Trim() } }
    [pscustomobject]@{ Wakes = $wakes; Armed = $armed; Requests = $requests; Timers = $timers; States = $avail; Admin = $isAdmin }
}

# ---------------------------------------------------------------- User profiles
function Get-WUserProfiles([bool]$Sizes = $true) {
    foreach ($p in @(Get-CimInstance Win32_UserProfile -ErrorAction Stop | Where-Object { -not $_.Special })) {
        $name = try { (New-Object System.Security.Principal.SecurityIdentifier $p.SID).Translate([System.Security.Principal.NTAccount]).Value } catch { Split-Path $p.LocalPath -Leaf }
        $k = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$($p.SID)"
        $last = $null
        try {
            $hi = (Get-ItemProperty -LiteralPath $k -ErrorAction Stop).LocalProfileLoadTimeHigh; $lo = (Get-ItemProperty -LiteralPath $k).LocalProfileLoadTimeLow
            if ($null -ne $hi -and $null -ne $lo) { $last = [DateTime]::FromFileTime(([long][uint32]$hi -shl 32) -bor [long][uint32]$lo) }
        } catch { }
        if (-not $last -and $p.LastUseTime) { $last = [datetime]$p.LastUseTime }
        $size = 0
        if ($Sizes -and (Test-Path -LiteralPath $p.LocalPath)) {
            $sum = & robocopy.exe $p.LocalPath 'C:\ComputerDoctorNonexistentTarget' /L /S /NJH /BYTES /NFL /NDL /XJ /R:0 /W:0 2>$null | Where-Object { $_ -match '^\s*Bytes\s*:' } | Select-Object -First 1
            if ($sum -match 'Bytes\s*:\s*(\d+)') { $size = [long]$Matches[1] }
        }
        $flags = @(); if ($p.Status -band 1) { $flags += 'Temporary' }; if ($p.Status -band 8) { $flags += 'Corrupted' }; if ($p.Status -band 4) { $flags += 'Mandatory' }; if ($p.Status -band 2) { $flags += 'Roaming' }
        [pscustomobject]@{ Sid = [string]$p.SID; User = [string]$name; Path = [string]$p.LocalPath; Loaded = [bool]$p.Loaded; LastUsed = $last; SizeBytes = $size; Flags = ($flags -join ', ') }
    }
}

function Remove-WUserProfile([string]$Sid) {
    $p = Get-CimInstance Win32_UserProfile -Filter "SID='$Sid'" -ErrorAction Stop
    if (-not $p) { throw 'Profile not found' }
    if ($p.Special) { throw 'Windows system profiles cannot be removed' }
    if ($p.Loaded) { throw 'This profile is in use - the user must sign out first' }
    Remove-CimInstance -InputObject $p -ErrorAction Stop
    Write-WLog "Removed profile $($p.LocalPath)"
}

# ---------------------------------------------------------------- Printers
function Get-WPrinterInfo {
    $printers = @(Get-Printer -ErrorAction Stop)
    $ports = @(Get-PrinterPort -ErrorAction SilentlyContinue)
    $drivers = @(Get-PrinterDriver -ErrorAction SilentlyContinue)
    $usedPorts = @($printers | ForEach-Object PortName); $usedDrivers = @($printers | ForEach-Object DriverName)
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($p in $printers) {
        $jobs = @(Get-PrintJob -PrinterName $p.Name -ErrorAction SilentlyContinue).Count
        $rows.Add([pscustomobject]@{ Kind = 'Printer'; Name = [string]$p.Name; Detail = "Port $($p.PortName) - driver $($p.DriverName)" + $(if ($jobs) { " - $jobs job(s) waiting" } else { '' }); Status = [string]$p.PrinterStatus; Unused = $false })
    }
    foreach ($p in $ports) {
        if ($p.Name -match '^(COM\d+:|LPT\d+:|FILE:|nul:|PORTPROMPT:|SHRFAX:|USB\d+|WSD-|TS\d+)' -or $p.Description -match 'Local Port' -and $p.Name -notmatch '^\d') { continue }
        $rows.Add([pscustomobject]@{ Kind = 'Port'; Name = [string]$p.Name; Detail = [string]$(if ($p.PrinterHostAddress) { "TCP/IP $($p.PrinterHostAddress)" } else { $p.Description }); Status = $(if ($usedPorts -contains $p.Name) { 'In use' } else { 'Not used by any printer' }); Unused = ($usedPorts -notcontains $p.Name) })
    }
    foreach ($d in $drivers) {
        if ($d.Name -match '^Microsoft|Remote Desktop Easy Print') { continue }
        $rows.Add([pscustomobject]@{ Kind = 'Driver'; Name = [string]$d.Name; Detail = "$($d.Manufacturer) $($d.MajorVersion)".Trim(); Status = $(if ($usedDrivers -contains $d.Name) { 'In use' } else { 'Not used by any printer' }); Unused = ($usedDrivers -notcontains $d.Name) })
    }
    $rows
}

function Remove-WPrinterItem([string]$Kind, [string]$Name) {
    switch ($Kind) {
        'Printer' { Remove-Printer -Name $Name -ErrorAction Stop }
        'Port'    { Remove-PrinterPort -Name $Name -ErrorAction Stop }
        'Driver'  { Remove-PrinterDriver -Name $Name -ErrorAction Stop }
    }
    Write-WLog "Removed printer $($Kind.ToLower()) '$Name'"
}

function Add-WPrinterByIp([string]$Ip, [string]$Name, [string]$Driver) {
    $port = "IP_$Ip"
    if (-not (Get-PrinterPort -Name $port -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name $port -PrinterHostAddress $Ip -ErrorAction Stop }
    Add-Printer -Name $Name -DriverName $Driver -PortName $port -ErrorAction Stop
    Write-WLog "Added printer '$Name' at $Ip ($Driver)"
}

function Reset-WSpooler {
    Stop-Service -Name Spooler -Force -ErrorAction Stop
    $n = 0
    foreach ($f in @(Get-ChildItem -LiteralPath (Join-Path $env:SystemRoot 'System32\spool\PRINTERS') -File -ErrorAction SilentlyContinue)) { try { [IO.File]::Delete($f.FullName); $n++ } catch { } }
    Start-Service -Name Spooler -ErrorAction Stop
    Write-WLog "Print spooler restarted, $n stuck job file(s) cleared"
}

# ---------------------------------------------------------------- Helpdesk: sessions, processes, messages
function Get-WSessions {
    $rows = @()
    $q = if (Get-Command quser.exe -ErrorAction SilentlyContinue) { & quser.exe 2>$null } else { $null }
    if ($q) {
        foreach ($l in ($q | Select-Object -Skip 1)) {
            $x = $l.Substring(1) -split '\s{2,}'
            if ($x.Count -ge 5) { $rows += [pscustomobject]@{ User = $x[0]; Session = $(if ($x.Count -ge 6) { $x[1] } else { '' }); Id = [int]$x[$(if ($x.Count -ge 6) { 2 } else { 1 })]; State = $x[$(if ($x.Count -ge 6) { 3 } else { 2 })]; Idle = $x[-2]; Logon = $x[-1] } }
        }
    }
    if (-not $rows) {   # Windows Home has no quser: fall back to who owns explorer.exe
        foreach ($p in @(Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" -ErrorAction SilentlyContinue)) {
            $o = Invoke-CimMethod -InputObject $p -MethodName GetOwner -ErrorAction SilentlyContinue
            $rows += [pscustomobject]@{ User = "$($o.Domain)\$($o.User)"; Session = 'Console'; Id = [int]$p.SessionId; State = 'Active'; Idle = ''; Logon = '' }
        }
    }
    $rows
}

function Get-WTopProcesses {
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Id -gt 4 } | Sort-Object WorkingSet64 -Descending | Select-Object -First 30 | ForEach-Object {
        [pscustomobject]@{ Name = $_.ProcessName; Id = $_.Id; MemMB = [Math]::Round($_.WorkingSet64 / 1MB); CpuSec = [Math]::Round($_.CPU, 1); Session = $_.SessionId; Responding = $_.Responding }
    }
}

# ---------------------------------------------------------------- Time sync
function Get-WTimeStatus {
    $st = (& w32tm.exe /query /status 2>&1) -join "`n"
    $p = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Source = $(if ($st -match 'Source:\s*(.+)') { $Matches[1].Trim() } else { 'Unknown' })
        LastSync = $(if ($st -match 'Last Successful Sync Time:\s*(.+)') { $Matches[1].Trim() } else { 'Never / unknown' })
        Type = [string]$p.Type; NtpServer = [string]$p.NtpServer; Running = ((Get-Service w32time -ErrorAction SilentlyContinue).Status -eq 'Running')
    }
}

function Set-WTimeSource([string]$Peers) {
    $p = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' -ErrorAction Stop
    $revFlags = if ($p.Type -eq 'NT5DS') { 'DOMHIER' } else { 'MANUAL' }
    $revert = "& w32tm.exe /config /manualpeerlist:`"$($p.NtpServer)`" /syncfromflags:$revFlags /update | Out-Null; Restart-Service w32time -Force; & w32tm.exe /resync /force | Out-Null"
    if ((Get-Service w32time).Status -ne 'Running') { Start-Service w32time }
    & w32tm.exe /config "/manualpeerlist:$Peers" /syncfromflags:manual /update 2>&1 | Out-Null
    Restart-Service w32time -Force
    $r = (& w32tm.exe /resync /force 2>&1) -join ' '
    Write-WLog "Time source set to $Peers - $r"
    [pscustomobject]@{ UndoKind = 'Script'; Label = "Set time source to $Peers"; Revert = $revert
        AppRevert = @([pscustomobject]@{ Tool = 'w32tm.exe'; Args = "/config /manualpeerlist:`"$($p.NtpServer)`" /syncfromflags:$revFlags /update" }) }
}

# ---------------------------------------------------------------- LAN throughput test (this PC <-> another PC)
# Copies a 256 MB test file to and from the other PC: over its ADMIN$ share (closest to real file copies),
# or over WinRM when SMB is blocked (slower; shows the minimum).
function Test-WLanSpeed([string]$Computer, $Credential) {
    $local = Join-Path ([IO.Path]::GetTempPath()) 'computerdoctor-lan-test.bin'
    $buf = New-Object byte[] (16MB); (New-Object Random).NextBytes($buf)
    $fs = [IO.File]::Create($local); for ($i = 0; $i -lt 16; $i++) { $fs.Write($buf, 0, $buf.Length) }; $fs.Dispose()
    $mb = 256; $res = [ordered]@{ Computer = $Computer; Method = ''; UploadMBps = 0; DownloadMBps = 0 }
    try {
        $drive = $null
        try {
            $p = @{ Name = 'AWLanTest'; PSProvider = 'FileSystem'; Root = "\\$Computer\ADMIN$"; ErrorAction = 'Stop' }
            if ($Credential) { $p.Credential = $Credential }
            $drive = New-PSDrive @p
        } catch { }
        if ($drive) {
            $res.Method = 'File share (SMB)'
            $remote = 'AWLanTest:\Temp\computerdoctor-lan-test.bin'; $back = "$local.back"
            $sw = [Diagnostics.Stopwatch]::StartNew(); Copy-Item -LiteralPath $local -Destination $remote -Force; $res.UploadMBps = [Math]::Round($mb / $sw.Elapsed.TotalSeconds, 1)
            $sw.Restart(); Copy-Item -LiteralPath $remote -Destination $back -Force; $res.DownloadMBps = [Math]::Round($mb / $sw.Elapsed.TotalSeconds, 1)
            Remove-Item -LiteralPath $remote, $back -Force -ErrorAction SilentlyContinue
            Remove-PSDrive -Name AWLanTest -ErrorAction SilentlyContinue
        } else {
            $res.Method = 'WinRM (file sharing blocked - real copies are usually faster)'
            $sp = @{ ComputerName = $Computer; ErrorAction = 'Stop' }; if ($Credential) { $sp.Credential = $Credential }
            $s = New-PSSession @sp
            try {
                $sw = [Diagnostics.Stopwatch]::StartNew(); Copy-Item -LiteralPath $local -Destination 'C:\Windows\Temp\computerdoctor-lan-test.bin' -ToSession $s -Force; $res.UploadMBps = [Math]::Round($mb / $sw.Elapsed.TotalSeconds, 1)
                $sw.Restart(); Copy-Item -Path 'C:\Windows\Temp\computerdoctor-lan-test.bin' -Destination "$local.back" -FromSession $s -Force; $res.DownloadMBps = [Math]::Round($mb / $sw.Elapsed.TotalSeconds, 1)
                Invoke-Command -Session $s { Remove-Item 'C:\Windows\Temp\computerdoctor-lan-test.bin' -Force -ErrorAction SilentlyContinue }
                Remove-Item -LiteralPath "$local.back" -Force -ErrorAction SilentlyContinue
            } finally { Remove-PSSession $s }
        }
    } finally { Remove-Item -LiteralPath $local -Force -ErrorAction SilentlyContinue }
    Write-WLog ("LAN test with {0}: {1} MB/s up, {2} MB/s down ({3})" -f $Computer, $res.UploadMBps, $res.DownloadMBps, $res.Method)
    [pscustomobject]$res
}

# ---------------------------------------------------------------- Software push (copy, then run on each PC)
function Get-WMsiResult([int]$Code) {
    switch ($Code) {
        0 { 'Installed' } 3010 { 'Installed - restart needed' } 1641 { 'Installed - restart started' } 1618 { 'Another installation was running - try again later' }
        1602 { 'Cancelled' } 1603 { 'Failed (fatal error - see the log)' } 1619 { 'Installer file could not be opened' } 1620 { 'Installer file is invalid' } 1638 { 'Another version is already installed' }
        default { "Exit code $Code" }
    }
}

function Invoke-WSoftwarePush([string[]]$Hosts, [string]$Installer, [string]$Arguments) {
    $hash = (Get-FileHash -LiteralPath $Installer -Algorithm SHA256).Hash
    $leaf = [IO.Path]::GetFileName($Installer); $isMsi = $leaf -like '*.msi'
    $run = {
        param($Path, $IsMsi, $Arguments, $Hash)
        if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Hash) { return [pscustomobject]@{ Code = -1; Log = 'The copied installer did not match (hash mismatch)' } }
        $log = "$Path.log"
        if ($IsMsi) { $p = Start-Process msiexec.exe -ArgumentList "/i `"$Path`" /qn /norestart /l*v `"$log`" $Arguments" -Wait -PassThru -WindowStyle Hidden }
        else { $p = Start-Process -FilePath $Path -ArgumentList $Arguments -Wait -PassThru -WindowStyle Hidden }
        $tail = if (Test-Path -LiteralPath $log) { (Get-Content -LiteralPath $log -Tail 15 -ErrorAction SilentlyContinue) -join "`n" } else { '' }
        Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        [pscustomobject]@{ Code = $p.ExitCode; Log = $tail }
    }
    $i = 0
    foreach ($h in $Hosts) {
        $i++; $Sync.Status = "Installing on $h ($i of $($Hosts.Count))..."; $Sync.Progress = [int]($i * 100 / $Hosts.Count)
        try {
            if ($h -in 'localhost', '.', $env:COMPUTERNAME) {
                $dst = Join-Path $env:SystemRoot "Temp\ComputerDoctorPush\$leaf"; New-Item -ItemType Directory -Path (Split-Path $dst) -Force | Out-Null
                Copy-Item -LiteralPath $Installer -Destination $dst -Force
                $r = & $run $dst $isMsi $Arguments $hash
            } else {
                $sp = @{ ComputerName = $h; ErrorAction = 'Stop' }
                $saved = try { [ComputerDoctor.CredMan]::ReadHost($h) } catch { $null }
                if ($saved) { $sp.Credential = New-Object System.Management.Automation.PSCredential($saved[0], (ConvertTo-SecureString $saved[1] -AsPlainText -Force)) }
                $s = New-PSSession @sp
                try {
                    $dst = Invoke-Command -Session $s { param($l) $d = Join-Path $env:SystemRoot 'Temp\ComputerDoctorPush'; New-Item -ItemType Directory -Path $d -Force | Out-Null; Join-Path $d $l } -ArgumentList $leaf
                    Copy-Item -LiteralPath $Installer -Destination $dst -ToSession $s -Force
                    $r = Invoke-Command -Session $s -ScriptBlock $run -ArgumentList $dst, $isMsi, $Arguments, $hash
                } finally { Remove-PSSession $s }
            }
            $msg = if ($r.Code -eq -1) { $r.Log } else { Get-WMsiResult ([int]$r.Code) }
            $ok = $r.Code -in 0, 3010, 1641
            Write-WLog "$($h): $msg" $(if ($ok) { 'INFO' } else { 'ERROR' })
            [pscustomobject]@{ Computer = $h; Ok = $ok; Code = $r.Code; Result = $msg; Log = $r.Log }
        } catch {
            Write-WLog "$($h): $($_.Exception.Message)" 'ERROR'
            [pscustomobject]@{ Computer = $h; Ok = $false; Code = $null; Result = $_.Exception.Message; Log = '' }
        }
    }
}

# ---------------------------------------------------------------- Security baseline audit (HardeningKitty CSV format, audit only)
function Invoke-WBaselineAudit([string]$CsvPath) {
    $list = @(Import-Csv -LiteralPath $CsvPath)
    $secedit = $null; $netAcc = $null
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $cmp = {
        param($cur, $rec, $op)
        if ($null -eq $cur -or "$cur" -eq '') { return $false }
        $n1 = 0.0; $n2 = 0.0
        $num = [double]::TryParse("$cur", [ref]$n1) -and [double]::TryParse("$rec", [ref]$n2)
        switch ($op) {
            '='        { if ($num) { $n1 -eq $n2 } else { "$cur" -eq "$rec" } }
            '<='       { $num -and $n1 -le $n2 }
            '>='       { $num -and $n1 -ge $n2 }
            '=|0'      { "$cur" -eq "$rec" -or "$cur" -eq '0' }
            'contains' { "$cur" -like "*$rec*" }
            default    { "$cur" -eq "$rec" }
        }
    }
    $i = 0
    foreach ($r in $list) {
        $i++; if ($i % 25 -eq 0) { $Sync.Status = "Auditing $i of $($list.Count)..."; $Sync.Progress = [int]($i * 100 / $list.Count) }
        $cur = $null; $supported = $true
        if (-not $isAdmin -and $r.Method -in 'secedit', 'auditpol', 'WindowsOptionalFeature', 'BitLockerVolume') {
            [pscustomobject]@{ Id = $r.ID; Category = $r.Category; Name = $r.Name; Current = ''; Recommended = "$($r.Operator) $($r.RecommendedValue)"; Result = 'Needs admin'; Severity = $r.Severity }; continue
        }
        try {
            switch ($r.Method) {
                'Registry' {
                    $cur = Get-WRegValue $r.RegistryPath $r.RegistryItem
                    if ($null -eq $cur) { $cur = $r.DefaultValue }
                }
                'secedit' {
                    if (-not $secedit) {
                        $tmp = Join-Path ([IO.Path]::GetTempPath()) ('computerdoctor-secedit-{0}.inf' -f [guid]::NewGuid().ToString('N'))
                        & secedit.exe /export /cfg $tmp /areas SECURITYPOLICY USER_RIGHTS 2>&1 | Out-Null
                        $secedit = @{}; $sec = ''
                        foreach ($l in (Get-Content -LiteralPath $tmp -ErrorAction SilentlyContinue)) {
                            if ($l -match '^\[(.+)\]$') { $sec = $Matches[1] } elseif ($l -match '^(.+?)\s*=\s*(.*)$') { $secedit["$sec\$($Matches[1].Trim())"] = $Matches[2].Trim() }
                        }
                        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
                    }
                    $cur = $secedit[$r.MethodArgument]
                    if ($null -eq $cur) { $cur = $r.DefaultValue }
                    if ($cur -match '^\d+,(.*)$') { $cur = $Matches[1].Trim('"') }
                }
                'auditpol' {
                    $o = & auditpol.exe /get "/subcategory:$($r.MethodArgument)" /r 2>$null | ConvertFrom-Csv
                    $cur = [string]@($o)[0].'Inclusion Setting'
                }
                'accountpolicy' {
                    if (-not $netAcc) { $netAcc = @{}; foreach ($l in (& net.exe accounts 2>$null)) { if ($l -match '^(.+?):\s+(.+)$') { $netAcc[$Matches[1].Trim()] = $Matches[2].Trim() } } }
                    $key = switch -Regex ($r.Name) {
                        'lockout duration' { 'Lockout duration (minutes)' } 'lockout threshold' { 'Lockout threshold' } 'observation|reset account lockout' { 'Lockout observation window (minutes)' }
                        'maximum password age' { 'Maximum password age (days)' } 'minimum password age' { 'Minimum password age (days)' } 'minimum password length' { 'Minimum password length' } 'password history' { 'Length of password history maintained' }
                        default { $null }
                    }
                    if ($key) { $cur = $netAcc[$key]; if ($cur -eq 'Never') { $cur = '0' } } else { $supported = $false }
                }
                'service' { $svc = Get-Service -Name $r.MethodArgument -ErrorAction SilentlyContinue; $cur = if ($svc) { [string]$svc.StartType } else { 'Not installed' } }
                'WindowsOptionalFeature' { $cur = [string](Get-WindowsOptionalFeature -Online -FeatureName $r.MethodArgument -ErrorAction Stop).State }
                'MpComputerStatus' { $cur = (Get-MpComputerStatus -ErrorAction Stop).($r.MethodArgument) }
                'CimInstance' { $cur = (Get-CimInstance -Namespace $r.Namespace -ClassName $r.ClassName -ErrorAction Stop | Select-Object -First 1).($r.Property) }
                'BitLockerVolume' { $cur = [string](Get-CimInstance -Namespace root/cimv2/Security/MicrosoftVolumeEncryption -ClassName Win32_EncryptableVolume -Filter "DriveLetter='$($env:SystemDrive)'" -ErrorAction Stop).($r.Property) }
                default { $supported = $false }
            }
        } catch { $cur = "Error: $($_.Exception.Message)"; $supported = $true }
        $result = if (-not $supported) { 'Not supported' } elseif ("$cur" -like 'Error:*') { 'Error' } elseif (& $cmp $cur $r.RecommendedValue $r.Operator) { 'Passed' } else { 'Failed' }
        [pscustomobject]@{ Id = $r.ID; Category = $r.Category; Name = $r.Name; Current = [string]$cur; Recommended = "$($r.Operator) $($r.RecommendedValue)"; Result = $result; Severity = $r.Severity }
    }
}

# ---------------------------------------------------------------- Inventory (one PC; fleet runs call it on each)
function Get-WInventory {
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
    $cpu = @(Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue)[0]
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    $sys = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction SilentlyContinue
    $disks = @(Get-PhysicalDisk -ErrorAction SilentlyContinue | ForEach-Object { '{0} ({1:N0} GB, {2})' -f $_.FriendlyName, ($_.Size / 1GB), $_.HealthStatus })
    $sig = $null; try { $sig = (Get-MpComputerStatus -ErrorAction Stop).AntivirusSignatureAge } catch { }
    $sb = $null; try { $sb = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -ErrorAction Stop).UEFISecureBootEnabled -eq 1 } catch { }
    $tpm = $null; try { $t = Get-CimInstance -Namespace root/cimv2/Security/MicrosoftTpm -ClassName Win32_Tpm -ErrorAction Stop; if ($t) { $tpm = ([string]$t.SpecVersion).Split(',')[0] } } catch { }
    $ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | ForEach-Object IPAddress)
    $reboot = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
    $apps = @(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 -and -not $_.ParentKeyName } | ForEach-Object { '{0} {1}' -f $_.DisplayName, $_.DisplayVersion } | Sort-Object -Unique)
    [pscustomobject]@{
        Computer = $env:COMPUTERNAME; Domain = [string]$cs.Domain; User = [string]$cs.UserName
        Manufacturer = [string]$cs.Manufacturer; Model = [string]$cs.Model; Serial = [string]$bios.SerialNumber
        Bios = '{0} ({1})' -f $bios.SMBIOSBIOSVersion, $(if ($bios.ReleaseDate) { ([datetime]$bios.ReleaseDate).ToString('yyyy-MM-dd') } else { '?' })
        OS = ([string]$os.Caption -replace '^Microsoft\s+', ''); Build = '{0}.{1}' -f $cv.CurrentBuild, $cv.UBR; DisplayVersion = [string]$cv.DisplayVersion
        Installed = $(if ($os.InstallDate) { ([datetime]$os.InstallDate).ToString('yyyy-MM-dd') } else { '' })
        LastBoot = $(if ($os.LastBootUpTime) { ([datetime]$os.LastBootUpTime).ToString('yyyy-MM-dd HH:mm') } else { '' })
        CPU = ([string]$cpu.Name).Trim(); RamGB = [Math]::Round($cs.TotalPhysicalMemory / 1GB)
        SystemFreeGB = $(if ($sys) { [Math]::Round($sys.FreeSpace / 1GB, 1) } else { $null }); Disks = $disks
        SecureBoot = $sb; Tpm = $tpm; DefenderSigDays = $sig; RebootPending = $reboot; IPs = $ips; Programs = $apps
        Win11Ready = $(if ([int]$cv.CurrentBuild -ge 22000) { 'Running Windows 11' } else { try { (Get-WWin11Readiness $true).Summary } catch { '?' } })
        SecureBootCerts = $(try { (Get-WSecureBootCerts).Status } catch { '?' })
        BitLockerKey = $(try { $b = Get-WBitLockerSummary (Get-WBitLockerInfo); "$($b.Health): $($b.Text)" } catch { '?' })
        Collected = (Get-Date).ToString('o')
    }
}

# Collects Get-WInventory from each host over WinRM (saved Credential Manager credentials are used
# when present), writes inventory.json / .csv / report.html into a dated folder, and lists what
# changed since the previous run (programs added / removed, BIOS, Windows build, RAM...).
function Invoke-WFleetInventory([string[]]$Hosts, [string]$OutRoot) {
    $stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $dir = Join-Path $OutRoot $stamp
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $prev = @{}
    $prevDir = Get-ChildItem -LiteralPath $OutRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne $stamp -and (Test-Path (Join-Path $_.FullName 'inventory.json')) } | Sort-Object Name -Descending | Select-Object -First 1
    if ($prevDir) { foreach ($x in @(Get-Content -LiteralPath (Join-Path $prevDir.FullName 'inventory.json') -Raw | ConvertFrom-Json)) { $prev[[string]$x.Computer] = $x } }
    $wrapper = { param($Lib) $Sync = @{ Remote = $true }; . ([scriptblock]::Create($Lib)); Get-WInventory }
    $results = New-Object System.Collections.Generic.List[object]; $fails = New-Object System.Collections.Generic.List[object]
    $i = 0
    foreach ($h in $Hosts) {
        $i++; $Sync.Status = "Inventory: $h ($i of $($Hosts.Count))..."; $Sync.Progress = [int]($i * 100 / $Hosts.Count)
        try {
            if ($h -in 'localhost', '.', $env:COMPUTERNAME) { $results.Add((Get-WInventory)); continue }
            $p = @{ ComputerName = $h; ScriptBlock = $wrapper; ArgumentList = @($Sync.WorkerLib); ErrorAction = 'Stop' }
            $saved = try { [ComputerDoctor.CredMan]::ReadHost($h) } catch { $null }
            if ($saved) { $p.Credential = New-Object System.Management.Automation.PSCredential($saved[0], (ConvertTo-SecureString $saved[1] -AsPlainText -Force)) }
            $r = Invoke-Command @p 6>$null | Select-Object -Property * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName
            $results.Add($r)
            Write-WLog "Inventory: $h done"
        } catch { $fails.Add([pscustomobject]@{ Computer = $h; Error = $_.Exception.Message }); Write-WLog "Inventory of $h failed: $($_.Exception.Message)" 'WARN' }
    }
    $changes = foreach ($r in $results) {
        $o = $prev[[string]$r.Computer]
        if (-not $o) { continue }
        $c = @(foreach ($f in 'Model', 'Serial', 'Bios', 'OS', 'Build', 'RamGB', 'Tpm', 'SecureBoot', 'SecureBootCerts') { if ("$($r.$f)" -ne "$($o.$f)") { "$($f): $($o.$f) -> $($r.$f)" } })
        $added = @($r.Programs | Where-Object { $_ -notin @($o.Programs) }); $removed = @($o.Programs | Where-Object { $_ -notin @($r.Programs) })
        if ($c.Count -or $added.Count -or $removed.Count) { [pscustomobject]@{ Computer = $r.Computer; Changes = $c; Added = $added; Removed = $removed } }
    }
    ConvertTo-Json -InputObject $results.ToArray() -Depth 4 | Set-Content -LiteralPath (Join-Path $dir 'inventory.json') -Encoding UTF8   # (@(List) throws in PS 5.1)
    $results | Select-Object Computer, Domain, User, Manufacturer, Model, Serial, Bios, OS, DisplayVersion, Build, Installed, LastBoot, CPU, RamGB, SystemFreeGB, SecureBoot, Tpm, DefenderSigDays, RebootPending, Win11Ready, SecureBootCerts, BitLockerKey,
        @{ n = 'Disks'; e = { $_.Disks -join '; ' } }, @{ n = 'IPs'; e = { $_.IPs -join ', ' } }, @{ n = 'Programs'; e = { @($_.Programs).Count } } |
        Export-Csv -LiteralPath (Join-Path $dir 'inventory.csv') -NoTypeInformation -Encoding UTF8
    if ($fails.Count) { $fails | Export-Csv -LiteralPath (Join-Path $dir 'failed.csv') -NoTypeInformation -Encoding UTF8 }
    $e = { param($s) [System.Net.WebUtility]::HtmlEncode([string]$s) }
    $rows = foreach ($r in $results) {
        $flag = if ($r.RebootPending) { ' (restart pending)' } else { '' }
        "<tr><td><b>$(& $e $r.Computer)</b><br><small>$(& $e $r.User)</small></td><td>$(& $e "$($r.Manufacturer) $($r.Model)")<br><small>S/N $(& $e $r.Serial)</small></td><td>$(& $e $r.OS)<br><small>$(& $e $r.DisplayVersion) build $(& $e $r.Build)$flag</small></td><td>$(& $e $r.Bios)</td><td>$(& $e $r.CPU)<br><small>$($r.RamGB) GB RAM</small></td><td>$($r.SystemFreeGB) GB</td><td>SB $(& $e $r.SecureBoot) (certs $(& $e $r.SecureBootCerts)), TPM $(& $e $r.Tpm), Defender defs $(& $e $r.DefenderSigDays) d</td><td>$(@($r.Programs).Count)</td></tr>"
    }
    $chg = foreach ($c in @($changes)) {
        "<h3>$(& $e $c.Computer)</h3><ul>" + (($c.Changes | ForEach-Object { "<li>$(& $e $_)</li>" }) -join '') + (($c.Added | ForEach-Object { "<li style='color:#1f9e8f'>+ $(& $e $_)</li>" }) -join '') + (($c.Removed | ForEach-Object { "<li style='color:#c8344f'>- $(& $e $_)</li>" }) -join '') + '</ul>'
    }
    $fl = if ($fails.Count) { '<h2>Not reached</h2><ul>' + (($fails | ForEach-Object { "<li><b>$(& $e $_.Computer)</b>: $(& $e $_.Error)</li>" }) -join '') + '</ul>' } else { '' }
    $html = @"
<!doctype html><html><head><meta charset="utf-8"><title>Fleet inventory $stamp</title>
<style>body{font-family:Segoe UI,sans-serif;margin:28px;color:#1c2140}table{border-collapse:collapse;width:100%;font-size:13px}td,th{padding:7px 9px;border-bottom:1px solid #dde;text-align:left;vertical-align:top}th{color:#667}small{color:#778}</style></head>
<body><h1>Fleet inventory</h1><p>$($results.Count) PC(s) collected $((Get-Date).ToString('f')) by Computer Doctor. $(if ($prevDir) { "Compared with $($prevDir.Name)." } else { 'First run - nothing to compare with yet.' })</p>
<table><tr><th>Computer</th><th>Model</th><th>Windows</th><th>BIOS</th><th>CPU / RAM</th><th>Free on C:</th><th>Security</th><th>Programs</th></tr>
$($rows -join "`n")</table>
<h2>Changes since last run</h2>$(if (@($changes).Count) { $chg -join "`n" } else { '<p>None.</p>' })
$fl</body></html>
"@
    $html | Set-Content -LiteralPath (Join-Path $dir 'report.html') -Encoding UTF8
    [pscustomobject]@{ Dir = $dir; Html = (Join-Path $dir 'report.html'); Count = $results.Count; Failed = $fails.Count; Changed = @($changes).Count }
}

# ---------------------------------------------------------------- Folder backup (robocopy mirror + versions)
# Backups made before the rename to Computer Doctor are in <Dest>\AWiper-Backup\<COMPUTER>. The first
# backup after the rename moves that folder to ComputerDoctor-Backup (same drive, so it is instant and
# keeps the older versions). If it can't be moved, the old folder keeps being used.
function Get-WBackupRoot([string]$Dest, [switch]$Move) {
    $root = Join-Path $Dest "ComputerDoctor-Backup\$env:COMPUTERNAME"
    $old = Join-Path $Dest "AWiper-Backup\$env:COMPUTERNAME"
    if ((Test-Path -LiteralPath $root) -or -not (Test-Path -LiteralPath $old)) { return $root }
    if (-not $Move) { return $old }
    try {
        New-Item -ItemType Directory -Path (Split-Path $root) -Force | Out-Null
        [IO.Directory]::Move($old, $root)
        Write-WLog "Backup: moved the earlier backup from $old to $root"
        try { [IO.Directory]::Delete((Split-Path $old)) } catch { }   # removes AWiper-Backup only if nothing else is in it
        $root
    } catch {
        Write-WLog "Backup: could not move $old to $root ($($_.Exception.Message)) - using the old folder" 'WARN'
        $old
    }
}

# Mirrors each source into <Dest>\ComputerDoctor-Backup\<COMPUTER>\current\<name>. Before mirroring, files the
# mirror would overwrite or delete are moved to versions\<timestamp>\ so older copies are kept.
# Refuses to run if the destination isn't the exact volume chosen when the job was set up.
function Invoke-WBackup($Job) {
    $res = [ordered]@{ Ok = $false; New = 0; Versioned = 0; Errors = 0; Message = '' }
    if (-not $Job.Dest -or -not (Test-Path -LiteralPath $Job.Dest)) { $res.Message = "The backup drive isn't connected ($($Job.Dest))."; return [pscustomobject]$res }
    if ($Job.DestVolumeId -and [ComputerDoctor.Native]::VolumeId($Job.Dest) -ne $Job.DestVolumeId) {
        $res.Message = "A different drive is using $($Job.Dest) now - backup skipped to protect it. Reconnect the backup drive or choose it again."; return [pscustomobject]$res
    }
    $root = Get-WBackupRoot $Job.Dest -Move
    $stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $verRoot = Join-Path $root "versions\$stamp"
    foreach ($src in @($Job.Sources)) {
        if (-not (Test-Path -LiteralPath $src)) { Write-WLog "Backup: $src not found - skipped" 'WARN'; $res.Errors++; continue }
        $name = ($src.TrimEnd('\') -replace ':', '' -replace '\\', '_')
        $cur = Join-Path $root "current\$name"
        $Sync.Status = "Backing up $src..."
        # 1) What would the mirror overwrite or delete? Keep those as versions first.
        $plan = & robocopy.exe $src $cur /MIR /L /XJ /R:0 /W:0 /NJH /NJS /FP /NS /NP 2>&1
        $moves = New-Object System.Collections.Generic.List[string]
        foreach ($l in $plan) {
            # A folder line starts with its file count ("*EXTRA Dir  -1  D:\x\"); without stripping it the folder was never kept.
            if ("$l" -match '^\s*\*EXTRA (File|Dir)\s+(?:-?\d+\s+)?(.+?)\\?\s*$') { $moves.Add($Matches[2]) }
            elseif ("$l" -match '^\s*(Newer|Older|Changed|Tweaked)\s+(.+?)\s*$') { $res.New++; $p = $Matches[2]; if ($p.StartsWith($src, [StringComparison]::OrdinalIgnoreCase)) { $moves.Add((Join-Path $cur $p.Substring($src.TrimEnd('\').Length).TrimStart('\'))) } }
            elseif ("$l" -match '^\s*New File\s') { $res.New++ }
        }
        foreach ($m in ($moves | Sort-Object Length)) {
            if (-not (Test-Path -LiteralPath $m)) { continue }        # already moved with its folder
            $rel = $m.Substring((Join-Path $root 'current').Length).TrimStart('\')
            $to = Join-Path $verRoot $rel
            try { New-Item -ItemType Directory -Path (Split-Path $to) -Force | Out-Null; Move-Item -LiteralPath $m -Destination $to -Force -ErrorAction Stop; $res.Versioned++ }
            catch { Write-WLog "Backup: could not keep old version of $($m): $($_.Exception.Message)" 'WARN'; $res.Errors++ }
        }
        # 2) Mirror.
        & robocopy.exe $src $cur /MIR /XJ /R:1 /W:1 /MT:8 /DCOPY:T /COPY:DAT /NP /NFL /NDL /NJH /NJS 2>&1 | Out-Null
        if ($LASTEXITCODE -ge 8) { Write-WLog "Backup: robocopy reported errors for $src (exit $LASTEXITCODE)" 'ERROR'; $res.Errors++ }
    }
    # 3) Keep only the newest N version folders.
    $vdir = Join-Path $root 'versions'
    if (Test-Path -LiteralPath $vdir) {
        $keep = [Math]::Max(1, [int]$Job.Keep)
        foreach ($old in @(Get-ChildItem -LiteralPath $vdir -Directory | Sort-Object Name -Descending | Select-Object -Skip $keep)) {
            Remove-Item -LiteralPath $old.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    $res.Ok = $res.Errors -eq 0
    $res.Message = '{0} new or changed file(s) copied, {1} older version(s) kept{2}' -f $res.New, $res.Versioned, $(if ($res.Errors) { ", $($res.Errors) problem(s) - see the log" } else { '' })
    Write-WLog "Backup finished: $($res.Message)"
    [pscustomobject]$res
}

# ---------------------------------------------------------------- Windows 11 readiness + ESU
# Checks Microsoft's published minimums. The CPU list is a heuristic (Intel 8th gen or newer, Core
# Ultra, AMD Ryzen 2000 or newer, any ARM64); Microsoft's PC Health Check is the final word.
function Get-WWin11Readiness([bool]$Quick = $true) {
    $checks = New-Object System.Collections.Generic.List[object]
    $add = { param($Name, $Ok, $Detail) $checks.Add([pscustomobject]@{ Name = $Name; Ok = $Ok; Detail = $Detail }) }
    $cpu = @(Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue)[0]
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $name = ([string]$cpu.Name).Trim()
    $cpuOk = $null
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $cpu.Architecture -eq 12) { $cpuOk = $true }
    elseif ($name -match 'Core\(TM\) Ultra|Core Ultra') { $cpuOk = $true }
    elseif ($name -match 'i[3579]-(\d{4,5})') { $n = $Matches[1]; $gen = if ($n.Length -eq 5) { [int]$n.Substring(0, 2) } else { [int]$n.Substring(0, 1) }; $cpuOk = $gen -ge 8 }
    elseif ($name -match 'Core\(TM\) [3579] \d{3}') { $cpuOk = $true }
    elseif ($name -match 'Ryzen.*?(\d)(\d{3})') { $cpuOk = [int]$Matches[1] -ge 2 -and $name -notmatch '\b(2200U|2300U|2500U|2700U|2800H)\b' }
    elseif ($name -match 'Xeon|Pentium|Celeron|Atom|EPYC|Athlon') { $cpuOk = $null }
    else { $cpuOk = $false }
    $cores = [int]$cpu.NumberOfCores; $ghz = [Math]::Round($cpu.MaxClockSpeed / 1000.0, 1)
    $basic = $cores -ge 2 -and $ghz -ge 1 -and [Environment]::Is64BitOperatingSystem
    & $add 'Processor' $(if (-not $basic) { $false } else { $cpuOk }) ("$name ($cores cores, $ghz GHz)" + $(if ($null -eq $cpuOk) { ' - check this model on Microsoft''s supported CPU list' } elseif (-not $cpuOk) { ' - older than the supported list' } else { '' }))
    $ram = [Math]::Round($cs.TotalPhysicalMemory / 1GB)
    & $add 'Memory' ($ram -ge 4) "$ram GB (4 GB needed)"
    $sd = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction SilentlyContinue
    $gb = if ($sd) { [Math]::Round($sd.Size / 1GB) } else { 0 }
    & $add 'System disk' ($gb -ge 64) "$gb GB (64 GB needed)"
    # Windows sets %firmware_type% (UEFI / Legacy) in every process.
    $uefi = if ($env:firmware_type) { $env:firmware_type -eq 'UEFI' } else { Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' }
    & $add 'UEFI firmware' $uefi $(if ($uefi) { 'Booting in UEFI mode' } else { 'Legacy BIOS boot - convert the disk with mbr2gpt and switch to UEFI' })
    $sb = $null; try { $sb = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -ErrorAction Stop).UEFISecureBootEnabled } catch { }
    & $add 'Secure Boot' ([bool]$uefi) $(if ($sb -eq 1) { 'On' } elseif ($uefi) { 'Supported but off (capable is enough for the upgrade)' } else { 'Needs UEFI' })
    $tpm = $null; try { $t = Get-CimInstance -Namespace root/cimv2/Security/MicrosoftTpm -ClassName Win32_Tpm -ErrorAction Stop; if ($t) { $tpm = ([string]$t.SpecVersion).Split(',')[0].Trim() } } catch { }
    if ($tpm) { & $add 'TPM' ([version]$tpm -ge [version]'2.0') ("TPM $tpm" + $(if ([version]$tpm -lt [version]'2.0') { ' (2.0 needed)' } else { '' })) }
    else {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        & $add 'TPM' $(if ($isAdmin) { $false } else { $null }) $(if ($isAdmin) { 'No TPM found - it may be switched off in the BIOS (PTT / fTPM)' } else { 'Needs administrator rights to check' })
    }
    if (-not $Quick) {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ('computerdoctor-dx-{0}.txt' -f [guid]::NewGuid().ToString('N'))
        try {
            $p = Start-Process dxdiag.exe -ArgumentList "/whql:off /t `"$tmp`"" -PassThru -WindowStyle Hidden; [void]$p.WaitForExit(60000)
            $txt = Get-Content -LiteralPath $tmp -Raw -ErrorAction Stop
            $dx = [regex]::Match($txt, 'DDI Version:\s*(\d+)').Groups[1].Value; $wddm = [regex]::Match($txt, 'Driver Model:\s*WDDM\s*([\d\.]+)').Groups[1].Value
            & $add 'Graphics' ([int]$dx -ge 12 -and [double]$wddm -ge 2) "DirectX $dx, WDDM $wddm (DirectX 12 / WDDM 2.0 needed)"
        } catch { & $add 'Graphics' $null 'Could not read dxdiag' }
        finally { if (Test-Path -LiteralPath $tmp) { [IO.File]::Delete($tmp) } }
    }
    $fail = @($checks | Where-Object { $_.Ok -eq $false }); $unk = @($checks | Where-Object { $null -eq $_.Ok })
    # Extended Security Updates: a Windows 10 ESU licence shows up as an activated licensing product.
    $esu = $null
    try {
        $esu = @(Get-CimInstance SoftwareLicensingProduct -Filter "Name LIKE '%ESU%' AND PartialProductKey IS NOT NULL" -ErrorAction Stop |
            ForEach-Object { '{0} ({1})' -f $_.Name, $(switch ([int]$_.LicenseStatus) { 1 { 'active' } 0 { 'not active' } default { "status $($_.LicenseStatus)" } }) })
    } catch { }
    [pscustomobject]@{
        Ready = ($fail.Count -eq 0 -and $unk.Count -eq 0); Blockers = @($fail | ForEach-Object Name); Unknown = @($unk | ForEach-Object Name)
        Checks = $checks.ToArray(); Esu = @($esu)
        Summary = if ($fail.Count) { 'Not ready: ' + (($fail | ForEach-Object { "$($_.Name) - $($_.Detail)" }) -join '; ') } elseif ($unk.Count) { 'Probably ready - could not confirm: ' + (($unk | ForEach-Object Name) -join ', ') } else { 'Meets the Windows 11 requirements' }
    }
}

# ---------------------------------------------------------------- Recovery readiness
function Test-WAdmin { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }

# Secure Boot certificate rollover (KB5062710 / KB5068202): the 2011 Microsoft certificates expire in
# 2026 (KEK and UEFI CA in June, Windows Production PCA on Oct 19). PCs that don't move to the 2023
# certificates keep booting but stop getting boot manager and DBX security fixes. Status comes from
# Windows' own servicing keys and TPM-WMI events; the firmware's DB / KEK are read when elevated.
function Get-WSecureBootCerts {
    $r = [ordered]@{ Applies = $true; SecureBootOn = $false; Status = 'Unknown'; Health = 'NA'; Summary = ''; Advice = ''; State = ''; Capable = $null
                     ErrorCode = 0; AvailableUpdates = $null; OptedOut = $false; Db2023 = $null; Kek2023 = $null; LastEvent = $null; BitLockerRisk = $false; Blocked = $false; TaskFound = $false }
    if ($env:firmware_type -and $env:firmware_type -ne 'UEFI') {
        $r.Applies = $false; $r.Status = 'NotApplicable'; $r.Summary = 'This PC boots in legacy BIOS mode, so Secure Boot certificates do not apply'; return [pscustomobject]$r
    }
    $r.SecureBootOn = (Get-WRegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' 'UEFISecureBootEnabled') -eq 1
    foreach ($k in 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing', 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot') {
        if (-not $r.State) { $r.State = [string](Get-WRegValue $k 'UEFICA2023Status') }
        if ($null -eq $r.Capable) { $r.Capable = Get-WRegValue $k 'WindowsUEFICA2023Capable' }
        $e = Get-WRegValue $k 'UEFICA2023Error'; if ($e) { $r.ErrorCode = [int64]$e }
    }
    $r.AvailableUpdates = Get-WRegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot' 'AvailableUpdates'
    $r.OptedOut = (Get-WRegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot' 'HighConfidenceOptOut') -eq 1
    $r.TaskFound = [bool](Get-ScheduledTask -TaskPath '\Microsoft\Windows\PI\' -TaskName 'Secure-Boot-Update' -ErrorAction SilentlyContinue)
    $meaning = @{ 1808 = 'certificates updated'; 1799 = '2023 boot manager installed'; 1801 = 'update waiting for the firmware'; 1800 = 'a restart is needed'
                  1795 = 'the firmware rejected the update - a BIOS update from the PC maker is needed first'; 1796 = 'an unexpected error'
                  1802 = 'blocked because of a known firmware problem on this model'; 1803 = 'the PC maker has not provided a signed key for this model yet'
                  1032 = 'held back because BitLocker would ask for the recovery key'; 1043 = 'new KEK added'; 1044 = 'Option ROM CA 2023 added'; 1045 = 'UEFI CA 2023 added' }
    $ev = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = @($meaning.Keys); StartTime = (Get-Date).AddDays(-180) } -MaxEvents 50 -ErrorAction SilentlyContinue |
        Where-Object { $_.ProviderName -match 'TPM-WMI' })
    if ($ev.Count) { $r.LastEvent = [pscustomobject]@{ Id = $ev[0].Id; Time = $ev[0].TimeCreated; Meaning = $meaning[$ev[0].Id] } }
    $latestKey = @($ev | Where-Object { $_.Id -in 1808, 1801, 1800, 1795, 1802, 1803, 1032, 1796 }) | Select-Object -First 1
    $r.BitLockerRisk = [bool](@($ev | Where-Object { $_.Id -eq 1032 -and $_.TimeCreated -gt (Get-Date).AddDays(-30) }).Count)
    if (Test-WAdmin) {
        try { $r.Db2023 = [Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI -Name db -ErrorAction Stop).Bytes) -match 'Windows UEFI CA 2023' } catch { }
        try { $r.Kek2023 = [Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI -Name KEK -ErrorAction Stop).Bytes) -match 'KEK 2K CA 2023' } catch { }
    }
    if ($r.State -eq 'Updated' -or $r.Capable -eq 2 -or ($latestKey -and $latestKey.Id -eq 1808)) {
        $r.Status = 'Updated'; $r.Health = 'Good'; $r.Summary = 'This PC has the 2023 Secure Boot certificates and boots with the 2023-signed boot manager'
    } elseif ($latestKey -and $latestKey.Id -in 1795, 1802, 1803) {
        $r.Status = 'Blocked'; $r.Blocked = $true; $r.Health = 'Warning'; $r.Summary = "Secure Boot certificate update blocked: $($meaning[$latestKey.Id])"
        $r.Advice = 'Install the latest BIOS / UEFI update from the PC maker, then check again.'
    } elseif ($r.State -eq 'InProgress' -or $r.Capable -eq 1 -or ($latestKey -and $latestKey.Id -in 1801, 1800, 1032)) {
        $r.Status = 'InProgress'; $r.Health = $(if ($r.BitLockerRisk) { 'Warning' } else { 'Info' })
        $r.Summary = 'The Secure Boot certificate update has started' + $(if ($latestKey) { " - last step: $($meaning[$latestKey.Id])" } else { '' })
        $r.Advice = if ($r.BitLockerRisk) { 'Make sure the BitLocker recovery key is saved, then let Computer Doctor suspend BitLocker for two restarts and finish the update.' } else { 'Restart the PC (twice if asked) to let it finish.' }
    } else {
        $r.Status = 'NotStarted'; $r.Health = 'Warning'
        $r.Summary = 'This PC still uses the 2011 Secure Boot certificates. They expire in 2026 (the last on Oct 19), after which boot security fixes stop'
        $r.Advice = if ($r.OptedOut) { 'Automatic rollout is turned off here (HighConfidenceOptOut). Use "Update certificates" after saving the BitLocker recovery key.' } else { 'Windows rolls this out automatically through monthly updates; you can start it now with "Update certificates".' }
    }
    if (-not $r.SecureBootOn -and $r.Status -ne 'Updated') { $r.Health = 'Info'; $r.Summary += ' (Secure Boot is currently off)' }
    if ($r.ErrorCode -and $r.Status -ne 'Updated') { $r.Summary += (' - error 0x{0:X}' -f $r.ErrorCode) }
    [pscustomobject]$r
}

# Starts the Secure Boot certificate update the way Microsoft documents for IT-managed PCs:
# AvailableUpdates = 0x5944, then the Secure-Boot-Update task. Optionally suspends BitLocker for
# two restarts first. Firmware changes can't be rolled back, so this isn't put in the undo journal.
function Start-WSecureBootUpdate([bool]$SuspendBitLocker) {
    if (-not (Test-WAdmin)) { throw 'Needs administrator rights.' }
    $c = Get-WSecureBootCerts
    if (-not $c.Applies) { throw $c.Summary }
    if ($c.Blocked) { throw "$($c.Summary). $($c.Advice)" }
    if ($SuspendBitLocker) {
        $v = Get-CimInstance -Namespace root/cimv2/Security/MicrosoftVolumeEncryption -ClassName Win32_EncryptableVolume -Filter "DriveLetter='$($env:SystemDrive)'" -ErrorAction SilentlyContinue
        if ($v -and $v.ProtectionStatus -eq 1) {
            $x = Invoke-CimMethod -InputObject $v -MethodName DisableKeyProtectors -Arguments @{ DisableCount = [uint32]2 }
            if ($x.ReturnValue -ne 0) { throw "Could not suspend BitLocker (code $($x.ReturnValue))" }
            Write-WLog "BitLocker suspended on $($env:SystemDrive) for two restarts"
        }
    }
    Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot' -Name 'AvailableUpdates' -Value 0x5944 -Type DWord -ErrorAction Stop
    try { Start-ScheduledTask -TaskPath '\Microsoft\Windows\PI\' -TaskName 'Secure-Boot-Update' -ErrorAction Stop } catch { Write-WLog "Secure-Boot-Update task: $($_.Exception.Message) - it runs on its own within 12 hours" 'WARN' }
    Write-WLog 'Secure Boot certificate update requested (AvailableUpdates=0x5944). Restart the PC, twice if Windows asks.'
    Start-Sleep -Seconds 5
    Get-WSecureBootCerts
}

# BitLocker per volume, plus where (if anywhere) Windows says the recovery key was backed up.
# Recovery passwords themselves are never returned here.
function Get-WBitLockerInfo {
    $admin = Test-WAdmin
    $join = @{ Domain = $false; Entra = $false }
    try { $ds = (& dsregcmd.exe /status 2>$null) -join "`n"; $join.Domain = $ds -match 'DomainJoined\s*:\s*YES'; $join.Entra = $ds -match 'AzureAdJoined\s*:\s*YES' } catch { }
    $escrow = @{}
    foreach ($e in @(Get-WinEvent -LogName 'Microsoft-Windows-BitLocker/BitLocker Management' -MaxEvents 400 -ErrorAction SilentlyContinue)) {
        if ($e.Message -notmatch 'backed up|backup') { continue }
        if ($e.LevelDisplayName -match 'Error|Warning' -or $e.Level -in 2, 3) { continue }
        $dest = if ($e.Message -match 'Azure|Entra') { 'Microsoft Entra ID' } elseif ($e.Message -match 'Active Directory') { 'Active Directory' } else { 'a directory service' }
        foreach ($m in [regex]::Matches($e.Message, '\{[0-9A-Fa-f-]{36}\}')) { if (-not $escrow[$m.Value.ToUpperInvariant()]) { $escrow[$m.Value.ToUpperInvariant()] = $dest } }
    }
    $vols = New-Object System.Collections.Generic.List[object]
    if ($admin -and (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue)) {
        foreach ($v in @(Get-BitLockerVolume -ErrorAction SilentlyContinue)) {
            $rp = @($v.KeyProtector | Where-Object { "$($_.KeyProtectorType)" -eq 'RecoveryPassword' })
            $esc = @($rp | ForEach-Object { $escrow[([string]$_.KeyProtectorId).ToUpperInvariant()] } | Where-Object { $_ } | Select-Object -Unique)
            $vs = "$($v.VolumeStatus)"; $ps = "$($v.ProtectionStatus)"
            $state = if ($vs -eq 'FullyDecrypted') { 'Off' } elseif (-not @($v.KeyProtector).Count -and $vs -ne 'FullyDecrypted') { 'Waiting' } elseif ($ps -eq 'Off') { 'Suspended' } elseif ($vs -match 'Progress') { 'Encrypting' } else { 'On' }
            $vols.Add([pscustomobject]@{ Mount = [string]$v.MountPoint; Type = "$($v.VolumeType)"; State = $state; Percent = [int]$v.EncryptionPercentage
                Protectors = @($v.KeyProtector | ForEach-Object { "$($_.KeyProtectorType)" }); RecoveryPasswords = $rp.Count; EscrowedTo = $esc })
        }
    } else {
        # Without admin rights only Explorer's BitLocker icon state is readable.
        try {
            $sh = New-Object -ComObject Shell.Application
            foreach ($d in [IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' }) {
                $p = $sh.NameSpace(17).ParseName($d.Name.TrimEnd('\')).ExtendedProperty('System.Volume.BitLockerProtection')
                $state = switch ([int]$p) { 1 { 'On' } 3 { 'Encrypting' } 5 { 'Suspended' } 2 { 'Off' } 0 { 'Off' } default { 'Unknown' } }
                $vols.Add([pscustomobject]@{ Mount = $d.Name.TrimEnd('\'); Type = $(if ($d.Name.TrimEnd('\') -eq $env:SystemDrive) { 'OperatingSystem' } else { 'Data' }); State = $state; Percent = -1; Protectors = @(); RecoveryPasswords = -1; EscrowedTo = @() })
            }
        } catch { }
    }
    $pde = Get-WRegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker' 'PreventDeviceEncryption'
    [pscustomobject]@{ Admin = $admin; Volumes = $vols.ToArray(); Domain = $join.Domain; Entra = $join.Entra; PreventDeviceEncryption = ($pde -eq 1) }
}

# One summary line + status for the Health Check and inventory.
function Get-WBitLockerSummary($Info) {
    $enc = @($Info.Volumes | Where-Object { $_.State -in 'On', 'Suspended', 'Encrypting', 'Waiting' })
    if (-not $Info.Volumes.Count) { return [pscustomobject]@{ Health = 'NA'; Text = 'BitLocker status is not available' } }
    if (-not $enc.Count) {
        if (-not $Info.Admin) { return [pscustomobject]@{ Health = 'Info'; Text = 'No drives appear to be encrypted with BitLocker (run as administrator for a definite answer)' } }
        return [pscustomobject]@{ Health = 'Info'; Text = 'No drives are encrypted with BitLocker - nothing to lose if the PC''s security chip or firmware changes' }
    }
    $names = ($enc | ForEach-Object Mount) -join ', '
    if (-not $Info.Admin) { return [pscustomobject]@{ Health = 'Info'; Text = "BitLocker is on for $names. Run as administrator to check that a recovery key exists and where it's saved" } }
    $noKey = @($enc | Where-Object { $_.State -ne 'Waiting' -and $_.RecoveryPasswords -eq 0 })
    if ($noKey.Count) { return [pscustomobject]@{ Health = 'Problem'; Text = "$(($noKey | ForEach-Object Mount) -join ', ') is encrypted without a recovery password - if Windows ever asks for one, the data can't be unlocked. Add one and save it" } }
    $waiting = @($enc | Where-Object { $_.State -eq 'Waiting' })
    $susp = @($enc | Where-Object { $_.State -eq 'Suspended' })
    $unknown = @($enc | Where-Object { $_.State -ne 'Waiting' -and -not @($_.EscrowedTo).Count })
    $parts = @()
    if ($susp.Count) { $parts += "Protection is suspended on $(($susp | ForEach-Object Mount) -join ', ') (it resumes after the set number of restarts)" }
    if ($waiting.Count) { $parts += "$(($waiting | ForEach-Object Mount) -join ', ') is encrypted but waiting for activation - a recovery key is created and protection turns on when someone signs in with a Microsoft or work account" }
    if ($waiting.Count -eq $enc.Count) { return [pscustomobject]@{ Health = 'Info'; Text = $parts -join '. ' } }
    if ($unknown.Count) {
        $where = if ($Info.Entra -or $Info.Domain) { 'Windows has no record of it being backed up to your organization' } else { 'check it is in your Microsoft account (aka.ms/myrecoverykey) or save a copy now' }
        return [pscustomobject]@{ Health = 'Warning'; Text = "BitLocker is on for $names. Make sure the recovery key is saved somewhere other than this PC: $where" + $(if ($parts) { '. Also: ' + ($parts -join '; ') } else { '' }) }
    }
    $prot = @($enc | Where-Object { $_.State -ne 'Waiting' })
    [pscustomobject]@{ Health = $(if ($susp.Count) { 'Warning' } else { 'Good' }); Text = "BitLocker is on for $(($prot | ForEach-Object Mount) -join ', ') and the recovery key is backed up to $((@($prot | ForEach-Object { $_.EscrowedTo }) | Select-Object -Unique) -join ', ')" + $(if ($parts) { '. ' + ($parts -join '. ') } else { '' }) }
}

# Recovery passwords for one volume - only on explicit request, never logged.
function Get-WBitLockerRecoveryKeys([string]$Mount) {
    if (-not (Test-WAdmin)) { throw 'Needs administrator rights.' }
    @((Get-BitLockerVolume -MountPoint $Mount -ErrorAction Stop).KeyProtector | Where-Object { "$($_.KeyProtectorType)" -eq 'RecoveryPassword' } |
        ForEach-Object { [pscustomobject]@{ Id = [string]$_.KeyProtectorId; Password = [string]$_.RecoveryPassword } })
}
function Add-WBitLockerRecoveryPassword([string]$Mount) {
    if (-not (Test-WAdmin)) { throw 'Needs administrator rights.' }
    [void](Add-BitLockerKeyProtector -MountPoint $Mount -RecoveryPasswordProtector -ErrorAction Stop -WarningAction SilentlyContinue)
    Write-WLog "BitLocker: added a recovery password to $Mount"
}
function Backup-WBitLockerKey([string]$Mount, [string]$To) {
    if (-not (Test-WAdmin)) { throw 'Needs administrator rights.' }
    $n = 0
    foreach ($kp in @((Get-BitLockerVolume -MountPoint $Mount -ErrorAction Stop).KeyProtector | Where-Object { "$($_.KeyProtectorType)" -eq 'RecoveryPassword' })) {
        if ($To -eq 'Entra') { [void](BackupToAAD-BitLockerKeyProtector -MountPoint $Mount -KeyProtectorId $kp.KeyProtectorId -ErrorAction Stop) }
        else { [void](Backup-BitLockerKeyProtector -MountPoint $Mount -KeyProtectorId $kp.KeyProtectorId -ErrorAction Stop) }
        $n++
    }
    Write-WLog "BitLocker: backed up $n recovery key(s) for $Mount to $(if ($To -eq 'Entra') { 'Microsoft Entra ID' } else { 'Active Directory' })"
    $n
}

# Windows RE, Quick Machine Recovery and Point-in-time Restore.
function Get-WRecoveryEnv {
    $r = [ordered]@{ Admin = (Test-WAdmin); WinRE = 'Unknown'; WinREPath = ''; Qmr = 'Unknown'; QmrAuto = 'Unknown'; Pitr = 'Unknown'; RestorePoints = -1; LastRestorePoint = $null; ProtectionOn = $null }
    if ($r.Admin) {
        $info = (& reagentc.exe /info 2>&1) -join "`n"
        if ($info -match 'Windows RE status:\s*(\w+)') { $r.WinRE = $Matches[1] }
        if ($info -match 'Windows RE location:\s*(\S.*)') { $r.WinREPath = $Matches[1].Trim() }
        $xml = (& reagentc.exe /getrecoverysettings 2>&1) -join "`n"
        if ($xml -match '<') {
            # Only read the two switches; the XML can contain a saved Wi-Fi password, which is never kept.
            $cloud = [regex]::Match($xml, 'CloudRemediation[^>]*?state\s*=\s*"(\d)"', 'IgnoreCase'); if (-not $cloud.Success) { $cloud = [regex]::Match($xml, '<CloudRemediation[^>]*>\s*(\w+)', 'IgnoreCase') }
            $auto = [regex]::Match($xml, 'AutoRemediation[^>]*?state\s*=\s*"(\d)"', 'IgnoreCase'); if (-not $auto.Success) { $auto = [regex]::Match($xml, '<AutoRemediation[^>]*>\s*(\w+)', 'IgnoreCase') }
            $map = { param($v) switch -Regex ([string]$v) { '^(1|true|on|enabled)$' { 'On' } '^(0|false|off|disabled)$' { 'Off' } default { 'Unknown' } } }
            if ($cloud.Success) { $r.Qmr = & $map $cloud.Groups[1].Value }
            if ($auto.Success) { $r.QmrAuto = & $map $auto.Groups[1].Value }
        } else { $r.Qmr = 'NotSupported' }
        try {
            $pts = @(Get-CimInstance -Namespace root/default -ClassName SystemRestore -ErrorAction Stop)
            $r.RestorePoints = $pts.Count
            if ($pts.Count) { $r.LastRestorePoint = ($pts | ForEach-Object { try { [datetime]::SpecifyKind([datetime]::ParseExact(([string]$_.CreationTime).Substring(0, 14), 'yyyyMMddHHmmss', $null), 'Utc').ToLocalTime() } catch { } } | Sort-Object -Descending | Select-Object -First 1) }
        } catch { }
    }
    $r.ProtectionOn = (Get-WRegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' 'RPSessionInterval') -eq 1
    # Point-in-time Restore (Windows 11, 2026): not documented for scripts; this value is what the Settings toggle writes.
    $pitr = Get-WRegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Recovery\PITR\Settings' 'Active_UX'
    $r.Pitr = if ($pitr -eq 1) { 'On' } elseif ($pitr -eq 0) { 'Off' } elseif (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Recovery\PITR') { 'Available' } else { 'NotAvailable' }
    [pscustomobject]$r
}

# Windows 10 consumer Extended Security Updates (now through Oct 12, 2027): what's missing to enroll.
function Get-WEsuEligibility {
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    $build = [int]$cv.CurrentBuild
    if ($build -ge 22000) { return [pscustomobject]@{ Applies = $false; Ready = $false; Missing = @(); Enrolled = $null; Summary = 'Windows 11 - ESU does not apply' } }
    $miss = New-Object System.Collections.Generic.List[string]
    if ($build -ne 19045) { $miss.Add("version 22H2 (this PC is build $build)") }
    if ([string]$cv.EditionID -notmatch '^(Core|CoreSingleLanguage|CoreCountrySpecific|Professional|ProfessionalEducation|ProfessionalWorkstation)') { $miss.Add("a Home or Pro edition (this is $($cv.EditionID); businesses buy ESU through volume licensing)") }
    $hf = @(Get-HotFix -ErrorAction SilentlyContinue)
    if (-not ($hf | Where-Object HotFixID -eq 'KB5126256')) {
        $pkg = $false; try { $pkg = [bool](Get-WindowsPackage -Online -ErrorAction Stop | Where-Object PackageName -match '5126256') } catch { }
        if (-not $pkg) { $miss.Add('the ESU licensing preparation update KB5126256') }
    }
    $last = $hf | Where-Object InstalledOn | Sort-Object InstalledOn -Descending | Select-Object -First 1
    if ($last -and $last.InstalledOn -lt (Get-Date).AddDays(-45)) { $miss.Add(('the latest cumulative update (last update installed {0:MMM d, yyyy})' -f $last.InstalledOn)) }
    try { $ds = (& dsregcmd.exe /status 2>$null) -join "`n"; if ($ds -match 'DomainJoined\s*:\s*YES' -or $ds -match 'AzureAdJoined\s*:\s*YES') { $miss.Add('a PC that is not joined to a domain or Entra ID (organizations use commercial ESU)') } } catch { }
    if (@(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction SilentlyContinue | Where-Object { $_.GetValue('UPN') }).Count) { $miss.Add('a PC that is not managed by MDM / Intune') }
    $enrolled = $null
    try { $enrolled = [bool]@(Get-CimInstance SoftwareLicensingProduct -Filter "Name LIKE '%ESU%' AND LicenseStatus = 1" -ErrorAction Stop).Count } catch { }
    $summary = if ($enrolled) { 'Extended Security Updates are active on this PC (through Oct 12, 2027)' }
               elseif ($miss.Count) { 'Not eligible for consumer Extended Security Updates yet - needs ' + ($miss -join '; ') }
               else { 'Eligible for free consumer Extended Security Updates through Oct 12, 2027 - enroll in Settings > Windows Update with a Microsoft account that is an administrator' }
    [pscustomobject]@{ Applies = $true; Ready = ($miss.Count -eq 0); Missing = $miss.ToArray(); Enrolled = $enrolled; Summary = $summary }
}

# ---------------------------------------------------------------- Old files (Downloads, Desktop, Documents...)
# The signed-in user's folders, wherever they've been redirected (OneDrive, another drive...).
function Get-WUserFolder([string]$Name) {
    $value = @{ Downloads = '{374DE290-123F-4565-9164-39C4925E467B}'; Desktop = 'Desktop'; Documents = 'Personal'; Pictures = 'My Pictures'; Videos = 'My Video'; Music = 'My Music' }[$Name]
    if (-not $value) { return $Name }                                     # already a path
    $p = try { (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop).$value } catch { $null }
    if ($p) { [Environment]::ExpandEnvironmentVariables($p) } else { Join-Path $env:USERPROFILE $Name }
}
function Get-WDownloadsFolder { Get-WUserFolder 'Downloads' }
function Get-WFileKind([string]$Ext) {
    switch -Regex ($Ext.ToLowerInvariant()) {
        '^\.(exe|msi|msix|msixbundle|appx|appxbundle|msu|cab)$' { 'Installer'; break }
        '^\.(iso|img|vhd|vhdx|vmdk|wim|esd)$' { 'Disk image'; break }
        '^\.(zip|7z|rar|tar|gz|tgz|bz2|xz|zst)$' { 'Archive'; break }
        '^\.(mp4|mkv|avi|mov|wmv|webm|m4v|flv|mpg|mpeg|ts)$' { 'Video'; break }
        '^\.(jpg|jpeg|png|gif|bmp|tif|tiff|heic|heif|webp|raw|cr2|cr3|nef|arw|dng|psd)$' { 'Picture'; break }
        '^\.(mp3|wav|flac|aac|m4a|ogg|wma|opus)$' { 'Music'; break }
        '^\.(pdf|doc|docx|xls|xlsx|ppt|pptx|txt|rtf|odt|ods|csv|md|epub)$' { 'Document'; break }
        '^\.(ps1|py|js|ts|cs|cpp|c|h|java|go|rs|json|xml|yml|yaml|sql|sh|bat|cmd)$' { 'Code'; break }
        default { 'Other' }
    }
}
# Files not modified or opened for $Days days and at least $MinBytes, in the given folders (names like
# 'Downloads' or full paths). Junctions, cloud-only placeholders, hidden system files and developer
# folders (.git, node_modules...) are skipped. "Last opened" is only as good as Windows' last-access
# time, so the newer of modified / accessed is used. Each result says which folder it came from and
# flags archives that were already extracted next to themselves.
function Get-WOldFiles([string[]]$Folders, [int]$Days = 90, [long]$MinBytes = 0) {
    $cut = (Get-Date).AddDays(-$Days)
    $skipDirs = '^(\.git|\.svn|\.hg|node_modules|__pycache__|\.vs|\.venv|venv|bin|obj)$'
    $seen = @{}
    $clouds = @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') + '\' } | Select-Object -Unique)
    foreach ($name in $Folders) {
        $root = Get-WUserFolder $name
        if (-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) { continue }
        $label = if ($root -eq $name) { Split-Path $root -Leaf } else { $name }
        $cloud = [bool]@($clouds | Where-Object { ($root.TrimEnd('\') + '\').StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count
        $stack = New-Object System.Collections.Generic.Stack[System.IO.DirectoryInfo]
        $stack.Push((New-Object System.IO.DirectoryInfo $root))
        while ($stack.Count) {
            $d = $stack.Pop()
            if ($seen[$d.FullName]) { continue }; $seen[$d.FullName] = $true   # e.g. Pictures inside Documents
            $Sync.Status = "Looking for old files: $($d.FullName)"
            $entries = try { $d.GetFileSystemInfos() } catch { @() }
            $dirs = @{}
            foreach ($e in $entries) { if ($e -is [System.IO.DirectoryInfo]) { $dirs[$e.Name.ToLowerInvariant()] = $true } }
            foreach ($e in $entries) {
                $a = [int]$e.Attributes
                if ($a -band 0x400) { continue }                                   # junction / symlink
                if ($e -is [System.IO.DirectoryInfo]) { if ($e.Name -notmatch $skipDirs -and -not (($a -band 2) -and ($a -band 4))) { $stack.Push($e) }; continue }
                if (($a -band 0x400000) -or ($a -band 0x40000) -or ($a -band 0x1000)) { continue }   # cloud-only / offline
                if (($a -band 2) -and ($a -band 4)) { continue }                   # hidden + system
                if ($e.Name -eq 'desktop.ini' -or $e.Length -lt $MinBytes) { continue }
                $last = if ($e.LastAccessTime -gt $e.LastWriteTime) { $e.LastAccessTime } else { $e.LastWriteTime }
                if ($last -gt $cut) { continue }
                $kind = Get-WFileKind $e.Extension
                $base = [IO.Path]::GetFileNameWithoutExtension($e.Name) -replace '\.tar$', ''
                $extracted = $kind -eq 'Archive' -and $dirs[$base.ToLowerInvariant()]
                [pscustomobject]@{ Path = $e.FullName; Name = $e.Name; Folder = $e.DirectoryName; Size = $e.Length; Extension = $e.Extension.ToLowerInvariant(); Modified = $e.LastWriteTime
                    LastUsed = $last; Kind = $kind; Root = $(if ($cloud) { "$label (OneDrive)" } else { $label }); Extracted = [bool]$extracted; Cloud = $cloud }
            }
        }
    }
}

# ---------------------------------------------------------------- Startup entries (Run keys + Startup folders)
# Same StartupApproved switches Task Manager uses. $MachineOnly skips the current user's entries
# (used over WinRM, where "current user" is the connecting admin).
function Get-WStartupItems([bool]$MachineOnly = $false) {
    $base = 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved'
    $admin = Test-WAdmin
    $enabled = { param($Key, $Name) try { $v = (Get-ItemProperty -LiteralPath $Key -Name $Name -ErrorAction Stop).$Name; if ($v -is [byte[]] -and $v.Length -gt 0) { return -not ($v[0] -band 1) } } catch { }; $true }
    $sources = @(
        @{ Hive = 'HKCU'; Key = 'Software\Microsoft\Windows\CurrentVersion\Run';             Approved = 'Run';   Location = 'Registry Run';   Scope = 'User' }
        @{ Hive = 'HKLM'; Key = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run';             Approved = 'Run';   Location = 'Registry Run';   Scope = 'All users' }
        @{ Hive = 'HKLM'; Key = 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Approved = 'Run32'; Location = 'Registry Run32'; Scope = 'All users' }
    )
    foreach ($s in $sources) {
        if ($MachineOnly -and $s.Hive -eq 'HKCU') { continue }
        $path = "$($s.Hive):\$($s.Key)"
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $k = Get-Item -LiteralPath $path
        $approved = "$($s.Hive):\$base\$($s.Approved)"
        foreach ($name in $k.GetValueNames()) {
            if (-not $name) { continue }
            [pscustomobject]@{ Name = $name; Command = [string]$k.GetValue($name); Location = $s.Location; Scope = $s.Scope
                Enabled = (& $enabled $approved $name); CanToggle = ($s.Hive -eq 'HKCU' -or $admin); ApprovedKey = $approved; ValueName = $name; FilePath = $null }
        }
    }
    $folders = @(
        @{ Path = [Environment]::GetFolderPath('Startup');       Hive = 'HKCU'; Scope = 'User' }
        @{ Path = [Environment]::GetFolderPath('CommonStartup'); Hive = 'HKLM'; Scope = 'All users' }
    )
    foreach ($f in $folders) {
        if ($MachineOnly -and $f.Hive -eq 'HKCU') { continue }
        if (-not $f.Path -or -not (Test-Path -LiteralPath $f.Path)) { continue }
        $approved = "$($f.Hive):\$base\StartupFolder"
        foreach ($file in (Get-ChildItem -LiteralPath $f.Path -File -Force -ErrorAction SilentlyContinue)) {
            if ($file.Name -eq 'desktop.ini') { continue }
            $cmd = $file.FullName
            if ($file.Extension -eq '.lnk') {
                try { $sh = New-Object -ComObject WScript.Shell; $t = $sh.CreateShortcut($file.FullName); if ($t.TargetPath) { $cmd = ('"{0}" {1}' -f $t.TargetPath, $t.Arguments).Trim() } } catch { }
            }
            [pscustomobject]@{ Name = $file.BaseName; Command = $cmd; Location = 'Startup folder'; Scope = $f.Scope
                Enabled = (& $enabled $approved $file.Name); CanToggle = ($f.Hive -eq 'HKCU' -or $admin); ApprovedKey = $approved; ValueName = $file.Name; FilePath = $file.FullName }
        }
    }
}

function Set-WStartupState($Item, [bool]$Enable) {
    if (-not (Test-Path -LiteralPath $Item.ApprovedKey)) { New-Item -Path $Item.ApprovedKey -Force -ErrorAction Stop | Out-Null }
    $bytes = New-Object byte[] 12
    if ($Enable) { $bytes[0] = 2 }
    else { $bytes[0] = 3; [Array]::Copy([BitConverter]::GetBytes((Get-Date).ToFileTime()), 0, $bytes, 4, 8) }
    New-ItemProperty -LiteralPath $Item.ApprovedKey -Name $Item.ValueName -PropertyType Binary -Value $bytes -Force -ErrorAction Stop | Out-Null
    Write-WLog ("Startup item '{0}' {1}" -f $Item.Name, $(if ($Enable) { 'enabled' } else { 'disabled' }))
}

# ---------------------------------------------------------------- Right-click menu (context menu) entries
# Shell extension handlers (shellex\ContextMenuHandlers) and static verbs (shell\<verb>) for files,
# folders, the desktop / folder background and drives. Handlers are turned off through the system's
# Shell Extensions\Blocked list; verbs with a LegacyDisable value. Both are undone by removing the value.
function Get-WContextMenu([bool]$MachineOnly = $false) {
    $blocked = @{}
    foreach ($bk in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked') {
        try { (Get-Item -LiteralPath $bk -ErrorAction Stop).GetValueNames() | ForEach-Object { if ($_) { $blocked[$_.ToUpperInvariant()] = $true } } } catch { }
    }
    $where = [ordered]@{ '*' = 'Files'; 'AllFilesystemObjects' = 'Files and folders'; 'Directory' = 'Folders'; 'Directory\Background' = 'Folder background'; 'Folder' = 'Folders'; 'Drive' = 'Drives'; 'DesktopBackground' = 'Desktop' }
    $builtIn = '^(open|opennewwindow|opennewprocess|opennewtab|explore|find|print|printto|runas|runasuser|edit|properties|cmd|powershell|Powershell|pintohome|pintostartscreen|Windows\.Share|Windows\.ModernShare|UpdateEncryptionSettings.*|encrypt-bde.*|manage-bde|resume-bde.*|unlock-bde|change-passphrase|change-pin|format)$'
    $seen = @{}
    $companies = @{}
    $companyOf = { param($f) if (-not $companies.ContainsKey($f)) { $companies[$f] = try { [string][Diagnostics.FileVersionInfo]::GetVersionInfo($f).CompanyName } catch { '' } }; $companies[$f] }
    foreach ($hive in @('HKLM') + @(if (-not $MachineOnly) { 'HKCU' })) {
        foreach ($cls in $where.Keys) {
            $base = "$($hive):\SOFTWARE\Classes\$cls"
            # Shell extension handlers.
            foreach ($k in @(Get-ChildItem -LiteralPath "$base\shellex\ContextMenuHandlers" -ErrorAction SilentlyContinue)) {
                $clsid = [string]$k.GetValue('')
                if ($k.PSChildName -match '^\{[0-9A-Fa-f-]{36}\}$') { $clsid = $k.PSChildName }
                if ($clsid -notmatch '^\{[0-9A-Fa-f-]{36}\}$') { continue }
                $id = "H|$($clsid.ToUpperInvariant())|$cls"
                if ($seen[$id]) { continue }; $seen[$id] = $true
                $name = $null; $dll = $null
                foreach ($root in 'HKLM:\SOFTWARE\Classes\CLSID', 'HKCU:\SOFTWARE\Classes\CLSID') {
                    $ck = Get-Item -LiteralPath "$root\$clsid" -ErrorAction SilentlyContinue
                    if ($ck) { if (-not $name) { $name = [string]$ck.GetValue('') }; if (-not $dll) { $dll = [string](Get-ItemProperty -LiteralPath "$root\$clsid\InprocServer32" -ErrorAction SilentlyContinue).'(default)' } }
                }
                $dllPath = if ($dll) { [Environment]::ExpandEnvironmentVariables($dll.Trim('"')) } else { '' }
                $company = if ($dllPath -and (Test-Path -LiteralPath $dllPath)) { & $companyOf $dllPath } else { '' }
                $label = if ($k.PSChildName -notmatch '^\{') { $k.PSChildName } elseif ($name) { $name } else { $clsid }
                [pscustomobject]@{ Id = $id; Kind = 'Handler'; Name = $label.Trim(); Where = $where[$cls]; Company = [string]$company; Command = $dllPath; Clsid = $clsid; Key = "$base\shellex\ContextMenuHandlers\$($k.PSChildName)"
                    Hive = $hive; Enabled = -not $blocked[$clsid.ToUpperInvariant()]; Microsoft = ($company -match '^Microsoft') }
            }
            # Static verbs.
            foreach ($k in @(Get-ChildItem -LiteralPath "$base\shell" -ErrorAction SilentlyContinue)) {
                if ($k.PSChildName -match $builtIn) { continue }
                $names = @(); try { $names = $k.GetValueNames() } catch { }
                if ($names -contains 'ProgrammaticAccessOnly') { continue }      # never shown in the menu
                $id = "V|$hive|$cls|$($k.PSChildName)"
                if ($seen[$id]) { continue }; $seen[$id] = $true
                $label = [string]$k.GetValue('MUIVerb'); if (-not $label) { $label = [string]$k.GetValue('') }
                if (-not $label -or $label -match '^@') { $label = $k.PSChildName }
                $cmd = [string](Get-ItemProperty -LiteralPath "$($k.PSPath)\command" -ErrorAction SilentlyContinue).'(default)'
                $exe = [regex]::Match($cmd, '^"([^"]+)"|^(\S+)'); $exePath = if ($exe.Groups[1].Success) { $exe.Groups[1].Value } else { $exe.Groups[2].Value }
                $company = ''
                if ($exePath) { $exePath = [Environment]::ExpandEnvironmentVariables($exePath); if (Test-Path -LiteralPath $exePath) { $company = & $companyOf $exePath } }
                # Windows' own verbs: no program of their own, a shell32-style resource label or a COM command handler.
                $mui = [string]$k.GetValue('MUIVerb')
                $delegate = [string](Get-ItemProperty -LiteralPath "$($k.PSPath)\command" -ErrorAction SilentlyContinue).DelegateExecute
                $winVerb = (-not $exePath -and ($delegate -or $mui -match '^@%?\w*%?\\?.*(shell32|windows\.storage|twinui|explorerframe|ntshrui)' -or $names -contains 'CommandStateHandler' -or $names -contains 'ExplorerCommandHandler')) -or
                           ($exePath -and $exePath -like "$env:SystemRoot\*" -and (-not $company -or $company -match '^Microsoft'))
                [pscustomobject]@{ Id = $id; Kind = 'Command'; Name = ($label -replace '&', '').Trim(); Where = $where[$cls]; Company = $(if ($winVerb -and -not $company) { 'Windows' } else { [string]$company }); Command = $cmd; Clsid = ''; Key = "$base\shell\$($k.PSChildName)"
                    Hive = $hive; Enabled = $names -notcontains 'LegacyDisable'; Microsoft = ($winVerb -or $company -match '^Microsoft') }
            }
        }
    }
}

# Turns one entry on or off and returns an undo capture (registry snapshot of the values it touched).
# Handlers are blocked machine-wide with admin rights, otherwise for the signed-in user only.
function Set-WContextMenuItem($Item, [bool]$Enabled) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $sub = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
    if ($Item.Kind -eq 'Handler') {
        $keys = if ($Enabled) { @("HKCU:\$sub") + @(if ($isAdmin) { "HKLM:\$sub" }) } else { @(if ($isAdmin) { "HKLM:\$sub" } else { "HKCU:\$sub" }) }
        $vals = @($keys | ForEach-Object { @{ Path = $_; Name = $Item.Clsid } })
    } else {
        if ($Item.Hive -eq 'HKLM' -and -not $isAdmin) { throw 'This entry is for all users - run Computer Doctor as administrator to change it.' }
        $vals = @(@{ Path = $Item.Key; Name = 'LegacyDisable' })
    }
    if ($Enabled -and $Item.Kind -eq 'Handler' -and -not $isAdmin -and $null -ne (Get-WRegValue "HKLM:\$sub" $Item.Clsid)) {
        throw 'This entry is blocked for all users - run Computer Doctor as administrator to turn it back on.'
    }
    $snap = @(Get-WRegSnapshot $vals)
    foreach ($v in $vals) {
        if ($Enabled) { Remove-ItemProperty -LiteralPath $v.Path -Name $v.Name -ErrorAction SilentlyContinue }
        else {
            if (-not (Test-Path -LiteralPath $v.Path)) { New-Item -Path $v.Path -Force -ErrorAction Stop | Out-Null }
            New-ItemProperty -LiteralPath $v.Path -Name $v.Name -Value $(if ($Item.Kind -eq 'Handler') { [string]$Item.Name } else { '' }) -PropertyType String -Force -ErrorAction Stop | Out-Null
        }
    }
    Write-WLog ("Right-click menu: {0} '{1}' ({2})" -f $(if ($Enabled) { 'turned on' } else { 'turned off' }), $Item.Name, $Item.Where)
    [pscustomobject]@{ UndoKind = 'Registry'; Label = ('Right-click menu: {0} "{1}"' -f $(if ($Enabled) { 'turned on' } else { 'turned off' }), $Item.Name); Snapshot = $snap; RemoveKeys = @() }
}

# ---------------------------------------------------------------- Health check
# Every row: Id, Name, Status (Good / Warning / Problem / Info / NA), Detail, Action.
# NA means the data source isn't available here - it must never be counted as healthy.
function Get-WHealth {
    $rows = New-Object System.Collections.Generic.List[object]
    $add = { param($Id, $Name, $Status, $Detail, $Action) $rows.Add([pscustomobject]@{ Id = $Id; Name = $Name; Status = $Status; Detail = $Detail; Action = [string]$Action }) }
    $since = (Get-Date).AddDays(-30)
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # Disks: Windows' health flag plus whatever reliability counters the driver exposes.
    try {
        foreach ($d in @(Get-PhysicalDisk -ErrorAction Stop | Sort-Object DeviceId)) {
            $rc = $null
            try { $rc = $d | Get-StorageReliabilityCounter -ErrorAction Stop } catch { }
            $facts = New-Object System.Collections.Generic.List[string]; $status = 'Good'; $why = @()
            $hs = "$($d.HealthStatus)"
            # "Unknown" (5) means no health data, often a USB enclosure, not a failing disk: it ends up N/A below.
            if ($hs -and $hs -notin 'Healthy', '0', 'Unknown', '5') { $status = 'Problem'; $why += "Windows reports the disk as $hs" }
            if ($rc) {
                if ($rc.Temperature -gt 0) { $facts.Add("$($rc.Temperature) C"); if ($rc.Temperature -ge 70 -and $status -eq 'Good') { $status = 'Warning'; $why += 'running hot' } }
                if ($rc.Wear -gt 0) {
                    $facts.Add("$($rc.Wear)% of rated life used")
                    if ($rc.Wear -ge 90) { $status = 'Problem'; $why += 'nearly worn out' } elseif ($rc.Wear -ge 70 -and $status -eq 'Good') { $status = 'Warning'; $why += 'heavily worn' }
                }
                if ($rc.PowerOnHours -gt 0) { $facts.Add(('{0:N0} hours powered on' -f $rc.PowerOnHours)) }
                if ($rc.ReadErrorsUncorrected -gt 0 -or $rc.WriteErrorsUncorrected -gt 0) { $status = 'Problem'; $why += 'uncorrected read/write errors' }
            }
            # NVMe drives: the drive's own SMART / health log (CrystalDiskInfo-level detail, no extra driver).
            if ("$($d.BusType)" -eq 'NVMe' -and ('ComputerDoctor.StorageHealth' -as [type])) {
                try {
                    $nv = [ComputerDoctor.StorageHealth]::ReadNvme([int]$d.DeviceId)
                    $facts.Clear()
                    $facts.Add("$($nv.PercentUsed)% of rated life used"); $facts.Add("$($nv.TemperatureC) C"); $facts.Add("$($nv.AvailableSpare)% spare")
                    $facts.Add(('{0:N1} TB written' -f $nv.WrittenTB)); $facts.Add(('{0:N0} power-on hours' -f $nv.PowerOnHours))
                    if ($nv.UnsafeShutdowns) { $facts.Add("$($nv.UnsafeShutdowns) unsafe shutdowns") }
                    if ($nv.CriticalWarning -ne 0) {
                        $bits = @(); $cw = $nv.CriticalWarning
                        if ($cw -band 1) { $bits += 'spare space is low' }; if ($cw -band 2) { $bits += 'temperature limit reached' }
                        if ($cw -band 4) { $bits += 'reliability is degraded' }; if ($cw -band 8) { $bits += 'the drive is now read-only' }
                        $status = 'Problem'; $why += "the drive reports a critical warning: $($bits -join ', ') - back up now"
                    }
                    if ($nv.PercentUsed -ge 90 -or ($nv.SpareThreshold -gt 0 -and $nv.AvailableSpare -le $nv.SpareThreshold)) { $status = 'Problem'; $why += 'nearly worn out - plan a replacement' }
                    elseif ($nv.PercentUsed -ge 70 -and $status -eq 'Good') { $status = 'Warning'; $why += 'heavily worn' }
                    if ($nv.MediaErrors -gt 0) { if ($status -eq 'Good') { $status = 'Warning' }; $why += "$($nv.MediaErrors) media error(s) recorded" }
                    if ($nv.CriticalTempMinutes -gt 0 -and $status -eq 'Good') { $status = 'Warning'; $why += "ran critically hot for $($nv.CriticalTempMinutes) min" }
                } catch { }
            }
            if ($status -eq 'Good' -and $facts.Count -eq 0 -and (-not $hs -or $hs -in 'Unknown', '5')) {
                $status = 'NA'; $why += $(if ("$($d.BusType)" -eq 'USB') { 'health data is not passed through this USB enclosure' } else { 'the drive does not report health data' })
            }
            $detail = (@($why) + @($facts)) -join ' - '
            if (-not $detail) { $detail = 'Windows reports the disk as healthy' + $(if (-not $rc -and -not $isAdmin) { ' (run as admin to also see wear and temperature)' } else { '' }) }
            & $add "Disk$($d.DeviceId)" "Disk: $($d.FriendlyName)" $status $detail 'Map'
        }
    } catch { & $add 'Disk' 'Disk health' 'NA' "Not available: $($_.Exception.Message)" '' }

    # SMART failure prediction (SATA drives; NVMe drives don't expose this class).
    try {
        $sm = @(Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction Stop)
        if ($sm.Count) {
            $bad = @($sm | Where-Object { $_.PredictFailure })
            if ($bad.Count) { & $add 'Smart' 'SMART failure prediction' 'Problem' "$($bad.Count) drive(s) predict a failure - back up now" 'Backup' }
            else { & $add 'Smart' 'SMART failure prediction' 'Good' "$($sm.Count) drive(s) report no predicted failure" '' }
        } else { & $add 'Smart' 'SMART failure prediction' 'NA' 'No SATA SMART data (normal for NVMe drives)' '' }
    } catch { & $add 'Smart' 'SMART failure prediction' 'NA' $(if ($isAdmin) { 'No SATA SMART data (normal for NVMe drives)' } else { 'Needs administrator rights' }) '' }

    # Free space on the system drive.
    try {
        $sd = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction Stop
        $pct = [Math]::Round($sd.FreeSpace * 100.0 / $sd.Size, 1)
        $st = if ($pct -lt 5) { 'Problem' } elseif ($pct -lt 10) { 'Warning' } else { 'Good' }
        & $add 'Space' "Free space on $($env:SystemDrive)" $st ('{0} free ({1}%)' -f (Format-WSize $sd.FreeSpace), $pct) 'Cleaner'
    } catch { & $add 'Space' 'Free space' 'NA' $_.Exception.Message '' }

    # Crashes and unexpected shutdowns in the last 30 days.
    try {
        $bsod = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'; Id = 1001; StartTime = $since } -ErrorAction SilentlyContinue)
        $kp   = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-Power'; Id = 41; StartTime = $since } -ErrorAction SilentlyContinue)
        $dirty = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'EventLog'; Id = 6008; StartTime = $since } -ErrorAction SilentlyContinue)
        if ($bsod.Count) { & $add 'Crash' 'Crashes (30 days)' 'Problem' ('{0} blue screen(s), last on {1:MMM d}. {2} unexpected shutdown(s).' -f $bsod.Count, $bsod[0].TimeCreated, $kp.Count) 'Reliability' }
        elseif ($kp.Count -or $dirty.Count) { & $add 'Crash' 'Crashes (30 days)' 'Warning' ('{0} unexpected shutdown(s) - power loss, a hard reset or a hang' -f [Math]::Max($kp.Count, $dirty.Count)) 'Reliability' }
        else { & $add 'Crash' 'Crashes (30 days)' 'Good' 'No blue screens or unexpected shutdowns' 'Reliability' }
    } catch { & $add 'Crash' 'Crashes (30 days)' 'NA' $_.Exception.Message '' }

    # Hardware errors reported by the CPU / chipset (WHEA).
    try {
        $wh = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WHEA-Logger'; StartTime = $since } -ErrorAction SilentlyContinue)
        $fatal = @($wh | Where-Object { $_.Level -le 2 })
        if ($fatal.Count) { & $add 'Whea' 'Hardware errors (30 days)' 'Problem' "$($fatal.Count) uncorrected hardware error(s) - check memory, CPU and overclocking" 'Memory' }
        elseif ($wh.Count) { & $add 'Whea' 'Hardware errors (30 days)' 'Warning' "$($wh.Count) corrected hardware error(s)" 'Memory' }
        else { & $add 'Whea' 'Hardware errors (30 days)' 'Good' 'None reported' '' }
    } catch { & $add 'Whea' 'Hardware errors (30 days)' 'NA' $_.Exception.Message '' }

    # Last Windows Memory Diagnostic result.
    try {
        $md = Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-MemoryDiagnostics-Results' } -MaxEvents 1 -ErrorAction SilentlyContinue
        if (-not $md) { & $add 'MemTest' 'Memory test' 'Info' 'Never run on this PC' 'Memory' }
        elseif ($md.Id -eq 1202) { & $add 'MemTest' 'Memory test' 'Problem' ('Found errors on {0:MMM d, yyyy} - a memory module is likely faulty' -f $md.TimeCreated) 'Memory' }
        else { & $add 'MemTest' 'Memory test' 'Good' ('Passed on {0:MMM d, yyyy}' -f $md.TimeCreated) 'Memory' }
    } catch { & $add 'MemTest' 'Memory test' 'NA' $_.Exception.Message '' }

    # Reliability Monitor's stability index (1-10).
    try {
        $si = Get-CimInstance Win32_ReliabilityStabilityMetrics -ErrorAction Stop | Sort-Object TimeGenerated -Descending | Select-Object -First 1
        if ($si) {
            $v = [Math]::Round([double]$si.SystemStabilityIndex, 1)
            $st = if ($v -ge 8) { 'Good' } elseif ($v -ge 5) { 'Warning' } else { 'Problem' }
            & $add 'Stability' 'Stability index' $st "$v out of 10 (Reliability Monitor)" 'Reliability'
        } else { & $add 'Stability' 'Stability index' 'NA' 'Reliability Monitor has no data yet' 'Reliability' }
    } catch { & $add 'Stability' 'Stability index' 'NA' 'Reliability Monitor data is not available' '' }

    # Devices with driver problems (disabled and disconnected devices are ignored).
    try {
        $pd = @(Get-CimInstance Win32_PnPEntity -Filter 'ConfigManagerErrorCode <> 0' -ErrorAction Stop | Where-Object { $_.ConfigManagerErrorCode -notin 22, 24, 45 })
        if ($pd.Count) { & $add 'Devices' 'Device problems' 'Warning' ("$($pd.Count): " + (($pd | Select-Object -First 3 | ForEach-Object { "$($_.Name) (code $($_.ConfigManagerErrorCode))" }) -join ', ')) 'Devices' }
        else { & $add 'Devices' 'Device problems' 'Good' 'All devices are working' 'Devices' }
    } catch { & $add 'Devices' 'Device problems' 'NA' $_.Exception.Message '' }

    # Battery wear (laptops only).
    try {
        if (@(Get-CimInstance Win32_Battery -ErrorAction Stop).Count) {
            $xmlPath = Join-Path ([IO.Path]::GetTempPath()) ('computerdoctor-battery-{0}.xml' -f [guid]::NewGuid().ToString('N'))
            & powercfg.exe /batteryreport /xml /output $xmlPath 2>&1 | Out-Null
            [xml]$x = Get-Content -LiteralPath $xmlPath -Raw
            Remove-Item -LiteralPath $xmlPath -Force -ErrorAction SilentlyContinue
            $b = @($x.BatteryReport.Batteries.Battery)[0]
            $design = [double]$b.DesignCapacity; $full = [double]$b.FullChargeCapacity
            if ($design -gt 0 -and $full -gt 0 -and $full -le $design * 1.1) {
                $wear = [Math]::Round((1 - $full / $design) * 100)
                if ($wear -lt 0) { $wear = 0 }
                $cyc = if ([int]$b.CycleCount -gt 0) { ", $($b.CycleCount) charge cycles" } else { '' }
                $st = if ($wear -ge 40) { 'Problem' } elseif ($wear -ge 20) { 'Warning' } else { 'Good' }
                & $add 'Battery' 'Battery' $st "$wear% worn (holds $([int]$full) of $([int]$design) mWh)$cyc" ''
            } else { & $add 'Battery' 'Battery' 'NA' 'The battery does not report its capacity' '' }
        }
    } catch { & $add 'Battery' 'Battery' 'NA' $_.Exception.Message '' }

    # Antivirus: Microsoft Defender, or a third-party product registered with Security Center.
    try {
        $av3 = @()
        try { $av3 = @(Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction Stop | Where-Object { $_.displayName -notmatch 'Windows Defender|Microsoft Defender' }) } catch { }
        $mp = $null
        try { $mp = Get-MpComputerStatus -ErrorAction Stop } catch { }
        if ($mp -and $mp.AMServiceEnabled -and $mp.RealTimeProtectionEnabled) {
            $age = [int]$mp.AntivirusSignatureAge
            $st = if ($age -gt 14) { 'Problem' } elseif ($age -gt 3) { 'Warning' } else { 'Good' }
            & $add 'Defender' 'Antivirus' $st ("Microsoft Defender is on. Definitions are $age day(s) old" + $(if ($age -gt 3) { ' - update them, or import an offline update from Resources\defs' } else { '' })) 'Defender'
        } elseif ($av3.Count) {
            & $add 'Defender' 'Antivirus' 'Info' "Protected by $(($av3 | ForEach-Object displayName) -join ', ')" ''
        } elseif ($mp) {
            & $add 'Defender' 'Antivirus' 'Problem' 'Microsoft Defender real-time protection is off and no other antivirus is registered' 'Defender'
        } else { & $add 'Defender' 'Antivirus' 'NA' 'Antivirus status is not available' '' }
    } catch { & $add 'Defender' 'Antivirus' 'NA' $_.Exception.Message '' }

    # Pending restart and uptime.
    try {
        $cbs = Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
        $wu  = Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $days = [int]((Get-Date) - $os.LastBootUpTime).TotalDays
        if ($cbs -or $wu) { & $add 'Reboot' 'Restart' 'Warning' "A restart is needed to finish installing updates (up $days day(s))" '' }
        elseif ($days -ge 14) { & $add 'Reboot' 'Restart' 'Warning' "Not restarted in $days days - a restart often clears slowdowns" '' }
        else { & $add 'Reboot' 'Restart' 'Good' "No restart pending (up $days day(s))" '' }
    } catch { & $add 'Reboot' 'Restart' 'NA' $_.Exception.Message '' }

    # Local network: is the default gateway answering? (No internet needed.)
    try {
        $gw = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop | Sort-Object RouteMetric | Select-Object -First 1
        if (-not $gw) { & $add 'Network' 'Local network' 'Info' 'No default gateway - this PC is not on a routed network' '' }
        elseif (Test-Connection -ComputerName $gw.NextHop -Count 1 -Quiet -ErrorAction SilentlyContinue) { & $add 'Network' 'Local network' 'Good' "Gateway $($gw.NextHop) is reachable" '' }
        else { & $add 'Network' 'Local network' 'Warning' "Gateway $($gw.NextHop) did not answer a ping (it may block ping)" '' }
    } catch { & $add 'Network' 'Local network' 'Info' 'No default gateway - this PC is not on a routed network' '' }

    # Windows 10 PCs: can they move to Windows 11, and are they covered by Extended Security Updates?
    try {
        $build = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop).CurrentBuild
        if ($build -lt 22000) {
            $w = Get-WWin11Readiness $true
            $e = Get-WEsuEligibility
            $st = if ($e.Enrolled) { 'Info' } elseif ($w.Ready -or $e.Ready) { 'Warning' } else { 'Problem' }
            & $add 'Win11' 'Windows 11 readiness' $(if ($w.Ready) { 'Info' } else { 'Warning' }) ($w.Summary + '.') ''
            & $add 'Esu' 'Windows 10 security updates' $st ("Windows 10 support ended Oct 14, 2025. " + $e.Summary + '.') ''
        }
    } catch { & $add 'Win11' 'Windows 11 readiness' 'NA' $_.Exception.Message '' }

    # Can this PC be recovered if it won't start? Secure Boot certificates, BitLocker recovery key, Windows RE.
    try {
        $sb = Get-WSecureBootCerts
        if ($sb.Applies) { & $add 'SecureBootCA' 'Secure Boot certificates' $sb.Health ($sb.Summary + $(if ($sb.Advice) { ". $($sb.Advice)" } else { '' })) 'Readiness' }
    } catch { & $add 'SecureBootCA' 'Secure Boot certificates' 'NA' $_.Exception.Message '' }
    try {
        $bl = Get-WBitLockerSummary (Get-WBitLockerInfo)
        & $add 'BitLockerKey' 'BitLocker recovery key' $bl.Health $bl.Text 'Readiness'
    } catch { & $add 'BitLockerKey' 'BitLocker recovery key' 'NA' $_.Exception.Message '' }
    if ($isAdmin) {
        try {
            $re = Get-WRecoveryEnv
            if ($re.WinRE -eq 'Enabled') { & $add 'WinRE' 'Recovery environment' 'Good' ('Windows RE is enabled' + $(if ($re.Qmr -eq 'On') { ', and Quick Machine Recovery can fetch fixes if Windows stops starting' } else { '' })) 'Readiness' }
            elseif ($re.WinRE -eq 'Disabled') { & $add 'WinRE' 'Recovery environment' 'Problem' 'Windows RE is disabled - Startup Repair, Reset this PC and Quick Machine Recovery won''t work if Windows stops starting' 'Readiness' }
            else { & $add 'WinRE' 'Recovery environment' 'NA' 'Could not read the Windows RE status' '' }
        } catch { & $add 'WinRE' 'Recovery environment' 'NA' $_.Exception.Message '' }
    } else { & $add 'WinRE' 'Recovery environment' 'NA' 'Needs administrator rights to check' '' }

    $rows
}

function Resolve-WTarget([string]$Path) {
    $p = [Environment]::ExpandEnvironmentVariables($Path)
    if ($p -match '[\*\?]') {
        @(Get-Item -Path $p -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | ForEach-Object { $_.FullName })
    }
    elseif (Test-Path -LiteralPath $p -PathType Container) { @($p) }
    else { @() }
}

function Get-WTargetFiles($Target) {
    $filter  = if ($Target.Filter) { $Target.Filter } else { '*' }
    $recurse = $Target.Recurse -ne $false
    $cutoff  = if ($Target.MinAgeHours) { (Get-Date).AddHours(-[double]$Target.MinAgeHours) } else { $null }
    foreach ($root in (Resolve-WTarget $Target.Path)) {
        $files = Get-ChildItem -LiteralPath $root -Filter $filter -File -Force -Recurse:$recurse -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            if ($cutoff -and $f.LastWriteTime -gt $cutoff) { continue }
            $f
        }
    }
}

function Remove-WEmptyDirs([string]$Root) {
    $dirs = Get-ChildItem -LiteralPath $Root -Directory -Recurse -Force -ErrorAction SilentlyContinue |
        Sort-Object { $_.FullName.Length } -Descending
    foreach ($d in $dirs) {
        try {
            if (-not [System.IO.Directory]::EnumerateFileSystemEntries($d.FullName).GetEnumerator().MoveNext()) {
                [System.IO.Directory]::Delete($d.FullName)
            }
        } catch { }
    }
}

function Get-WRecycleFolders {
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
        if ($d.DriveType -eq 'Fixed' -and $d.IsReady) {
            $rb = Join-Path $d.RootDirectory.FullName ('$Recycle.Bin\' + $sid)
            if (Test-Path -LiteralPath $rb) { $rb }
        }
    }
}

function Get-WSubDirs([string]$Path) {
    try {
        foreach ($d in ([IO.DirectoryInfo]$Path).EnumerateDirectories()) {
            if (-not ($d.Attributes -band [IO.FileAttributes]::ReparsePoint)) { $d }     # never follow junctions / links
        }
    } catch { }
}

# Programs' own log / temp / crash-report folders (Take = 'Log') or cache folders (Take = 'Cache'), found by
# looking under $Item.Discover.Bases up to MaxDepth folder levels. Returns one entry per program (its top folder
# name): @{ App; Tops = top folders; Targets = @{ Path; Recurse; Names; MinAgeHours } }. Folders that other rules
# cover ($Item.Covered), NeverInside folders, junctions and data folders (IndexedDB, Local Storage, ...) are skipped.
function Find-WAppFolders($Item) {
    $cfg = $Item.Discover
    $ci = [StringComparer]::OrdinalIgnoreCase
    $exp = { param($p) [Environment]::ExpandEnvironmentVariables([string]$p).TrimEnd('\') }
    $long = { param($p) if ($p -and $p.Contains('~') -and ('ComputerDoctor.Native' -as [type])) { [ComputerDoctor.Native]::LongPath($p) } else { $p } }
    $stop = New-Object 'System.Collections.Generic.HashSet[string]' $ci       # never enter or take
    $hold = New-Object 'System.Collections.Generic.HashSet[string]' $ci       # holds a stop folder: walk in, never take whole
    $add = {
        param($p)
        if (-not $p) { return }
        $p = & $long $p
        [void]$stop.Add($p)
        $i = $p.LastIndexOf('\')
        while ($i -gt 2) { $p = $p.Substring(0, $i); [void]$hold.Add($p); $i = $p.LastIndexOf('\') }
    }
    foreach ($n in @($cfg.NeverInside)) { & $add (& $exp $n) }
    foreach ($x in @($cfg.Extra)) { if ($x) { & $add (& $exp $x.Path) } }
    foreach ($c in @($Item.Covered)) { foreach ($root in (Resolve-WTarget $c)) { & $add $root.TrimEnd('\') } }

    $cacheNames = New-Object 'System.Collections.Generic.HashSet[string]' $ci
    foreach ($n in 'Cache', 'Caches', 'cache2', 'Code Cache', 'GPUCache', 'DawnCache', 'DawnGraphiteCache', 'DawnWebGPUCache', 'GrShaderCache', 'ShaderCache', 'CachedData') { [void]$cacheNames.Add($n) }
    $cachePairs = New-Object 'System.Collections.Generic.HashSet[string]' $ci
    foreach ($n in 'Service Worker\CacheStorage', 'Service Worker\ScriptCache') { [void]$cachePairs.Add($n) }
    $logNames = New-Object 'System.Collections.Generic.HashSet[string]' $ci
    $ln = if ($cfg.LogNames) { $cfg.LogNames } else { @('Logs', 'Log', 'Temp', 'tmp', 'Crash Reports', 'CrashDumps', 'CrashReports') }
    foreach ($n in $ln) { [void]$logNames.Add($n) }
    $logPairs = New-Object 'System.Collections.Generic.HashSet[string]' $ci
    if (-not $cfg.LogNames) { [void]$logPairs.Add('Crashpad\reports') }
    $skip = New-Object 'System.Collections.Generic.HashSet[string]' $ci
    foreach ($n in 'IndexedDB', 'Local Storage', 'Session Storage', 'databases', 'blob_storage', 'File System', 'Extensions', 'Backups', 'Saves', 'Saved Games',
                   'OneDrive', 'Dropbox', 'DriveFS', 'Google Drive', 'Box', 'Box Sync', 'iCloud', 'iCloudDrive', 'MEGAsync', 'Nextcloud', 'ownCloud', 'pCloud') { [void]$skip.Add($n) }

    $apps = [ordered]@{}
    $getSet = {
        param($name, $top)
        $k = $name.ToLowerInvariant()
        if (-not $apps.Contains($k)) { $apps[$k] = @{ App = $name; Tops = New-Object System.Collections.Generic.List[string]; Targets = New-Object System.Collections.Generic.List[object] } }
        $apps[$k].Tops.Add($top)
        $apps[$k]
    }
    foreach ($b in @($cfg.Bases)) {
        $bp = & $long (& $exp $b)
        if (-not $bp -or -not [IO.Directory]::Exists($bp)) { continue }
        foreach ($top in @(Get-WSubDirs $bp)) {
            if ($stop.Contains($top.FullName) -or $skip.Contains($top.Name)) { continue }
            $set = & $getSet $top.Name $top.FullName
            if (@($cfg.TopFiles).Count) { $set.Targets.Add(@{ Path = $top.FullName; Recurse = $false; Names = @($cfg.TopFiles); MinAgeHours = $cfg.MinAgeHours }) }
            $stack = New-Object System.Collections.Generic.Stack[object]
            $stack.Push(@($top, 1, ''))
            while ($stack.Count) {
                $e = $stack.Pop(); $dir = $e[0]; $lvl = $e[1]; $mode = $e[2]
                foreach ($d in @(Get-WSubDirs $dir.FullName)) {
                    $n = $d.Name
                    if ($skip.Contains($n) -or $stop.Contains($d.FullName)) { continue }
                    $pair = $dir.Name + '\' + $n
                    $kind = ''
                    if ($mode -eq 'Profiles') { if ($n -eq 'cache2') { $kind = 'Cache' } }
                    elseif ($cacheNames.Contains($n) -or $cachePairs.Contains($pair)) { $kind = 'Cache' }
                    elseif ($mode -ne 'UserData' -and ($logNames.Contains($n) -or $logPairs.Contains($pair))) { $kind = 'Log' }
                    if ($kind) {
                        if ($kind -eq $cfg.Take -and -not $hold.Contains($d.FullName)) { $set.Targets.Add(@{ Path = $d.FullName; Recurse = $true; Names = $null; MinAgeHours = $cfg.MinAgeHours }) }
                        continue                                            # a matched folder is taken whole, never split
                    }
                    if ($lvl + 1 -lt $cfg.MaxDepth) {
                        $m = if ($n -eq 'Profiles') { 'Profiles' } elseif ($n -eq 'User Data') { 'UserData' } else { $mode }
                        $stack.Push(@($d, ($lvl + 1), $m))
                    }
                }
            }
        }
    }
    if ($cfg.Take -eq 'Log') {
        foreach ($x in @($cfg.Extra)) {
            if (-not $x) { continue }
            $p = & $long (& $exp $x.Path)
            if ([IO.Directory]::Exists($p)) { $set = & $getSet $x.App $p; $set.Targets.Add(@{ Path = $p; Recurse = $true; Names = $null; MinAgeHours = $x.MinAgeHours }) }
        }
    }
    foreach ($s in $apps.Values) { if ($s.Targets.Count) { $s } }
}

# Files of one found target: no junctions, only names matching Names (when set), older than MinAgeHours.
function Get-WFoundFiles($T) {
    $cutoff = if ($T.MinAgeHours -gt 0) { (Get-Date).AddHours(-[double]$T.MinAgeHours) } else { $null }
    $stack = New-Object System.Collections.Generic.Stack[string]
    $stack.Push($T.Path)
    while ($stack.Count) {
        $entries = try { @(([IO.DirectoryInfo]$stack.Pop()).GetFileSystemInfos()) } catch { @() }
        foreach ($e in $entries) {
            if ($e -is [IO.DirectoryInfo]) {
                if ($T.Recurse -and -not ($e.Attributes -band [IO.FileAttributes]::ReparsePoint)) { $stack.Push($e.FullName) }
                continue
            }
            if ($T.Names) { $ok = $false; foreach ($n in $T.Names) { if ($e.Name -like $n) { $ok = $true; break } }; if (-not $ok) { continue } }
            if ($cutoff -and $e.LastWriteTime -gt $cutoff) { continue }
            $e
        }
    }
}

function Get-WProcPaths {
    @(Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $p = $null; try { $p = $_.Path } catch { }; @{ Name = $_.ProcessName; Path = [string]$p } })
}
# Best effort: a process named like the program's top folder, or running from inside it.
function Test-WAppRunning($Set, $Procs) {
    foreach ($pr in $Procs) {
        if ($pr.Name -ieq $Set.App) { return $true }
        if ($pr.Path) { foreach ($t in $Set.Tops) { if ($pr.Path.StartsWith($t + '\', [StringComparison]::OrdinalIgnoreCase)) { return $true } } }
    }
    $false
}

function Format-WAppCount([int]$N) { if ($N -eq 1) { '1 app' } else { "$N apps" } }

# What the Space Map shows as cleanable: every target of the rules that don't need admin, expanded on this PC.
function Get-WCleanMapEntries($Rules) {
    foreach ($rule in @($Rules)) {
        if ($rule.Admin) { continue }
        switch ($rule.Kind) {
            'Files' {
                foreach ($t in $rule.Targets) {
                    foreach ($root in (Resolve-WTarget $t.Path)) { @{ Path = $(if ($root.Contains('~')) { [ComputerDoctor.Native]::LongPath($root) } else { $root }); Filter = $(if ($t.Filter) { $t.Filter } else { '*' }); Recurse = ($t.Recurse -ne $false); Reason = $rule.Name } }
                }
            }
            'RecycleBin' { foreach ($rb in (Get-WRecycleFolders)) { @{ Path = $rb; Filter = '*'; Recurse = $true; Reason = $rule.Name } } }
            'Found' {
                foreach ($set in (Find-WAppFolders $rule)) {
                    foreach ($t in $set.Targets) {
                        if ($t.Names) { foreach ($n in $t.Names) { @{ Path = $t.Path; Filter = $n; Recurse = $false; Reason = $rule.Name } } }
                        else { @{ Path = $t.Path; Filter = '*'; Recurse = $true; Reason = $rule.Name } }
                    }
                }
            }
        }
    }
}

# ---- Apps that must be closed before cleaning. A blocker is @{ Label; Names (process names); Tops (folders) }.
function Get-WAppLabel([string]$Name, [string]$Fallback) {
    $l = @{ msedge = 'Edge'; chrome = 'Chrome'; brave = 'Brave'; firefox = 'Firefox'; teams = 'Teams'; 'ms-teams' = 'Teams' }[$Name.ToLowerInvariant()]
    if ($l) { $l } elseif ($Fallback) { $Fallback } else { $Name }
}
function Get-WBlockerProcs($Blocker) {
    @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $pr = $_
        if (@($Blocker.Names | Where-Object { $_ -and $pr.ProcessName -ieq $_ }).Count) { return $true }
        $path = $null; try { $path = $pr.Path } catch { }
        $path -and @($Blocker.Tops | Where-Object { $_ -and $path.StartsWith($_ + '\', [StringComparison]::OrdinalIgnoreCase) }).Count
    })
}
# The open apps that hold back a rule: one blocker per running app (a browser rule can name several).
function Get-WRuleBlockers($Item) {
    if ($Item.Kind -eq 'Found') {
        $procs = Get-WProcPaths
        foreach ($set in (Find-WAppFolders $Item)) {
            if (Test-WAppRunning $set $procs) { @{ Label = $set.App; Names = @($set.App); Tops = @($set.Tops); RuleId = $Item.Id; RuleName = $Item.Name; Set = $set } }
        }
        return
    }
    foreach ($n in @($Item.Process)) {
        if ($n -and (Get-Process -Name $n -ErrorAction SilentlyContinue)) {
            @{ Label = (Get-WAppLabel $n $Item.ProcessLabel); Names = @($n); Tops = @(); RuleId = $Item.Id; RuleName = $Item.Name }
        }
    }
}
# Asks the apps to close the way clicking X does (WM_CLOSE to each of their windows). Never force-kills.
function Close-WBlockers($Blockers) {
    $ids = @(foreach ($b in @($Blockers)) { Get-WBlockerProcs $b | ForEach-Object { $_.Id } })
    if ($ids.Count) { [void][ComputerDoctor.Native]::CloseWindows([int[]]$ids) }
    $ids.Count
}
# Labels of the blockers that still have a process running.
function Get-WOpenBlockers($Blockers) {
    @(foreach ($b in @($Blockers)) { if (@(Get-WBlockerProcs $b).Count) { $b.Label } }) | Select-Object -Unique
}
function Wait-WBlockersClosed($Blockers, [int]$Seconds = 15) {
    $until = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $until -and @(Get-WOpenBlockers $Blockers).Count) { Start-Sleep -Milliseconds 500 }
    @(Get-WOpenBlockers $Blockers)
}

# Report of the cleanups that need administrator rights, to hand to someone who has them. $Info: Computer, Windows,
# User, Drive, Date. $Items: Id, Name, Desc, Bytes (-1 = can't be measured without admin). Returns @{ Text; Html }.
function New-WAdminReport($Info, $Items, [string]$ScriptPath) {
    $Items = @($Items)
    $ids = (@($Items | ForEach-Object { $_.Id })) -join ','
    $names = (@($Items | ForEach-Object { $_.Name })) -join ', '
    [long]$known = 0; $unknown = 0
    foreach ($i in $Items) { if ([long]$i.Bytes -ge 0) { $known += [long]$i.Bytes } else { $unknown++ } }
    $size = { param($i) if ([long]$i.Bytes -lt 0) { 'size unknown - needs admin to measure' } else { Format-WSize ([long]$i.Bytes) } }
    $title = 'Computer Doctor - cleanups that need administrator rights'
    $facts = @(
        @('PC', $Info.Computer), @('Windows', $Info.Windows), @('User', $Info.User), @('System drive', $Info.Drive), @('Date', $Info.Date)
    )
    $total = 'About {0}{1}' -f (Format-WSize $known), $(if ($unknown) { " plus $unknown item(s) that need admin to measure" } else { '' })
    $steps = @(
        '1. Sign in to this PC as an administrator, or start ComputerDoctor.ps1 and enter an administrator''s password when Windows asks for administrator rights.',
        '2. Open Cleaner.',
        "3. Leave these ticked: $names.",
        '4. Click Analyze, then Run Cleaner.'
    )
    $cmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -Clean {1} -Yes' -f $ScriptPath, $ids
    $alt = 'Without Computer Doctor: Settings > System > Storage > Temporary files (as an administrator).'

    $t = New-Object System.Text.StringBuilder
    [void]$t.AppendLine($title).AppendLine()
    foreach ($f in $facts) { [void]$t.AppendLine(('{0}: {1}' -f $f[0], $f[1])) }
    [void]$t.AppendLine().AppendLine("What can be cleaned ($total):")
    foreach ($i in $Items) { [void]$t.AppendLine(('- {0} ({1}): {2}' -f $i.Name, (& $size $i), $i.Desc)) }
    [void]$t.AppendLine().AppendLine('Steps for the administrator:')
    foreach ($s in $steps) { [void]$t.AppendLine($s) }
    [void]$t.AppendLine().AppendLine('Or run this in an administrator terminal:').AppendLine('  ' + $cmd).AppendLine().AppendLine($alt)

    $e = { param($x) [System.Net.WebUtility]::HtmlEncode([string]$x) }
    $h = New-Object System.Text.StringBuilder
    [void]$h.Append('<!DOCTYPE html><html><head><meta charset="utf-8"><title>').Append((& $e $title)).Append('</title>')
    [void]$h.Append('<style>body{font-family:Segoe UI,Arial,sans-serif;max-width:760px;margin:32px auto;padding:0 16px;color:#111;line-height:1.45}')
    [void]$h.Append('h1{font-size:22px}h2{font-size:16px;margin-top:24px}table{border-collapse:collapse;width:100%}td,th{border:1px solid #ccc;padding:6px 8px;text-align:left;vertical-align:top}')
    [void]$h.Append('th{background:#f2f2f2}code{display:block;background:#f4f4f4;border:1px solid #ddd;padding:8px;white-space:pre-wrap;word-break:break-all}.muted{color:#555}</style></head><body>')
    [void]$h.Append('<h1>').Append((& $e $title)).Append('</h1><p class="muted">')
    [void]$h.Append((($facts | ForEach-Object { '<b>' + (& $e $_[0]) + ':</b> ' + (& $e $_[1]) }) -join '<br>')).Append('</p>')
    [void]$h.Append('<h2>What can be cleaned (').Append((& $e $total)).Append(')</h2><table><tr><th>Cleanup</th><th>Size</th><th>What it is</th></tr>')
    foreach ($i in $Items) { [void]$h.Append('<tr><td>').Append((& $e $i.Name)).Append('</td><td>').Append((& $e (& $size $i))).Append('</td><td>').Append((& $e $i.Desc)).Append('</td></tr>') }
    [void]$h.Append('</table><h2>Steps for the administrator</h2><ol>')
    foreach ($s in $steps) { [void]$h.Append('<li>').Append((& $e ($s -replace '^\d+\.\s*', ''))).Append('</li>') }
    [void]$h.Append('</ol><p>Or run this in an administrator terminal:</p><code>').Append((& $e $cmd)).Append('</code>')
    [void]$h.Append('<p>').Append((& $e $alt)).Append('</p></body></html>')
    @{ Text = $t.ToString(); Html = $h.ToString() }
}

function Test-WProcess($Item) {
    if (-not $Item.Process) { return $false }
    [bool](Get-Process -Name $Item.Process -ErrorAction SilentlyContinue)
}

function Measure-WItem($Item) {
    $res = @{ Id = $Item.Id; Name = $Item.Name; Group = $Item.Group; Files = 0; Bytes = [long]0; Note = '' }
    $subs = New-Object System.Collections.Generic.List[object]
    if (Test-WProcess $Item) { $res.Note = "$($Item.ProcessLabel) is running - close it before cleaning" }
    switch ($Item.Kind) {
        'Found' {
            # One line per program, under the rule's own line ("Zoom: 340 MB").
            $procs = Get-WProcPaths
            foreach ($set in (Find-WAppFolders $Item)) {
                $n = 0; [long]$b = 0
                foreach ($t in $set.Targets) { foreach ($f in (Get-WFoundFiles $t)) { $n++; $b += $f.Length } }
                if (-not $n) { continue }
                $res.Files += $n; $res.Bytes += $b
                $subs.Add(@{ Id = $Item.Id; Name = $set.App; Group = $Item.Group; Files = $n; Bytes = $b; Sub = $true
                             Note = $(if (Test-WAppRunning $set $procs) { "$($set.App) is running - close it before cleaning" } else { '' }) })
            }
            $res.Note = '{0} in {1}' -f (Format-WSize $res.Bytes), (Format-WAppCount $subs.Count)
        }
        'Files' {
            foreach ($t in $Item.Targets) {
                foreach ($f in (Get-WTargetFiles $t)) { $res.Files++; $res.Bytes += $f.Length }
            }
        }
        'RecycleBin' {
            foreach ($rb in (Get-WRecycleFolders)) {
                foreach ($f in (Get-ChildItem -LiteralPath $rb -Force -Recurse -File -ErrorAction SilentlyContinue)) {
                    if ($f.Name -eq 'desktop.ini') { continue }
                    if ($f.Name -like '$R*' -or $f.DirectoryName -ne $rb) { $res.Files++ }
                    $res.Bytes += $f.Length
                }
            }
        }
        'Action' { if (-not $res.Note) { $res.Note = 'Action - runs during clean' } }
    }
    $res
    foreach ($x in @($subs | Sort-Object { [long]$_.Bytes } -Descending)) { $x }
}

function Invoke-WClean($Item) {
    $res = @{ Id = $Item.Id; Name = $Item.Name; Group = $Item.Group; Files = 0; Bytes = [long]0; Failed = 0; Note = '' }
    $subs = New-Object System.Collections.Generic.List[object]
    if (Test-WProcess $Item) {
        # Skipped, with what it holds back and which apps are open (the Cleaner and automatic cleanup offer to close them).
        $res.Note = "Skipped - $($Item.ProcessLabel) is running"
        $res.Skipped = $true
        $res.Blockers = @(Get-WRuleBlockers $Item)
        try { $res.Held = [long](@(Measure-WItem $Item) | Select-Object -First 1).Bytes } catch { $res.Held = [long]0 }
        Write-WLog "$($Item.Name): skipped, $($Item.ProcessLabel) is running" 'WARN'
        return $res
    }

    $svcStopped = $false
    if ($Item.Service) {
        $svc = Get-Service -Name $Item.Service -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq 'Running') {
            try { Stop-Service -Name $Item.Service -Force -ErrorAction Stop; $svcStopped = $true; Write-WLog "Stopped service $($Item.Service)" }
            catch { Write-WLog "Could not stop $($Item.Service): $($_.Exception.Message)" 'WARN' }
        }
    }

    try {
        switch ($Item.Kind) {
            'Files' {
                foreach ($t in $Item.Targets) {
                    foreach ($f in (Get-WTargetFiles $t)) {
                        $len = $f.Length
                        try {
                            if ($f.IsReadOnly) { $f.IsReadOnly = $false }
                            $f.Delete()
                            $res.Files++; $res.Bytes += $len
                        } catch { $res.Failed++ }
                    }
                    if ($t.Recurse -ne $false -and -not $t.KeepDirs) {
                        foreach ($root in (Resolve-WTarget $t.Path)) { Remove-WEmptyDirs $root }
                    }
                }
            }
            'Found' {
                # Folders are left in place (only old files go); a program that is open is skipped.
                $procs = Get-WProcPaths
                $held = New-Object System.Collections.Generic.List[object]
                foreach ($set in (Find-WAppFolders $Item)) {
                    $files = @(foreach ($t in $set.Targets) { Get-WFoundFiles $t })
                    if (-not $files.Count) { continue }
                    if (Test-WAppRunning $set $procs) {
                        [long]$hb = 0; foreach ($f in $files) { $hb += $f.Length }
                        $res.Held = [long]$res.Held + $hb
                        $held.Add(@{ Label = $set.App; Names = @($set.App); Tops = @($set.Tops); RuleId = $Item.Id; RuleName = $Item.Name })
                        $subs.Add(@{ Id = $Item.Id; Name = $set.App; Group = $Item.Group; Files = 0; Bytes = [long]0; Sub = $true; Skipped = $true; Held = $hb; Note = "Skipped - $($set.App) is running" })
                        Write-WLog "$($Item.Name): skipped $($set.App), it is running" 'WARN'
                        continue
                    }
                    $n = 0; [long]$b = 0; $bad = 0
                    foreach ($f in $files) {
                        $len = $f.Length
                        try { if ($f.IsReadOnly) { $f.IsReadOnly = $false }; $f.Delete(); $n++; $b += $len } catch { $bad++ }
                    }
                    $res.Files += $n; $res.Bytes += $b; $res.Failed += $bad
                    $subs.Add(@{ Id = $Item.Id; Name = $set.App; Group = $Item.Group; Files = $n; Bytes = $b; Sub = $true
                                 Note = $(if ($bad) { "$bad file(s) in use or locked - skipped" } else { '' }) })
                }
                if ($held.Count) { $res.Skipped = $true; $res.Blockers = @($held) }
                $res.Note = '{0} in {1}' -f (Format-WSize $res.Bytes), (Format-WAppCount @($subs | Where-Object { -not $_.Skipped }).Count)
                if ($held.Count) { $res.Note += "; skipped $(Format-WAppCount $held.Count) that are running" }
            }
            'RecycleBin' {
                $m = Measure-WItem $Item
                [void][ComputerDoctor.Native]::SHEmptyRecycleBin([IntPtr]::Zero, $null, 7)
                $res.Files = $m.Files; $res.Bytes = $m.Bytes
            }
            'Action' {
                switch ($Item.Action) {
                    'FlushDns'  { & ipconfig.exe /flushdns | Out-Null; $res.Note = 'DNS resolver cache flushed' }
                    'Clipboard' { [System.Windows.Forms.Clipboard]::Clear(); $res.Note = 'Clipboard cleared' }
                }
            }
        }
    }
    finally {
        if ($svcStopped) {
            try { Start-Service -Name $Item.Service -ErrorAction Stop; Write-WLog "Restarted service $($Item.Service)" }
            catch { Write-WLog "Could not restart $($Item.Service): $($_.Exception.Message)" 'WARN' }
        }
    }

    if ($res.Failed -gt 0 -and -not $res.Note) { $res.Note = "$($res.Failed) file(s) in use or locked - skipped" }
    Write-WLog ("{0}: removed {1} file(s), {2}" -f $Item.Name, $res.Files, (Format-WSize $res.Bytes))
    $res
    foreach ($x in @($subs | Sort-Object { [long]$_.Bytes } -Descending)) { $x }
}
'@
#endregion

#region ---------------------------------------------------------------- Cleaner rules
function New-AWRule {
    param($Id, $Group, $Name, $Desc, [string]$Kind = 'Files', $Targets = @(), [bool]$Admin = $false, [bool]$Default = $true,
          $Service, $Process, $ProcessLabel, $Action)
    @{ Id = $Id; Group = $Group; Name = $Name; Desc = $Desc; Kind = $Kind; Targets = @($Targets); Admin = $Admin; Default = $Default
       Service = $Service; Process = $Process; ProcessLabel = $ProcessLabel; Action = $Action }
}
function T([string]$Path, [string]$Filter = '*', [bool]$Recurse = $true, [int]$MinAgeHours = 0, [bool]$KeepDirs = $false) {
    @{ Path = $Path; Filter = $Filter; Recurse = $Recurse; MinAgeHours = $MinAgeHours; KeepDirs = $KeepDirs }
}

$chromium = { param($base) @( (T "$base\User Data\*\Cache\Cache_Data"), (T "$base\User Data\*\Code Cache"), (T "$base\User Data\*\GPUCache"), (T "$base\User Data\ShaderCache") ) }
$swCache  = { param($base) @( (T "$base\User Data\*\Service Worker\CacheStorage"), (T "$base\User Data\*\Service Worker\ScriptCache") ) }

# Rules found by looking (Kind 'Found'): programs' own log, temp and cache folders. Discover says where to look;
# see Find-WAppFolders. Folders other rules cover are added as Covered below, so no file is counted twice.
$userNever = @('%LOCALAPPDATA%\Temp', '%LOCALAPPDATA%\Packages', '%LOCALAPPDATA%\Microsoft\Windows', '%LOCALAPPDATA%\ComputerDoctor', '%LOCALAPPDATA%\AWiper', '%OneDrive%', '%OneDriveConsumer%', '%OneDriveCommercial%')
$userBases = @('%LOCALAPPDATA%', '%APPDATA%', '%USERPROFILE%\AppData\LocalLow')

$script:CleanerRules = @(
    New-AWRule 'UserTemp'   'Windows' 'User temp files'         'Files in your %TEMP% folder older than 24 hours.' -Targets (T '%TEMP%' -MinAgeHours 24)
    New-AWRule 'WinTemp'    'Windows' 'Windows temp files'      'Files in C:\Windows\Temp older than 24 hours.' -Targets (T '%SystemRoot%\Temp' -MinAgeHours 24) -Admin $true
    New-AWRule 'Recycle'    'Windows' 'Recycle Bin (empty permanently)' 'PERMANENTLY empties the Recycle Bin on all fixed drives. Emptied items can no longer be restored from Recovery > Recycle Bin. Off by default.' -Kind 'RecycleBin' -Default $false
    New-AWRule 'Thumbs'     'Windows' 'Thumbnail cache'         'Explorer thumbnail databases (rebuilt automatically; files in use are skipped).' -Targets (T '%LOCALAPPDATA%\Microsoft\Windows\Explorer' 'thumbcache_*.db' $false)
    New-AWRule 'WerUser'    'Windows' 'Error reports (user)'    'Windows Error Reporting archives for your account.' -Targets (T '%LOCALAPPDATA%\Microsoft\Windows\WER')
    New-AWRule 'WerSys'     'Windows' 'Error reports (system)'  'System-wide Windows Error Reporting queue and archives.' -Targets (T '%ProgramData%\Microsoft\Windows\WER') -Admin $true
    New-AWRule 'CrashDumps' 'Windows' 'App crash dumps'         'Application crash dumps in %LOCALAPPDATA%\CrashDumps.' -Targets (T '%LOCALAPPDATA%\CrashDumps')
    New-AWRule 'MemDumps'   'Windows' 'System memory dumps'     'Minidumps and MEMORY.DMP from blue screens. The Crashes tab needs these to explain past crashes - off by default, clean only once you no longer need them.' -Targets @((T '%SystemRoot%\Minidump'), (T '%SystemRoot%' 'MEMORY.DMP' $false)) -Admin $true -Default $false
    New-AWRule 'WinUpdate'  'Windows' 'Windows Update cache'    'Downloaded update packages already installed. Briefly stops the Windows Update service.' -Targets (T '%SystemRoot%\SoftwareDistribution\Download') -Admin $true -Service 'wuauserv'
    New-AWRule 'DeliveryOp' 'Windows' 'Delivery Optimization'   'Peer-to-peer update cache. Briefly stops the Delivery Optimization service.' -Targets (T '%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache') -Admin $true -Default $false -Service 'DoSvc'
    New-AWRule 'Prefetch'   'Windows' 'Prefetch data'           'Launch-optimization data. The next few app launches may be slightly slower.' -Targets (T '%SystemRoot%\Prefetch' '*.pf' $false) -Admin $true -Default $false
    New-AWRule 'WinLogs'    'Windows' 'Windows logs'            'Old Windows log files (servicing, setup, updates, Delivery Optimization). Only files older than 30 days; Windows starts new ones as needed.' -Targets @((T '%SystemRoot%\Logs' '*.log' $true 720 $true), (T '%SystemRoot%\Logs' '*.etl' $true 720 $true), (T '%SystemRoot%\Logs' '*.cab' $true 720 $true), (T '%ProgramData%\USOShared\Logs' '*.etl' $true 720 $true), (T '%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Logs' '*' $true 720 $true)) -Admin $true
    New-AWRule 'Shaders'    'Windows' 'GPU shader caches'       'DirectX, NVIDIA and AMD shader caches. Games rebuild them on next launch.' -Targets @((T '%LOCALAPPDATA%\D3DSCache'), (T '%LOCALAPPDATA%\NVIDIA\DXCache'), (T '%LOCALAPPDATA%\NVIDIA\GLCache'), (T '%LOCALAPPDATA%\AMD\DxCache')) -Default $false
    New-AWRule 'INetCache'  'Windows' 'Internet cache'          'Cached web files used by Windows, Office and apps that show web pages; they are downloaded again when needed and files in use are skipped.' -Targets (T '%LOCALAPPDATA%\Microsoft\Windows\INetCache')
    New-AWRule 'StoreAppCaches' 'Windows' 'Store app caches'    'Temporary and cached files of Microsoft Store apps, which the apps rebuild when needed.' -Targets @((T '%LOCALAPPDATA%\Packages\*\AC\INetCache'), (T '%LOCALAPPDATA%\Packages\*\AC\Temp'), (T '%LOCALAPPDATA%\Packages\*\TempState')) -Default $false
    New-AWRule 'ProgramLogs' 'Windows' 'Program logs (all users)' 'Old log files that programs keep for all users in ProgramData. Only files older than 30 days.' -Kind 'Found' -Admin $true

    New-AWRule 'Edge'       'Browsers' 'Microsoft Edge cache'   'Cached web content, code cache and GPU cache. History, cookies and passwords are untouched.' -Targets (& $chromium '%LOCALAPPDATA%\Microsoft\Edge') -Process 'msedge' -ProcessLabel 'Edge'
    New-AWRule 'Chrome'     'Browsers' 'Google Chrome cache'    'Cached web content, code cache and GPU cache. History, cookies and passwords are untouched.' -Targets (& $chromium '%LOCALAPPDATA%\Google\Chrome') -Process 'chrome' -ProcessLabel 'Chrome'
    New-AWRule 'Brave'      'Browsers' 'Brave cache'            'Cached web content, code cache and GPU cache.' -Targets (& $chromium '%LOCALAPPDATA%\BraveSoftware\Brave-Browser') -Process 'brave' -ProcessLabel 'Brave'
    New-AWRule 'Firefox'    'Browsers' 'Firefox cache'          'Firefox cache2 folders for every profile.' -Targets (T '%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*\cache2') -Process 'firefox' -ProcessLabel 'Firefox'
    New-AWRule 'BrowserSW'  'Browsers' 'Browser service worker caches' 'Offline copies websites keep in Edge, Chrome and Brave; sites download again what they need.' -Targets (@(& $swCache '%LOCALAPPDATA%\Microsoft\Edge') + @(& $swCache '%LOCALAPPDATA%\Google\Chrome') + @(& $swCache '%LOCALAPPDATA%\BraveSoftware\Brave-Browser')) -Process @('msedge', 'chrome', 'brave') -ProcessLabel 'your browser' -Default $false

    New-AWRule 'Teams'      'Applications' 'Microsoft Teams cache' 'Classic and new Teams web caches.' -Targets @((T '%APPDATA%\Microsoft\Teams\Cache'), (T '%APPDATA%\Microsoft\Teams\Service Worker\CacheStorage'), (T '%LOCALAPPDATA%\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\EBWebView\*\Cache')) -Process @('Teams', 'ms-teams') -ProcessLabel 'Teams' -Default $false
    New-AWRule 'Discord'    'Applications' 'Discord cache'       'Discord web, code and GPU caches.' -Targets @((T '%APPDATA%\discord\Cache'), (T '%APPDATA%\discord\Code Cache'), (T '%APPDATA%\discord\GPUCache')) -Process 'Discord' -ProcessLabel 'Discord' -Default $false
    New-AWRule 'Steam'      'Applications' 'Steam web cache'     'Steam client browser cache (not games or shader pre-caches).' -Targets (T '%LOCALAPPDATA%\Steam\htmlcache') -Process 'steam' -ProcessLabel 'Steam' -Default $false
    New-AWRule 'VSCode'     'Applications' 'Visual Studio Code cache' 'Caches Visual Studio Code keeps (web, code and GPU caches, cached data and extension downloads); it rebuilds them when needed.' -Targets @((T '%APPDATA%\Code\Cache'), (T '%APPDATA%\Code\Code Cache'), (T '%APPDATA%\Code\GPUCache'), (T '%APPDATA%\Code\CachedData'), (T '%APPDATA%\Code\CachedExtensionVSIXs')) -Process 'Code' -ProcessLabel 'VS Code' -Default $false
    New-AWRule 'Slack'      'Applications' 'Slack cache'         'Slack web, code, GPU and offline caches, which Slack downloads again when needed.' -Targets @((T '%APPDATA%\Slack\Cache'), (T '%APPDATA%\Slack\Code Cache'), (T '%APPDATA%\Slack\GPUCache'), (T '%APPDATA%\Slack\Service Worker\CacheStorage')) -Process 'slack' -ProcessLabel 'Slack' -Default $false
    New-AWRule 'Spotify'    'Applications' 'Spotify cache'       'Songs and data Spotify keeps for quicker playback; it downloads them again when needed (songs you downloaded for offline listening may need downloading again).' -Targets @((T '%LOCALAPPDATA%\Spotify\Storage'), (T '%LOCALAPPDATA%\Spotify\Data')) -Process 'Spotify' -ProcessLabel 'Spotify' -Default $false
    New-AWRule 'OneDriveLogs' 'Applications' 'OneDrive logs'     'OneDrive log files older than 24 hours; OneDrive writes new ones as needed.' -Targets (T '%LOCALAPPDATA%\Microsoft\OneDrive\logs' '*' $true 24) -Default $false
    New-AWRule 'AppLogs'    'Applications' "Other apps' logs and temp files" 'Old log files, temp files and crash reports that programs leave in your profile. Only files older than 7 days; nothing they need to run.' -Kind 'Found'
    New-AWRule 'AppCaches'  'Applications' "Other apps' caches"  "Caches other programs keep in your profile. They're rebuilt when needed, so the next start of each program may be a little slower." -Kind 'Found' -Default $false

    New-AWRule 'NpmCache'   'Developer' 'npm cache'              'Packages npm keeps after downloading them; npm downloads them again when needed.' -Targets @((T '%LOCALAPPDATA%\npm-cache'), (T '%APPDATA%\npm-cache')) -Default $false
    New-AWRule 'PipCache'   'Developer' 'pip cache'              'Python packages pip keeps after downloading them; pip downloads them again when needed.' -Targets (T '%LOCALAPPDATA%\pip\Cache') -Default $false
    New-AWRule 'NuGetCache' 'Developer' 'NuGet HTTP cache'       'Package downloads NuGet keeps (not the installed packages folder); NuGet downloads them again when needed.' -Targets @((T '%LOCALAPPDATA%\NuGet\v3-cache'), (T '%LOCALAPPDATA%\NuGet\plugins-cache')) -Default $false
    New-AWRule 'YarnCache'  'Developer' 'Yarn cache'             'Packages Yarn keeps after downloading them; Yarn downloads them again when needed.' -Targets (T '%LOCALAPPDATA%\Yarn\Cache') -Default $false

    New-AWRule 'Recent'     'Privacy' 'Recent items list'       'Shortcuts in the Recent Items list (the files themselves are untouched).' -Targets (T '%APPDATA%\Microsoft\Windows\Recent' '*.lnk' $false) -Default $false
    New-AWRule 'Clipboard'  'Privacy' 'Clipboard'               'Clears the current clipboard contents.' -Kind 'Action' -Action 'Clipboard' -Default $false
    New-AWRule 'Dns'        'Privacy' 'DNS resolver cache'      'Flushes cached DNS lookups (ipconfig /flushdns).' -Kind 'Action' -Action 'FlushDns' -Default $false
)

# Steam keeps a per-game shader pre-cache in every library folder (steamapps\shadercache). Libraries
# can be on any drive, so they're read from Steam's own libraryfolders.vdf on this PC.
function Get-AWSteamLibraries {
    $steam = try { (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath } catch { $null }
    if (-not $steam) { return @() }
    $libs = New-Object System.Collections.Generic.List[string]
    $libs.Add(($steam -replace '/', '\'))
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
        foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
            $p = $m.Groups[1].Value -replace '\\\\', '\' -replace '/', '\'
            if ($libs -notcontains $p) { $libs.Add($p) }
        }
    }
    @($libs | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'steamapps') })
}
$steamLibs = @(Get-AWSteamLibraries)
if ($steamLibs.Count) {
    $r = New-AWRule 'SteamShaders' 'Applications' 'Steam shader pre-caches' "Per-game shader caches in $($steamLibs.Count) Steam library folder(s). Steam downloads or rebuilds them when a game next starts." -Targets @($steamLibs | ForEach-Object { T (Join-Path $_ 'steamapps\shadercache') }) -Process 'steam' -ProcessLabel 'Steam' -Default $false
    $r.UserScope = $true      # library paths are this PC's
    $at = [array]::FindIndex([object[]]$script:CleanerRules, [Predicate[object]]{ param($x) $x.Id -eq 'Steam' }) + 1
    $script:CleanerRules = @($script:CleanerRules[0..($at - 1)]) + @($r) + @($script:CleanerRules[$at..($script:CleanerRules.Count - 1)])
}

# Where the rules found by looking look. Logs = log / temp / crash-report folders, Cache = cache folders; the
# same walk serves both, so AppLogs and AppCaches never count the same file.
$covered = @($script:CleanerRules | Where-Object { $_.Kind -eq 'Files' } | ForEach-Object { $_.Targets } | ForEach-Object { $_.Path })
foreach ($r in $script:CleanerRules) {
    switch ($r.Id) {
        'AppLogs' {
            $r.UserScope = $true
            $r.Discover = @{ Bases = $userBases; MaxDepth = 4; Take = 'Log'; MinAgeHours = 168; TopFiles = @('*.log', '*.log.old', '*.dmp'); NeverInside = $userNever
                             Extra = @(@{ App = 'LocalLow Temp'; Path = '%USERPROFILE%\AppData\LocalLow\Temp'; MinAgeHours = 24 }) }
        }
        'AppCaches' {
            $r.UserScope = $true
            $r.Discover = @{ Bases = $userBases; MaxDepth = 4; Take = 'Cache'; MinAgeHours = 0; TopFiles = @(); NeverInside = $userNever
                             Extra = @(@{ App = 'LocalLow Temp'; Path = '%USERPROFILE%\AppData\LocalLow\Temp'; MinAgeHours = 24 }) }
        }
        'ProgramLogs' {
            $r.Discover = @{ Bases = @('%ProgramData%'); MaxDepth = 3; Take = 'Log'; MinAgeHours = 720; TopFiles = @('*.log'); LogNames = @('Logs', 'Log')
                             NeverInside = @('%ProgramData%\Package Cache', '%ProgramData%\Microsoft\Windows\WER', '%ProgramData%\Microsoft\Windows Defender', '%ProgramData%\Microsoft\Crypto',
                                             '%ProgramData%\Microsoft\Network', '%ProgramData%\ComputerDoctor', '%ProgramData%\AWiper') }
        }
    }
    if ($r.Kind -eq 'Found') { $r.Covered = $covered }
}
#endregion

#region ---------------------------------------------------------------- Automatic cleanup (shared by the window and -AutoClean)
# Only rules that don't need admin can run automatically; the Recycle Bin is never chosen for you.
function Get-AWAutoCleanDefaultIds { @($script:CleanerRules | Where-Object { $_.Default -and -not $_.Admin -and $_.Id -ne 'Recycle' } | ForEach-Object { $_.Id }) }
function Get-AWAutoCleanRules {
    $ids = @($script:State.AutoClean.Rules)
    @($script:CleanerRules | Where-Object { -not $_.Admin -and $ids -contains $_.Id })
}
$script:AutoCleanTask = 'ComputerDoctor Auto Clean'

# Records a finished run: last run / freed / result, and the reclaimed totals.
function Save-AWAutoCleanRun([long]$Freed, [long]$Held = 0, [string[]]$OpenApps = @()) {
    $ac = $script:State.AutoClean
    $ac.LastRun = (Get-Date).ToString('o'); $ac.LastFreed = $Freed
    $ac.LastResult = "Freed $(Format-AWSize $Freed)" + $(if (@($OpenApps).Count) { "; skipped $(Format-AWSize $Held) because these were open: $($OpenApps -join ', ')" } else { '' })
    $script:State.TotalFreed += $Freed; $script:State.Cleans++; $script:State.LastClean = (Get-Date).ToString('o')
    Save-AWState
}
# More freed after closing the apps that were open.
function Add-AWAutoCleanFreed([long]$More, [string[]]$StillOpen = @()) {
    $ac = $script:State.AutoClean
    $ac.LastFreed = [long]$ac.LastFreed + $More
    $ac.LastResult = "Freed $(Format-AWSize $ac.LastFreed) (after closing open apps)" + $(if (@($StillOpen).Count) { "; still open - skipped: $($StillOpen -join ', ')" } else { '' })
    $script:State.TotalFreed += $More
    Save-AWState
}
#endregion

#region ---------------------------------------------------------------- Debloat catalog
# Store apps Computer Doctor knows about. Pattern is matched against the package Name with -like.
# Recommended = pre-checked. Anything not listed only appears with "Show all apps".
function A([string]$Pattern, [string]$Name, [string]$Category, [bool]$Recommended = $true, [string]$Note = '') {
    @{ Pattern = $Pattern; Name = $Name; Category = $Category; Recommended = $Recommended; Note = $Note }
}
$script:BloatCatalog = @(
    A 'Microsoft.BingNews'                      'Microsoft News'            'Microsoft'
    A 'Microsoft.BingWeather'                   'Weather'                   'Microsoft'
    A 'Microsoft.BingFinance'                   'Money'                     'Microsoft'
    A 'Microsoft.BingSports'                    'Sports'                    'Microsoft'
    A 'Microsoft.BingSearch'                    'Bing Search'               'Microsoft'
    A 'Microsoft.BingTravel'                    'Travel'                    'Microsoft'
    A 'Microsoft.News'                          'News'                      'Microsoft'
    A 'Microsoft.GetHelp'                       'Get Help'                  'Microsoft'
    A 'Microsoft.Getstarted'                    'Tips'                      'Microsoft'
    A 'Microsoft.MicrosoftOfficeHub'            'Microsoft 365 (Office hub)' 'Microsoft'
    A 'Microsoft.MicrosoftSolitaireCollection'  'Solitaire Collection'      'Microsoft'
    A 'Microsoft.People'                        'People'                    'Microsoft'
    A 'Microsoft.PowerAutomateDesktop'          'Power Automate'            'Microsoft'
    A 'Microsoft.Todos'                         'Microsoft To Do'           'Microsoft'
    A 'Microsoft.WindowsFeedbackHub'            'Feedback Hub'              'Microsoft'
    A 'Microsoft.WindowsMaps'                   'Maps'                      'Microsoft'
    A 'Microsoft.549981C3F5F10'                 'Cortana'                   'Microsoft'
    A 'Microsoft.MixedReality.Portal'           'Mixed Reality Portal'      'Microsoft'
    A 'Microsoft.SkypeApp'                      'Skype'                     'Microsoft'
    A 'Microsoft.Office.OneNote'                'OneNote for Windows 10'    'Microsoft'
    A 'Microsoft.Office.Sway'                   'Sway'                      'Microsoft'
    A 'Microsoft.3DBuilder'                     '3D Builder'                'Microsoft'
    A 'Microsoft.Microsoft3DViewer'             '3D Viewer'                 'Microsoft'
    A 'Microsoft.Print3D'                       'Print 3D'                  'Microsoft'
    A 'Microsoft.Messaging'                     'Messaging'                 'Microsoft'
    A 'Microsoft.Wallet'                        'Wallet'                    'Microsoft'
    A 'Microsoft.NetworkSpeedTest'              'Network Speed Test'        'Microsoft'
    A 'Microsoft.MicrosoftJournal'              'Journal'                   'Microsoft'
    A 'Microsoft.ZuneVideo'                     'Movies and TV'             'Microsoft'
    A 'Microsoft.Copilot'                       'Copilot'                   'Microsoft'
    A 'Microsoft.Windows.DevHome'               'Dev Home'                  'Microsoft'
    A 'Microsoft.WindowsCommunicationsApps'     'Mail and Calendar'         'Microsoft'
    A 'Clipchamp.Clipchamp'                     'Clipchamp'                 'Microsoft'
    A 'MicrosoftCorporationII.MicrosoftFamily'  'Family Safety'             'Microsoft'
    A 'MicrosoftTeams'                          'Teams (personal)'          'Microsoft'
    A 'Microsoft.OutlookForWindows'             'Outlook (new)'             'Microsoft' $false 'Keep if you use it for mail'
    A 'MSTeams'                                 'Teams (work or school)'    'Microsoft' $false 'Keep if your organization uses Teams'
    A 'Microsoft.ZuneMusic'                     'Media Player'              'Microsoft' $false 'Default music and video player'
    A 'Microsoft.YourPhone'                     'Phone Link'                'Microsoft' $false
    A 'Microsoft.WindowsSoundRecorder'          'Sound Recorder'            'Microsoft' $false
    A 'Microsoft.MicrosoftStickyNotes'          'Sticky Notes'              'Microsoft' $false
    A 'Microsoft.WindowsAlarms'                 'Clock'                     'Microsoft' $false
    A 'MicrosoftCorporationII.QuickAssist'      'Quick Assist'              'Microsoft' $false 'Used for remote support'
    A 'Microsoft.GamingApp'                     'Xbox app'                  'Gaming'    $false 'Needed for Game Pass PC games'
    A 'Microsoft.XboxApp'                       'Xbox Console Companion'    'Gaming'
    A 'Microsoft.XboxGamingOverlay'             'Xbox Game Bar'             'Gaming'    $false 'Win+G overlay and screen capture'

    A 'SpotifyAB.SpotifyMusic'                  'Spotify'                   'Third-party'
    A 'Disney.37853FC22B2CE'                    'Disney+'                   'Third-party'
    A '4DF9E0F8.Netflix'                        'Netflix'                   'Third-party'
    A 'AmazonVideo.PrimeVideo'                  'Prime Video'               'Third-party'
    A '*.AmazonAlexa'                           'Alexa'                     'Third-party'
    A 'king.com.*'                              'King games (Candy Crush)'  'Third-party'
    A 'Facebook.*'                              'Facebook'                  'Third-party'
    A 'FACEBOOK.*'                              'Facebook'                  'Third-party'
    A '*.Instagram'                             'Instagram'                 'Third-party'
    A 'BytedancePte.Ltd.TikTok'                 'TikTok'                    'Third-party'
    A '*.Twitter'                               'X (Twitter)'               'Third-party'
    A '7EE7776C.LinkedInforWindows'             'LinkedIn'                  'Third-party'
    A '*.Duolingo-LearnLanguagesforFree'        'Duolingo'                  'Third-party'
    A '*.PicsArt-PhotoStudio'                   'PicsArt'                   'Third-party'
    A '*.Flipboard'                             'Flipboard'                 'Third-party'
    A '*.HiddenCity*'                           'Hidden City'               'Third-party'
    A '*.MarchofEmpires'                        'March of Empires'          'Third-party'
    A '*.Asphalt*'                              'Asphalt'                   'Third-party'
    A '*.CaesarsSlotsFreeCasino'                'Caesars Slots'             'Third-party'
    A '*.ROBLOXCORPORATION.ROBLOX'              'Roblox'                    'Third-party' $false
)

# Microsoft Store product IDs used by Rebloat to reinstall catalog apps (checked with winget show, Oct 2026).
$script:StoreIds = @{
    'Microsoft.BingWeather' = '9WZDNCRFJ3Q2'; 'Microsoft.BingNews' = '9WZDNCRFHVFW'; 'Microsoft.BingSearch' = '9NZBF4GT040C'
    'Microsoft.GetHelp' = '9PKDZBMV1H3T'; 'Microsoft.WindowsFeedbackHub' = '9NBLGGH4R32N'; 'Microsoft.Todos' = '9NBLGGH5R558'
    'Microsoft.PowerAutomateDesktop' = '9NFTCH6J7FHV'; 'Clipchamp.Clipchamp' = '9P1J8S7CCWWT'; 'Microsoft.ZuneMusic' = '9WZDNCRFJ3PT'
    'Microsoft.ZuneVideo' = '9WZDNCRFJ3P2'; 'Microsoft.YourPhone' = '9NMPJ99VJBWV'; 'Microsoft.WindowsSoundRecorder' = '9WZDNCRFHWKN'
    'Microsoft.MicrosoftStickyNotes' = '9NBLGGH4QGHW'; 'Microsoft.WindowsAlarms' = '9WZDNCRFJ3PR'; 'MicrosoftCorporationII.QuickAssist' = '9P7BP5VNWKX5'
    'Microsoft.GamingApp' = '9MV0B5HZVK9Z'; 'Microsoft.XboxGamingOverlay' = '9NZKPSTSNW4P'; 'Microsoft.OutlookForWindows' = '9NRX63209R7B'
    'Microsoft.MicrosoftOfficeHub' = '9WZDNCRD29V9'; 'Microsoft.Copilot' = '9NHT9RB2F4HD'; 'MicrosoftCorporationII.MicrosoftFamily' = '9PDJDJS743XF'
    'Microsoft.MicrosoftJournal' = '9N318R854RHH'; 'Microsoft.WindowsCommunicationsApps' = '9WZDNCRFHVQM'; 'MSTeams' = 'XP8BT8DW290MPQ'
    'SpotifyAB.SpotifyMusic' = '9NCBCSZSJRSB'; '4DF9E0F8.Netflix' = '9WZDNCRFJ3TJ'; 'Disney.37853FC22B2CE' = '9NXQXXLFST89'
    'AmazonVideo.PrimeVideo' = '9P6RC76MSMMJ'; 'BytedancePte.Ltd.TikTok' = '9NH2GPH4JZS4'; '*.Instagram' = '9NBLGGH5L9XT'
    '7EE7776C.LinkedInforWindows' = '9WZDNCRFJ4Q7'
}
# Apps Microsoft has retired. Rebloat only offers them if a copy is still on disk.
$script:RetiredApps = @(
    'Microsoft.549981C3F5F10', 'Microsoft.People', 'Microsoft.SkypeApp', 'Microsoft.XboxApp', 'Microsoft.BingFinance',
    'Microsoft.BingSports', 'Microsoft.BingTravel', 'Microsoft.3DBuilder', 'Microsoft.Print3D', 'Microsoft.MixedReality.Portal',
    'Microsoft.Messaging', 'Microsoft.Wallet', 'MicrosoftTeams', 'Microsoft.Windows.DevHome'
)

# Packages never offered for removal, even with "Show all apps".
$script:ProtectedApps = @(
    'Microsoft.WindowsStore', 'Microsoft.StorePurchaseApp', 'Microsoft.DesktopAppInstaller', 'Microsoft.SecHealthUI',
    'Microsoft.Windows.Photos', 'Microsoft.WindowsCalculator', 'Microsoft.WindowsNotepad', 'Microsoft.WindowsTerminal',
    'Microsoft.Paint', 'Microsoft.ScreenSketch', 'Microsoft.WindowsCamera', 'Microsoft.HEIFImageExtension',
    'Microsoft.HEVCVideoExtension', 'Microsoft.VP9VideoExtensions', 'Microsoft.WebMediaExtensions', 'Microsoft.WebpImageExtension',
    'Microsoft.RawImageExtension', 'Microsoft.AV1VideoExtension', 'Microsoft.AVCEncoderVideoExtension', 'Microsoft.MPEG2VideoExtension',
    'Microsoft.Xbox.TCUI', 'Microsoft.XboxIdentityProvider', 'Microsoft.XboxSpeechToTextOverlay', 'Microsoft.XboxGameOverlay',
    'Microsoft.WindowsAppRuntime*', 'Microsoft.VCLibs*', 'Microsoft.UI.Xaml*', 'Microsoft.NET.*', 'Microsoft.Services.Store.Engagement',
    'Microsoft.MicrosoftEdge*', 'Microsoft.Windows.*', 'Microsoft.AAD.BrokerPlugin', 'Microsoft.AccountsControl', 'Microsoft.LockApp',
    'Microsoft.ApplicationCompatibilityEnhancements', 'Microsoft.OneDriveSync', 'MicrosoftWindows.*', 'windows.*', 'Windows.*',
    'Microsoft.Winget.*', 'Microsoft.LanguageExperiencePack*', 'Microsoft.WidgetsPlatformRuntime', 'Microsoft.StartExperiencesApp'
)

# Registry tweaks. Each value: Path / Name / Type / Value / Revert ($null = delete the value on revert).
# RemoveKeys are deleted on revert (used where the tweak creates a key whose presence is the setting).
function New-AWTweak {
    param($Id, $Group, $Name, $Desc, $Values, [bool]$Admin = $false, [bool]$Default = $true, [bool]$Explorer = $false, $RemoveKeys = @())
    @{ Id = $Id; Group = $Group; Name = $Name; Desc = $Desc; Values = @($Values); Admin = $Admin; Default = $Default; Explorer = $Explorer; RemoveKeys = @($RemoveKeys) }
}
function RegV([string]$Path, [string]$Name, $Value, $Revert = $null, [string]$Type = 'DWord') {
    @{ Path = $Path; Name = $Name; Type = $Type; Value = $Value; Revert = $Revert }
}
$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$classicMenu = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'

$script:Tweaks = @(
    New-AWTweak 'Telemetry' 'Privacy' 'Limit telemetry' 'Sets diagnostic data to the lowest level this edition allows (machine policy).' -Admin $true -Values @(
        (RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0))
    New-AWTweak 'AdId' 'Privacy' 'Disable advertising ID' 'Stops apps from using your advertising ID and diagnostic data for personalized ads and tips.' -Values @(
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 1)
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0 1))
    New-AWTweak 'Suggestions' 'Privacy' 'Disable tips, ads and suggestions' 'Removes suggested apps in Start, tips on the lock screen and in Settings, and silent app installs.' -Values @(
        (RegV $cdm 'SubscribedContent-338388Enabled' 0 1), (RegV $cdm 'SubscribedContent-338389Enabled' 0 1),
        (RegV $cdm 'SubscribedContent-353694Enabled' 0 1), (RegV $cdm 'SubscribedContent-353696Enabled' 0 1),
        (RegV $cdm 'SubscribedContent-310093Enabled' 0 1), (RegV $cdm 'SystemPaneSuggestionsEnabled' 0 1),
        (RegV $cdm 'SilentInstalledAppsEnabled' 0 1), (RegV $cdm 'SoftLandingEnabled' 0 1),
        (RegV $cdm 'RotatingLockScreenOverlayEnabled' 0 1),
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' 'ScoobeSystemSettingEnabled' 0 1))
    New-AWTweak 'StartRecs' 'Privacy' 'Hide Start menu recommendations' 'Stops promoted apps and websites in the Recommended section of Start.' -Values @(
        (RegV $adv 'Start_IrisRecommendations' 0 1))

    New-AWTweak 'BingSearch' 'Search and AI' 'Disable Bing in Start search' 'Start search only looks at your PC instead of sending queries to Bing.' -Admin $true -Values @(
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0 1)
        (RegV 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1))
    New-AWTweak 'Copilot' 'Search and AI' 'Turn off Copilot' 'Disables Windows Copilot and hides its taskbar button.' -Admin $true -Explorer $true -Values @(
        (RegV 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1)
        (RegV $adv 'ShowCopilotButton' 0 1))
    New-AWTweak 'Recall' 'Search and AI' 'Turn off Recall snapshots' 'Stops Windows Recall from saving snapshots on Copilot+ PCs.' -Admin $true -Values @(
        (RegV 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1))

    New-AWTweak 'Widgets' 'Taskbar and Explorer' 'Remove Widgets' 'Hides the Widgets (news and weather) board and its taskbar button.' -Admin $true -Explorer $true -Values @(
        (RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0))
    New-AWTweak 'Chat' 'Taskbar and Explorer' 'Hide Chat button' 'Removes the Teams Chat button from the taskbar.' -Explorer $true -Values @(
        (RegV $adv 'TaskbarMn' 0 1))
    New-AWTweak 'TaskView' 'Taskbar and Explorer' 'Hide Task View button' 'Removes the Task View button. Win+Tab still works.' -Default $false -Explorer $true -Values @(
        (RegV $adv 'ShowTaskViewButton' 0 1))
    New-AWTweak 'SearchIcon' 'Taskbar and Explorer' 'Search as icon only' 'Shrinks the taskbar search box to an icon.' -Default $false -Explorer $true -Values @(
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 1 2))
    New-AWTweak 'AlignLeft' 'Taskbar and Explorer' 'Align taskbar to the left' 'Moves the Start button and taskbar icons back to the left edge.' -Default $false -Explorer $true -Values @(
        (RegV $adv 'TaskbarAl' 0 1))
    New-AWTweak 'ClassicMenu' 'Taskbar and Explorer' 'Classic right-click menu' 'Shows the full Windows 10 context menu without "Show more options".' -Default $false -Explorer $true -Values @(
        (RegV "$classicMenu\InprocServer32" '(default)' '' $null 'String')) -RemoveKeys @($classicMenu)
    New-AWTweak 'FileExt' 'Taskbar and Explorer' 'Show file extensions' 'Shows extensions like .exe and .pdf in File Explorer.' -Explorer $true -Values @(
        (RegV $adv 'HideFileExt' 0 1))
    New-AWTweak 'Hidden' 'Taskbar and Explorer' 'Show hidden files' 'Shows hidden files and folders in File Explorer.' -Default $false -Explorer $true -Values @(
        (RegV $adv 'Hidden' 1 2))
)
#endregion

#region ---------------------------------------------------------------- Offline mode + Resources folder
# Online state: $true / $false / $null (unknown). Forced offline (switch, saved setting) always wins.
$script:Online = $null
$script:ForceOffline = [bool]$Offline -or [bool]$script:State.ForceOffline
$script:ResourceDirs = @('ISO', 'LOF', 'updates', 'defs', 'apps', 'appx', 'drivers', 'tools')

function Test-AWOffline { $script:ForceOffline -or ($script:Online -eq $false) }

# Uses the result Windows' own connectivity check (NCSI) already computed, then one short probe of the
# same endpoint Windows uses. "Unknown" is treated as online-capable; features still fail gracefully.
function Test-AWInternet {
    try {
        $profiles = @(Get-NetConnectionProfile -ErrorAction Stop)
        if (@($profiles | Where-Object { "$($_.IPv4Connectivity)" -eq 'Internet' -or "$($_.IPv6Connectivity)" -eq 'Internet' }).Count) { return $true }
        if ($profiles.Count -eq 0) { return $false }
    } catch { }
    try {
        $req = [Net.WebRequest]::Create('http://www.msftconnecttest.com/connecttest.txt')
        $req.Timeout = 3000
        $resp = $req.GetResponse()
        $text = (New-Object IO.StreamReader($resp.GetResponseStream())).ReadToEnd(); $resp.Close()
        return $text -eq 'Microsoft Connect Test'
    } catch { return $false }
}

# A Resources folder holds everything Computer Doctor needs offline: ISO\ (Windows media), updates\, defs\,
# drivers\, apps\, appx\, LOF\, tools\. It can live next to ComputerDoctor.ps1, on any drive as
# <drive>:\ComputerDoctor\Resources (handy on a USB stick; <drive>:\AWiper\Resources from before the
# rename is still found), or anywhere chosen in Tools.
function Find-AWResources {
    $cands = New-Object System.Collections.Generic.List[string]
    if ($Resources) { $cands.Add($Resources) }
    if ($script:State.ResourcesPath) { $cands.Add($script:State.ResourcesPath) }
    if ($PSCommandPath) { $cands.Add((Join-Path (Split-Path $PSCommandPath) 'Resources')) }
    foreach ($d in [IO.DriveInfo]::GetDrives()) {
        if (("$($d.DriveType)" -eq 'Fixed' -or "$($d.DriveType)" -eq 'Removable') -and $d.IsReady) {
            $cands.Add((Join-Path $d.RootDirectory.FullName 'ComputerDoctor\Resources'))
            $cands.Add((Join-Path $d.RootDirectory.FullName 'AWiper\Resources'))   # USB sticks set up before the rename to Computer Doctor
        }
    }
    foreach ($c in $cands) { if ($c -and (Test-Path -LiteralPath $c -PathType Container)) { return (Resolve-Path -LiteralPath $c).ProviderPath } }
    $null
}

# Windows install media found under Resources\ISO: .iso files, or folders that contain sources\install.wim|esd.
function Get-AWRepairMedia([string]$Root) {
    if (-not $Root) { return }
    $iso = Join-Path $Root 'ISO'
    if (-not (Test-Path -LiteralPath $iso)) { return }
    foreach ($f in @(Get-ChildItem -LiteralPath $iso -Filter '*.iso' -File -ErrorAction SilentlyContinue)) { [pscustomobject]@{ Kind = 'ISO'; Path = $f.FullName; Name = $f.Name } }
    foreach ($d in @($iso) + @(Get-ChildItem -LiteralPath $iso -Directory -ErrorAction SilentlyContinue | ForEach-Object FullName)) {
        if ((Test-Path -LiteralPath (Join-Path $d 'sources\install.wim')) -or (Test-Path -LiteralPath (Join-Path $d 'sources\install.esd'))) {
            [pscustomobject]@{ Kind = 'Folder'; Path = $d; Name = Split-Path $d -Leaf }
        }
    }
}

function New-AWResourceLayout([string]$Root) {
    foreach ($d in $script:ResourceDirs) { New-Item -ItemType Directory -Path (Join-Path $Root $d) -Force | Out-Null }
    @'
Computer Doctor Resources folder - everything Computer Doctor needs to work without internet.

  ISO\       Windows install media matching your PCs (an .iso, or its extracted files).
             Used for "Repair Windows image" and ".NET Framework 3.5" with no internet.
  LOF\       Languages and Optional Features media (Features on Demand).
  updates\   wsusscn2.cab and downloaded .msu update packages.
  defs\      Microsoft Defender offline definitions (x64\mpam-fe.exe).
  drivers\   Exported drivers, one folder per PC model.
  apps\      Installers; appx\  Store app packages (.msixbundle / .appx) with dependencies.
  tools\     Your own utilities (e.g. Sysinternals - they can't be redistributed, so bring your own copy).

Put this folder next to ComputerDoctor.ps1, or at <drive>:\ComputerDoctor\Resources on a USB stick, and Computer Doctor finds it.
Use "Build manifest" in Computer Doctor's Tools on a trusted copy, then "Verify" on other machines to detect
missing or tampered files (SHA-256).
'@ | Set-Content -LiteralPath (Join-Path $Root 'README.txt') -Encoding UTF8
}
#endregion

#region ---------------------------------------------------------------- Driver sources
# Where a driver should come from. Matched on the driver provider first, then on the PCI / USB
# vendor ID in the device's hardware IDs. Links were checked in Oct 2026.
$script:DriverVendors = @(
    @{ Name = 'Intel';    Provider = '^Intel';                         Hw = 'VEN_8086|VID_8086|VID_8087|\\VEN_INTC';   Url = 'https://www.intel.com/content/www/us/en/support/detect.html' }
    @{ Name = 'NVIDIA';   Provider = 'NVIDIA';                         Hw = 'VEN_10DE|VID_0955';                     Url = 'https://www.nvidia.com/en-us/drivers/' }
    @{ Name = 'AMD';      Provider = '^AMD|Advanced Micro Devices';    Hw = 'VEN_1002|VEN_1022';                     Url = 'https://www.amd.com/en/support/download/drivers.html' }
    @{ Name = 'Realtek';  Provider = 'Realtek';                        Hw = 'VEN_10EC|VID_0BDA';                     Url = 'https://www.realtek.com/Download/Index' }
    @{ Name = 'Qualcomm'; Provider = 'Qualcomm';                       Hw = 'VEN_17CB|VEN_168C|VEN_QCOM';            Url = 'https://www.qualcomm.com/support' }
    @{ Name = 'Samsung';  Provider = '^Samsung';                       Hw = 'VEN_144D|VID_04E8';                     Url = 'https://semiconductor.samsung.com/consumer-storage/support/tools/' }
    @{ Name = 'Logitech'; Provider = 'Logitech';                       Hw = 'VID_046D';                              Url = 'https://support.logi.com/' }
)

function Resolve-AWDriverVendor([string]$Provider, $HardwareIds) {
    if ($Provider -match '^Microsoft') { return @{ Name = 'Microsoft (built into Windows)'; Url = '' } }
    foreach ($v in $script:DriverVendors) { if ($Provider -match $v.Provider) { return @{ Name = $v.Name; Url = $v.Url } } }
    $ids = (@($HardwareIds) -join ' ')
    foreach ($v in $script:DriverVendors) { if ($ids -match $v.Hw) { return @{ Name = $v.Name; Url = $v.Url } } }
    @{ Name = $Provider; Url = '' }
}

# The PC maker's driver page for this exact model (laptops often need the maker's customized drivers).
# Custom-built PCs report a placeholder maker, so the motherboard maker / model is used instead.
function Test-AWGenericMaker([string]$Maker) { -not $Maker -or $Maker -match 'System manufacturer|To Be Filled|Default string|O\.E\.M|^Not Applicable' }

function Get-AWOemSupport($System) {
    $maker = [string]$System.Manufacturer; $model = [string]$System.Model
    if ((Test-AWGenericMaker $maker) -and $System.BoardMaker) { $maker = [string]$System.BoardMaker; $model = [string]$System.BoardModel }
    $q = [uri]::EscapeDataString($model)
    $url = switch -Regex ($maker) {
        'Dell'                  { "https://www.dell.com/support/home/en-us/product-support/servicetag/$([uri]::EscapeDataString($System.Serial))/drivers" }
        'HP|Hewlett'            { 'https://support.hp.com/us-en/drivers' }
        'Lenovo'                { 'https://pcsupport.lenovo.com/us/en/' }
        'Micro-Star|^MSI'       { "https://www.msi.com/search/$q" }
        'ASUS'                  { 'https://www.asus.com/support/download-center/' }
        'Acer'                  { 'https://www.acer.com/us-en/support/drivers-and-manuals' }
        'Gigabyte'              { 'https://www.gigabyte.com/Support' }
        'ASRock'                { 'https://www.asrock.com/support/index.asp' }
        '^Microsoft'            { 'https://support.microsoft.com/surface/download-drivers-and-firmware-for-surface-09bb2e09-2a4b-cb69-0951-078a7739e120' }
        'Framework'             { 'https://knowledgebase.frame.work/' }
        default                 { 'https://www.bing.com/search?q=' + [uri]::EscapeDataString("$maker $model drivers") }
    }
    $short = ($maker -replace '(?i)\b(Co\.?,? ?Ltd\.?|Inc\.?|Corporation|International|Computer)\b', '' -replace '[,.]', '' -replace '\s+', ' ').Trim()
    $friendly = if ($maker -match 'Lenovo' -and $System.Family) { $System.Family } else { $model }
    [pscustomobject]@{ Maker = $short; Model = $friendly; Url = $url; SendsSerial = ($maker -match 'Dell') }
}
#endregion

#region ---------------------------------------------------------------- Headless (command-line) mode
function Write-AWCli([string]$Text, [string]$Color = '') {
    if ($Format -ne 'Text') { return }
    if ($Color) { Write-Host $Text -ForegroundColor $Color } else { Write-Host $Text }
}

function Read-AWConfig([string]$Path) {
    $j = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    @{
        Clean = @($j.Clean | Where-Object { $_ }); ApplyTweaks = @($j.ApplyTweaks | Where-Object { $_ }); RevertTweaks = @($j.RevertTweaks | Where-Object { $_ })
        RemoveApps = @($j.RemoveApps | Where-Object { $_ }); RestorePoint = [string]$j.RestorePoint; HealthCheck = [bool]$j.HealthCheck; Analyze = [bool]$j.Analyze
    }
}

# After an automatic cleanup that skipped rules because their apps were open: a small topmost popup in the
# bottom-right corner offering to close them (the way clicking X does) and clean what's left. Closes itself
# after 10 minutes (= Not now). Only in an interactive session.
function Show-AWAutoCleanPopup([long]$Freed, [long]$Held, $Blockers, $Rules) {
    if (-not [Environment]::UserInteractive -or [Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') { return }
    $apps = @($Blockers | ForEach-Object { $_.Label } | Select-Object -Unique)
    [xml]$px = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Computer Doctor" Width="390" SizeToContent="Height" WindowStyle="None" ResizeMode="NoResize" Topmost="True"
        ShowInTaskbar="False" AllowsTransparency="True" Background="Transparent" FontFamily="Segoe UI" ShowActivated="False">
  <Border Background="#151922" BorderBrush="#2C3341" BorderThickness="1" CornerRadius="12" Padding="18,14" Margin="8">
    <StackPanel>
      <TextBlock Text="Computer Doctor" Foreground="#E6E9F0" FontWeight="SemiBold" FontSize="14"/>
      <TextBlock x:Name="Msg" Foreground="#C9CEDA" TextWrapping="Wrap" Margin="0,8,0,0" FontSize="12.5"/>
      <StackPanel x:Name="Btns" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,14,0,0">
        <Button x:Name="Later" Content="Not now" Padding="14,6" Margin="0,0,8,0" Background="#2C3341" Foreground="#E6E9F0" BorderThickness="0" Cursor="Hand"/>
        <Button x:Name="Go" Content="Close them and clean" Padding="14,6" Background="#2563EB" Foreground="White" BorderThickness="0" Cursor="Hand"/>
      </StackPanel>
    </StackPanel>
  </Border>
</Window>
'@
    try { $w = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $px)) } catch { Write-WLog "Could not show the automatic cleanup popup: $($_.Exception.Message)" 'WARN'; return }
    $script:AcPop = @{ Window = $w; Msg = $w.FindName('Msg'); Btns = $w.FindName('Btns'); Blockers = @($Blockers); Rules = @($Rules); Started = $null; Timer = $null }
    $script:AcPop.Msg.Text = 'Automatic cleanup finished and freed {0}. {1} more is waiting because these are open: {2}. Close them now to finish?' -f (Format-AWSize $Freed), (Format-AWSize $Held), ($apps -join ', ')
    $w.Add_Loaded({
        $wa = [System.Windows.SystemParameters]::WorkArea
        $script:AcPop.Window.Left = $wa.Right - $script:AcPop.Window.ActualWidth - 8
        $script:AcPop.Window.Top = $wa.Bottom - $script:AcPop.Window.ActualHeight - 8
    })
    $w.FindName('Later').Add_Click({ $script:AcPop.Window.Close() })
    $w.FindName('Go').Add_Click({
        $p = $script:AcPop
        $p.Btns.IsEnabled = $false
        $p.Msg.Text = 'Closing ' + ((@($p.Blockers | ForEach-Object { $_.Label } | Select-Object -Unique)) -join ', ') + '...'
        [void](Close-WBlockers $p.Blockers)
        Write-WLog ('Automatic cleanup: asked ' + ((@($p.Blockers | ForEach-Object { $_.Label } | Select-Object -Unique)) -join ', ') + ' to close')
        $p.Started = Get-Date
        $p.Timer.Interval = [TimeSpan]::FromMilliseconds(500)
        $p.Timer.Tag = 'closing'
        $p.Timer.Start()
    })
    # One timer: the 10-minute auto-close, then the wait for apps to close (up to 15 s), then 5 s showing the result.
    $t = New-Object System.Windows.Threading.DispatcherTimer
    $t.Interval = [TimeSpan]::FromMinutes(10); $t.Tag = 'idle'
    $t.Add_Tick({
        $p = $script:AcPop
        switch ($p.Timer.Tag) {
            'closing' {
                $open = @(Get-WOpenBlockers $p.Blockers)
                if ($open.Count -and ((Get-Date) - $p.Started).TotalSeconds -lt 15) { return }
                $p.Timer.Stop()
                [long]$more = 0
                foreach ($rule in $p.Rules) {
                    try { foreach ($r in @(Invoke-WClean $rule | Where-Object { $_ -is [hashtable] -and -not $_.Sub })) { $more += [long]$r.Bytes } }
                    catch { Write-WLog "$($rule.Name): $($_.Exception.Message)" 'ERROR' }
                }
                Add-AWAutoCleanFreed $more $open
                Write-AWAction 'AutoClean' @($p.Rules | ForEach-Object { $_.Id }) @{ Bytes = $more; AfterClosingApps = $true; StillOpen = $open } 'Done'
                $p.Msg.Text = "Freed $(Format-AWSize $more) more." + $(if ($open.Count) { " Still open - skipped: $($open -join ', ')." } else { '' })
                $p.Timer.Tag = 'done'; $p.Timer.Interval = [TimeSpan]::FromSeconds(5); $p.Timer.Start()
            }
            default { $p.Timer.Stop(); $p.Window.Close() }
        }
    })
    $script:AcPop.Timer = $t
    $t.Start()
    [void]$w.ShowDialog()
    $t.Stop()
    $line = $null; $buf = New-Object System.Text.StringBuilder
    while ($Sync.Log.TryDequeue([ref]$line)) { [void]$buf.AppendLine($line) }
    try { [IO.File]::AppendAllText($script:LogFile, $buf.ToString()) } catch { }
}

function Invoke-AWCli {
    $Sync.Echo = ($Format -eq 'Text')
    . ([scriptblock]::Create($Sync.WorkerLib))
    $Target = $null
    $result = [ordered]@{ Computer = $env:COMPUTERNAME; Target = $env:COMPUTERNAME; Started = (Get-Date).ToString('o'); DryRun = (-not $Yes); Admin = $script:IsAdmin; Steps = @() }
    $failed = $false; $healthCode = 0

    # ---- inputs: switches plus an optional JSON profile (profiles only reference built-in IDs)
    $want = @{ Clean = @($Clean); ApplyTweaks = @($ApplyTweak); RevertTweaks = @($RevertTweak); RemoveApps = @($RemoveApp); RestorePoint = $RestorePoint; HealthCheck = [bool]$HealthCheck; Analyze = [bool]$Analyze }
    if ($Config) {
        try { $cfg = Read-AWConfig $Config } catch { Write-Host "Could not read profile $($Config): $($_.Exception.Message)" -ForegroundColor Red; return 2 }
        foreach ($k in 'Clean', 'ApplyTweaks', 'RevertTweaks', 'RemoveApps') { $want[$k] = @($want[$k]) + @($cfg[$k]) }
        if (-not $want.RestorePoint) { $want.RestorePoint = $cfg.RestorePoint }
        $want.HealthCheck = $want.HealthCheck -or $cfg.HealthCheck; $want.Analyze = $want.Analyze -or $cfg.Analyze
    }
    foreach ($k in 'Clean', 'ApplyTweaks', 'RevertTweaks', 'RemoveApps') { $want[$k] = @($want[$k] | Where-Object { $_ } | ForEach-Object { "$_".Split(',') } | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique) }

    $rules = @()
    foreach ($r in $want.Clean) {
        if ($r -eq 'Default') { $rules += @($script:CleanerRules | Where-Object { $_.Default }) }
        elseif ($r -eq 'All') { $rules += $script:CleanerRules }
        else {
            $m = @($script:CleanerRules | Where-Object { $_.Id -eq $r })
            if (-not $m.Count) { Write-Host "Unknown cleaning rule '$r'. Use -ListRules to see the IDs." -ForegroundColor Red; return 2 }
            $rules += $m
        }
    }
    if ($want.Analyze -and -not $rules.Count) { $rules = @($script:CleanerRules | Where-Object { $_.Default }) }
    $rules = @($rules | Sort-Object { $_.Id } -Unique)
    $tweakSel = @{}
    foreach ($pair in @(@('ApplyTweaks', $true), @('RevertTweaks', $false))) {
        foreach ($id in $want[$pair[0]]) {
            $tw = @($script:Tweaks | Where-Object { $_.Id -eq $id })
            if (-not $tw.Count) { Write-Host "Unknown tweak '$id'. Use -ListTweaks to see the IDs." -ForegroundColor Red; return 2 }
            $tweakSel[$id] = @{ Tweak = $tw[0]; Apply = $pair[1] }
        }
    }

    # ---- target
    if ($ComputerName) {
        $cred = $Credential
        if (-not $cred -and $UseSavedCredential) {
            $saved = try { [ComputerDoctor.CredMan]::ReadHost($ComputerName) } catch { $null }
            if (-not $saved) { Write-Host "No saved credentials for $ComputerName in Credential Manager." -ForegroundColor Red; return 2 }
            $cred = New-Object System.Management.Automation.PSCredential($saved[0], (ConvertTo-SecureString $saved[1] -AsPlainText -Force))
        }
        try {
            $p = @{ ComputerName = $ComputerName; ScriptBlock = { $env:COMPUTERNAME }; ErrorAction = 'Stop' }
            if ($cred) { $p.Credential = $cred }
            $name = Invoke-Command @p
        } catch { Write-Host "Could not connect to $($ComputerName): $($_.Exception.Message)" -ForegroundColor Red; return 1 }
        $Target = @{ Host = $ComputerName; Credential = $cred; ComputerName = [string]$name }
        $script:Target = $Target
        $result.Target = [string]$name
    }
    $remote = [bool]$Target
    $canAdmin = $script:IsAdmin -or $remote
    $wantsChanges = [bool]$Backup -or [bool]$Fetch -or ($want.Clean.Count -and -not $want.Analyze) -or $want.ApplyTweaks.Count -or $want.RevertTweaks.Count -or $want.RemoveApps.Count -or $want.RestorePoint
    Write-AWCli ("Computer Doctor {0} - {1}{2}{3}" -f $script:AppVersion, $result.Target, $(if ($remote) { ' (remote)' } else { '' }), $(if ($wantsChanges -and -not $Yes) { ' - preview only, add -Yes to make changes' } else { '' })) Cyan
    if ($script:ElevationNote -and -not $remote) { Write-AWCli $script:ElevationNote Yellow }

    # ---- listings
    if ($ListRules) {
        $rows = $script:CleanerRules | ForEach-Object { [pscustomobject]@{ Id = $_.Id; Group = $_.Group; Name = $_.Name; Admin = $_.Admin; Default = $_.Default } }
        # A fixed wide width, so ids aren't cut short when the output is redirected (a narrow or unknown console).
        Write-AWCli ($rows | Format-Table -AutoSize | Out-String -Width 400).TrimEnd()
        $result.Steps += [ordered]@{ Step = 'ListRules'; Items = @($rows) }
    }
    if ($ListTweaks) {
        $rows = $script:Tweaks | ForEach-Object { [pscustomobject]@{ Id = $_.Id; Group = $_.Group; Name = $_.Name; Admin = $_.Admin; Default = $_.Default } }
        Write-AWCli ($rows | Format-Table -AutoSize | Out-String -Width 400).TrimEnd()
        $result.Steps += [ordered]@{ Step = 'ListTweaks'; Items = @($rows) }
    }

    # Catalog-matched Store apps (protected system apps are never offered)
    $appList = $null
    $getApps = {
        $raw = @(Invoke-WTarget { param($AllUsers) Get-WStoreAppsRaw $AllUsers } -ArgumentList @($canAdmin))
        $seen = @{}
        foreach ($p in $raw) {
            if ($seen[$p.Name]) { continue }; $seen[$p.Name] = $true
            $match = $null; foreach ($c in $script:BloatCatalog) { if ($p.Name -like $c.Pattern) { $match = $c; break } }
            if (-not $match) { $prot = $false; foreach ($x in $script:ProtectedApps) { if ($p.Name -like $x) { $prot = $true; break } }; if ($prot) { continue } }
            [pscustomobject]@{ Package = $p.Name; Name = $(if ($match) { $match.Name } else { $p.Name }); Category = $(if ($match) { $match.Category } else { 'Other' }); Recommended = [bool]($match -and $match.Recommended); Provisioned = $p.Prov }
        }
    }
    if ($ListApps) {
        $appList = @(& $getApps)
        Write-AWCli ($appList | Sort-Object Category, Name | Format-Table Package, Name, Category, Recommended -AutoSize | Out-String).TrimEnd()
        $result.Steps += [ordered]@{ Step = 'ListApps'; Items = @($appList) }
    }

    # ---- health check (read-only)
    if ($want.HealthCheck) {
        Write-AWCli "`nHealth check" Cyan
        $rows = @(Invoke-WTarget { Get-WHealth } | Where-Object { $_.Status })
        foreach ($r in $rows) {
            $c = switch ($r.Status) { 'Good' { 'Green' } 'Warning' { 'Yellow' } 'Problem' { 'Red' } default { 'Gray' } }
            Write-AWCli ('  {0,-8} {1,-28} {2}' -f $r.Status.ToUpper(), $r.Name, $r.Detail) $c
        }
        $cnt = @{}; foreach ($s in 'Good', 'Warning', 'Problem', 'Info', 'NA') { $cnt[$s] = @($rows | Where-Object { $_.Status -eq $s }).Count }
        Write-AWCli ("  {0} good, {1} warning(s), {2} problem(s), {3} not available here" -f $cnt.Good, $cnt.Warning, $cnt.Problem, $cnt.NA)
        $healthCode = if ($cnt.Problem) { 4 } elseif ($cnt.Warning) { 3 } else { 0 }
        $result.Steps += [ordered]@{ Step = 'HealthCheck'; Items = @($rows); Summary = $cnt }
    }

    # ---- drivers (read-only)
    if ($CheckDrivers) {
        Write-AWCli "`nDrivers" Cyan
        $inv = @(Invoke-WTarget { Get-WDriverInventory }) | Where-Object { $_.System } | Select-Object -Last 1
        $oem = Get-AWOemSupport $inv.System
        Write-AWCli "  $($oem.Maker) $($oem.Model) - BIOS $($inv.System.Bios) - $(@($inv.Drivers).Count) drivers"
        $updates = @()
        if (Test-AWOffline) { Write-AWCli '  Offline - skipping the Windows Update check.' Gray }
        else {
            try { $updates = @(Invoke-WTarget { Get-WDriverUpdates } | Where-Object { $_.UpdateId }) }
            catch { Write-AWCli "  Windows Update check failed: $($_.Exception.Message)" Red; $failed = $true }
        }
        $probs = @($inv.Drivers | Where-Object { $_.ErrorCode -ne 0 })
        foreach ($d in $probs) { Write-AWCli ("  PROBLEM  {0} (code {1})" -f $d.Name, $d.ErrorCode) Red }
        foreach ($u in $updates) { Write-AWCli ("  UPDATE   {0} - {1:yyyy-MM-dd} driver from {2}" -f $(if ($u.Model) { $u.Model } else { $u.Title }), $u.VerDate, $u.Source) Green }
        $old = @($inv.Drivers | Where-Object { $_.Provider -notmatch '^Microsoft' -and $_.Date -ne [datetime]::MinValue -and $_.Date -lt (Get-Date).AddYears(-3) })
        if ($old.Count) { Write-AWCli "  $($old.Count) third-party driver(s) are over 3 years old - check the vendor sites" Yellow }
        Write-AWCli "  Maker's driver page: $($oem.Url)"
        $result.Steps += [ordered]@{ Step = 'CheckDrivers'; System = $inv.System; Problems = @($probs | ForEach-Object Name); Updates = @($updates); OldDrivers = @($old | ForEach-Object Name); MakerPage = $oem.Url }
    }

    # ---- fleet inventory (read-only)
    if ($Inventory) {
        $hosts = @($Inventory | ForEach-Object { "$_" -split '[,;\s]+' } | Where-Object { $_ } | Select-Object -Unique)
        Write-AWCli "`nFleet inventory of $($hosts.Count) PC(s)" Cyan
        $inv = Invoke-WFleetInventory $hosts (Join-Path $script:DataDir 'Inventory')
        Write-AWCli ("  {0} collected, {1} not reached, {2} changed since last run" -f $inv.Count, $inv.Failed, $inv.Changed) $(if ($inv.Failed) { 'Yellow' } else { 'Green' })
        Write-AWCli "  Report: $($inv.Html)"
        if ($inv.Failed) { $failed = $true }
        $result.Steps += [ordered]@{ Step = 'Inventory'; Hosts = $hosts; Folder = $inv.Dir; Report = $inv.Html; Collected = $inv.Count; Failed = $inv.Failed; Changed = $inv.Changed }
    }

    # ---- air gap: needs list (offline PC) and fetch (connected PC)
    if ($ExportNeeds -or $Fetch) {
        $root = Find-AWResources
        if (-not $root) { Write-AWCli 'No Resources folder found - pass -Resources <path> or create one in the window (Tools > Offline kit).' Red; $failed = $true }
        elseif ($ExportNeeds) {
            Write-AWCli "`nNeeds list" Cyan
            $cab = Join-Path $root 'updates\wsusscn2.cab'
            $missing = @()
            if ($script:IsAdmin -and (Test-Path -LiteralPath $cab)) { Write-AWCli '  Scanning offline with wsusscn2.cab (a few minutes)...'; $missing = @(Get-WMissingUpdates $cab) }
            elseif (-not (Test-AWOffline)) { Write-AWCli '  Scanning with Windows Update...'; $missing = @(Get-WMissingUpdates '') }
            else { Write-AWCli '  No scan file (Resources\updates\wsusscn2.cab) or admin rights - missing updates are not included this time.' Yellow }
            $n = Get-WNeedsList $missing @()
            $f = Join-Path $root "needs\$env:COMPUTERNAME.json"
            New-Item -ItemType Directory -Path (Split-Path $f) -Force | Out-Null
            ConvertTo-Json -InputObject $n -Depth 5 | Set-Content -LiteralPath $f -Encoding UTF8
            Write-AWCli ("  Saved {0}: {1} update(s), {2} problem device(s)" -f $f, @($n.MissingUpdates).Count, @($n.ProblemDevices).Count) Green
            Write-AWAction 'ExportNeedsList' @($f) @{} 'Done'
            $result.Steps += [ordered]@{ Step = 'ExportNeeds'; File = $f; MissingUpdates = @($n.MissingUpdates).Count }
        }
        if ($root -and $Fetch) {
            Write-AWCli "`nFetch into $root" Cyan
            if (Test-AWOffline) { Write-AWCli '  Offline - fetching needs internet.' Red; $failed = $true }
            elseif (-not $Yes) { Write-AWCli "  Would download for $(@(Get-ChildItem -LiteralPath (Join-Path $root 'needs') -Filter '*.json' -ErrorAction SilentlyContinue).Count) needs list(s), plus the scan file and Defender definitions." }
            else {
                $s = Invoke-WFetch $root
                [void](New-WResourceManifest $root)
                Write-AWCli ("  {0} update(s), {1} app(s), {2} driver(s), {3} baseline list(s){4}{5}; {6} problem(s). Manifest refreshed." -f $s.Updates, $s.Apps, $s.Drivers, $s.Baselines, $(if ($s.ScanCab) { ', scan file' } else { '' }), $(if ($s.Defender) { ', Defender definitions' } else { '' }), $s.Errors) $(if ($s.Errors) { 'Yellow' } else { 'Green' })
                Write-AWAction 'Fetch' @($root) @{} $(if ($s.Errors) { 'Partly failed' } else { 'Done' })
                if ($s.Errors) { $failed = $true }
                $result.Steps += [ordered]@{ Step = 'Fetch'; Summary = $s }
            }
        }
    }

    # ---- folder backup (the job saved in the window)
    if ($Backup) {
        $job = $script:State.Backup
        Write-AWCli "`nBackup" Cyan
        if (-not @($job.Sources).Count -or -not $job.Dest) { Write-AWCli '  No backup is set up yet - choose folders and a drive in Recovery > Backup.' Yellow; $failed = $true }
        elseif (-not $Yes) { Write-AWCli "  Would back up $(@($job.Sources).Count) folder(s) to $($job.Dest)" }
        else {
            $r = Invoke-WBackup ([pscustomobject]$job)
            $script:State.Backup.LastRun = (Get-Date).ToString('o'); $script:State.Backup.LastResult = $r.Message; Save-AWState
            Write-AWCli "  $($r.Message)" $(if ($r.Ok) { 'Green' } else { 'Yellow' })
            Write-AWAction 'Backup' @($job.Sources) @{ Dest = $job.Dest } $(if ($r.Ok) { 'Done' } else { 'Problems' })
            if (-not $r.Ok) { $failed = $true }
            $result.Steps += [ordered]@{ Step = 'Backup'; Ok = $r.Ok; Message = $r.Message }
        }
    }

    # ---- automatic cleanup (the scheduled task): the rules chosen in Cleaner > Automatic cleanup, never admin rules.
    # It is set up in the window, so it runs without -Yes. Apps that are open are skipped, then offered in a popup.
    if ($AutoClean) {
        Write-AWCli "`nAutomatic cleanup" Cyan
        $ac = $script:State.AutoClean
        if ($remote) { Write-AWCli '  Automatic cleanup runs on this PC only.' Red; $failed = $true }
        elseif (-not $ac.Enabled) { Write-AWCli '  Automatic cleanup is turned off (Cleaner > Automatic cleanup) - nothing to do.' Yellow }
        else {
            $acRules = @(Get-AWAutoCleanRules)
            $acItems = @(); [long]$acTotal = 0; [long]$acHeld = 0; $acBlockers = @(); $acBlocked = @()
            foreach ($rule in $acRules) {
                try {
                    $rows = @(Invoke-WClean $rule | Where-Object { $_ -is [hashtable] })
                    $r = @($rows | Where-Object { -not $_.Sub }) | Select-Object -First 1
                    Write-AWCli ('  {0,10}  {1,-28} {2}' -f (Format-AWSize ([long]$r.Bytes)), $rule.Name, $r.Note)
                    foreach ($x in @($rows | Where-Object { $_.Sub })) { Write-AWCli ('  {0,10}    {1,-26} {2}' -f (Format-AWSize ([long]$x.Bytes)), $x.Name, $x.Note) }
                    $acTotal += [long]$r.Bytes
                    if ($r.Skipped) { $acHeld += [long]$r.Held; $acBlockers += @($r.Blockers | Where-Object { $_ }); $acBlocked += $rule }
                    $acItems += [ordered]@{ Id = $rule.Id; Name = $rule.Name; Files = [long]$r.Files; Bytes = [long]$r.Bytes; Note = [string]$r.Note }
                } catch { Write-AWCli "  failed   $($rule.Name): $($_.Exception.Message)" Red; $failed = $true }
            }
            $acApps = @($acBlockers | ForEach-Object { $_.Label } | Select-Object -Unique)
            Save-AWAutoCleanRun $acTotal $acHeld $acApps
            Write-AWAction 'AutoClean' @($acRules | ForEach-Object { $_.Id }) @{ Bytes = $acTotal; SkippedOpen = $acApps } 'Done'
            Write-AWCli ('  {0} freed' -f (Format-AWSize $acTotal)) Green
            if ($acApps.Count) { Write-AWCli ('  {0} more is waiting because these are open: {1}' -f (Format-AWSize $acHeld), ($acApps -join ', ')) Yellow }
            $result.Steps += [ordered]@{ Step = 'AutoClean'; Items = $acItems; TotalBytes = $acTotal; WaitingBytes = $acHeld; OpenApps = $acApps }
            if ($acApps.Count) {
                # Flush the log first: the popup can stay up for a while.
                $line = $null; $buf = New-Object System.Text.StringBuilder
                while ($Sync.Log.TryDequeue([ref]$line)) { [void]$buf.AppendLine($line) }
                try { [IO.File]::AppendAllText($script:LogFile, $buf.ToString()) } catch { }
                Show-AWAutoCleanPopup $acTotal $acHeld $acBlockers $acBlocked
            }
        }
    }

    # ---- restore point (explicit, or automatic before tweaks / app removal)
    $rpDesc = $want.RestorePoint
    if (-not $rpDesc -and $Yes -and ($want.ApplyTweaks.Count -or $want.RemoveApps.Count)) { $rpDesc = Get-AWAutoRP 'command-line changes' }
    if ($rpDesc) {
        if (-not $canAdmin) { Write-AWCli 'Restore point skipped: needs administrator rights.' Yellow }
        elseif (-not $Yes) { Write-AWCli "Would create restore point '$rpDesc'." }
        else {
            $ok = [bool](@(Invoke-WTarget { param($d) New-WRestorePoint $d } -ArgumentList @($rpDesc)) | Select-Object -Last 1)
            Write-AWAction 'RestorePoint' @($rpDesc) @{} $(if ($ok) { 'Done' } else { 'Failed' })
            $result.Steps += [ordered]@{ Step = 'RestorePoint'; Description = $rpDesc; Ok = $ok }
        }
    }

    # ---- cleaning
    if ($rules.Count) {
        $doClean = $Yes -and $want.Clean.Count -and -not $want.Analyze
        Write-AWCli $(if ($doClean) { "`nCleaning" } else { "`nAnalyzing (nothing is deleted)" }) Cyan
        $items = @()
        foreach ($rule in $rules) {
            $userScope = $rule.UserScope -or $rule.Kind -eq 'RecycleBin' -or $rule.Action -eq 'Clipboard' -or @($rule.Targets | Where-Object { $_.Path -match '%(TEMP|LOCALAPPDATA|APPDATA|USERPROFILE)%' }).Count
            if ($remote -and $userScope) { Write-AWCli "  skipped  $($rule.Name) (per-user, this PC only)" Gray; continue }
            if ($rule.Admin -and -not $canAdmin) { Write-AWCli "  skipped  $($rule.Name) (needs admin)" Gray; continue }
            try {
                $r = if ($doClean) { Invoke-WTarget { param($x) Invoke-WClean $x } -ArgumentList @(, $rule) } else { Invoke-WTarget { param($x) Measure-WItem $x } -ArgumentList @(, $rule) }
                $rows = @($r | Where-Object { $_ -is [hashtable] -or $_.Bytes -ne $null })
                $r = @($rows | Where-Object { -not $_.Sub }) | Select-Object -Last 1
                Write-AWCli ('  {0,10}  {1,-28} {2}' -f (Format-AWSize ([long]$r.Bytes)), $rule.Name, $r.Note)
                $apps = @($rows | Where-Object { $_.Sub } | ForEach-Object { Write-AWCli ('  {0,10}    {1,-26} {2}' -f (Format-AWSize ([long]$_.Bytes)), $_.Name, $_.Note); [ordered]@{ Name = [string]$_.Name; Files = [long]$_.Files; Bytes = [long]$_.Bytes; Note = [string]$_.Note } })
                $items += [ordered]@{ Id = $rule.Id; Name = $rule.Name; Files = [long]$r.Files; Bytes = [long]$r.Bytes; Note = [string]$r.Note; Apps = $apps }
            } catch { Write-AWCli "  failed   $($rule.Name): $($_.Exception.Message)" Red; $failed = $true }
        }
        [long]$total = 0; foreach ($i in $items) { $total += $i.Bytes }
        Write-AWCli ('  {0} {1}' -f (Format-AWSize $total), $(if ($doClean) { 'freed' } else { 'can be cleaned' })) Green
        if ($doClean) {
            $script:State.TotalFreed += $total; $script:State.Cleans++; $script:State.LastClean = (Get-Date).ToString('o'); Save-AWState
            Write-AWAction 'Clean' ($items | ForEach-Object { $_.Id }) @{ Bytes = $total } 'Done'
        }
        $result.Steps += [ordered]@{ Step = $(if ($doClean) { 'Clean' } else { 'Analyze' }); Items = $items; TotalBytes = $total }
    }

    # ---- tweaks
    if ($tweakSel.Count) {
        Write-AWCli "`nTweaks" Cyan
        $done = @()
        foreach ($id in $tweakSel.Keys) {
            $t = $tweakSel[$id].Tweak; $apply = $tweakSel[$id].Apply
            $hklmOnly = -not @($t.Values | Where-Object { $_.Path -notlike 'HKLM:*' }).Count
            if ($remote -and -not $hklmOnly) { Write-AWCli "  skipped  $($t.Name) (per-user setting, this PC only)" Gray; continue }
            if (-not $remote -and $t.Admin -and -not $script:IsAdmin) { Write-AWCli "  skipped  $($t.Name) (needs admin)" Gray; continue }
            if (-not $Yes) { Write-AWCli ("  would {0} {1}" -f $(if ($apply) { 'apply ' } else { 'revert' }), $t.Name); continue }
            try {
                $cap = @(Invoke-WTarget { param($Tw, $On) Set-WTweak $Tw $On } -ArgumentList @($t, $apply)) | Where-Object { $_.UndoKind } | Select-Object -Last 1
                $uid = if ($cap) { Add-AWUndoEntry $cap } else { '' }
                Write-AWAction $(if ($apply) { 'ApplyTweak' } else { 'RevertTweak' }) @($t.Id) @{} 'Done' $uid
                $done += [ordered]@{ Id = $t.Id; Applied = $apply; UndoId = $uid }
            } catch { Write-AWCli "  failed   $($t.Name): $($_.Exception.Message)" Red; $failed = $true }
        }
        $result.Steps += [ordered]@{ Step = 'Tweaks'; Items = $done }
    }

    # ---- Store app removal
    if ($want.RemoveApps.Count) {
        Write-AWCli "`nStore apps" Cyan
        if (-not $appList) { $appList = @(& $getApps) }
        $sel = @($appList | Where-Object {
            $a = $_
            @($want.RemoveApps | Where-Object { ($_ -eq 'Recommended' -and $a.Recommended) -or ($_ -ne 'Recommended' -and $a.Package -like $_) }).Count
        })
        if (-not $sel.Count) { Write-AWCli '  No matching apps are installed.' Gray }
        $removed = @()
        foreach ($a in $sel) {
            if (-not $Yes) { Write-AWCli "  would remove $($a.Name) ($($a.Package))"; continue }
            try {
                Invoke-WTarget { param($App, $AllUsers, $Prov) Remove-WStoreApp $App $AllUsers $Prov } -ArgumentList @(@{ Name = $a.Name; Package = $a.Package; Provisioned = $a.Provisioned }, $canAdmin, $canAdmin)
                $removed += $a.Package
            } catch { Write-AWCli "  failed   $($a.Name): $($_.Exception.Message)" Red; $failed = $true }
        }
        if ($removed.Count) { Write-AWAction 'RemoveApps' $removed @{ AllUsers = $canAdmin } 'Done' }
        $result.Steps += [ordered]@{ Step = 'RemoveApps'; Items = @($sel | ForEach-Object Package); Removed = $removed }
    }

    # ---- finish: flush the activity log, write results
    $line = $null; $buf = New-Object System.Text.StringBuilder
    while ($Sync.Log.TryDequeue([ref]$line)) { [void]$buf.AppendLine($line) }
    try { [IO.File]::AppendAllText($script:LogFile, $buf.ToString()) } catch { }
    $code = if ($failed) { 1 } else { $healthCode }
    $result.ExitCode = $code; $result.Finished = (Get-Date).ToString('o')
    $json = ConvertTo-Json -InputObject $result -Depth 8
    if ($OutFile) {
        $of = $OutFile.Replace('{computer}', $env:COMPUTERNAME).Replace('{date}', (Get-Date -Format 'yyyyMMdd-HHmm'))
        try { $json | Set-Content -LiteralPath $of -Encoding UTF8 } catch { Write-Host "Could not write $($of): $($_.Exception.Message)" -ForegroundColor Red }
    }
    if ($Format -eq 'Json') { [Console]::Out.WriteLine($json) }
    $code
}

if ($script:CliMode) {
    # The automatic cleanup popup's button handlers call worker functions; load them at script level too so the
    # handlers find them whichever scope they run in.
    if ($AutoClean) { . ([scriptblock]::Create($Sync.WorkerLib)) }
    $code = Invoke-AWCli
    exit ([int](@($code)[-1]))
}
#endregion

#region ---------------------------------------------------------------- XAML
[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Computer Doctor" Width="1320" Height="840" MinWidth="1080" MinHeight="680"
        WindowStartupLocation="CenterScreen" Background="#0B0D12"
        FontFamily="Segoe UI" FontSize="13" Foreground="#E6E9F0"
        UseLayoutRounding="True" SnapsToDevicePixels="True">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="56" ResizeBorderThickness="6" GlassFrameThickness="0" CornerRadius="0" UseAeroCaptionButtons="False"/>
  </WindowChrome.WindowChrome>

  <Window.Resources>
    <SolidColorBrush x:Key="TextBrush"   Color="#E6E9F0"/>
    <SolidColorBrush x:Key="MutedBrush"  Color="#8C93A5"/>
    <SolidColorBrush x:Key="DimBrush"    Color="#5C6375"/>
    <SolidColorBrush x:Key="TealBrush"   Color="#60A5FA"/>
    <SolidColorBrush x:Key="PurpleBrush" Color="#38BDF8"/>
    <SolidColorBrush x:Key="LineBrush"   Color="#252A35"/>
    <SolidColorBrush x:Key="FieldBrush"  Color="#1A1E27"/>
    <SolidColorBrush x:Key="HoverBrush"  Color="#242A36"/>
    <SolidColorBrush x:Key="SelBrush"    Color="#1B2D50"/>
    <SolidColorBrush x:Key="TrackBrush"  Color="#262C38"/>
    <SolidColorBrush x:Key="DangerBrush" Color="#F87171"/>
    <SolidColorBrush x:Key="AmberBrush"  Color="#FBBF24"/>
    <SolidColorBrush x:Key="SuccessBrush" Color="#34D399"/>

    <LinearGradientBrush x:Key="TealGrad" StartPoint="0,0" EndPoint="1,0">
      <GradientStop Color="#2563EB" Offset="0"/><GradientStop Color="#3B82F6" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="PurpleGrad" StartPoint="0,0" EndPoint="1,0">
      <GradientStop Color="#0369A1" Offset="0"/><GradientStop Color="#0284C7" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="BrandGrad" StartPoint="0,0" EndPoint="1,0">
      <GradientStop Color="#93C5FD" Offset="0"/><GradientStop Color="#38BDF8" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="CardGrad" StartPoint="0,0" EndPoint="0,1">
      <GradientStop Color="#151922" Offset="0"/><GradientStop Color="#13161D" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="WindowGrad" StartPoint="0,0" EndPoint="1,1">
      <GradientStop Color="#0B0D12" Offset="0"/><GradientStop Color="#0B0D12" Offset="1"/>
    </LinearGradientBrush>

    <FontFamily x:Key="IconFont">Segoe Fluent Icons, Segoe MDL2 Assets</FontFamily>

    <!-- Text -->
    <Style x:Key="H1" TargetType="TextBlock">
      <Setter Property="FontSize" Value="24"/><Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style x:Key="H2" TargetType="TextBlock">
      <Setter Property="FontSize" Value="16"/><Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style x:Key="Muted" TargetType="TextBlock">
      <Setter Property="Foreground" Value="{StaticResource MutedBrush}"/><Setter Property="TextWrapping" Value="Wrap"/>
    </Style>
    <Style x:Key="Caps" TargetType="TextBlock">
      <Setter Property="Foreground" Value="{StaticResource DimBrush}"/><Setter Property="FontSize" Value="11"/>
      <Setter Property="FontWeight" Value="Bold"/><Setter Property="Margin" Value="0,14,0,6"/>
    </Style>
    <Style x:Key="Icon" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="{StaticResource IconFont}"/><Setter Property="VerticalAlignment" Value="Center"/>
    </Style>

    <!-- Card -->
    <Style x:Key="Card" TargetType="Border">
      <Setter Property="Background" Value="{StaticResource CardGrad}"/>
      <Setter Property="BorderBrush" Value="{StaticResource LineBrush}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="14"/>
      <Setter Property="Padding" Value="18"/>
    </Style>
    <Style x:Key="Pill" TargetType="Border">
      <Setter Property="CornerRadius" Value="10"/><Setter Property="Padding" Value="7,1"/>
      <Setter Property="Margin" Value="8,0,0,0"/><Setter Property="VerticalAlignment" Value="Center"/>
      <Setter Property="BorderThickness" Value="1"/>
    </Style>

    <!-- Buttons -->
    <Style x:Key="BtnBase" TargetType="Button">
      <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
      <Setter Property="Background" Value="#1A1E27"/>
      <Setter Property="BorderBrush" Value="#353C4B"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="16,8"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#3B82F6"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Opacity" Value="0.8"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="Button" BasedOn="{StaticResource BtnBase}"/>
    <Style x:Key="BtnAccent" TargetType="Button" BasedOn="{StaticResource BtnBase}">
      <Setter Property="Background" Value="{StaticResource TealGrad}"/>
      <Setter Property="BorderBrush" Value="Transparent"/>
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="Effect"><Setter.Value><DropShadowEffect Color="#3B82F6" BlurRadius="14" ShadowDepth="0" Opacity="0.25"/></Setter.Value></Setter>
    </Style>
    <Style x:Key="BtnPurple" TargetType="Button" BasedOn="{StaticResource BtnBase}">
      <Setter Property="Background" Value="{StaticResource PurpleGrad}"/>
      <Setter Property="BorderBrush" Value="Transparent"/>
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="Effect"><Setter.Value><DropShadowEffect Color="#38BDF8" BlurRadius="14" ShadowDepth="0" Opacity="0.2"/></Setter.Value></Setter>
    </Style>
    <Style x:Key="BtnOutline" TargetType="Button" BasedOn="{StaticResource BtnBase}">
      <Setter Property="BorderBrush" Value="#3B82F6"/>
    </Style>
    <Style x:Key="BtnChip" TargetType="Button" BasedOn="{StaticResource BtnBase}">
      <Setter Property="Padding" Value="12,5"/><Setter Property="Margin" Value="0,0,6,0"/><Setter Property="FontSize" Value="12"/>
    </Style>
    <Style x:Key="BtnIcon" TargetType="Button" BasedOn="{StaticResource BtnBase}">
      <Setter Property="Padding" Value="10,8"/><Setter Property="FontFamily" Value="{StaticResource IconFont}"/><Setter Property="FontSize" Value="14"/>
    </Style>

    <Style x:Key="CapBtn" TargetType="Button">
      <Setter Property="Width" Value="46"/><Setter Property="Height" Value="34"/>
      <Setter Property="Foreground" Value="{StaticResource MutedBrush}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="FontFamily" Value="{StaticResource IconFont}"/><Setter Property="FontSize" Value="10"/>
      <Setter Property="WindowChrome.IsHitTestVisibleInChrome" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Background="{TemplateBinding Background}" CornerRadius="8">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#242A36"/><Setter Property="Foreground" Value="White"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <Style x:Key="CapClose" TargetType="Button" BasedOn="{StaticResource CapBtn}">
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#E81123"/><Setter Property="Foreground" Value="White"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <!-- Sidebar navigation -->
    <Style x:Key="NavBtn" TargetType="RadioButton">
      <Setter Property="Foreground" Value="{StaticResource MutedBrush}"/>
      <Setter Property="FontSize" Value="13.5"/>
      <Setter Property="Margin" Value="0,2"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="GroupName" Value="Nav"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="Bd" CornerRadius="10" Padding="14,8" Background="Transparent">
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="{Binding Tag, RelativeSource={RelativeSource TemplatedParent}}" FontFamily="{StaticResource IconFont}"
                           FontSize="16" Width="22" VerticalAlignment="Center"/>
                <ContentPresenter Margin="10,0,0,0" VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#1A1E27"/><Setter Property="Foreground" Value="White"/>
              </Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="{StaticResource TealGrad}"/>
                <Setter Property="Foreground" Value="White"/><Setter Property="FontWeight" Value="SemiBold"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Rounded square checkbox -->
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Grid Background="Transparent">
              <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Border x:Name="Box" Width="18" Height="18" CornerRadius="5" BorderThickness="2" BorderBrush="#353C4B" Background="Transparent" VerticalAlignment="Center">
                <Path x:Name="Mark" Data="M 2.5,7 L 6,10.5 L 11.5,3.5" Stroke="White" StrokeThickness="2" Visibility="Collapsed"
                      StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round"/>
              </Border>
              <ContentPresenter Grid.Column="1" Margin="10,0,0,0" VerticalAlignment="Center"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Box" Property="Background" Value="{StaticResource TealGrad}"/>
                <Setter TargetName="Box" Property="BorderBrush" Value="#3B82F6"/>
                <Setter TargetName="Mark" Property="Visibility" Value="Visible"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Box" Property="BorderBrush" Value="#3B82F6"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- ON / OFF switch -->
    <Style x:Key="Switch" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Grid Width="58" Height="24">
              <Border x:Name="Track" CornerRadius="12" Background="#353C4B"/>
              <TextBlock x:Name="Lbl" Text="OFF" FontSize="9.5" FontWeight="Bold" Foreground="White"
                         VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,8,0"/>
              <Border x:Name="Knob" Width="20" Height="20" CornerRadius="10" Background="#E6E9F0" HorizontalAlignment="Left" Margin="2,0,0,0"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Track" Property="Background" Value="{StaticResource TealGrad}"/>
                <Setter TargetName="Lbl" Property="Text" Value="ON"/>
                <Setter TargetName="Lbl" Property="HorizontalAlignment" Value="Left"/>
                <Setter TargetName="Lbl" Property="Margin" Value="9,0,0,0"/>
                <Setter TargetName="Knob" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="Knob" Property="Margin" Value="0,0,2,0"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Progress bar -->
    <Style TargetType="ProgressBar">
      <Setter Property="Height" Value="8"/>
      <Setter Property="Foreground" Value="{StaticResource TealGrad}"/>
      <Setter Property="Background" Value="{StaticResource TrackBrush}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ProgressBar">
            <Grid>
              <Border x:Name="PART_Track" CornerRadius="4" Background="{TemplateBinding Background}"/>
              <Border x:Name="PART_Indicator" CornerRadius="4" Background="{TemplateBinding Foreground}" HorizontalAlignment="Left"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsIndeterminate" Value="True">
                <Setter TargetName="PART_Indicator" Property="HorizontalAlignment" Value="Stretch"/>
                <Trigger.EnterActions>
                  <BeginStoryboard x:Name="Pulse">
                    <Storyboard>
                      <DoubleAnimation Storyboard.TargetName="PART_Indicator" Storyboard.TargetProperty="Opacity"
                                       From="0.25" To="1" Duration="0:0:0.8" AutoReverse="True" RepeatBehavior="Forever"/>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.EnterActions>
                <Trigger.ExitActions><StopStoryboard BeginStoryboardName="Pulse"/></Trigger.ExitActions>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Text box with placeholder (Tag) -->
    <Style TargetType="TextBox">
      <Setter Property="Background" Value="{StaticResource FieldBrush}"/>
      <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
      <Setter Property="BorderBrush" Value="{StaticResource LineBrush}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="10,7"/>
      <Setter Property="CaretBrush" Value="White"/>
      <Setter Property="SelectionBrush" Value="#3B82F6"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TextBox">
            <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8">
              <Grid>
                <TextBlock x:Name="Ph" Text="{Binding Tag, RelativeSource={RelativeSource TemplatedParent}}" Foreground="{StaticResource DimBrush}"
                           Margin="{TemplateBinding Padding}" VerticalAlignment="Center" IsHitTestVisible="False" Visibility="Collapsed"/>
                <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="Text" Value=""><Setter TargetName="Ph" Property="Visibility" Value="Visible"/></Trigger>
              <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#3B82F6"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="PasswordBox">
      <Setter Property="Background" Value="{StaticResource FieldBrush}"/>
      <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
      <Setter Property="BorderBrush" Value="{StaticResource LineBrush}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="10,7"/>
      <Setter Property="CaretBrush" Value="White"/>
      <Setter Property="SelectionBrush" Value="#3B82F6"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="PasswordBox">
            <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8">
              <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#3B82F6"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Segmented choice (radio buttons that look like tabs) -->
    <Style x:Key="SegBtn" TargetType="RadioButton">
      <Setter Property="Foreground" Value="{StaticResource MutedBrush}"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="Bd" CornerRadius="8" Padding="12,8" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#242A36"/></Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="{StaticResource TealGrad}"/>
                <Setter Property="Foreground" Value="White"/><Setter Property="FontWeight" Value="SemiBold"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="LinkBtn" TargetType="Button">
      <Setter Property="Foreground" Value="{StaticResource TealBrush}"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <TextBlock x:Name="T" Text="{TemplateBinding Content}" Foreground="{TemplateBinding Foreground}"/>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="T" Property="TextDecorations" Value="Underline"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Slim scrollbars -->
    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="10"/><Setter Property="MinWidth" Value="10"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Track x:Name="PART_Track" IsDirectionReversed="True">
              <Track.Thumb>
                <Thumb>
                  <Thumb.Template>
                    <ControlTemplate TargetType="Thumb"><Border Background="#353C4B" CornerRadius="4" Margin="2"/></ControlTemplate>
                  </Thumb.Template>
                </Thumb>
              </Track.Thumb>
            </Track>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
      <Style.Triggers>
        <Trigger Property="Orientation" Value="Horizontal">
          <Setter Property="Width" Value="Auto"/><Setter Property="MinWidth" Value="0"/>
          <Setter Property="Height" Value="10"/><Setter Property="MinHeight" Value="10"/>
          <Setter Property="Template">
            <Setter.Value>
              <ControlTemplate TargetType="ScrollBar">
                <Track x:Name="PART_Track" IsDirectionReversed="False">
                  <Track.Thumb>
                    <Thumb>
                      <Thumb.Template>
                        <ControlTemplate TargetType="Thumb"><Border Background="#353C4B" CornerRadius="4" Margin="2"/></ControlTemplate>
                      </Thumb.Template>
                    </Thumb>
                  </Track.Thumb>
                </Track>
              </ControlTemplate>
            </Setter.Value>
          </Setter>
        </Trigger>
      </Style.Triggers>
    </Style>

    <!-- List views -->
    <Style TargetType="ListView">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
      <Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Auto"/>
      <Setter Property="VirtualizingStackPanel.IsVirtualizing" Value="True"/>
    </Style>
    <Style TargetType="ListViewItem">
      <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="Margin" Value="0,1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ListViewItem">
            <Border x:Name="Bd" Background="Transparent" CornerRadius="6" Padding="0,6">
              <GridViewRowPresenter VerticalAlignment="Center" Columns="{TemplateBinding GridView.ColumnCollection}" Content="{TemplateBinding Content}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#1A1E27"/></Trigger>
              <Trigger Property="IsSelected" Value="True"><Setter TargetName="Bd" Property="Background" Value="#1B2D50"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="GridViewColumnHeader">
      <Setter Property="Foreground" Value="{StaticResource MutedBrush}"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="HorizontalContentAlignment" Value="Left"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="GridViewColumnHeader">
            <Grid>
              <Border x:Name="Bd" Background="Transparent" BorderBrush="#252A35" BorderThickness="0,0,0,1" Padding="7,8">
                <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"/>
              </Border>
              <Thumb x:Name="PART_HeaderGripper" HorizontalAlignment="Right" Width="6" Cursor="SizeWE">
                <Thumb.Template><ControlTemplate TargetType="Thumb"><Border Background="Transparent"/></ControlTemplate></Thumb.Template>
              </Thumb>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter Property="Foreground" Value="White"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ListBox">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
      <Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Disabled"/>
    </Style>
    <Style TargetType="ListBoxItem">
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ListBoxItem">
            <Border x:Name="Bd" Background="Transparent" CornerRadius="6" Padding="6,4">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#1A1E27"/></Trigger>
              <Trigger Property="IsSelected" Value="True"><Setter TargetName="Bd" Property="Background" Value="#1B2D50"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="ToolTip">
      <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ToolTip">
            <Border Background="#1A1E27" BorderBrush="#353C4B" BorderThickness="1" CornerRadius="6" Padding="9,6" MaxWidth="420">
              <ContentPresenter>
                <ContentPresenter.Resources>
                  <Style TargetType="TextBlock"><Setter Property="TextWrapping" Value="Wrap"/></Style>
                </ContentPresenter.Resources>
              </ContentPresenter>
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="CtxMenu" TargetType="ContextMenu">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ContextMenu">
            <Border Background="#13161D" BorderBrush="#353C4B" BorderThickness="1" CornerRadius="8" Padding="4">
              <StackPanel IsItemsHost="True"/>
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ComboBox">
      <Setter Property="Foreground" Value="#E6E9F0"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Height" Value="32"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ComboBox">
            <Grid>
              <ToggleButton Focusable="False" ClickMode="Press" IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                <ToggleButton.Template>
                  <ControlTemplate TargetType="ToggleButton">
                    <Border x:Name="Bd" Background="#1A1E27" BorderBrush="#353C4B" BorderThickness="1" CornerRadius="8">
                      <TextBlock Text="&#x25BE;" Foreground="#8C93A5" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,10,0"/>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#3B82F6"/></Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </ToggleButton.Template>
              </ToggleButton>
              <ContentPresenter IsHitTestVisible="False" Content="{TemplateBinding SelectionBoxItem}" Margin="12,0,26,0" VerticalAlignment="Center" HorizontalAlignment="Left" TextElement.Foreground="#E6E9F0"/>
              <Popup IsOpen="{TemplateBinding IsDropDownOpen}" Placement="Bottom" AllowsTransparency="True" Focusable="False" PopupAnimation="Fade">
                <Border Background="#13161D" BorderBrush="#353C4B" BorderThickness="1" CornerRadius="8" Padding="4" Margin="0,4,0,0" MinWidth="{TemplateBinding ActualWidth}">
                  <ScrollViewer MaxHeight="320" VerticalScrollBarVisibility="Auto"><StackPanel IsItemsHost="True"/></ScrollViewer>
                </Border>
              </Popup>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ComboBoxItem">
      <Setter Property="Foreground" Value="#E6E9F0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ComboBoxItem">
            <Border x:Name="Bd" Background="Transparent" CornerRadius="6" Padding="10,6">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsHighlighted" Value="True"><Setter TargetName="Bd" Property="Background" Value="#1B2D50"/></Trigger>
              <Trigger Property="IsSelected" Value="True"><Setter Property="Foreground" Value="#60A5FA"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="CtxItem" TargetType="MenuItem">
      <Setter Property="Foreground" Value="#E6E9F0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="MenuItem">
            <Border x:Name="Bd" Background="Transparent" CornerRadius="6" Padding="12,7" MinWidth="170">
              <ContentPresenter ContentSource="Header" TextElement.Foreground="#E6E9F0"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsHighlighted" Value="True"><Setter TargetName="Bd" Property="Background" Value="#1B2D50"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border x:Name="RootBorder" Background="{StaticResource WindowGrad}">
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="56"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="34"/>
      </Grid.RowDefinitions>

      <!-- ================= Title bar ================= -->
      <Grid Grid.Row="0">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="244"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel Orientation="Horizontal" Margin="20,0,0,0" VerticalAlignment="Center">
          <Border Width="32" Height="32" CornerRadius="10" Background="{StaticResource TealGrad}">
            <TextBlock Text="&#xE945;" Style="{StaticResource Icon}" FontSize="16" Foreground="White" HorizontalAlignment="Center"/>
          </Border>
          <TextBlock Text="Computer Doctor" FontSize="17" FontWeight="Bold" Margin="9,0,0,0" VerticalAlignment="Center" Foreground="{StaticResource BrandGrad}"/>
          <TextBlock x:Name="VersionText" Text="v1.0" Foreground="{StaticResource DimBrush}" FontSize="11" Margin="7,6,0,0" VerticalAlignment="Center"/>
        </StackPanel>
        <TextBlock x:Name="ViewTitle" Grid.Column="1" Text="Dashboard" FontSize="15" FontWeight="SemiBold" Foreground="{StaticResource MutedBrush}"
                   VerticalAlignment="Center" Margin="14,0,0,0"/>
        <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,14,0">
          <Button x:Name="TargetBtn" Margin="0,0,10,0" Padding="11,5" FontSize="12" WindowChrome.IsHitTestVisibleInChrome="True"
                  ToolTip="Choose which computer Computer Doctor works on">
            <StackPanel Orientation="Horizontal">
              <TextBlock x:Name="TargetIcon" Text="&#xE7F4;" Style="{StaticResource Icon}" FontSize="12" Foreground="{StaticResource TealBrush}"/>
              <TextBlock x:Name="TargetText" Text="This PC" Margin="7,0,0,0"/>
              <TextBlock Text="&#xE70D;" Style="{StaticResource Icon}" FontSize="9" Margin="8,1,0,0" Foreground="{StaticResource MutedBrush}"/>
            </StackPanel>
          </Button>
          <Button x:Name="NetBtn" Margin="0,0,10,0" Padding="11,5" FontSize="12" WindowChrome.IsHitTestVisibleInChrome="True"
                  ToolTip="Internet status. Click to switch offline mode on or off.">
            <StackPanel Orientation="Horizontal">
              <TextBlock x:Name="NetIcon" Text="&#xE774;" Style="{StaticResource Icon}" FontSize="12" Foreground="{StaticResource MutedBrush}"/>
              <TextBlock x:Name="NetText" Text="Checking..." Margin="7,0,0,0"/>
            </StackPanel>
          </Button>
          <Border x:Name="AdminBadge" CornerRadius="13" Padding="11,5" BorderThickness="1" BorderBrush="#2563EB" Background="#1B2D50">
            <StackPanel Orientation="Horizontal">
              <TextBlock x:Name="AdminIcon" Text="&#xEA18;" Style="{StaticResource Icon}" FontSize="12" Foreground="{StaticResource TealBrush}"/>
              <TextBlock x:Name="AdminText" Text="Administrator" FontSize="12" FontWeight="SemiBold" Margin="7,0,0,0" Foreground="{StaticResource TealBrush}"/>
            </StackPanel>
          </Border>
          <Button x:Name="BtnElevate" Content="Restart as admin" Style="{StaticResource BtnPurple}" Padding="12,5" FontSize="12"
                  Margin="10,0,0,0" WindowChrome.IsHitTestVisibleInChrome="True" Visibility="Collapsed"/>
        </StackPanel>
        <StackPanel Grid.Column="3" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,10,0">
          <Button x:Name="BtnMin"   Style="{StaticResource CapBtn}"   Content="&#xE921;"/>
          <Button x:Name="BtnMax"   Style="{StaticResource CapBtn}"   Content="&#xE922;"/>
          <Button x:Name="BtnClose" Style="{StaticResource CapClose}" Content="&#xE8BB;"/>
        </StackPanel>
      </Grid>

      <!-- ================= Body ================= -->
      <Grid Grid.Row="1">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="244"/>
          <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Sidebar -->
        <Border Style="{StaticResource Card}" Margin="16,0,0,0" Padding="12">
          <DockPanel>
            <StackPanel DockPanel.Dock="Bottom" Margin="6,10,6,4">
              <TextBlock Text="SYSTEM DRIVE" Style="{StaticResource Caps}" Margin="0,0,0,6"/>
              <ProgressBar x:Name="SideDriveBar" Maximum="100" Value="0" Height="6"/>
              <TextBlock x:Name="SideDriveText" Text="" Foreground="{StaticResource MutedBrush}" FontSize="12" Margin="0,7,0,0"/>
            </StackPanel>
            <ScrollViewer VerticalScrollBarVisibility="Auto">
            <StackPanel>
              <TextBlock Text="MENU" Style="{StaticResource Caps}" Margin="8,4,0,6"/>
              <RadioButton x:Name="NavHome"     Style="{StaticResource NavBtn}" Tag="&#xE80F;" Content="Dashboard" IsChecked="True"/>
              <RadioButton x:Name="NavHealth"   Style="{StaticResource NavBtn}" Tag="&#xE95E;" Content="Health Check"/>
              <RadioButton x:Name="NavCleaner"  Style="{StaticResource NavBtn}" Tag="&#xE74D;" Content="Cleaner"/>
              <RadioButton x:Name="NavMap"      Style="{StaticResource NavBtn}" Tag="&#xEB05;" Content="Space Map"/>
              <RadioButton x:Name="NavLarge"    Style="{StaticResource NavBtn}" Tag="&#xE7C3;" Content="Large Files"/>
              <RadioButton x:Name="NavRecovery" Style="{StaticResource NavBtn}" Tag="&#xE81C;" Content="Recovery"/>
              <TextBlock Text="SYSTEM" Style="{StaticResource Caps}" Margin="8,16,0,6"/>
              <RadioButton x:Name="NavStartup"  Style="{StaticResource NavBtn}" Tag="&#xE7E8;" Content="Startup"/>
              <RadioButton x:Name="NavPrograms" Style="{StaticResource NavBtn}" Tag="&#xE71D;" Content="Programs"/>
              <RadioButton x:Name="NavDrivers"  Style="{StaticResource NavBtn}" Tag="&#xE772;" Content="Drivers"/>
              <RadioButton x:Name="NavBios"     Style="{StaticResource NavBtn}" Tag="&#xE950;" Content="BIOS"/>
              <RadioButton x:Name="NavAdmin"    Style="{StaticResource NavBtn}" Tag="&#xE7EF;" Content="IT Admin"/>
              <RadioButton x:Name="NavDebloat"  Style="{StaticResource NavBtn}" Tag="&#xE71C;" Content="Debloat"/>
              <RadioButton x:Name="NavRebloat"  Style="{StaticResource NavBtn}" Tag="&#xE896;" Content="Rebloat"/>
              <RadioButton x:Name="NavTools"    Style="{StaticResource NavBtn}" Tag="&#xE90F;" Content="Tools and Log"/>
            </StackPanel>
            </ScrollViewer>
          </DockPanel>
        </Border>

        <!-- Views -->
        <Grid Grid.Column="1" Margin="16,0,16,0">

          <!-- ===== Dashboard ===== -->
          <Grid x:Name="ViewHome">
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Border Style="{StaticResource Card}" Padding="24,22">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel>
                  <TextBlock Text="Keep this PC lean and fast" Style="{StaticResource H1}"/>
                  <TextBlock Text="Analyze junk files, map where your space went, and trim startup clutter. Nothing is removed until you review it." Style="{StaticResource Muted}" Margin="0,6,0,16" MaxWidth="560" HorizontalAlignment="Left"/>
                  <WrapPanel>
                    <Button x:Name="HomeQuick" Style="{StaticResource BtnAccent}" Margin="0,0,10,0">
                      <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE74D;" Style="{StaticResource Icon}" Margin="0,0,8,0"/><TextBlock Text="Analyze junk"/></StackPanel>
                    </Button>
                    <Button x:Name="HomeScan" Style="{StaticResource BtnPurple}" Margin="0,0,10,0">
                      <StackPanel Orientation="Horizontal"><TextBlock Text="&#xEB05;" Style="{StaticResource Icon}" Margin="0,0,8,0"/><TextBlock Text="Map system drive"/></StackPanel>
                    </Button>
                    <Button x:Name="HomeStartup" Style="{StaticResource BtnOutline}">
                      <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE7E8;" Style="{StaticResource Icon}" Margin="0,0,8,0"/><TextBlock Text="Review startup"/></StackPanel>
                    </Button>
                  </WrapPanel>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="24,0,0,0">
                  <StackPanel Margin="0,0,30,0">
                    <TextBlock Text="RECLAIMED" Style="{StaticResource Caps}" Margin="0"/>
                    <TextBlock x:Name="HomeFreed" Text="0 B" FontSize="28" FontWeight="Bold" Foreground="{StaticResource TealBrush}"/>
                    <TextBlock x:Name="HomeCleans" Text="0 cleans" Foreground="{StaticResource MutedBrush}" FontSize="12"/>
                  </StackPanel>
                  <StackPanel>
                    <TextBlock Text="LAST CLEAN" Style="{StaticResource Caps}" Margin="0"/>
                    <TextBlock x:Name="HomeLast" Text="Never" FontSize="28" FontWeight="Bold" Foreground="#38BDF8"/>
                    <TextBlock x:Name="HomeLastSub" Text="" Foreground="{StaticResource MutedBrush}" FontSize="12"/>
                  </StackPanel>
                </StackPanel>
              </Grid>
            </Border>
            <Grid Grid.Row="1" Margin="0,16,0,0">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="330"/></Grid.ColumnDefinitions>
              <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel>
                  <TextBlock Text="DRIVES" Style="{StaticResource Caps}" Margin="4,0,0,10"/>
                  <WrapPanel x:Name="DriveCards"/>
                </StackPanel>
              </ScrollViewer>
              <Border Grid.Column="1" Style="{StaticResource Card}" Margin="16,0,0,16" VerticalAlignment="Top">
                <StackPanel>
                  <TextBlock Text="This PC" Style="{StaticResource H2}"/>
                  <StackPanel x:Name="SysInfo" Margin="0,10,0,0"/>
                </StackPanel>
              </Border>
            </Grid>
          </Grid>

          <!-- ===== Health Check ===== -->
          <Grid x:Name="ViewHealth" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Background="{StaticResource FieldBrush}" CornerRadius="10" Padding="3" BorderBrush="{StaticResource LineBrush}" BorderThickness="1" HorizontalAlignment="Left">
              <StackPanel Orientation="Horizontal">
                <RadioButton x:Name="HTabChecks"  Style="{StaticResource SegBtn}" GroupName="HTab" IsChecked="True" Content="Checks" MinWidth="96"/>
                <RadioButton x:Name="HTabEvents"  Style="{StaticResource SegBtn}" GroupName="HTab" Content="Events" MinWidth="96"/>
                <RadioButton x:Name="HTabBoot"    Style="{StaticResource SegBtn}" GroupName="HTab" Content="Startup time" MinWidth="96"/>
                <RadioButton x:Name="HTabSec"     Style="{StaticResource SegBtn}" GroupName="HTab" Content="Security" MinWidth="96"/>
                <RadioButton x:Name="HTabPriv"    Style="{StaticResource SegBtn}" GroupName="HTab" Content="Privacy" MinWidth="96"/>
                <RadioButton x:Name="HTabCrash"   Style="{StaticResource SegBtn}" GroupName="HTab" Content="Crashes" MinWidth="96"/>
                <RadioButton x:Name="HTabSleep"   Style="{StaticResource SegBtn}" GroupName="HTab" Content="Sleep" MinWidth="96"/>
              </StackPanel>
            </Border>
            <Grid Grid.Row="1" Margin="0,14,0,16">

              <!-- Checks -->
              <Grid x:Name="HPanelChecks">
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                <Border Style="{StaticResource Card}" Padding="24,20">
                  <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <StackPanel>
                      <TextBlock x:Name="HealthTitle" Text="Health check" Style="{StaticResource H1}"/>
                      <TextBlock x:Name="HealthSummary" Text="Checks disks, crashes, hardware errors, devices, battery, antivirus and more. Read-only and works offline."
                                 Style="{StaticResource Muted}" Margin="0,6,0,12" MaxWidth="640" HorizontalAlignment="Left"/>
                      <WrapPanel x:Name="HealthCounts"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                      <Button x:Name="HealthSave" Content="Save report..." Style="{StaticResource BtnChip}" IsEnabled="False"/>
                      <Button x:Name="HealthRun" Style="{StaticResource BtnAccent}" Padding="20,10">
                        <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE95E;" Style="{StaticResource Icon}" Margin="0,0,8,0"/><TextBlock Text="Run health check"/></StackPanel>
                      </Button>
                    </StackPanel>
                  </Grid>
                </Border>
                <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,16,0,0" Padding="10,8">
                  <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel x:Name="HealthRows" Margin="4,0,8,0"/>
                  </ScrollViewer>
                </Border>
              </Grid>

              <!-- Events -->
              <Border x:Name="HPanelEvents" Style="{StaticResource Card}" Padding="14,12" Visibility="Collapsed">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,10">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBlock Text="What went wrong recently" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                    <Border Grid.Column="1" Background="{StaticResource FieldBrush}" CornerRadius="10" Padding="3" Margin="14,0,0,0" BorderBrush="{StaticResource LineBrush}" BorderThickness="1">
                      <StackPanel Orientation="Horizontal">
                        <RadioButton x:Name="EvtDays7"  Style="{StaticResource SegBtn}" GroupName="EvtDays" IsChecked="True" Content="7 days"/>
                        <RadioButton x:Name="EvtDays30" Style="{StaticResource SegBtn}" GroupName="EvtDays" Content="30 days"/>
                      </StackPanel>
                    </Border>
                    <TextBlock x:Name="EvtInfo" Grid.Column="2" Text="" Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="14,0" TextTrimming="CharacterEllipsis"/>
                    <StackPanel Grid.Column="3" Orientation="Horizontal" VerticalAlignment="Center">
                      <Button x:Name="EvtViewer" Content="Event Viewer" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="EvtBundle" Content="Create support bundle..." Style="{StaticResource BtnPurple}" Padding="14,6" FontSize="12"
                              ToolTip="Zips the last 7 days of System / Application logs, health and event reports, system info and the driver list - handy for a technician"/>
                    </StackPanel>
                  </Grid>
                  <TextBlock DockPanel.Dock="Bottom" Text="Hover a row for what it means and what to do. Security-log items (failed sign-ins) need administrator rights."
                             Style="{StaticResource Muted}" FontSize="11.5" Margin="6,8,6,0"/>
                  <ListView x:Name="EvtList">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="Severity" Width="90">
                          <GridViewColumn.CellTemplate><DataTemplate>
                            <TextBlock x:Name="S" Text="{Binding Severity}" FontWeight="SemiBold" Foreground="#8C93A5"/>
                            <DataTemplate.Triggers>
                              <DataTrigger Binding="{Binding Severity}" Value="Problem"><Setter TargetName="S" Property="Foreground" Value="#F87171"/></DataTrigger>
                              <DataTrigger Binding="{Binding Severity}" Value="Warning"><Setter TargetName="S" Property="Foreground" Value="#FBBF24"/></DataTrigger>
                            </DataTemplate.Triggers>
                          </DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="What happened" Width="230">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Title}" FontWeight="SemiBold" ToolTip="{Binding Why}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Times" Width="64">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Count}" TextAlignment="Right"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Last seen" Width="130" DisplayMemberBinding="{Binding LastText}"/>
                        <GridViewColumn Header="Details" Width="520">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Source}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Why}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>

              <!-- Startup time -->
              <Grid x:Name="HPanelBoot" Visibility="Collapsed">
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                <Border Style="{StaticResource Card}" Padding="20,16">
                  <DockPanel>
                    <Grid DockPanel.Dock="Top">
                      <StackPanel>
                        <TextBlock Text="How long Windows takes to start" Style="{StaticResource H2}"/>
                        <TextBlock x:Name="BootSummary" Text="" Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                      </StackPanel>
                      <Button x:Name="BootStartup" Content="Open Startup manager" Style="{StaticResource BtnChip}" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0"/>
                    </Grid>
                    <Canvas x:Name="BootChart" Height="150" Margin="0,14,0,0" ClipToBounds="True"/>
                  </DockPanel>
                </Border>
                <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,16,0,0" Padding="14,12">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="What slowed startup (last 60 days)" Style="{StaticResource H2}" Margin="2,0,0,8"/>
                    <ListView x:Name="BootList">
                      <ListView.View>
                        <GridView>
                          <GridViewColumn Header="Type" Width="80" DisplayMemberBinding="{Binding Kind}"/>
                          <GridViewColumn Header="Name" Width="320">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding File}"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                          <GridViewColumn Header="Times" Width="64" DisplayMemberBinding="{Binding Times}"/>
                          <GridViewColumn Header="Average delay" Width="120">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding DelayText}" Foreground="#FBBF24" FontWeight="SemiBold"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                          <GridViewColumn Header="Last seen" Width="140" DisplayMemberBinding="{Binding LastText}"/>
                        </GridView>
                      </ListView.View>
                    </ListView>
                  </DockPanel>
                </Border>
              </Grid>

              <!-- Security -->
              <Border x:Name="HPanelSec" Style="{StaticResource Card}" Padding="14,12" Visibility="Collapsed">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,10">
                    <StackPanel>
                      <TextBlock Text="Security checks" Style="{StaticResource H2}"/>
                      <TextBlock x:Name="SecInfo" Text="" Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                      <Button x:Name="SecRefresh" Content="Refresh" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="SecFix" Content="Fix checked" Style="{StaticResource BtnAccent}" Padding="14,6" FontSize="12"/>
                    </StackPanel>
                  </Grid>
                  <TextBlock DockPanel.Dock="Bottom" Style="{StaticResource Muted}" FontSize="11.5" Margin="6,8,6,0" TextWrapping="Wrap"
                             Text="Only safe, reversible fixes can be checked - each one goes into the undo history (Rebloat). Items marked policy are set by your organization's Group Policy, which overwrites local changes."/>
                  <ListView x:Name="SecList">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="" Width="44">
                          <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsChecked, Mode=TwoWay}" IsEnabled="{Binding CanFix}" Margin="4,0,0,0"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Status" Width="90">
                          <GridViewColumn.CellTemplate><DataTemplate>
                            <TextBlock x:Name="S" Text="{Binding StatusText}" FontWeight="SemiBold" Foreground="#8C93A5"/>
                            <DataTemplate.Triggers>
                              <DataTrigger Binding="{Binding Status}" Value="Good"><Setter TargetName="S" Property="Foreground" Value="#34D399"/></DataTrigger>
                              <DataTrigger Binding="{Binding Status}" Value="Warning"><Setter TargetName="S" Property="Foreground" Value="#FBBF24"/></DataTrigger>
                              <DataTrigger Binding="{Binding Status}" Value="Problem"><Setter TargetName="S" Property="Foreground" Value="#F87171"/></DataTrigger>
                            </DataTemplate.Triggers>
                          </DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Check" Width="220">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Details" Width="560">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Detail}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Detail}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="" Width="70">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding PolicyText}" Foreground="#FBBF24" FontSize="11"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>

              <!-- Crashes (blue screens) -->
              <Border x:Name="HPanelCrash" Style="{StaticResource Card}" Padding="14,12" Visibility="Collapsed">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,10">
                    <StackPanel>
                      <TextBlock Text="Blue screens" Style="{StaticResource H2}"/>
                      <TextBlock x:Name="CrashInfo" Text="" Style="{StaticResource Muted}" Margin="0,4,0,0" TextWrapping="Wrap"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                      <Button x:Name="CrashFolder" Content="Open dump folder" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="CrashFix" Content="Do suggested fix" Style="{StaticResource BtnAccent}" Padding="14,6" FontSize="12"/>
                    </StackPanel>
                  </Grid>
                  <ListView x:Name="CrashList">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="When" Width="140" DisplayMemberBinding="{Binding WhenText}"/>
                        <GridViewColumn Header="Code" Width="100" DisplayMemberBinding="{Binding Code}"/>
                        <GridViewColumn Header="Error" Width="260">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding Parameters}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="What it usually means" Width="420">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Meaning}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Meaning}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Suggested" Width="150">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding FixText}" Foreground="#60A5FA"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Source" Width="240">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Source}" Foreground="#5C6375" TextTrimming="CharacterEllipsis" ToolTip="{Binding Source}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>

              <!-- Sleep and wake -->
              <Grid x:Name="HPanelSleep" Visibility="Collapsed">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                <Border Style="{StaticResource Card}" Padding="14,12">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="What woke this PC" Style="{StaticResource H2}" Margin="2,0,0,4"/>
                    <TextBlock x:Name="SleepInfo" DockPanel.Dock="Top" Text="" Style="{StaticResource Muted}" FontSize="12" Margin="2,0,0,8" TextWrapping="Wrap"/>
                    <ListView x:Name="SleepWakes">
                      <ListView.View>
                        <GridView>
                          <GridViewColumn Header="When" Width="140" DisplayMemberBinding="{Binding WhenText}"/>
                          <GridViewColumn Header="Woken by" Width="340">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" TextTrimming="CharacterEllipsis" ToolTip="{Binding Name}"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                        </GridView>
                      </ListView.View>
                    </ListView>
                  </DockPanel>
                </Border>
                <Border Grid.Column="1" Style="{StaticResource Card}" Margin="16,0,0,0" Padding="14,12">
                  <DockPanel>
                    <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                      <TextBlock Text="Devices that can wake it" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                      <Button x:Name="SleepNoWake" Content="Stop this one waking it" Style="{StaticResource BtnChip}" HorizontalAlignment="Right" Margin="0"/>
                    </Grid>
                    <ListBox x:Name="SleepArmed"/>
                  </DockPanel>
                </Border>
                <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,16,0,0" Padding="14,12">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Keeping it awake right now" Style="{StaticResource H2}" Margin="2,0,0,8"/>
                    <ListView x:Name="SleepReq">
                      <ListView.View>
                        <GridView>
                          <GridViewColumn Header="Blocks" Width="110" DisplayMemberBinding="{Binding Kind}"/>
                          <GridViewColumn Header="Requested by" Width="380">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" TextTrimming="CharacterEllipsis" ToolTip="{Binding Name}"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                        </GridView>
                      </ListView.View>
                    </ListView>
                  </DockPanel>
                </Border>
                <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource Card}" Margin="16,16,0,0" Padding="14,12">
                  <StackPanel>
                    <TextBlock Text="Sleep states and timers" Style="{StaticResource H2}"/>
                    <TextBlock x:Name="SleepStates" Text="" TextWrapping="Wrap" Margin="0,8,0,0" FontSize="12.5"/>
                    <TextBlock x:Name="SleepTimers" Text="" Style="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,8,0,0" FontSize="12"/>
                    <WrapPanel Margin="0,12,0,0">
                      <Button x:Name="SleepRefresh" Content="Refresh" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="SleepStudy" Content="Sleep study report" Style="{StaticResource BtnChip}" ToolTip="powercfg /sleepstudy - battery drain during Modern Standby (laptops)"/>
                      <Button x:Name="SleepBattery" Content="Battery report" Style="{StaticResource BtnChip}" Margin="0"/>
                    </WrapPanel>
                  </StackPanel>
                </Border>
              </Grid>

              <!-- Privacy -->
              <Grid x:Name="HPanelPriv" Visibility="Collapsed">
                <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                <Border Style="{StaticResource Card}" Padding="14,12">
                  <DockPanel>
                    <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                      <StackPanel>
                        <TextBlock Text="Which apps used your camera, microphone or location" Style="{StaticResource H2}"/>
                        <TextBlock x:Name="PrivInfo" Text="" Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                      </StackPanel>
                      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                        <Button x:Name="PrivRefresh" Content="Refresh" Style="{StaticResource BtnChip}"/>
                        <Button x:Name="PrivSettings" Content="Privacy settings" Style="{StaticResource BtnChip}" Margin="0"/>
                      </StackPanel>
                    </Grid>
                    <ListView x:Name="PrivList">
                      <ListView.View>
                        <GridView>
                          <GridViewColumn Header="Used" Width="100" DisplayMemberBinding="{Binding Capability}"/>
                          <GridViewColumn Header="App" Width="460">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding App}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding App}"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                          <GridViewColumn Header="Last used" Width="150" DisplayMemberBinding="{Binding LastText}"/>
                          <GridViewColumn Header="" Width="90">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding NowText}" Foreground="#F87171" FontWeight="Bold"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                        </GridView>
                      </ListView.View>
                    </ListView>
                  </DockPanel>
                </Border>
                <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,16,0,0" Padding="14,12">
                  <DockPanel>
                    <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                      <StackPanel>
                        <TextBlock Text="Adware and hijack sweep" Style="{StaticResource H2}"/>
                        <TextBlock x:Name="PupInfo" Text="" Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                      </StackPanel>
                      <Button x:Name="PupOpen" Content="Open location" Style="{StaticResource BtnChip}" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0"/>
                    </Grid>
                    <ListView x:Name="PupList">
                      <ListView.View>
                        <GridView>
                          <GridViewColumn Header="Found" Width="130" DisplayMemberBinding="{Binding Kind}"/>
                          <GridViewColumn Header="Item" Width="280">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Item}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding Item}"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                          <GridViewColumn Header="Details" Width="560">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Detail}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Detail}"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                        </GridView>
                      </ListView.View>
                    </ListView>
                  </DockPanel>
                </Border>
              </Grid>
            </Grid>
          </Grid>
          <!-- ===== Cleaner ===== -->
          <Grid x:Name="ViewCleaner" Visibility="Collapsed">
            <Grid.ColumnDefinitions><ColumnDefinition Width="330"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Border Style="{StaticResource Card}" Margin="0,0,0,16" Padding="16,14">
              <DockPanel>
                <Grid DockPanel.Dock="Top">
                  <TextBlock Text="Cleaning rules" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                  <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button x:Name="RulesDefault" Content="Defaults" Style="{StaticResource BtnChip}"/>
                    <Button x:Name="RulesAll" Content="All" Style="{StaticResource BtnChip}"/>
                    <Button x:Name="RulesNone" Content="None" Style="{StaticResource BtnChip}" Margin="0"/>
                  </StackPanel>
                </Grid>
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,6,0,0">
                  <StackPanel x:Name="CleanerItems" Margin="2,0,8,0"/>
                </ScrollViewer>
              </DockPanel>
            </Border>
            <Grid Grid.Column="1" Margin="16,0,0,0">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
              </Grid.RowDefinitions>
              <Border Style="{StaticResource Card}" Padding="24,20">
                <Grid>
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                  <StackPanel>
                    <TextBlock x:Name="CleanSummary" Text="Ready to analyze" FontSize="30" FontWeight="Bold"/>
                    <TextBlock x:Name="CleanSubtext" Text="Pick the rules on the left, then Analyze to see what can be removed." Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                  </StackPanel>
                  <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button x:Name="BtnAdminReport" Content="Report for an administrator" Margin="0,0,10,0" Padding="14,10" Visibility="Collapsed"
                            ToolTip="A page listing the cleanups that need administrator rights, with short steps for someone who has them"/>
                    <Button x:Name="BtnAnalyze" Margin="0,0,10,0" Padding="20,10">
                      <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE721;" Style="{StaticResource Icon}" Margin="0,0,8,0"/><TextBlock Text="Analyze"/></StackPanel>
                    </Button>
                    <Button x:Name="BtnClean" Style="{StaticResource BtnAccent}" Padding="20,10">
                      <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE74D;" Style="{StaticResource Icon}" Margin="0,0,8,0"/><TextBlock Text="Run Cleaner"/></StackPanel>
                    </Button>
                  </StackPanel>
                  <ProgressBar x:Name="CleanProgress" Grid.Row="1" Grid.ColumnSpan="2" Margin="0,18,0,0" Maximum="100" Value="0"/>
                  <StackPanel x:Name="AdminReportBar" Grid.Row="2" Grid.ColumnSpan="2" Orientation="Horizontal" Margin="0,12,0,0" Visibility="Collapsed">
                    <Button x:Name="BtnAdminReportCopy" Content="Copy as text" Style="{StaticResource BtnChip}" Visibility="Collapsed"/>
                    <TextBlock x:Name="AdminReportInfo" Text="" Style="{StaticResource Muted}" FontSize="12" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                  </StackPanel>
                </Grid>
              </Border>
              <!-- Automatic cleanup: a scheduled task for this account, running only rules that don't need admin -->
              <Border x:Name="AcCard" Grid.Row="1" Style="{StaticResource Card}" Margin="0,16,0,0" Padding="20,14">
                <StackPanel>
                  <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <StackPanel VerticalAlignment="Center">
                      <TextBlock Text="Automatic cleanup" FontSize="15" FontWeight="SemiBold"/>
                      <TextBlock x:Name="AcSummary" Text="" Style="{StaticResource Muted}" FontSize="12" Margin="0,2,0,0" TextWrapping="Wrap"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                      <Button x:Name="AcMore" Content="Settings" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="AcRunNow" Content="Run now" Style="{StaticResource BtnChip}"/>
                    </StackPanel>
                    <CheckBox x:Name="AcOn" Grid.Column="2" Style="{StaticResource Switch}" VerticalAlignment="Center" Margin="8,0,0,0"
                              ToolTip="Cleans the rules you choose on a schedule, for your account only (no administrator rights needed)"/>
                  </Grid>
                  <StackPanel x:Name="AcDetails" Visibility="Collapsed" Margin="0,12,0,0">
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="Run" VerticalAlignment="Center" Margin="0,0,8,0"/>
                      <ComboBox x:Name="AcDay" Width="130">
                        <ComboBoxItem Content="Daily"/><ComboBoxItem Content="Monday"/><ComboBoxItem Content="Tuesday"/><ComboBoxItem Content="Wednesday"/>
                        <ComboBoxItem Content="Thursday"/><ComboBoxItem Content="Friday"/><ComboBoxItem Content="Saturday"/><ComboBoxItem Content="Sunday"/>
                      </ComboBox>
                      <TextBlock Text="at" VerticalAlignment="Center" Margin="8,0"/>
                      <TextBox x:Name="AcTime" Width="70" Text="12:00" ToolTip="HH:mm"/>
                    </StackPanel>
                    <TextBlock Text="RULES" Style="{StaticResource Caps}" Margin="0,12,0,4"/>
                    <WrapPanel x:Name="AcRules"/>
                    <TextBlock Text="Runs as you while you're signed in; a missed run catches up when the PC is next on. Apps that are open are skipped and you're asked to close them. Rules that need administrator rights can't run automatically."
                               Style="{StaticResource Muted}" FontSize="11.5" Margin="0,8,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                  <TextBlock x:Name="AcRemoteNote" Visibility="Collapsed" Style="{StaticResource Muted}" FontSize="12" Margin="0,6,0,0" TextWrapping="Wrap"
                             Text="Automatic cleanup is for this PC. Switch back to this PC (title bar) to set it up."/>
                </StackPanel>
              </Border>
              <Border Grid.Row="2" Style="{StaticResource Card}" Margin="0,16,0,16" Padding="12,10">
                <DockPanel>
                  <TextBlock DockPanel.Dock="Bottom" Text="Browser history, cookies, sessions and saved passwords are never touched. Items marked ADMIN need an elevated session." Style="{StaticResource Muted}" FontSize="11.5" Margin="8,8,8,2"/>
                  <ListView x:Name="CleanResults">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="Item" Width="230">
                          <GridViewColumn.CellTemplate><DataTemplate>
                            <StackPanel Orientation="Horizontal">
                              <Ellipse Width="8" Height="8" Fill="{Binding Dot}" Margin="2,0,10,0" VerticalAlignment="Center"/>
                              <TextBlock Text="{Binding Name}" FontWeight="SemiBold"/>
                            </StackPanel>
                          </DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Group" Width="110" DisplayMemberBinding="{Binding Group}"/>
                        <GridViewColumn Header="Files" Width="90">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Files}" TextAlignment="Right"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Size" Width="100">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Size}" TextAlignment="Right" Foreground="#60A5FA" FontWeight="SemiBold"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Details" Width="380">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Note}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>
            </Grid>
          </Grid>

          <!-- ===== Space Map ===== -->
          <Grid x:Name="ViewMap" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Style="{StaticResource Card}" Padding="12">
              <StackPanel>
              <Border x:Name="MapScope" Visibility="Collapsed" Background="#1B2D50" BorderBrush="#3B82F6" BorderThickness="1" CornerRadius="8" Padding="12,6" Margin="0,0,0,10">
                <Grid>
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <TextBlock x:Name="MapScopeText" Text="" VerticalAlignment="Center" TextWrapping="Wrap" FontWeight="SemiBold"/>
                  <StackPanel Grid.Column="1" Orientation="Horizontal" Margin="12,0,0,0">
                    <RadioButton x:Name="MapOnRemote" Style="{StaticResource SegBtn}" GroupName="MapOn" IsChecked="True" Content="Remote PC"/>
                    <RadioButton x:Name="MapOnLocal"  Style="{StaticResource SegBtn}" GroupName="MapOn" Content="This PC"/>
                  </StackPanel>
                </Grid>
              </Border>
              <Grid>
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="Auto"/>
                  <ColumnDefinition Width="*"/>
                  <ColumnDefinition Width="Auto"/>
                  <ColumnDefinition Width="Auto"/>
                  <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Button x:Name="MapUp" Style="{StaticResource BtnIcon}" Content="&#xE74A;" ToolTip="Up one level" Margin="0,0,8,0"/>
                <TextBox x:Name="MapPath" Grid.Column="1" Tag="Folder or drive to scan, e.g. C:\" Margin="0,0,8,0"/>
                <Button x:Name="MapBrowse" Grid.Column="2" Style="{StaticResource BtnIcon}" Content="&#xE838;" ToolTip="Browse for a folder" Margin="0,0,12,0"/>
                <WrapPanel x:Name="MapDrives" Grid.Column="3" VerticalAlignment="Center" Margin="0,0,6,0"/>
                <StackPanel Grid.Column="4" Orientation="Horizontal">
                  <Button x:Name="MapScan" Style="{StaticResource BtnAccent}" Content="Scan" Padding="22,8" Margin="0,0,8,0"/>
                  <Button x:Name="MapStop" Content="Stop" IsEnabled="False"/>
                </StackPanel>
              </Grid>
              </StackPanel>
            </Border>
            <Grid Grid.Row="1" Margin="0,16,0,16">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="310"/></Grid.ColumnDefinitions>
              <Border Style="{StaticResource Card}" Padding="12">
                <Grid>
                  <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                  <Grid Margin="4,0,4,10">
                    <TextBlock x:Name="MapCrumb" Text="No scan yet" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" Margin="0,0,140,0"/>
                    <TextBlock x:Name="MapCurSize" Text="" HorizontalAlignment="Right" Foreground="{StaticResource TealBrush}" FontWeight="Bold"/>
                  </Grid>
                  <Border Grid.Row="1" CornerRadius="10" Background="#0F1218" ClipToBounds="True">
                    <Grid>
                      <Canvas x:Name="MapCanvas" Background="Transparent" ClipToBounds="True"/>
                      <StackPanel x:Name="MapHint" HorizontalAlignment="Center" VerticalAlignment="Center">
                        <TextBlock Text="&#xEB05;" Style="{StaticResource Icon}" FontSize="46" Foreground="#2C3341" HorizontalAlignment="Center"/>
                        <TextBlock Text="Pick a drive or folder and press Scan" Foreground="{StaticResource MutedBrush}" Margin="0,12,0,0" HorizontalAlignment="Center"/>
                        <TextBlock Text="Double-click a folder to zoom in, right-click for actions" Foreground="{StaticResource DimBrush}" FontSize="12" Margin="0,4,0,0" HorizontalAlignment="Center"/>
                      </StackPanel>
                    </Grid>
                  </Border>
                  <Grid Grid.Row="2" Margin="4,10,0,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <WrapPanel VerticalAlignment="Center">
                      <StackPanel Orientation="Horizontal" Margin="0,2">
                        <Border Width="12" Height="12" CornerRadius="3" Background="{StaticResource PurpleGrad}"/>
                        <TextBlock Text="Folders" Foreground="{StaticResource MutedBrush}" FontSize="12" Margin="6,0,16,0"/>
                        <Border Width="12" Height="12" CornerRadius="3" Background="{StaticResource TealGrad}"/>
                        <TextBlock Text="Files (1 MB+)" Foreground="{StaticResource MutedBrush}" FontSize="12" Margin="6,0,16,0"/>
                        <Border Width="12" Height="12" CornerRadius="3" Background="#2C3341"/>
                        <TextBlock Text="Small files, grouped" Foreground="{StaticResource MutedBrush}" FontSize="12" Margin="6,0,16,0"/>
                      </StackPanel>
                      <StackPanel x:Name="MapHlLegend" Orientation="Horizontal" Margin="0,2" Visibility="Collapsed">
                        <Border Width="12" Height="12" CornerRadius="3" Background="#166534" BorderBrush="#4ADE80" BorderThickness="2"/>
                        <TextBlock Text="You can clean" Foreground="{StaticResource MutedBrush}" FontSize="12" Margin="6,0,16,0"/>
                        <Border Width="12" Height="12" CornerRadius="3" Background="#7F1D1D" BorderBrush="#F87171" BorderThickness="2"/>
                        <TextBlock Text="Your account can't delete" Foreground="{StaticResource MutedBrush}" FontSize="12" Margin="6,0,0,0"/>
                      </StackPanel>
                    </WrapPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="12,0,0,0">
                      <TextBlock x:Name="MapHlNote" Text="Highlighting works on this PC only" Foreground="{StaticResource DimBrush}" FontSize="12" VerticalAlignment="Center" Margin="0,0,10,0" Visibility="Collapsed"/>
                      <TextBlock Text="Highlight what you can clean" Foreground="{StaticResource MutedBrush}" FontSize="12" VerticalAlignment="Center" Margin="0,0,8,0"/>
                      <CheckBox x:Name="MapHighlight" Style="{StaticResource Switch}" IsChecked="True"
                                ToolTip="Green: junk a cleaner rule removes, or old installers in Downloads. Red: folders your account can't delete."/>
                    </StackPanel>
                  </Grid>
                </Grid>
              </Border>
              <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto" Margin="16,0,0,0">
                <StackPanel>
                  <Border Style="{StaticResource Card}">
                    <StackPanel>
                      <TextBlock Text="SELECTED" Style="{StaticResource Caps}" Margin="0,0,0,6"/>
                      <TextBlock x:Name="MapSelName" Text="Nothing selected" FontSize="15" FontWeight="SemiBold" TextWrapping="Wrap"/>
                      <TextBlock x:Name="MapSelPath" Text="" Style="{StaticResource Muted}" FontSize="11.5" Margin="0,3,0,0"/>
                      <TextBlock x:Name="MapSelSize" Text="" FontSize="26" FontWeight="Bold" Foreground="{StaticResource TealBrush}" Margin="0,10,0,0"/>
                      <TextBlock x:Name="MapSelMeta" Text="" Style="{StaticResource Muted}" FontSize="12"/>
                      <TextBlock x:Name="MapSelReason" Text="" FontSize="12" FontWeight="SemiBold" TextWrapping="Wrap" Margin="0,6,0,0" Visibility="Collapsed"/>
                      <WrapPanel Margin="0,12,0,0">
                        <Button x:Name="MapOpenCleaner" Content="Open Cleaner" Style="{StaticResource BtnChip}" Visibility="Collapsed"/>
                        <Button x:Name="MapOpen" Content="Open" Style="{StaticResource BtnChip}" IsEnabled="False"/>
                        <Button x:Name="MapZoom" Content="Zoom in" Style="{StaticResource BtnChip}" IsEnabled="False"/>
                        <Button x:Name="MapRecycle" Content="Recycle" Style="{StaticResource BtnChip}" IsEnabled="False" BorderBrush="#F87171"/>
                      </WrapPanel>
                      <TextBlock x:Name="MapDenied" Text="" Foreground="#F87171" FontSize="12" TextWrapping="Wrap" Margin="0,10,0,0" Visibility="Collapsed"/>
                    </StackPanel>
                  </Border>
                  <Border Style="{StaticResource Card}" Margin="0,14,0,0">
                    <StackPanel>
                      <TextBlock Text="LARGEST HERE" Style="{StaticResource Caps}" Margin="0,0,0,6"/>
                      <ListBox x:Name="MapTopList">
                        <ListBox.ItemTemplate>
                          <DataTemplate>
                            <Grid>
                              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                              <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                              <TextBlock Text="{Binding Name}" TextTrimming="CharacterEllipsis"/>
                              <TextBlock Grid.Column="1" Text="{Binding SizeText}" Foreground="#8C93A5" Margin="8,0,0,0"/>
                              <ProgressBar Grid.Row="1" Grid.ColumnSpan="2" Height="4" Margin="0,5,0,2" Maximum="100" Value="{Binding PercentOfParent, Mode=OneWay}"/>
                            </Grid>
                          </DataTemplate>
                        </ListBox.ItemTemplate>
                      </ListBox>
                    </StackPanel>
                  </Border>
                  <Border Style="{StaticResource Card}" Margin="0,14,0,0">
                    <StackPanel>
                      <TextBlock Text="BY KIND" Style="{StaticResource Caps}" Margin="0,0,0,6"/>
                      <ItemsControl x:Name="MapKindList">
                        <ItemsControl.ItemTemplate>
                          <DataTemplate>
                            <Grid Margin="0,4" ToolTip="{Binding PercentText}">
                              <Grid.ColumnDefinitions><ColumnDefinition Width="86"/><ColumnDefinition Width="*"/><ColumnDefinition Width="72"/></Grid.ColumnDefinitions>
                              <TextBlock Text="{Binding Extension}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                              <ProgressBar Grid.Column="1" Height="6" Maximum="100" Value="{Binding RelPercent, Mode=OneWay}" Foreground="{StaticResource TealGrad}" Margin="4,0,8,0"/>
                              <TextBlock Grid.Column="2" Text="{Binding SizeText}" Foreground="#8C93A5" TextAlignment="Right"/>
                            </Grid>
                          </DataTemplate>
                        </ItemsControl.ItemTemplate>
                      </ItemsControl>
                    </StackPanel>
                  </Border>
                  <Border Style="{StaticResource Card}" Margin="0,14,0,0">
                    <StackPanel>
                      <TextBlock Text="FILE TYPES" Style="{StaticResource Caps}" Margin="0,0,0,6"/>
                      <ItemsControl x:Name="MapExtList">
                        <ItemsControl.ItemTemplate>
                          <DataTemplate>
                            <Grid Margin="0,4">
                              <Grid.ColumnDefinitions><ColumnDefinition Width="62"/><ColumnDefinition Width="*"/><ColumnDefinition Width="72"/></Grid.ColumnDefinitions>
                              <TextBlock Text="{Binding Extension}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                              <ProgressBar Grid.Column="1" Height="6" Maximum="100" Value="{Binding RelPercent, Mode=OneWay}" Foreground="{StaticResource PurpleGrad}" Margin="4,0,8,0"/>
                              <TextBlock Grid.Column="2" Text="{Binding SizeText}" Foreground="#8C93A5" TextAlignment="Right"/>
                            </Grid>
                          </DataTemplate>
                        </ItemsControl.ItemTemplate>
                      </ItemsControl>
                    </StackPanel>
                  </Border>
                </StackPanel>
              </ScrollViewer>
            </Grid>
          </Grid>

          <!-- ===== Large Files ===== -->
          <Grid x:Name="ViewLarge" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Style="{StaticResource Card}" Padding="6" Margin="0,0,0,14">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <StackPanel Orientation="Horizontal">
                  <RadioButton x:Name="LTabLargest" Style="{StaticResource SegBtn}" GroupName="LTab" IsChecked="True" Content="Largest" MinWidth="100"/>
                  <RadioButton x:Name="LTabOld"     Style="{StaticResource SegBtn}" GroupName="LTab" Content="Old files" MinWidth="100"/>
                  <RadioButton x:Name="LTabDupes"   Style="{StaticResource SegBtn}" GroupName="LTab" Content="Duplicates" MinWidth="100"/>
                </StackPanel>
                <StackPanel x:Name="OldBar" Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right" Visibility="Collapsed" Margin="0,0,6,0">
                  <Button x:Name="OldFolders" Content="Folders: Downloads  &#x25BE;" Style="{StaticResource BtnChip}" MaxWidth="260" ToolTip="Which of your folders to look in">
                    <Button.ContextMenu><ContextMenu Style="{StaticResource CtxMenu}"/></Button.ContextMenu>
                  </Button>
                  <ComboBox x:Name="OldDays" Width="165" SelectedIndex="1" ToolTip="Not modified or opened since">
                    <ComboBoxItem Content="Unused 30+ days" Tag="30"/><ComboBoxItem Content="Unused 90+ days" Tag="90"/><ComboBoxItem Content="Unused 6+ months" Tag="182"/><ComboBoxItem Content="Unused 1+ year" Tag="365"/><ComboBoxItem Content="Unused 2+ years" Tag="730"/>
                  </ComboBox>
                  <ComboBox x:Name="OldMin" Width="110" SelectedIndex="1" Margin="8,0,0,0" ToolTip="Smallest file to list">
                    <ComboBoxItem Content="Any size" Tag="0"/><ComboBoxItem Content="1 MB+" Tag="1048576"/><ComboBoxItem Content="10 MB+" Tag="10485760"/><ComboBoxItem Content="100 MB+" Tag="104857600"/>
                  </ComboBox>
                  <ComboBox x:Name="OldKind" Width="120" SelectedIndex="0" Margin="8,0,0,0" ToolTip="Show only one kind of file">
                    <ComboBoxItem Content="All kinds"/><ComboBoxItem Content="Installer"/><ComboBoxItem Content="Disk image"/><ComboBoxItem Content="Archive"/><ComboBoxItem Content="Video"/><ComboBoxItem Content="Picture"/><ComboBoxItem Content="Music"/><ComboBoxItem Content="Document"/><ComboBoxItem Content="Code"/><ComboBoxItem Content="Other"/>
                  </ComboBox>
                  <Button x:Name="OldFind" Content="Find old files" Style="{StaticResource BtnPurple}" Padding="14,6" FontSize="12" Margin="8,0,0,0"/>
                </StackPanel>
                <StackPanel x:Name="DupeBar" Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right" Visibility="Collapsed" Margin="0,0,6,0">
                  <TextBox x:Name="DupePath" Width="230" Tag="Folder to search" Padding="8,6"/>
                  <Button x:Name="DupeBrowse" Content="Browse" Style="{StaticResource BtnChip}"/>
                  <Border Background="#14FFFFFF" CornerRadius="8" Padding="3" Margin="4,0">
                    <StackPanel Orientation="Horizontal">
                      <RadioButton x:Name="DupeExact"   Style="{StaticResource SegBtn}" GroupName="DupeMode" IsChecked="True" Content="Exact copies"/>
                      <RadioButton x:Name="DupePhotos"  Style="{StaticResource SegBtn}" GroupName="DupeMode" Content="Similar photos"/>
                    </StackPanel>
                  </Border>
                  <Button x:Name="DupeFind" Content="Find duplicates" Style="{StaticResource BtnPurple}" Padding="14,6" FontSize="12" Margin="4,0,0,0"/>
                  <Button x:Name="DupeStop" Content="Stop" Style="{StaticResource BtnChip}" IsEnabled="False"/>
                </StackPanel>
              </Grid>
            </Border>
            <Border Grid.Row="1" Style="{StaticResource Card}" Padding="14,12">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="320"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <Grid>
                  <TextBox x:Name="LargeSearch" Tag="Search by name, folder or extension..." Padding="10,7,44,7"/>
                  <Border HorizontalAlignment="Right" Width="38" Margin="0,1,1,1" CornerRadius="0,7,7,0" Background="{StaticResource TealGrad}" IsHitTestVisible="False">
                    <TextBlock Text="&#xE721;" Style="{StaticResource Icon}" HorizontalAlignment="Center" Foreground="White"/>
                  </Border>
                </Grid>
                <TextBlock x:Name="LargeInfo" Grid.Column="1" Text="Run a scan in Space Map to list the largest files." Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="16,0"/>
                <StackPanel Grid.Column="2" Orientation="Horizontal">
                  <Button x:Name="LargeScan" Content="Scan a drive" Style="{StaticResource BtnChip}"/>
                  <Button x:Name="DupeKeep" Content="Tick extra copies" Style="{StaticResource BtnChip}" Visibility="Collapsed" ToolTip="In every group, keeps the newest copy unticked and ticks the rest"/>
                  <Button x:Name="LargeOpen" Content="Open location" Style="{StaticResource BtnChip}"/>
                  <Button x:Name="LargeExport" Content="Export CSV" Style="{StaticResource BtnChip}"/>
                  <Button x:Name="LargeRecycle" Content="Recycle checked" Style="{StaticResource BtnPurple}" Padding="14,6" FontSize="12"/>
                </StackPanel>
              </Grid>
            </Border>
            <Border Grid.Row="2" Style="{StaticResource Card}" Margin="0,16,0,16" Padding="12,10">
              <ListView x:Name="LargeList">
                <ListView.View>
                  <GridView>
                    <GridViewColumn Header="" Width="44">
                      <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsChecked, Mode=TwoWay}" Margin="4,0,0,0"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Name" Width="280">
                      <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Size" Width="100">
                      <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding SizeText}" TextAlignment="Right" Foreground="#60A5FA" FontWeight="SemiBold"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Type" Width="70" DisplayMemberBinding="{Binding Extension}"/>
                    <GridViewColumn Header="Modified" Width="130" DisplayMemberBinding="{Binding ModifiedText}"/>
                    <GridViewColumn x:Name="LargeStatusCol" Header="Group" Width="0">
                      <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Status}" Foreground="#7DD3FC" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Folder" Width="460">
                      <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Folder}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                  </GridView>
                </ListView.View>
              </ListView>
            </Border>
          </Grid>

          <!-- ===== Recovery ===== -->
          <Grid x:Name="ViewRecovery" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Style="{StaticResource Card}" Padding="20,16">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel>
                  <TextBlock Text="Recover deleted files" Style="{StaticResource H2}"/>
                  <TextBlock Text="Check the Recycle Bin and previous versions first. For a deep scan, stop using the drive and save what you recover to a different drive."
                             Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                </StackPanel>
                <Border Grid.Column="1" Background="{StaticResource FieldBrush}" CornerRadius="10" Padding="3" Margin="16,0,0,0"
                        BorderBrush="{StaticResource LineBrush}" BorderThickness="1" VerticalAlignment="Center">
                  <StackPanel Orientation="Horizontal">
                    <RadioButton x:Name="RecTabBin"    Style="{StaticResource SegBtn}" GroupName="RecTab" IsChecked="True" Content="Recycle Bin"/>
                    <RadioButton x:Name="RecTabShadow" Style="{StaticResource SegBtn}" GroupName="RecTab" Content="Previous versions"/>
                    <RadioButton x:Name="RecTabUndel"  Style="{StaticResource SegBtn}" GroupName="RecTab" Content="Undelete"/>
                    <RadioButton x:Name="RecTabRP"     Style="{StaticResource SegBtn}" GroupName="RecTab" Content="Restore points"/>
                    <RadioButton x:Name="RecTabBackup" Style="{StaticResource SegBtn}" GroupName="RecTab" Content="Backup"/>
                    <RadioButton x:Name="RecTabDeep"   Style="{StaticResource SegBtn}" GroupName="RecTab" Content="Deep scan"/>
                    <RadioButton x:Name="RecTabReady"  Style="{StaticResource SegBtn}" GroupName="RecTab" Content="Readiness" ToolTip="If this PC won't start tomorrow, can you get it back?"/>
                  </StackPanel>
                </Border>
              </Grid>
            </Border>

            <ScrollViewer Grid.Row="1" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Disabled" Margin="0,14,0,0">
              <StackPanel x:Name="RecDrives" Orientation="Horizontal"/>
            </ScrollViewer>

            <Grid Grid.Row="2" Margin="0,14,0,16">
              <!-- Readiness: can this PC be recovered? -->
              <Border x:Name="RecPanelReady" Style="{StaticResource Card}" Padding="18,14" Visibility="Collapsed">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <StackPanel>
                      <TextBlock Text="If this PC won't start tomorrow, can you get it back?" Style="{StaticResource H2}"/>
                      <TextBlock x:Name="ReadyInfo" Text="Checks the BitLocker recovery key, Secure Boot certificates, the recovery environment, restore points and backups." Style="{StaticResource Muted}" Margin="0,4,0,0" TextWrapping="Wrap"/>
                    </StackPanel>
                    <Button x:Name="ReadyRefresh" Grid.Column="1" Content="Check again" Style="{StaticResource BtnChip}" VerticalAlignment="Center" Margin="0"/>
                  </Grid>
                  <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel x:Name="ReadyRows"/>
                  </ScrollViewer>
                </DockPanel>
              </Border>
              <!-- Recycle Bin -->
              <Border x:Name="RecPanelBin" Style="{StaticResource Card}" Padding="14,12">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="300"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox x:Name="BinSearch" Tag="Search by name or original location..."/>
                    <TextBlock x:Name="BinInfo" Grid.Column="1" Text="" Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="14,0"/>
                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                      <Button x:Name="BinRefresh" Content="Refresh" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="BinOpen" Content="Open original folder" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="BinRestoreTo" Content="Restore to..." Style="{StaticResource BtnChip}"/>
                      <Button x:Name="BinRestore" Content="Restore checked" Style="{StaticResource BtnAccent}" Padding="14,6" FontSize="12"/>
                    </StackPanel>
                  </Grid>
                  <TextBlock DockPanel.Dock="Bottom" Style="{StaticResource Muted}" FontSize="11.5" Margin="8,8,8,2"
                             Text="Items go back to where they were deleted from. If something already exists there, the restored copy gets &quot;(restored)&quot; added to its name - nothing is overwritten."/>
                  <ListView x:Name="BinList">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="" Width="44">
                          <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsChecked, Mode=TwoWay}" Margin="4,0,0,0"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Name" Width="230">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding OriginalPath}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Type" Width="64" DisplayMemberBinding="{Binding Kind}"/>
                        <GridViewColumn Header="Size" Width="90">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding SizeText}" TextAlignment="Right" Foreground="#60A5FA" FontWeight="SemiBold"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Deleted" Width="130" DisplayMemberBinding="{Binding DeletedText}"/>
                        <GridViewColumn Header="Deleted by" Width="150">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Owner}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Original location" Width="420">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Folder}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Folder}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>

              <!-- Previous versions (shadow copies) -->
              <Grid x:Name="RecPanelShadow" Visibility="Collapsed">
                <Grid.ColumnDefinitions><ColumnDefinition Width="320"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <Border Style="{StaticResource Card}" Padding="14,12">
                  <DockPanel>
                    <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                      <TextBlock Text="Snapshots" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                      <Button x:Name="ShadowRefresh" Content="Refresh" Style="{StaticResource BtnChip}" HorizontalAlignment="Right" Margin="0"/>
                    </Grid>
                    <StackPanel DockPanel.Dock="Bottom" Margin="0,10,0,0">
                      <TextBlock x:Name="ShadowNote" Text="" Style="{StaticResource Muted}" FontSize="11.5" Margin="0,0,0,10"/>
                      <WrapPanel>
                        <Button x:Name="ShadowExplore" Content="Open in Explorer" Style="{StaticResource BtnChip}"/>
                        <Button x:Name="ShadowProtect" Content="System Protection settings" Style="{StaticResource BtnChip}" Margin="0"/>
                      </WrapPanel>
                    </StackPanel>
                    <ListBox x:Name="ShadowList">
                      <ListBox.ItemTemplate>
                        <DataTemplate>
                          <StackPanel Margin="2,3">
                            <StackPanel Orientation="Horizontal">
                              <TextBlock Text="{Binding Drive}" FontWeight="Bold" Foreground="#60A5FA" Width="30"/>
                              <TextBlock Text="{Binding CreatedText}" FontWeight="SemiBold"/>
                            </StackPanel>
                            <TextBlock Text="{Binding Age}" Foreground="#8C93A5" FontSize="11.5" Margin="30,2,0,0"/>
                          </StackPanel>
                        </DataTemplate>
                      </ListBox.ItemTemplate>
                    </ListBox>
                  </DockPanel>
                </Border>
                <Border Grid.Column="1" Style="{StaticResource Card}" Margin="16,0,0,0" Padding="14,12">
                  <DockPanel>
                    <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                      <TextBox x:Name="ShadowFolder" Tag="Folder to check, e.g. C:\Users\you\Documents"/>
                      <CheckBox x:Name="ShadowChanged" Grid.Column="1" Content="Include changed files" Margin="12,0"/>
                      <Button x:Name="ShadowFind" Grid.Column="2" Content="Find deleted files" Style="{StaticResource BtnAccent}" Padding="14,6" FontSize="12"/>
                    </Grid>
                    <Grid DockPanel.Dock="Bottom" Margin="0,10,0,0">
                      <TextBlock x:Name="ShadowInfo" Text="Pick a snapshot, enter a folder, and Computer Doctor lists files that existed then but are gone now."
                                 Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="4,0,280,0"/>
                      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button x:Name="ShadowCopyTo" Content="Copy checked to..." Style="{StaticResource BtnChip}"/>
                        <Button x:Name="ShadowRestore" Content="Restore checked" Style="{StaticResource BtnAccent}" Padding="14,6" FontSize="12"/>
                      </StackPanel>
                    </Grid>
                    <ListView x:Name="ShadowResults">
                      <ListView.View>
                        <GridView>
                          <GridViewColumn Header="" Width="44">
                            <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsChecked, Mode=TwoWay}" Margin="4,0,0,0"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                          <GridViewColumn Header="Name" Width="220">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                          <GridViewColumn Header="Status" Width="80" DisplayMemberBinding="{Binding Status}"/>
                          <GridViewColumn Header="Size" Width="90">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding SizeText}" TextAlignment="Right" Foreground="#60A5FA"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                          <GridViewColumn Header="Modified" Width="130" DisplayMemberBinding="{Binding ModifiedText}"/>
                          <GridViewColumn Header="Folder" Width="380">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Folder}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Folder}"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                        </GridView>
                      </ListView.View>
                    </ListView>
                  </DockPanel>
                </Border>
              </Grid>

              <!-- Undelete (native NTFS file-table scan) -->
              <Border x:Name="RecPanelUndel" Style="{StaticResource Card}" Padding="14,12" Visibility="Collapsed">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,10">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <WrapPanel x:Name="UndelSources" VerticalAlignment="Center"/>
                    <TextBlock x:Name="UndelStatus" Grid.Column="1" Text="" Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="8,0,12,0"/>
                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                      <Button x:Name="UndelImage" Content="Scan an image file..." Style="{StaticResource BtnChip}"
                              ToolTip="Scan a raw NTFS volume image (.img / .dd / .bin), for example one made from a failing drive"/>
                      <Button x:Name="UndelStop" Content="Stop" Style="{StaticResource BtnChip}" IsEnabled="False"/>
                      <Button x:Name="UndelScan" Style="{StaticResource BtnAccent}" Padding="16,7" FontSize="12">
                        <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE721;" Style="{StaticResource Icon}" Margin="0,0,8,0"/><TextBlock Text="Scan for deleted files"/></StackPanel>
                      </Button>
                    </StackPanel>
                  </Grid>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="300"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <TextBox x:Name="UndelSearch" Tag="Filter by name or folder..."/>
                    <CheckBox x:Name="UndelLikely" Grid.Column="1" Content="Only files that look recoverable" IsChecked="True" Margin="14,0,0,0"/>
                    <TextBlock x:Name="UndelInfo" Grid.Column="2" Text="" Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="14,0,0,0" TextTrimming="CharacterEllipsis"/>
                  </Grid>
                  <Grid DockPanel.Dock="Bottom" Margin="0,10,0,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBlock Text="SAVE TO" Style="{StaticResource Caps}" Margin="4,0,10,0" VerticalAlignment="Center"/>
                    <TextBox x:Name="UndelDest" Grid.Column="1" Tag="A folder on a different drive, e.g. E:\Recovered"/>
                    <Button x:Name="UndelBrowse" Grid.Column="2" Style="{StaticResource BtnIcon}" Content="&#xE838;" ToolTip="Browse" Margin="8,0,10,0"/>
                    <Button x:Name="UndelRecover" Grid.Column="3" Content="Recover checked" Style="{StaticResource BtnAccent}" Padding="14,6" FontSize="12"/>
                  </Grid>
                  <TextBlock x:Name="UndelDestMsg" DockPanel.Dock="Bottom" Text="" Foreground="{StaticResource DangerBrush}" FontSize="12" Margin="4,8,0,0" TextWrapping="Wrap" Visibility="Collapsed"/>
                  <ListView x:Name="UndelList">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="" Width="44">
                          <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsChecked, Mode=TwoWay}" Margin="4,0,0,0"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Name" Width="220">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding FullPath}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Chance" Width="100">
                          <GridViewColumn.CellTemplate><DataTemplate>
                            <TextBlock x:Name="Ch" Text="{Binding Chance}" FontWeight="SemiBold" Foreground="#FBBF24"/>
                            <DataTemplate.Triggers>
                              <DataTrigger Binding="{Binding Chance}" Value="Excellent"><Setter TargetName="Ch" Property="Foreground" Value="#34D399"/></DataTrigger>
                              <DataTrigger Binding="{Binding Chance}" Value="Good"><Setter TargetName="Ch" Property="Foreground" Value="#34D399"/></DataTrigger>
                              <DataTrigger Binding="{Binding Chance}" Value="Overwritten"><Setter TargetName="Ch" Property="Foreground" Value="#F87171"/></DataTrigger>
                              <DataTrigger Binding="{Binding Chance}" Value="Empty"><Setter TargetName="Ch" Property="Foreground" Value="#5C6375"/></DataTrigger>
                              <DataTrigger Binding="{Binding Chance}" Value="Not supported"><Setter TargetName="Ch" Property="Foreground" Value="#5C6375"/></DataTrigger>
                            </DataTemplate.Triggers>
                          </DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Size" Width="90">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding SizeText}" TextAlignment="Right"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Modified" Width="130" DisplayMemberBinding="{Binding ModifiedText}"/>
                        <GridViewColumn Header="Original folder" Width="330">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Folder}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Folder}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Notes" Width="220">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Note}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Note}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>

              <!-- Restore points -->
              <Grid x:Name="RecPanelRP" Visibility="Collapsed">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="340"/></Grid.ColumnDefinitions>
                <Border Style="{StaticResource Card}" Padding="14,12">
                  <DockPanel>
                    <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                      <TextBlock Text="Restore points" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button x:Name="RPRefresh" Content="Refresh" Style="{StaticResource BtnChip}"/>
                        <Button x:Name="RPOpen" Content="Open System Restore" Style="{StaticResource BtnChip}" Margin="0"
                                ToolTip="Windows' own wizard for rolling the PC back to a restore point"/>
                      </StackPanel>
                    </Grid>
                    <Grid DockPanel.Dock="Bottom" Margin="0,10,0,0">
                      <TextBlock x:Name="RPInfo" Text="" Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="4,0,160,0"/>
                      <Button x:Name="RPDelete" Content="Delete selected" Style="{StaticResource BtnPurple}" Padding="14,6" FontSize="12" HorizontalAlignment="Right"/>
                    </Grid>
                    <ListView x:Name="RPList" SelectionMode="Extended">
                      <ListView.View>
                        <GridView>
                          <GridViewColumn Header="Created" Width="170" DisplayMemberBinding="{Binding CreatedText}"/>
                          <GridViewColumn Header="Description" Width="330">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Description}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding Description}"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                          <GridViewColumn Header="Type" Width="150">
                            <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding TypeText}" Foreground="#8C93A5"/></DataTemplate></GridViewColumn.CellTemplate>
                          </GridViewColumn>
                          <GridViewColumn Header="#" Width="60" DisplayMemberBinding="{Binding Sequence}"/>
                        </GridView>
                      </ListView.View>
                    </ListView>
                  </DockPanel>
                </Border>
                <Border Grid.Column="1" Style="{StaticResource Card}" Margin="16,0,0,0" Padding="18,14">
                  <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="0,0,6,0">
                      <TextBlock Text="New restore point" Style="{StaticResource H2}"/>
                      <TextBox x:Name="RPDesc" Tag="Description, e.g. Before installing drivers" Margin="0,10,0,8"/>
                      <Button x:Name="RPCreate" Content="Create restore point" Style="{StaticResource BtnAccent}" Padding="14,6" FontSize="12" HorizontalAlignment="Left"/>
                      <TextBlock Text="Computer Doctor works around Windows' one-per-24-hours limit for restore points you create here."
                                 Style="{StaticResource Muted}" FontSize="11.5" Margin="0,8,0,0"/>

                      <TextBlock Text="PROTECTION" Style="{StaticResource Caps}" Margin="0,18,0,6"/>
                      <TextBlock x:Name="RPProtect" Text="" TextWrapping="Wrap" FontSize="12.5"/>
                      <Button x:Name="RPEnable" Content="Turn on for system drive" Style="{StaticResource BtnChip}" HorizontalAlignment="Left" Margin="0,8,0,0" Visibility="Collapsed"/>

                      <TextBlock Text="SPACE FOR RESTORE POINTS" Style="{StaticResource Caps}" Margin="0,18,0,6"/>
                      <TextBlock x:Name="RPStorage" Text="" TextWrapping="Wrap" FontSize="12.5"/>
                      <WrapPanel Margin="0,8,0,0">
                        <Button x:Name="RPSize5"  Content="5%"  Style="{StaticResource BtnChip}" Tag="5"/>
                        <Button x:Name="RPSize10" Content="10%" Style="{StaticResource BtnChip}" Tag="10"/>
                        <Button x:Name="RPSize15" Content="15%" Style="{StaticResource BtnChip}" Tag="15"/>
                      </WrapPanel>

                      <TextBlock Text="SAFETY NET" Style="{StaticResource Caps}" Margin="0,18,0,6"/>
                      <CheckBox x:Name="RPAuto" Content="Create one automatically before removing apps or applying tweaks"/>
                    </StackPanel>
                  </ScrollViewer>
                </Border>
              </Grid>

              <!-- Folder backup -->
              <Grid x:Name="RecPanelBackup" Visibility="Collapsed">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="360"/></Grid.ColumnDefinitions>
                <Border Style="{StaticResource Card}" Padding="14,12">
                  <DockPanel>
                    <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                      <StackPanel>
                        <TextBlock Text="Folders to back up" Style="{StaticResource H2}"/>
                        <TextBlock Text="Copied to the backup drive and kept in sync. Files you change or delete keep their older versions there." Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                      </StackPanel>
                    </Grid>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,10,0,0">
                      <Button x:Name="BkAddMine" Content="Add my folders" Style="{StaticResource BtnChip}" ToolTip="Documents, Pictures, Desktop, Videos and Music"/>
                      <Button x:Name="BkAdd" Content="Add folder..." Style="{StaticResource BtnChip}"/>
                      <Button x:Name="BkRemove" Content="Remove" Style="{StaticResource BtnChip}"/>
                    </WrapPanel>
                    <ListBox x:Name="BkSources"/>
                  </DockPanel>
                </Border>
                <Border Grid.Column="1" Style="{StaticResource Card}" Margin="16,0,0,0" Padding="18,14">
                  <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="0,0,6,0">
                      <TextBlock Text="BACKUP DRIVE" Style="{StaticResource Caps}" Margin="0,0,0,6"/>
                      <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <TextBox x:Name="BkDest" IsReadOnly="True" Tag="Choose a folder on an external drive"/>
                        <Button x:Name="BkBrowse" Grid.Column="1" Style="{StaticResource BtnIcon}" Content="&#xE838;" ToolTip="Choose" Margin="8,0,0,0"/>
                      </Grid>
                      <TextBlock x:Name="BkDestInfo" Text="" TextWrapping="Wrap" FontSize="12" Margin="2,6,0,0"/>

                      <TextBlock Text="OLDER VERSIONS" Style="{StaticResource Caps}"/>
                      <StackPanel Orientation="Horizontal">
                        <TextBlock Text="Keep the last" VerticalAlignment="Center" Margin="0,0,8,0"/>
                        <TextBox x:Name="BkKeep" Width="56" Text="10"/>
                        <TextBlock Text="backup runs' changes" VerticalAlignment="Center" Margin="8,0,0,0"/>
                      </StackPanel>

                      <TextBlock Text="SCHEDULE" Style="{StaticResource Caps}"/>
                      <StackPanel Orientation="Horizontal">
                        <CheckBox x:Name="BkDaily" Content="Back up every day at" VerticalAlignment="Center"/>
                        <TextBox x:Name="BkTime" Width="70" Text="19:00" Margin="8,0,0,0"/>
                      </StackPanel>
                      <TextBlock Text="Runs while you're signed in; a missed run catches up when the PC is next on. The drive just needs to be connected."
                                 Style="{StaticResource Muted}" FontSize="11.5" Margin="0,6,0,0"/>

                      <TextBlock x:Name="BkLast" Text="" Style="{StaticResource Muted}" FontSize="12" Margin="0,16,0,0" TextWrapping="Wrap"/>
                      <WrapPanel Margin="0,12,0,0">
                        <Button x:Name="BkSave" Content="Save settings" Style="{StaticResource BtnChip}"/>
                        <Button x:Name="BkRun" Content="Back up now" Style="{StaticResource BtnAccent}" Padding="16,7" FontSize="12" Margin="0,0,8,0"/>
                        <Button x:Name="BkOpen" Content="Open backup" Style="{StaticResource BtnChip}" Margin="0"/>
                      </WrapPanel>
                    </StackPanel>
                  </ScrollViewer>
                </Border>
              </Grid>

              <!-- Deep scan (Windows File Recovery) -->
              <Grid x:Name="RecPanelDeep" Visibility="Collapsed">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="330"/></Grid.ColumnDefinitions>
                <Border Style="{StaticResource Card}" Padding="18,14">
                  <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="0,0,8,0">
                      <Border x:Name="WinfrBox" CornerRadius="8" Padding="12,9" Background="#0F2E25" BorderBrush="#1F7A5C" BorderThickness="1">
                        <Grid>
                          <TextBlock x:Name="WinfrStatus" Text="Checking for Windows File Recovery..." TextWrapping="Wrap" FontSize="12.5" VerticalAlignment="Center" Margin="0,0,200,0"/>
                          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                            <Button x:Name="WinfrInstall" Content="Install" Style="{StaticResource BtnChip}" Visibility="Collapsed"/>
                            <Button x:Name="WinfrStore" Content="Microsoft Store" Style="{StaticResource BtnChip}" Margin="0" Visibility="Collapsed"/>
                          </StackPanel>
                        </Grid>
                      </Border>

                      <TextBlock Text="SCAN THIS DRIVE" Style="{StaticResource Caps}"/>
                      <WrapPanel x:Name="DeepSources"/>

                      <TextBlock Text="SAVE RECOVERED FILES TO" Style="{StaticResource Caps}"/>
                      <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <TextBox x:Name="DeepDest" Tag="A folder on a different drive, e.g. E:\Recovered"/>
                        <Button x:Name="DeepBrowse" Grid.Column="1" Style="{StaticResource BtnIcon}" Content="&#xE838;" ToolTip="Browse" Margin="8,0,0,0"/>
                      </Grid>
                      <TextBlock x:Name="DeepDestMsg" Text="" FontSize="12" Margin="2,6,0,0" TextWrapping="Wrap" Visibility="Collapsed"/>

                      <TextBlock Text="MODE" Style="{StaticResource Caps}"/>
                      <Border Background="{StaticResource FieldBrush}" CornerRadius="10" Padding="3" BorderBrush="{StaticResource LineBrush}" BorderThickness="1" HorizontalAlignment="Left">
                        <StackPanel Orientation="Horizontal">
                          <RadioButton x:Name="DeepRegular"   Style="{StaticResource SegBtn}" GroupName="DeepMode" IsChecked="True" Content="Regular" MinWidth="110"/>
                          <RadioButton x:Name="DeepExtensive" Style="{StaticResource SegBtn}" GroupName="DeepMode" Content="Extensive" MinWidth="110"/>
                        </StackPanel>
                      </Border>
                      <TextBlock x:Name="DeepModeHint" Text="" Style="{StaticResource Muted}" FontSize="12" Margin="2,6,0,0"/>

                      <TextBlock Text="WHAT TO LOOK FOR" Style="{StaticResource Caps}"/>
                      <TextBox x:Name="DeepFilter" Tag="e.g.  \Users\andre\Documents\ ;  *.jpg ;  budget*.xlsx"/>
                      <TextBlock Text="Folders end with \ and are relative to the drive. Separate several with ;. Leave empty to recover everything found (can be a lot)."
                                 Style="{StaticResource Muted}" FontSize="12" Margin="2,6,0,0"/>

                      <TextBlock Text="COMMAND" Style="{StaticResource Caps}"/>
                      <TextBox x:Name="DeepCmd" IsReadOnly="True" FontFamily="Cascadia Mono, Consolas" FontSize="12" TextWrapping="Wrap"/>

                      <StackPanel Orientation="Horizontal" Margin="0,16,0,4">
                        <Button x:Name="DeepStart" Style="{StaticResource BtnAccent}" Margin="0,0,10,0">
                          <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE81C;" Style="{StaticResource Icon}" Margin="0,0,8,0"/><TextBlock Text="Start recovery"/></StackPanel>
                        </Button>
                        <Button x:Name="DeepStop" Content="Stop" IsEnabled="False" Margin="0,0,10,0"/>
                        <Button x:Name="DeepOpenDest" Content="Open destination"/>
                      </StackPanel>
                    </StackPanel>
                  </ScrollViewer>
                </Border>
                <Border Grid.Column="1" Style="{StaticResource Card}" Margin="16,0,0,0" Padding="18,14">
                  <StackPanel>
                    <TextBlock Text="Before you start" Style="{StaticResource H2}"/>
                    <Border x:Name="DeepVerdictBox" CornerRadius="8" Padding="12,9" Margin="0,12,0,4" BorderThickness="1" Visibility="Collapsed">
                      <TextBlock x:Name="DeepVerdict" TextWrapping="Wrap" FontSize="12.5"/>
                    </Border>
                    <TextBlock Style="{StaticResource Muted}" FontSize="12.5" Margin="0,10,0,0" LineHeight="20">
                      <Run Text="1.  Stop using the drive. Every file written can overwrite what you want back."/><LineBreak/>
                      <Run Text="2.  Save recovered files to a different drive - Computer Doctor will not let you pick the same one."/><LineBreak/>
                      <Run Text="3.  Try Regular mode first for files deleted recently from an NTFS drive. Use Extensive for USB sticks, SD cards, formatted drives or older deletions."/><LineBreak/>
                      <Run Text="4.  Internal SSDs usually erase deleted data within minutes (TRIM), so deep scans there rarely find anything. Check the Recycle Bin and previous versions first."/><LineBreak/>
                      <Run Text="5.  If the drive clicks, disconnects or shows read errors, stop and have it imaged before trying again."/>
                    </TextBlock>
                    <TextBlock Text="Deep scan uses Microsoft's free Windows File Recovery tool. Results land in a Recovery_date folder inside the destination."
                               Style="{StaticResource Muted}" FontSize="11.5" Margin="0,14,0,0"/>
                  </StackPanel>
                </Border>
              </Grid>
            </Grid>
          </Grid>

          <!-- ===== Startup ===== -->
          <Grid x:Name="ViewStartup" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Style="{StaticResource Card}" Padding="6" Margin="0,0,0,14" HorizontalAlignment="Left">
              <StackPanel Orientation="Horizontal">
                <RadioButton x:Name="STabStartup" Style="{StaticResource SegBtn}" GroupName="STab" IsChecked="True" Content="Startup" MinWidth="110"/>
                <RadioButton x:Name="STabMenu"    Style="{StaticResource SegBtn}" GroupName="STab" Content="Right-click menu" MinWidth="130"/>
              </StackPanel>
            </Border>
            <Border Grid.Row="1" Style="{StaticResource Card}" Padding="20,16">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel>
                  <TextBlock x:Name="StartupTitle" Text="Startup programs" Style="{StaticResource H2}"/>
                  <TextBlock x:Name="StartupInfo" Text="Disabled items stay installed, they just won't launch when you sign in. Uses the same switches as Task Manager." Style="{StaticResource Muted}" Margin="0,4,0,0" TextWrapping="Wrap"/>
                </StackPanel>
                <StackPanel x:Name="StartupButtons" Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                  <Button x:Name="StartupOpen" Content="Open file location" Style="{StaticResource BtnChip}"/>
                  <Button x:Name="StartupRefresh" Content="Refresh" Style="{StaticResource BtnChip}" Margin="0"/>
                </StackPanel>
                <StackPanel x:Name="MenuButtons" Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Visibility="Collapsed">
                  <CheckBox x:Name="MenuShowMs" Content="Show Microsoft entries" VerticalAlignment="Center" Margin="0,0,12,0"/>
                  <Button x:Name="MenuOpen" Content="Open file location" Style="{StaticResource BtnChip}"/>
                  <Button x:Name="MenuRestart" Content="Restart Explorer" Style="{StaticResource BtnChip}" ToolTip="Changes show up after Explorer restarts"/>
                  <Button x:Name="MenuRefresh" Content="Refresh" Style="{StaticResource BtnChip}" Margin="0"/>
                </StackPanel>
              </Grid>
            </Border>
            <Border Grid.Row="2" Style="{StaticResource Card}" Margin="0,16,0,16" Padding="12,10">
              <Grid>
              <ListView x:Name="MenuList" Visibility="Collapsed">
                <ListView.View>
                  <GridView>
                    <GridViewColumn Header="Status" Width="86">
                      <GridViewColumn.CellTemplate><DataTemplate>
                        <CheckBox Style="{StaticResource Switch}" IsChecked="{Binding Enabled, Mode=OneWay}" Margin="4,0,0,0"/>
                      </DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Name" Width="230">
                      <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Shows on" Width="130" DisplayMemberBinding="{Binding Where}"/>
                    <GridViewColumn Header="Type" Width="90" DisplayMemberBinding="{Binding Kind}"/>
                    <GridViewColumn Header="Company" Width="170" DisplayMemberBinding="{Binding Company}"/>
                    <GridViewColumn Header="Runs" Width="420">
                      <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Command}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Command}"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                  </GridView>
                </ListView.View>
              </ListView>
              <ListView x:Name="StartupList">
                <ListView.View>
                  <GridView>
                    <GridViewColumn Header="Status" Width="86">
                      <GridViewColumn.CellTemplate><DataTemplate>
                        <CheckBox Style="{StaticResource Switch}" IsChecked="{Binding Enabled, Mode=OneWay}" IsEnabled="{Binding CanToggle}" Margin="4,0,0,0"/>
                      </DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Name" Width="220">
                      <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Scope" Width="90" DisplayMemberBinding="{Binding Scope}"/>
                    <GridViewColumn Header="Source" Width="140" DisplayMemberBinding="{Binding Location}"/>
                    <GridViewColumn Header="Command" Width="520">
                      <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Command}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Command}"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                  </GridView>
                </ListView.View>
              </ListView>
              </Grid>
            </Border>
          </Grid>

          <!-- ===== Programs ===== -->
          <Grid x:Name="ViewPrograms" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Style="{StaticResource Card}" Padding="14,12">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="320"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <Grid>
                  <TextBox x:Name="ProgSearch" Tag="Search programs or publishers..." Padding="10,7,44,7"/>
                  <Border HorizontalAlignment="Right" Width="38" Margin="0,1,1,1" CornerRadius="0,7,7,0" Background="{StaticResource PurpleGrad}" IsHitTestVisible="False">
                    <TextBlock Text="&#xE721;" Style="{StaticResource Icon}" HorizontalAlignment="Center" Foreground="White"/>
                  </Border>
                </Grid>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="16,0">
                  <RadioButton x:Name="ProgForAll"   Style="{StaticResource SegBtn}" GroupName="ProgFor" IsChecked="True" Content="All"/>
                  <RadioButton x:Name="ProgForMe"    Style="{StaticResource SegBtn}" GroupName="ProgFor" Content="Just me" ToolTip="Installed for this account only"/>
                  <RadioButton x:Name="ProgForUsers" Style="{StaticResource SegBtn}" GroupName="ProgFor" Content="All users" ToolTip="Installed for everyone on this PC"/>
                  <TextBlock x:Name="ProgInfo" Text="" Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="16,0,0,0" TextTrimming="CharacterEllipsis"/>
                </StackPanel>
                <StackPanel Grid.Column="2" Orientation="Horizontal">
                  <Button x:Name="ProgRefresh" Content="Refresh" Style="{StaticResource BtnChip}"/>
                  <Button x:Name="ProgOpen" Content="Open folder" Style="{StaticResource BtnChip}"/>
                  <Button x:Name="ProgUninstall" Content="Uninstall" Style="{StaticResource BtnPurple}" Padding="14,6" FontSize="12"/>
                </StackPanel>
                <TextBlock x:Name="ProgNote" Grid.Row="1" Grid.ColumnSpan="3" Visibility="Collapsed" Style="{StaticResource Muted}" FontSize="12" Margin="2,10,0,0"
                           Text="Programs installed just for you can be uninstalled without administrator rights."/>
              </Grid>
            </Border>
            <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,16,0,16" Padding="12,10">
              <ListView x:Name="ProgList" SelectionMode="Single">
                <ListView.View>
                  <GridView>
                    <GridViewColumn Header="Name" Width="320">
                      <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Publisher" Width="220">
                      <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Publisher}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Version" Width="130" DisplayMemberBinding="{Binding Version}"/>
                    <GridViewColumn Header="Installed" Width="100" DisplayMemberBinding="{Binding Installed}"/>
                    <GridViewColumn Header="Size" Width="90">
                      <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding SizeText}" TextAlignment="Right" Foreground="#60A5FA"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Installed for" Width="100" DisplayMemberBinding="{Binding For}"/>
                  </GridView>
                </ListView.View>
              </ListView>
            </Border>
          </Grid>

          <!-- ===== Drivers ===== -->
          <Grid x:Name="ViewDrivers" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Background="{StaticResource FieldBrush}" CornerRadius="10" Padding="3" BorderBrush="{StaticResource LineBrush}" BorderThickness="1" HorizontalAlignment="Left" Margin="0,0,0,14">
              <StackPanel Orientation="Horizontal">
                <RadioButton x:Name="DTabDrivers" Style="{StaticResource SegBtn}" GroupName="DTab" IsChecked="True" Content="Drivers" MinWidth="110"/>
                <RadioButton x:Name="DTabUpdates" Style="{StaticResource SegBtn}" GroupName="DTab" Content="Windows updates" MinWidth="110"/>
              </StackPanel>
            </Border>
            <Border x:Name="DrvHeader" Grid.Row="1" Style="{StaticResource Card}" Padding="20,16">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel>
                  <TextBlock Text="Drivers" Style="{StaticResource H2}"/>
                  <TextBlock x:Name="DrvSystem" Text="Reading this PC's drivers..." Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                  <TextBlock x:Name="DrvTools" Text="" Style="{StaticResource Muted}" FontSize="12" Margin="0,4,0,0" Visibility="Collapsed"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                  <Button x:Name="DrvOem" Content="PC maker's driver page" Style="{StaticResource BtnChip}" IsEnabled="False"/>
                  <Button x:Name="DrvCheck" Style="{StaticResource BtnAccent}" Padding="18,9">
                    <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE895;" Style="{StaticResource Icon}" Margin="0,0,8,0"/><TextBlock Text="Check for updates"/></StackPanel>
                  </Button>
                </StackPanel>
              </Grid>
            </Border>
            <Border x:Name="DrvBody" Grid.Row="2" Style="{StaticResource Card}" Margin="0,16,0,16" Padding="14,12">
              <DockPanel>
                <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                  <Grid.ColumnDefinitions><ColumnDefinition Width="260"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBox x:Name="DrvSearch" Tag="Filter devices, vendors, classes..."/>
                  <CheckBox x:Name="DrvHideMs" Grid.Column="1" Content="Hide drivers built into Windows" IsChecked="True" Margin="14,0,0,0"/>
                  <CheckBox x:Name="DrvOnlyIssues" Grid.Column="2" Content="Only updates and problems" Margin="14,0,0,0"/>
                  <TextBlock x:Name="DrvInfo" Grid.Column="3" Text="" Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="14,0,0,0" TextTrimming="CharacterEllipsis"/>
                </Grid>
                <Grid DockPanel.Dock="Bottom" Margin="0,10,0,0">
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <WrapPanel VerticalAlignment="Center">
                    <Button x:Name="DrvVendor" Content="Vendor's site" Style="{StaticResource BtnChip}" ToolTip="Open the download page of the company that makes the selected device"/>
                    <Button x:Name="DrvCatalog" Content="Search Update Catalog" Style="{StaticResource BtnChip}" ToolTip="Look up the selected device's hardware ID in the Microsoft Update Catalog"/>
                    <Button x:Name="DrvCopyId" Content="Copy hardware ID" Style="{StaticResource BtnChip}"/>
                    <Button x:Name="DrvBackup" Content="Back up drivers..." Style="{StaticResource BtnChip}" ToolTip="Export every third-party driver (pnputil) - keep it with your Resources for reinstalling offline"/>
                    <Button x:Name="DrvRestore" Content="Install from folder..." Style="{StaticResource BtnChip}" ToolTip="Install drivers from a backup or a downloaded driver folder (.inf files)"/>
                  </WrapPanel>
                  <Button x:Name="DrvInstall" Grid.Column="1" Content="Install checked updates" Style="{StaticResource BtnPurple}" Padding="14,6" FontSize="12" IsEnabled="False"/>
                </Grid>
                <TextBlock DockPanel.Dock="Bottom" Style="{StaticResource Muted}" FontSize="11.5" Margin="6,8,6,0" TextWrapping="Wrap"
                           Text="Updates are installed only through Windows Update (Microsoft-signed). On laptops, the PC maker's page usually has the right audio, touchpad and power drivers - they're often customized for that model."/>
                <ListView x:Name="DrvList">
                  <ListView.View>
                    <GridView>
                      <GridViewColumn Header="" Width="44">
                        <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsChecked, Mode=TwoWay}" IsEnabled="{Binding HasUpdate}" Margin="4,0,0,0"/></DataTemplate></GridViewColumn.CellTemplate>
                      </GridViewColumn>
                      <GridViewColumn Header="Device" Width="270">
                        <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding HardwareId}"/></DataTemplate></GridViewColumn.CellTemplate>
                      </GridViewColumn>
                      <GridViewColumn Header="Status" Width="130">
                        <GridViewColumn.CellTemplate><DataTemplate>
                          <TextBlock x:Name="St" Text="{Binding Status}" FontWeight="SemiBold" Foreground="#8C93A5"/>
                          <DataTemplate.Triggers>
                            <DataTrigger Binding="{Binding Status}" Value="Update available"><Setter TargetName="St" Property="Foreground" Value="#60A5FA"/></DataTrigger>
                            <DataTrigger Binding="{Binding Status}" Value="Problem"><Setter TargetName="St" Property="Foreground" Value="#F87171"/></DataTrigger>
                          </DataTemplate.Triggers>
                        </DataTemplate></GridViewColumn.CellTemplate>
                      </GridViewColumn>
                      <GridViewColumn Header="Vendor" Width="120" DisplayMemberBinding="{Binding Vendor}"/>
                      <GridViewColumn Header="Version" Width="130" DisplayMemberBinding="{Binding Version}"/>
                      <GridViewColumn Header="Date" Width="90" DisplayMemberBinding="{Binding DateText}"/>
                      <GridViewColumn Header="Update / notes" Width="260">
                        <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding UpdateText}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Note}"/></DataTemplate></GridViewColumn.CellTemplate>
                      </GridViewColumn>
                      <GridViewColumn Header="Class" Width="110" DisplayMemberBinding="{Binding Class}"/>
                    </GridView>
                  </ListView.View>
                </ListView>
              </DockPanel>
            </Border>

            <!-- Windows updates (online or offline scan, install from Resources) -->
            <Border x:Name="WuPanel" Grid.Row="1" Grid.RowSpan="2" Style="{StaticResource Card}" Margin="0,0,0,16" Padding="14,12" Visibility="Collapsed">
              <DockPanel>
                <Grid DockPanel.Dock="Top" Margin="0,0,0,10">
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <StackPanel>
                    <TextBlock Text="Windows updates" Style="{StaticResource H2}"/>
                    <TextBlock x:Name="WuInfo" Text="Scan to see which security updates this PC is missing - online through Windows Update, or offline with Microsoft's scan file (Resources\updates\wsusscn2.cab)."
                               Style="{StaticResource Muted}" Margin="0,4,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                  <WrapPanel Grid.Column="1" VerticalAlignment="Center" HorizontalAlignment="Right" MaxWidth="520">
                    <Button x:Name="WuScanOnline" Content="Scan online" Style="{StaticResource BtnChip}" Margin="0,0,6,6"/>
                    <Button x:Name="WuScanOffline" Content="Scan offline" Style="{StaticResource BtnChip}" Margin="0,0,6,6" ToolTip="Uses Resources\updates\wsusscn2.cab - no internet. Needs admin; takes a few minutes."/>
                    <Button x:Name="WuNeeds" Content="Export needs list" Style="{StaticResource BtnChip}" Margin="0,0,6,6" ToolTip="Saves what this PC is missing to Resources\needs so a connected PC can fetch it"/>
                    <Button x:Name="WuInstall" Content="Install from Resources" Style="{StaticResource BtnAccent}" Padding="14,6" FontSize="12" Margin="0,0,0,6"/>
                  </WrapPanel>
                </Grid>
                <TextBlock DockPanel.Dock="Bottom" Style="{StaticResource Muted}" FontSize="11.5" Margin="6,8,6,0" TextWrapping="Wrap"
                           Text="Offline: scan, then 'Export needs list' to the USB stick, run 'Fetch downloads' (Tools) on a connected PC, bring the stick back and 'Install from Resources'. Update files go in Resources\updates\&lt;KB number&gt;\."/>
                <ListView x:Name="WuList">
                  <ListView.View>
                    <GridView>
                      <GridViewColumn Header="" Width="44">
                        <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsChecked, Mode=TwoWay}" IsEnabled="{Binding CanCheck}" Margin="4,0,0,0"/></DataTemplate></GridViewColumn.CellTemplate>
                      </GridViewColumn>
                      <GridViewColumn Header="KB" Width="100" DisplayMemberBinding="{Binding Key}"/>
                      <GridViewColumn Header="Update" Width="520">
                        <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding Name}"/></DataTemplate></GridViewColumn.CellTemplate>
                      </GridViewColumn>
                      <GridViewColumn Header="Severity" Width="100" DisplayMemberBinding="{Binding Kind}"/>
                      <GridViewColumn Header="Size" Width="90" DisplayMemberBinding="{Binding SizeText}"/>
                      <GridViewColumn Header="In Resources" Width="160">
                        <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Status}" Foreground="#60A5FA"/></DataTemplate></GridViewColumn.CellTemplate>
                      </GridViewColumn>
                    </GridView>
                  </ListView.View>
                </ListView>
              </DockPanel>
            </Border>
          </Grid>

          <!-- ===== BIOS ===== -->
          <Grid x:Name="ViewBios" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,16,0,0" Padding="20,14">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <Border Width="36" Height="36" CornerRadius="10" Background="{StaticResource TealGrad}" VerticalAlignment="Top">
                  <TextBlock Text="&#xE895;" Style="{StaticResource Icon}" FontSize="16" Foreground="White" HorizontalAlignment="Center"/>
                </Border>
                <StackPanel Grid.Column="1" Margin="14,0,14,0">
                  <TextBlock Text="BIOS updates" Style="{StaticResource H2}" FontSize="15"/>
                  <TextBlock x:Name="BiosUpdText" Text="" TextWrapping="Wrap" Margin="0,4,0,0" FontSize="12.5"/>
                  <TextBlock x:Name="BiosUpdTips" Text="Before updating: plug a laptop into power, close your apps, use the maker's instructions and update tool, and never turn the PC off during the update."
                             Style="{StaticResource Muted}" FontSize="11.5" Margin="0,6,0,0"/>
                </StackPanel>
                <WrapPanel Grid.Column="2" VerticalAlignment="Center" MaxWidth="330" HorizontalAlignment="Right">
                  <Button x:Name="BiosFind" Content="Find BIOS update" Style="{StaticResource BtnAccent}" Padding="14,7" FontSize="12" Margin="0,0,8,6"/>
                  <Button x:Name="BiosWu" Content="Check Windows Update" Style="{StaticResource BtnChip}" Margin="0,0,8,6"/>
                  <Button x:Name="BiosBitlocker" Content="Suspend BitLocker for 1 restart" Style="{StaticResource BtnChip}" Margin="0,0,0,6" Visibility="Collapsed"/>
                </WrapPanel>
              </Grid>
            </Border>
            <Border Style="{StaticResource Card}" Padding="20,16">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel>
                  <TextBlock Text="BIOS and firmware" Style="{StaticResource H2}"/>
                  <TextBlock x:Name="BiosSummary" Text="Reading firmware settings..." Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                  <TextBlock Text="View only - Computer Doctor never changes BIOS settings." Style="{StaticResource Muted}" FontSize="11.5" Margin="0,4,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                  <Button x:Name="BiosRefresh" Content="Refresh" Style="{StaticResource BtnChip}"/>
                  <Button x:Name="BiosExport" Content="Export..." Style="{StaticResource BtnChip}" IsEnabled="False"/>
                  <Button x:Name="BiosRestart" Content="Restart into BIOS setup" Style="{StaticResource BtnPurple}" Padding="14,7" FontSize="12"
                          ToolTip="Restarts this PC straight into its UEFI firmware setup screen"/>
                  <Button x:Name="BiosAdvStart" Content="Advanced Startup" Style="{StaticResource BtnChip}" Margin="8,0,0,0"
                          ToolTip="Restarts into the Windows recovery menu: Startup Repair, System Restore, Safe Mode, UEFI settings"/>
                </StackPanel>
              </Grid>
            </Border>
            <Border Grid.Row="2" Style="{StaticResource Card}" Margin="0,16,0,16" Padding="14,12">
              <DockPanel>
                <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                  <Grid.ColumnDefinitions><ColumnDefinition Width="300"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBox x:Name="BiosSearch" Tag="Filter settings..."/>
                  <TextBlock x:Name="BiosInfo" Grid.Column="1" Text="" Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="14,0,0,0"/>
                </Grid>
                <ListView x:Name="BiosList">
                  <ListView.View>
                    <GridView>
                      <GridViewColumn Header="Section" Width="150">
                        <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Section}" Foreground="#8C93A5"/></DataTemplate></GridViewColumn.CellTemplate>
                      </GridViewColumn>
                      <GridViewColumn Header="Setting" Width="240">
                        <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding Name}"/></DataTemplate></GridViewColumn.CellTemplate>
                      </GridViewColumn>
                      <GridViewColumn Header="Value" Width="300">
                        <GridViewColumn.CellTemplate><DataTemplate>
                          <TextBlock x:Name="V" Text="{Binding Value}" TextTrimming="CharacterEllipsis" ToolTip="{Binding Value}"/>
                          <DataTemplate.Triggers>
                            <DataTrigger Binding="{Binding Flag}" Value="Good"><Setter TargetName="V" Property="Foreground" Value="#34D399"/></DataTrigger>
                            <DataTrigger Binding="{Binding Flag}" Value="Warn"><Setter TargetName="V" Property="Foreground" Value="#FBBF24"/></DataTrigger>
                          </DataTemplate.Triggers>
                        </DataTemplate></GridViewColumn.CellTemplate>
                      </GridViewColumn>
                      <GridViewColumn Header="Notes" Width="420">
                        <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Note}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Note}"/></DataTemplate></GridViewColumn.CellTemplate>
                      </GridViewColumn>
                    </GridView>
                  </ListView.View>
                </ListView>
              </DockPanel>
            </Border>
          </Grid>

          <!-- ===== IT Admin ===== -->
          <Grid x:Name="ViewAdmin" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Background="{StaticResource FieldBrush}" CornerRadius="10" Padding="3" BorderBrush="{StaticResource LineBrush}" BorderThickness="1" HorizontalAlignment="Left">
              <StackPanel Orientation="Horizontal">
                <RadioButton x:Name="ATabProfiles" Style="{StaticResource SegBtn}" GroupName="ATab" IsChecked="True" Content="User profiles" MinWidth="100"/>
                <RadioButton x:Name="ATabPrinters" Style="{StaticResource SegBtn}" GroupName="ATab" Content="Printers" MinWidth="90"/>
                <RadioButton x:Name="ATabHelp"     Style="{StaticResource SegBtn}" GroupName="ATab" Content="Helpdesk" MinWidth="90"/>
                <RadioButton x:Name="ATabSoftware" Style="{StaticResource SegBtn}" GroupName="ATab" Content="Software push" MinWidth="100"/>
                <RadioButton x:Name="ATabBaseline" Style="{StaticResource SegBtn}" GroupName="ATab" Content="Baseline audit" MinWidth="100"/>
                <RadioButton x:Name="ATabTime"     Style="{StaticResource SegBtn}" GroupName="ATab" Content="Time and network" MinWidth="110"/>
              </StackPanel>
            </Border>
            <Grid Grid.Row="1" Margin="0,14,0,16">

              <!-- User profiles -->
              <Border x:Name="APanelProfiles" Style="{StaticResource Card}" Padding="14,12">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                    <StackPanel>
                      <TextBlock Text="User profiles" Style="{StaticResource H2}"/>
                      <TextBlock x:Name="ProfInfo" Text="" Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                      <TextBlock Text="Unused for" VerticalAlignment="Center" Margin="0,0,6,0" Foreground="{StaticResource MutedBrush}"/>
                      <TextBox x:Name="ProfDays" Width="52" Text="90"/>
                      <TextBlock Text="days" VerticalAlignment="Center" Margin="6,0,8,0" Foreground="{StaticResource MutedBrush}"/>
                      <Button x:Name="ProfStale" Content="Check stale" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="ProfRefresh" Content="Refresh" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="ProfRemove" Content="Remove checked..." Style="{StaticResource BtnPurple}" Padding="14,6" FontSize="12"/>
                    </StackPanel>
                  </Grid>
                  <TextBlock DockPanel.Dock="Bottom" Style="{StaticResource Muted}" FontSize="11.5" Margin="6,8,6,0" TextWrapping="Wrap"
                             Text="Removing a profile permanently deletes that user's files and settings on this PC (their account is not deleted). Profiles in use and Windows system profiles can't be removed. 'Last used' comes from the last sign-in time Windows records."/>
                  <ListView x:Name="ProfList">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="" Width="44">
                          <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsChecked, Mode=TwoWay}" IsEnabled="{Binding CanCheck}" Margin="4,0,0,0"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="User" Width="220">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" ToolTip="{Binding Key}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Last used" Width="140" DisplayMemberBinding="{Binding WhenText}"/>
                        <GridViewColumn Header="Size" Width="90">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding SizeText}" TextAlignment="Right" Foreground="#60A5FA"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Status" Width="150" DisplayMemberBinding="{Binding Status}"/>
                        <GridViewColumn Header="Folder" Width="320">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Path}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>

              <!-- Printers -->
              <Border x:Name="APanelPrinters" Style="{StaticResource Card}" Padding="14,12" Visibility="Collapsed">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                    <StackPanel>
                      <TextBlock Text="Printers, ports and drivers" Style="{StaticResource H2}"/>
                      <TextBlock x:Name="PrnInfo" Text="" Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                    </StackPanel>
                    <WrapPanel HorizontalAlignment="Right" VerticalAlignment="Center" MaxWidth="560">
                      <Button x:Name="PrnAdd" Content="Add printer by IP..." Style="{StaticResource BtnChip}" Margin="0,0,6,6"/>
                      <Button x:Name="PrnSpooler" Content="Reset print spooler" Style="{StaticResource BtnChip}" Margin="0,0,6,6" ToolTip="Restarts the spooler and clears stuck print jobs"/>
                      <Button x:Name="PrnUnused" Content="Check unused" Style="{StaticResource BtnChip}" Margin="0,0,6,6"/>
                      <Button x:Name="PrnRefresh" Content="Refresh" Style="{StaticResource BtnChip}" Margin="0,0,6,6"/>
                      <Button x:Name="PrnRemove" Content="Remove checked" Style="{StaticResource BtnPurple}" Padding="14,6" FontSize="12" Margin="0,0,0,6"/>
                    </WrapPanel>
                  </Grid>
                  <ListView x:Name="PrnList">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="" Width="44">
                          <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsChecked, Mode=TwoWay}" Margin="4,0,0,0"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Type" Width="80" DisplayMemberBinding="{Binding Kind}"/>
                        <GridViewColumn Header="Name" Width="300">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Status" Width="170" DisplayMemberBinding="{Binding Status}"/>
                        <GridViewColumn Header="Details" Width="440">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Detail}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Detail}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>

              <!-- Helpdesk -->
              <Grid x:Name="APanelHelp" Visibility="Collapsed">
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                <Border Style="{StaticResource Card}" Padding="14,12">
                  <DockPanel>
                    <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                      <TextBlock Text="Signed-in users" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                      <WrapPanel HorizontalAlignment="Right">
                        <Button x:Name="HdMessage" Content="Send message..." Style="{StaticResource BtnChip}"/>
                        <Button x:Name="HdLogoff" Content="Sign out user" Style="{StaticResource BtnChip}"/>
                        <Button x:Name="HdAssist" Content="Remote Assistance" Style="{StaticResource BtnChip}" ToolTip="Offers help to the user (they must accept)"/>
                        <Button x:Name="HdShadow" Content="View session" Style="{StaticResource BtnChip}" ToolTip="Remote Desktop shadow of the selected session - the user is asked to allow it"/>
                        <Button x:Name="HdRestart" Content="Restart PC..." Style="{StaticResource BtnChip}"/>
                        <Button x:Name="HdCancel" Content="Cancel restart" Style="{StaticResource BtnChip}" Margin="0"/>
                      </WrapPanel>
                    </Grid>
                    <ListView x:Name="HdSessions" Height="110">
                      <ListView.View>
                        <GridView>
                          <GridViewColumn Header="User" Width="220" DisplayMemberBinding="{Binding Name}"/>
                          <GridViewColumn Header="Session" Width="120" DisplayMemberBinding="{Binding Kind}"/>
                          <GridViewColumn Header="ID" Width="50" DisplayMemberBinding="{Binding Key}"/>
                          <GridViewColumn Header="State" Width="100" DisplayMemberBinding="{Binding Status}"/>
                          <GridViewColumn Header="Idle / sign-in" Width="260" DisplayMemberBinding="{Binding Detail}"/>
                        </GridView>
                      </ListView.View>
                    </ListView>
                  </DockPanel>
                </Border>
                <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,16,0,0" Padding="14,12">
                  <DockPanel>
                    <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                      <TextBlock Text="Programs using the most memory" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button x:Name="HdRefresh" Content="Refresh" Style="{StaticResource BtnChip}"/>
                        <Button x:Name="HdKill" Content="End process" Style="{StaticResource BtnPurple}" Padding="14,6" FontSize="12"/>
                      </StackPanel>
                    </Grid>
                    <ListView x:Name="HdProcs">
                      <ListView.View>
                        <GridView>
                          <GridViewColumn Header="Program" Width="260" DisplayMemberBinding="{Binding Name}"/>
                          <GridViewColumn Header="PID" Width="70" DisplayMemberBinding="{Binding Key}"/>
                          <GridViewColumn Header="Memory" Width="100" DisplayMemberBinding="{Binding SizeText}"/>
                          <GridViewColumn Header="CPU time" Width="100" DisplayMemberBinding="{Binding Detail}"/>
                          <GridViewColumn Header="Status" Width="140" DisplayMemberBinding="{Binding Status}"/>
                        </GridView>
                      </ListView.View>
                    </ListView>
                  </DockPanel>
                </Border>
              </Grid>

              <!-- Software push -->
              <Border x:Name="APanelSoftware" Style="{StaticResource Card}" Padding="18,14" Visibility="Collapsed">
                <DockPanel>
                  <StackPanel DockPanel.Dock="Top">
                    <TextBlock Text="Install software on several PCs" Style="{StaticResource H2}"/>
                    <TextBlock Text="Computer Doctor copies the installer to each PC first, checks its hash, runs it silently there and reports the result - no file share or extra credentials hop needed. Works offline on your network."
                               Style="{StaticResource Muted}" Margin="0,4,0,8" TextWrapping="Wrap"/>
                    <Grid Margin="0,4,0,0">
                      <Grid.ColumnDefinitions><ColumnDefinition Width="110"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                      <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                      <TextBlock Text="Installer" VerticalAlignment="Center"/>
                      <TextBox x:Name="SwFile" Grid.Column="1" Tag="An .msi or .exe file"/>
                      <Button x:Name="SwBrowse" Grid.Column="2" Style="{StaticResource BtnIcon}" Content="&#xE838;" Margin="8,0,0,0"/>
                      <TextBlock Grid.Row="1" Text="Extra options" VerticalAlignment="Center" Margin="0,8,0,0"/>
                      <TextBox x:Name="SwArgs" Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="2" Margin="0,8,0,0" Tag=".msi: added after /qn (e.g. ALLUSERS=1). .exe: its silent switch (e.g. /S, /quiet, /VERYSILENT)"/>
                      <TextBlock Grid.Row="2" Text="Computers" VerticalAlignment="Center" Margin="0,8,0,0"/>
                      <TextBox x:Name="SwHosts" Grid.Row="2" Grid.Column="1" Margin="0,8,0,0" Tag="PC01, PC02, 192.168.1.20 (localhost = this PC)"/>
                      <Button x:Name="SwRun" Grid.Row="2" Grid.Column="2" Content="Install" Style="{StaticResource BtnAccent}" Padding="18,7" FontSize="12" Margin="8,8,0,0"/>
                    </Grid>
                  </StackPanel>
                  <ListView x:Name="SwResults" Margin="0,14,0,0">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="Computer" Width="180" DisplayMemberBinding="{Binding Name}"/>
                        <GridViewColumn Header="Result" Width="380">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Status}" FontWeight="SemiBold" ToolTip="{Binding Detail}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Exit code" Width="90" DisplayMemberBinding="{Binding Key}"/>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>

              <!-- Baseline audit -->
              <Border x:Name="APanelBaseline" Style="{StaticResource Card}" Padding="14,12" Visibility="Collapsed">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                    <StackPanel>
                      <TextBlock Text="Security baseline audit" Style="{StaticResource H2}"/>
                      <TextBlock x:Name="BlInfo" Text="Checks this PC against a baseline in HardeningKitty format (CIS, Microsoft, BSI, DoD lists). Audit only - nothing is changed."
                                 Style="{StaticResource Muted}" Margin="0,4,0,0" TextWrapping="Wrap"/>
                    </StackPanel>
                  </Grid>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox x:Name="BlFile" IsReadOnly="True" Tag="Choose a baseline list (.csv) - Fetch puts some in Resources\baselines"/>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" Margin="8,0,0,0">
                      <Button x:Name="BlBrowse" Content="Choose list..." Style="{StaticResource BtnChip}"/>
                      <CheckBox x:Name="BlFailed" Content="Only failed" IsChecked="True" VerticalAlignment="Center" Margin="4,0,10,0"/>
                      <Button x:Name="BlExport" Content="Export..." Style="{StaticResource BtnChip}" IsEnabled="False"/>
                      <Button x:Name="BlRun" Content="Run audit" Style="{StaticResource BtnAccent}" Padding="14,6" FontSize="12"/>
                    </StackPanel>
                  </Grid>
                  <ListView x:Name="BlList">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="Result" Width="100">
                          <GridViewColumn.CellTemplate><DataTemplate>
                            <TextBlock x:Name="R" Text="{Binding Result}" FontWeight="SemiBold" Foreground="#8C93A5"/>
                            <DataTemplate.Triggers>
                              <DataTrigger Binding="{Binding Result}" Value="Passed"><Setter TargetName="R" Property="Foreground" Value="#34D399"/></DataTrigger>
                              <DataTrigger Binding="{Binding Result}" Value="Failed"><Setter TargetName="R" Property="Foreground" Value="#F87171"/></DataTrigger>
                            </DataTemplate.Triggers>
                          </DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Severity" Width="80" DisplayMemberBinding="{Binding Severity}"/>
                        <GridViewColumn Header="Category" Width="160" DisplayMemberBinding="{Binding Category}"/>
                        <GridViewColumn Header="Setting" Width="380">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" TextTrimming="CharacterEllipsis" ToolTip="{Binding Name}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Current" Width="140">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Current}" TextTrimming="CharacterEllipsis" ToolTip="{Binding Current}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Recommended" Width="140" DisplayMemberBinding="{Binding Recommended}"/>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>

              <!-- Time and network -->
              <Grid x:Name="APanelTime" Visibility="Collapsed">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <Border Style="{StaticResource Card}" Padding="18,14" VerticalAlignment="Top">
                  <StackPanel>
                    <TextBlock Text="Time sync" Style="{StaticResource H2}"/>
                    <TextBlock x:Name="TimeStatus" Text="" TextWrapping="Wrap" Margin="0,8,0,0" FontSize="12.5"/>
                    <TextBlock Text="TIME SERVER" Style="{StaticResource Caps}"/>
                    <TextBox x:Name="TimePeer" Tag="e.g. 192.168.1.1, dc01.corp.local or time.windows.com"/>
                    <TextBlock Text="On an isolated network, point PCs at a local server (a router, domain controller or NTP appliance). Domain PCs normally sync from the domain automatically."
                               Style="{StaticResource Muted}" FontSize="11.5" Margin="0,6,0,0" TextWrapping="Wrap"/>
                    <WrapPanel Margin="0,12,0,0">
                      <Button x:Name="TimeSet" Content="Use this server" Style="{StaticResource BtnAccent}" Padding="14,6" FontSize="12" Margin="0,0,8,0"/>
                      <Button x:Name="TimeSync" Content="Sync now" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="TimeRefresh" Content="Refresh" Style="{StaticResource BtnChip}" Margin="0"/>
                    </WrapPanel>
                  </StackPanel>
                </Border>
                <Border Grid.Column="1" Style="{StaticResource Card}" Margin="16,0,0,0" Padding="18,14" VerticalAlignment="Top">
                  <StackPanel>
                    <TextBlock Text="Network speed test (local network)" Style="{StaticResource H2}"/>
                    <TextBlock Text="Copies a 256 MB test file to another PC and back to measure real file-copy speed between them - no internet needed."
                               Style="{StaticResource Muted}" Margin="0,4,0,0" TextWrapping="Wrap"/>
                    <TextBlock Text="OTHER PC" Style="{StaticResource Caps}"/>
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                      <TextBox x:Name="LanHost" Tag="Name or address"/>
                      <Button x:Name="LanRun" Grid.Column="1" Content="Test" Style="{StaticResource BtnAccent}" Padding="18,6" FontSize="12" Margin="8,0,0,0"/>
                    </Grid>
                    <TextBlock x:Name="LanResult" Text="" TextWrapping="Wrap" Margin="0,12,0,0" FontSize="13"/>
                  </StackPanel>
                </Border>
              </Grid>
            </Grid>
          </Grid>

          <!-- ===== Debloat ===== -->
          <Grid x:Name="ViewDebloat" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Style="{StaticResource Card}" Padding="20,16">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel>
                  <TextBlock Text="Debloat Windows" Style="{StaticResource H2}"/>
                  <TextBlock Text="Remove preinstalled Store apps and turn off ads, suggestions and AI features. Create a restore point first if you are making a lot of changes." Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                  <Button x:Name="DebloatRestore" Content="Create restore point" Style="{StaticResource BtnChip}"/>
                  <Button x:Name="DebloatRefresh" Content="Refresh" Style="{StaticResource BtnChip}" Margin="0"/>
                </StackPanel>
              </Grid>
            </Border>
            <Grid Grid.Row="1" Margin="0,16,0,16">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="400"/></Grid.ColumnDefinitions>
              <Border Style="{StaticResource Card}" Padding="14,12">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBlock Text="Store apps" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                    <TextBox x:Name="AppSearch" Grid.Column="1" Tag="Filter apps..." Margin="14,0,10,0"/>
                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                      <Button x:Name="AppsRecommended" Content="Recommended" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="AppsNone" Content="None" Style="{StaticResource BtnChip}" Margin="0"/>
                    </StackPanel>
                  </Grid>
                  <Grid DockPanel.Dock="Bottom" Margin="0,10,0,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                      <CheckBox x:Name="AppsShowAll" Content="Show all apps" Margin="0,0,18,0"/>
                      <CheckBox x:Name="AppsProvisioned" Content="Also remove for new users" IsChecked="True"
                                ToolTip="Removes the provisioned copy so Windows does not reinstall the app for new accounts. Needs admin."/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal">
                      <TextBlock x:Name="AppsInfo" Text="" Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="0,0,12,0"/>
                      <Button x:Name="AppsRemove" Content="Remove checked" Style="{StaticResource BtnPurple}" Padding="14,6" FontSize="12"/>
                    </StackPanel>
                  </Grid>
                  <ListView x:Name="AppList">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="" Width="44">
                          <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsChecked, Mode=TwoWay}" Margin="4,0,0,0"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="App" Width="210">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding Package}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Category" Width="100" DisplayMemberBinding="{Binding Category}"/>
                        <GridViewColumn Header="Notes" Width="260">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Note}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Note}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>
              <Border Grid.Column="1" Style="{StaticResource Card}" Margin="16,0,0,0" Padding="16,14">
                <DockPanel>
                  <Grid DockPanel.Dock="Top">
                    <TextBlock Text="Tweaks" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                      <Button x:Name="TweaksDefault" Content="Defaults" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="TweaksNone" Content="None" Style="{StaticResource BtnChip}" Margin="0"/>
                    </StackPanel>
                  </Grid>
                  <StackPanel DockPanel.Dock="Bottom" Margin="0,10,0,0">
                    <CheckBox x:Name="TweaksRestartExplorer" Content="Restart Explorer to apply taskbar changes" IsChecked="True" Margin="0,0,0,10"/>
                    <StackPanel Orientation="Horizontal">
                      <Button x:Name="TweaksApply" Content="Apply checked" Style="{StaticResource BtnAccent}" Padding="16,7" FontSize="12" Margin="0,0,8,0"/>
                      <Button x:Name="TweaksRevert" Content="Revert checked" Padding="16,7" FontSize="12"/>
                    </StackPanel>
                  </StackPanel>
                  <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,6,0,0">
                    <StackPanel x:Name="TweakItems" Margin="2,0,8,0"/>
                  </ScrollViewer>
                </DockPanel>
              </Border>
            </Grid>
          </Grid>

          <!-- ===== Rebloat ===== -->
          <Grid x:Name="ViewRebloat" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Border Style="{StaticResource Card}" Padding="20,16">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel>
                  <TextBlock Text="Rebloat Windows" Style="{StaticResource H2}"/>
                  <TextBlock Text="Changed your mind? Put back removed apps and undo debloat tweaks. Apps come back from Windows' own copy when one is still on disk, otherwise from the Microsoft Store."
                             Style="{StaticResource Muted}" Margin="0,4,0,0"/>
                </StackPanel>
                <Button x:Name="RebloatRefresh" Grid.Column="1" Content="Refresh" Style="{StaticResource BtnChip}" VerticalAlignment="Center" Margin="16,0,0,0"/>
              </Grid>
            </Border>
            <Grid Grid.Row="1" Margin="0,16,0,16">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="400"/></Grid.ColumnDefinitions>
              <Border Style="{StaticResource Card}" Padding="14,12">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBlock Text="Missing apps" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                    <TextBox x:Name="RebloatSearch" Grid.Column="1" Tag="Filter apps..." Margin="14,0,10,0"/>
                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                      <Button x:Name="RebloatAll" Content="All" Style="{StaticResource BtnChip}"/>
                      <Button x:Name="RebloatNone" Content="None" Style="{StaticResource BtnChip}" Margin="0"/>
                    </StackPanel>
                  </Grid>
                  <Grid DockPanel.Dock="Bottom" Margin="0,10,0,0">
                    <TextBlock x:Name="RebloatInfo" Text="" Style="{StaticResource Muted}" VerticalAlignment="Center" Margin="4,0,170,0"/>
                    <Button x:Name="RebloatInstall" Content="Reinstall checked" Style="{StaticResource BtnAccent}" Padding="14,6" FontSize="12" HorizontalAlignment="Right"/>
                  </Grid>
                  <ListView x:Name="RebloatList">
                    <ListView.View>
                      <GridView>
                        <GridViewColumn Header="" Width="44">
                          <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsChecked, Mode=TwoWay}" Margin="4,0,0,0"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="App" Width="210">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding Package}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Category" Width="100" DisplayMemberBinding="{Binding Category}"/>
                        <GridViewColumn Header="Comes back from" Width="140">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Source}" Foreground="#60A5FA"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                        <GridViewColumn Header="Notes" Width="240">
                          <GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Note}" Foreground="#8C93A5" TextTrimming="CharacterEllipsis" ToolTip="{Binding Note}"/></DataTemplate></GridViewColumn.CellTemplate>
                        </GridViewColumn>
                      </GridView>
                    </ListView.View>
                  </ListView>
                </DockPanel>
              </Border>
              <Grid Grid.Column="1" Margin="16,0,0,0">
              <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="230"/></Grid.RowDefinitions>
              <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,14,0,0" Padding="16,12">
                <DockPanel>
                  <Grid DockPanel.Dock="Top" Margin="0,0,0,6">
                    <TextBlock Text="Undo history" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                    <Button x:Name="UndoBtn" Content="Undo selected" Style="{StaticResource BtnChip}" HorizontalAlignment="Right" Margin="0"/>
                  </Grid>
                  <TextBlock DockPanel.Dock="Bottom" Text="Puts settings back exactly as they were before each change." Style="{StaticResource Muted}" FontSize="11.5" Margin="2,6,0,0"/>
                  <ListBox x:Name="UndoList">
                    <ListBox.ItemTemplate>
                      <DataTemplate>
                        <StackPanel Margin="2,2">
                          <TextBlock Text="{Binding Label}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                          <TextBlock Text="{Binding Sub}" Foreground="#8C93A5" FontSize="11.5"/>
                        </StackPanel>
                      </DataTemplate>
                    </ListBox.ItemTemplate>
                  </ListBox>
                </DockPanel>
              </Border>
              <Border Style="{StaticResource Card}" Padding="16,14">
                <DockPanel>
                  <TextBlock DockPanel.Dock="Top" Text="Tweaks in effect" Style="{StaticResource H2}"/>
                  <TextBlock DockPanel.Dock="Top" Text="Check the ones to set back to the Windows default." Style="{StaticResource Muted}" FontSize="12" Margin="0,4,0,4"/>
                  <StackPanel DockPanel.Dock="Bottom" Margin="0,10,0,0">
                    <CheckBox x:Name="RebloatRestartExplorer" Content="Restart Explorer to apply taskbar changes" IsChecked="True" Margin="0,0,0,10"/>
                    <Button x:Name="RebloatRevert" Content="Restore Windows defaults" Style="{StaticResource BtnAccent}" Padding="16,7" FontSize="12" HorizontalAlignment="Left"/>
                  </StackPanel>
                  <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,6,0,0">
                    <StackPanel x:Name="RebloatTweakItems" Margin="2,0,8,0"/>
                  </ScrollViewer>
                </DockPanel>
              </Border>
              </Grid>
            </Grid>
          </Grid>

          <!-- ===== Tools ===== -->
          <Grid x:Name="ViewTools" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="230"/></Grid.RowDefinitions>
            <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,0,0,2">
              <StackPanel x:Name="ToolCards"/>
            </ScrollViewer>
            <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,2,0,16" Padding="16,12">
              <DockPanel>
                <Grid DockPanel.Dock="Top" Margin="0,0,0,10">
                  <TextBlock Text="Activity log" Style="{StaticResource H2}" VerticalAlignment="Center"/>
                  <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button x:Name="LogClear" Content="Clear view" Style="{StaticResource BtnChip}"/>
                    <Button x:Name="LogOpen" Content="Open log folder" Style="{StaticResource BtnChip}" Margin="0"/>
                  </StackPanel>
                </Grid>
                <TextBox x:Name="LogBox" IsReadOnly="True" FontFamily="Cascadia Mono, Consolas" FontSize="12" Background="#0F1218"
                         VerticalContentAlignment="Top" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" TextWrapping="NoWrap"/>
              </DockPanel>
            </Border>
          </Grid>
        </Grid>
      </Grid>

      <!-- ================= Status bar ================= -->
      <Grid Grid.Row="2" Margin="20,0,20,8">
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="260"/></Grid.ColumnDefinitions>
        <TextBlock x:Name="StatusText" Text="Ready" Foreground="{StaticResource MutedBrush}" FontSize="12" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
        <ProgressBar x:Name="StatusProgress" Grid.Column="1" Height="5" Maximum="100" Value="0" VerticalAlignment="Center" Visibility="Hidden"/>
      </Grid>

      <!-- ================= Connect dialog (overlay) ================= -->
      <Grid x:Name="ConnectOverlay" Grid.RowSpan="3" Visibility="Collapsed" Background="#B30B0D12">
        <Border Style="{StaticResource Card}" Width="500" VerticalAlignment="Center" HorizontalAlignment="Center" Padding="26,22">
          <Border.Effect><DropShadowEffect Color="Black" BlurRadius="40" ShadowDepth="0" Opacity="0.6"/></Border.Effect>
          <StackPanel>
            <Grid>
              <StackPanel Orientation="Horizontal">
                <Border Width="34" Height="34" CornerRadius="10" Background="{StaticResource PurpleGrad}">
                  <TextBlock Text="&#xE7F4;" Style="{StaticResource Icon}" FontSize="15" Foreground="White" HorizontalAlignment="Center"/>
                </Border>
                <TextBlock Text="Connect to a computer" Style="{StaticResource H2}" FontSize="18" Margin="12,0,0,0" VerticalAlignment="Center"/>
              </StackPanel>
              <Button x:Name="ConnClose" Style="{StaticResource CapBtn}" Content="&#xE8BB;" HorizontalAlignment="Right" Width="34" Height="30"/>
            </Grid>
            <TextBlock Text="Uses PowerShell remoting (WinRM). You need admin rights on the remote PC, and remoting must be enabled there."
                       Style="{StaticResource Muted}" FontSize="12" Margin="0,10,0,4"/>

            <TextBlock Text="COMPUTER" Style="{StaticResource Caps}"/>
            <TextBox x:Name="ConnHost" Tag="Hostname, FQDN or IP address"/>
            <WrapPanel x:Name="ConnRecent" Margin="0,8,0,0"/>

            <TextBlock Text="DOMAIN (OPTIONAL)" Style="{StaticResource Caps}"/>
            <TextBox x:Name="ConnDomain" Tag="e.g. corp.contoso.com - added to short names and usernames"/>
            <TextBlock x:Name="ConnResolved" Text="" Foreground="{StaticResource DimBrush}" FontSize="11.5" Margin="2,5,0,0"/>

            <TextBlock Text="SIGN IN AS" Style="{StaticResource Caps}"/>
            <Border Background="{StaticResource FieldBrush}" CornerRadius="10" Padding="3" BorderBrush="{StaticResource LineBrush}" BorderThickness="1">
              <UniformGrid Columns="2">
                <RadioButton x:Name="ConnUseCurrent" Style="{StaticResource SegBtn}" GroupName="ConnCred" IsChecked="True">
                  <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE77B;" Style="{StaticResource Icon}" Margin="0,0,7,0"/><TextBlock x:Name="ConnCurrentText" Text="Current credentials"/></StackPanel>
                </RadioButton>
                <RadioButton x:Name="ConnUseOther" Style="{StaticResource SegBtn}" GroupName="ConnCred">
                  <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE8D7;" Style="{StaticResource Icon}" Margin="0,0,7,0"/><TextBlock Text="Other credentials"/></StackPanel>
                </RadioButton>
              </UniformGrid>
            </Border>

            <StackPanel x:Name="ConnOtherPanel" Visibility="Collapsed" Margin="0,10,0,0">
              <TextBox x:Name="ConnUser" Tag="DOMAIN\user or user@domain"/>
              <Grid Margin="0,8,0,0">
                <PasswordBox x:Name="ConnPass"/>
                <TextBlock x:Name="ConnPassHint" Text="Password" Foreground="{StaticResource DimBrush}" Margin="11,0,0,0"
                           VerticalAlignment="Center" IsHitTestVisible="False"/>
              </Grid>
              <Grid Margin="0,10,0,0">
                <CheckBox x:Name="ConnSave" Content="Save to Windows Credential Manager"/>
                <Button x:Name="ConnForget" Style="{StaticResource LinkBtn}" Content="Forget saved credentials" HorizontalAlignment="Right" Visibility="Collapsed"/>
              </Grid>
              <TextBlock x:Name="ConnSavedNote" Text="" Foreground="{StaticResource TealBrush}" FontSize="11.5" Margin="0,6,0,0" Visibility="Collapsed"/>
            </StackPanel>

            <Border x:Name="ConnMsgBox" CornerRadius="8" Padding="12,9" Margin="0,16,0,0" Background="#33280E" BorderBrush="#7A5E14" BorderThickness="1" Visibility="Collapsed">
              <StackPanel>
                <TextBlock x:Name="ConnMsg" Text="" TextWrapping="Wrap" FontSize="12" Foreground="#FDE68A"/>
                <Button x:Name="ConnTrust" Style="{StaticResource LinkBtn}" Content="Add this computer to TrustedHosts" Margin="0,8,0,0" HorizontalAlignment="Left" Visibility="Collapsed"/>
              </StackPanel>
            </Border>
            <ProgressBar x:Name="ConnProgress" IsIndeterminate="True" Height="4" Margin="0,14,0,0" Visibility="Collapsed"/>

            <Grid Margin="0,20,0,0">
              <Button x:Name="ConnLocal" Content="Use this PC" Style="{StaticResource BtnChip}" HorizontalAlignment="Left" Margin="0"/>
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="ConnCancel" Content="Cancel" Margin="0,0,10,0"/>
                <Button x:Name="ConnGo" Style="{StaticResource BtnAccent}">
                  <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE703;" Style="{StaticResource Icon}" Margin="0,0,8,0"/><TextBlock Text="Connect"/></StackPanel>
                </Button>
              </StackPanel>
            </Grid>
          </StackPanel>
        </Border>
      </Grid>
    </Grid>
  </Border>
</Window>
'@
#endregion

#region ---------------------------------------------------------------- Window + controls
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$ui = @{}
$xaml.SelectNodes('//*[@*[local-name()="Name"]]') | ForEach-Object {
    $n = $_.Attributes | Where-Object { $_.LocalName -eq 'Name' } | Select-Object -First 1 -ExpandProperty Value
    if ($n) { $ui[$n] = $window.FindName($n) }
}

$script:BrushConv = New-Object System.Windows.Media.BrushConverter
function New-Brush([string]$Hex) { $b = $script:BrushConv.ConvertFromString($Hex); $b.Freeze(); $b }
$script:Res = @{
    Teal = $window.FindResource('TealBrush'); Purple = $window.FindResource('PurpleBrush')
    Muted = $window.FindResource('MutedBrush'); Dim = $window.FindResource('DimBrush'); Success = $window.FindResource('SuccessBrush')
    Danger = $window.FindResource('DangerBrush'); Amber = $window.FindResource('AmberBrush')
    TealGrad = $window.FindResource('TealGrad'); PurpleGrad = $window.FindResource('PurpleGrad')
    Track = $window.FindResource('TrackBrush')
}

# From here on, event handlers use explicit -ErrorAction Stop where a failure must be caught.
$ErrorActionPreference = 'Continue'

function Show-AWMessage([string]$Text, [string]$Icon = 'Information') {
    [void][System.Windows.MessageBox]::Show($window, $Text, 'Computer Doctor', 'OK', $Icon)
}
function Confirm-AW([string]$Text) {
    ([System.Windows.MessageBox]::Show($window, $Text, 'Computer Doctor', 'YesNo', 'Warning')) -eq 'Yes'
}
function Open-AWExplorer([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Start-Process explorer.exe -ArgumentList "/select,`"$Path`"" }
    elseif (Test-Path -LiteralPath $Path) { Start-Process explorer.exe -ArgumentList "`"$Path`"" }
}
function Set-AWStatus([string]$Text) { $ui.StatusText.Text = $Text }

# Remote target: $null = this PC, otherwise @{ Host; Credential; ComputerName; OS }.
$script:Target = $null
function Test-AWRemote { [bool]$script:Target }
# Admin-only features: local admin, or a remote target (WinRM sessions are admin by default).
function Test-AWCanAdmin { $script:IsAdmin -or [bool]$script:Target }
#endregion

#region ---------------------------------------------------------------- Background task runner
$script:Jobs = New-Object System.Collections.ArrayList

function Start-AWTask {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Work,
        [hashtable]$Arguments = @{},
        [scriptblock]$OnComplete
    )
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = 'STA'
    $rs.ThreadOptions  = 'ReuseThread'
    $rs.Open()
    $rs.SessionStateProxy.SetVariable('Sync', $Sync)
    $rs.SessionStateProxy.SetVariable('Target', $script:Target)
    foreach ($k in $Arguments.Keys) { $rs.SessionStateProxy.SetVariable($k, $Arguments[$k]) }
    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    [void]$ps.AddScript(". ([scriptblock]::Create(`$Sync.WorkerLib))`n" + $Work.ToString())
    $Sync.Status = "$Name..."
    $Sync.Progress = -1
    [void]$script:Jobs.Add([pscustomobject]@{ Name = $Name; PS = $ps; Runspace = $rs; Handle = $ps.BeginInvoke(); OnComplete = $OnComplete })
    Write-AWLog "$Name started"
}

function Update-AWLogView {
    $line = $null
    $lines = New-Object System.Collections.Generic.List[string]
    while ($Sync.Log.TryDequeue([ref]$line)) { $lines.Add($line) }
    if ($lines.Count -eq 0) { return }
    $text = ($lines -join [Environment]::NewLine) + [Environment]::NewLine
    $ui.LogBox.AppendText($text)
    if ($ui.LogBox.LineCount -gt 3000) { $ui.LogBox.Text = ($ui.LogBox.Text -split "`r?`n" | Select-Object -Last 2000) -join [Environment]::NewLine }
    $ui.LogBox.ScrollToEnd()
    try { [System.IO.File]::AppendAllText($script:LogFile, $text) } catch { }
}

$script:Timer = New-Object System.Windows.Threading.DispatcherTimer
$script:Timer.Interval = [TimeSpan]::FromMilliseconds(200)
$script:Timer.Add_Tick({
    try {
        Update-AWLogView

        for ($i = $script:Jobs.Count - 1; $i -ge 0; $i--) {
            $j = $script:Jobs[$i]
            if (-not $j.Handle.IsCompleted) { continue }
            $result = $null
            try { $result = $j.PS.EndInvoke($j.Handle) }
            catch { Write-AWLog "$($j.Name) failed: $($_.Exception.Message)" 'ERROR' }
            $errs = @($j.PS.Streams.Error)
            foreach ($e in ($errs | Select-Object -First 10)) { Write-AWLog "$($j.Name): $e" 'WARN' }
            $j.PS.Dispose(); $j.Runspace.Dispose()
            $script:Jobs.RemoveAt($i)
            Write-AWLog "$($j.Name) finished"
            if ($j.OnComplete) {
                try { & $j.OnComplete $result } catch { Write-AWLog "$($j.Name) completion: $($_.Exception.Message)" 'ERROR' }
            }
        }

        if ($Sync.Scanning -and $script:Scanner -and $Sync.ScanVia -notin 'WinRM', 'Connecting') {
            $s = $script:Scanner
            $msg = 'Scanning {0:N0} files in {1:N0} folders - {2} - {3}' -f $s.FilesScanned, $s.FoldersScanned, (Format-AWSize $s.BytesScanned), $s.CurrentPath
            Set-AWStatus $msg
            if ($script:ScanExpected -gt 0) {
                $ui.StatusProgress.IsIndeterminate = $false
                $ui.StatusProgress.Value = [Math]::Min(99, $s.BytesScanned * 100.0 / $script:ScanExpected)
            } else { $ui.StatusProgress.IsIndeterminate = $true }
            $ui.StatusProgress.Visibility = 'Visible'
        }
        elseif ($script:UndelRunning -and $script:Undelete -and $script:Undelete.RecordsTotal -gt 0) {
            $u = $script:Undelete
            $msg = 'Reading the file table: {0:N0} of {1:N0} records - {2:N0} deleted files found' -f $u.RecordsScanned, $u.RecordsTotal, $u.DeletedFound
            Set-AWStatus $msg; $ui.UndelStatus.Text = $msg
            $ui.StatusProgress.Visibility = 'Visible'; $ui.StatusProgress.IsIndeterminate = $false
            $ui.StatusProgress.Value = [Math]::Min(100, $u.RecordsScanned * 100.0 / $u.RecordsTotal)
        }
        elseif ($script:DupeRunning -and $script:Dupes) {
            $d = $script:Dupes
            $msg = if ($d.FilesSeen -and $d.Candidates) { 'Comparing {0:N0} same-size files of {1:N0} - {2:N0} group(s) so far - {3}' -f $d.Candidates, $d.FilesSeen, $d.Groups, $d.Status }
                   else { 'Listing files: {0:N0} - {1}' -f $d.FilesSeen, $d.Status }
            Set-AWStatus $msg
            $ui.StatusProgress.Visibility = 'Visible'; $ui.StatusProgress.IsIndeterminate = $true
        }
        elseif ($script:Jobs.Count -gt 0) {
            Set-AWStatus $Sync.Status
            $ui.StatusProgress.Visibility = 'Visible'
            if ($Sync.Progress -ge 0) { $ui.StatusProgress.IsIndeterminate = $false; $ui.StatusProgress.Value = $Sync.Progress }
            else { $ui.StatusProgress.IsIndeterminate = $true }
            if ($script:CleanerBusy) { $ui.CleanProgress.Value = [Math]::Max(0, $Sync.Progress) }
        }
        elseif ($ui.StatusProgress.Visibility -eq 'Visible') {
            $ui.StatusProgress.IsIndeterminate = $false
            $ui.StatusProgress.Visibility = 'Hidden'
            Set-AWStatus $script:IdleStatus
        }
    }
    catch { Write-AWLog "UI timer: $($_.Exception.Message)" 'ERROR' }
})
$script:IdleStatus = 'Ready'
#endregion

#region ---------------------------------------------------------------- Navigation + title bar
$script:ViewTitles = @{
    Home = 'Dashboard'; Health = 'Health Check'; Cleaner = 'Cleaner'; Map = 'Space Map'; Large = 'Large Files'; Recovery = 'Recovery'
    Startup = 'Startup'; Programs = 'Programs'; Drivers = 'Drivers'; Bios = 'BIOS and Firmware'; Admin = 'IT Admin'; Debloat = 'Debloat'; Rebloat = 'Rebloat'; Tools = 'Tools and Activity Log'
}
$script:Loaded = @{}

foreach ($v in $script:ViewTitles.Keys) {
    $ui["Nav$v"].Add_Checked({
        param($s, $e)
        $name = $s.Name.Substring(3)
        foreach ($k in $script:ViewTitles.Keys) { $ui["View$k"].Visibility = if ($k -eq $name) { 'Visible' } else { 'Collapsed' } }
        Update-AWViewTitle $name
        if (-not $script:Loaded[$name]) {
            $script:Loaded[$name] = $true
            switch ($name) {
                'Startup'  { Update-AWStartupList }
                'Programs' { Update-AWProgramList }
                'Debloat'  { Update-AWAppList; Update-AWTweakStatus }
                'Recovery' { Initialize-AWRecovery }
                'Rebloat'  { Initialize-AWRebloat }
                'Health'   { Start-AWHealthCheck }
                'Drivers'  { Start-AWDriverInventory }
                'Bios'     { Start-AWBiosRead }
                'Admin'    { foreach ($k in 'Profiles', 'Printers', 'Help', 'Software', 'Baseline', 'Time') { if ($ui["ATab$k"].IsChecked) { Show-AWAdminTab $k } } }
            }
        }
        if ($name -eq 'Map') { Request-AWMapRedraw }
        if ($name -eq 'Cleaner') { Update-AWAutoCleanFromDisk; Update-AWAutoCleanSummary }
    })
}

function Select-AWView([string]$Name) { $ui["Nav$Name"].IsChecked = $true }

# Views that always work on this PC, even when a remote computer is targeted.
$script:LocalOnlyViews = @('Home')
function Get-AWCurrentView { foreach ($k in $script:ViewTitles.Keys) { if ($ui["Nav$k"].IsChecked) { return $k } } }
function Update-AWViewTitle([string]$Name) {
    $title = $script:ViewTitles[$Name]
    if (Test-AWRemote) {
        $local = "   -   this PC ($env:COMPUTERNAME)"
        $title += switch ($Name) {
            { $script:LocalOnlyViews -contains $_ } { $local; break }
            'Map'   { if ($ui.MapOnRemote.IsChecked) { "   -   $($script:Target.ComputerName)" } else { $local }; break }
            'Large' { if ($script:LargeTab -eq 'Largest' -and $script:ScanRemote) { "   -   $($script:ScanRemote.ComputerName)" } else { $local }; break }
            default { "   -   $($script:Target.ComputerName)" }
        }
    }
    $ui.ViewTitle.Text = $title
}

$ui.BtnMin.Add_Click({ $window.WindowState = 'Minimized' })
$ui.BtnMax.Add_Click({ $window.WindowState = if ($window.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' } })
$ui.BtnClose.Add_Click({ $window.Close() })
$window.Add_StateChanged({
    # Borderless windows overhang the screen by the resize border when maximized.
    if ($window.WindowState -eq 'Maximized') { $ui.RootBorder.Margin = '7'; $ui.BtnMax.Content = [char]0xE923 }
    else { $ui.RootBorder.Margin = '0'; $ui.BtnMax.Content = [char]0xE922 }
})

$ui.VersionText.Text = "v$script:AppVersion"
if ($script:IsAdmin) {
    $ui.AdminText.Text = 'Administrator'
} else {
    $ui.AdminBadge.Background  = New-Brush '#33280E'
    $ui.AdminBadge.BorderBrush = New-Brush '#7A5E14'
    $ui.AdminText.Foreground   = $script:Res.Amber
    $ui.AdminIcon.Foreground   = $script:Res.Amber
    $ui.AdminText.Text = 'Standard user'
    $ui.AdminBadge.ToolTip = 'Some cleaning rules, startup entries and tools need administrator rights.'
    $ui.BtnElevate.Visibility = 'Visible'
}
$ui.BtnElevate.Add_Click({
    if (Invoke-AWElevation) { $window.Close() }
    else { Show-AWMessage 'Elevation was cancelled. Computer Doctor will keep running with standard permissions.' }
})
#endregion

#region ---------------------------------------------------------------- Dashboard
function New-AWText([string]$Text, [double]$Size = 13, $Brush = $null, [string]$Weight = 'Normal') {
    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text = $Text; $t.FontSize = $Size; $t.FontWeight = $Weight
    if ($Brush) { $t.Foreground = $Brush }
    $t
}

function New-AWPill([string]$Text, [bool]$Ok = $true, [string]$Tone = '') {
    $pill = New-Object System.Windows.Controls.Border
    $pill.Style = $window.FindResource('Pill')
    if ($Tone -eq 'Teal') {
        $pill.BorderBrush = New-Brush '#2563EB'; $fg = $script:Res.Teal
    } elseif ($Ok) {
        $pill.BorderBrush = New-Brush '#353C4B'; $fg = $script:Res.Muted
    } else {
        $pill.BorderBrush = New-Brush '#7A5E14'; $fg = $script:Res.Amber
    }
    $pill.Child = New-AWText $Text 9 $fg 'Bold'
    $pill
}

function Get-AWFixedDrives {
    [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' -and $_.IsReady }
}

function New-AWGauge([double]$Fraction, [double]$Size = 116) {
    $g = New-Object System.Windows.Controls.Grid
    $g.Width = $Size; $g.Height = $Size
    $stroke = 11
    $track = New-Object System.Windows.Shapes.Ellipse
    $track.Stroke = $script:Res.Track; $track.StrokeThickness = $stroke
    [void]$g.Children.Add($track)

    $brush = if ($Fraction -ge 0.9) { $script:Res.Danger } elseif ($Fraction -ge 0.75) { $script:Res.PurpleGrad } else { $script:Res.TealGrad }
    $r = ($Size - $stroke) / 2; $c = $Size / 2
    if ($Fraction -ge 0.999) {
        $full = New-Object System.Windows.Shapes.Ellipse
        $full.Stroke = $brush; $full.StrokeThickness = $stroke
        [void]$g.Children.Add($full)
    }
    elseif ($Fraction -gt 0.001) {
        $angle = 2 * [Math]::PI * $Fraction
        $ex = $c + $r * [Math]::Sin($angle)
        $ey = $c - $r * [Math]::Cos($angle)
        $large = if ($Fraction -gt 0.5) { 1 } else { 0 }
        $inv = [Globalization.CultureInfo]::InvariantCulture
        $data = [string]::Format($inv, 'M {0},{1} A {2},{2} 0 {3} 1 {4},{5}', $c, ($c - $r), $r, $large, $ex, $ey)
        $arc = New-Object System.Windows.Shapes.Path
        $arc.Data = [System.Windows.Media.Geometry]::Parse($data)
        $arc.Stroke = $brush; $arc.StrokeThickness = $stroke
        $arc.StrokeStartLineCap = 'Round'; $arc.StrokeEndLineCap = 'Round'
        [void]$g.Children.Add($arc)
    }
    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.HorizontalAlignment = 'Center'; $sp.VerticalAlignment = 'Center'
    $pct = New-AWText ('{0:0}%' -f ($Fraction * 100)) 24 $null 'Bold'; $pct.HorizontalAlignment = 'Center'
    $lbl = New-AWText 'used' 11 $script:Res.Muted; $lbl.HorizontalAlignment = 'Center'
    [void]$sp.Children.Add($pct); [void]$sp.Children.Add($lbl)
    [void]$g.Children.Add($sp)
    $g
}

function New-AWInfoRow([string]$Label, [string]$Value) {
    $g = New-Object System.Windows.Controls.Grid
    $g.Margin = '0,3'
    $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = '80'
    $c2 = New-Object System.Windows.Controls.ColumnDefinition
    $g.ColumnDefinitions.Add($c1); $g.ColumnDefinitions.Add($c2)
    $l = New-AWText $Label 12.5 $script:Res.Muted
    $v = New-AWText $Value 12.5 $null 'SemiBold'; $v.TextTrimming = 'CharacterEllipsis'; $v.ToolTip = $Value
    [System.Windows.Controls.Grid]::SetColumn($v, 1)
    [void]$g.Children.Add($l); [void]$g.Children.Add($v)
    $g
}

function New-AWDriveCard([System.IO.DriveInfo]$Drive) {
    $used = $Drive.TotalSize - $Drive.TotalFreeSpace
    $frac = if ($Drive.TotalSize -gt 0) { $used / $Drive.TotalSize } else { 0 }

    $card = New-Object System.Windows.Controls.Border
    $card.Style = $window.FindResource('Card')
    $card.Width = 340; $card.Margin = '0,0,16,16'

    $grid = New-Object System.Windows.Controls.Grid
    $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = 'Auto'
    $c2 = New-Object System.Windows.Controls.ColumnDefinition
    $grid.ColumnDefinitions.Add($c1); $grid.ColumnDefinitions.Add($c2)
    [void]$grid.Children.Add((New-AWGauge $frac))

    $info = New-Object System.Windows.Controls.StackPanel
    $info.Margin = '20,0,0,0'; $info.VerticalAlignment = 'Center'
    $label = if ($Drive.VolumeLabel) { $Drive.VolumeLabel } else { 'Local Disk' }
    [void]$info.Children.Add((New-AWText ("{0}  {1}" -f $Drive.Name.TrimEnd('\'), $label) 16 $null 'SemiBold'))
    [void]$info.Children.Add((New-AWText $Drive.DriveFormat 11.5 $script:Res.Dim))
    $rows = New-Object System.Windows.Controls.StackPanel; $rows.Margin = '0,8,0,10'
    [void]$rows.Children.Add((New-AWInfoRow 'Used'  (Format-AWSize $used)))
    [void]$rows.Children.Add((New-AWInfoRow 'Free'  (Format-AWSize $Drive.TotalFreeSpace)))
    [void]$rows.Children.Add((New-AWInfoRow 'Total' (Format-AWSize $Drive.TotalSize)))
    [void]$info.Children.Add($rows)
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = 'Map this drive'; $btn.Style = $window.FindResource('BtnChip'); $btn.HorizontalAlignment = 'Left'
    $btn.Tag = $Drive.RootDirectory.FullName
    $btn.Add_Click({ param($s, $e) Select-AWView 'Map'; Start-AWMapScan $s.Tag })
    [void]$info.Children.Add($btn)
    [System.Windows.Controls.Grid]::SetColumn($info, 1)
    [void]$grid.Children.Add($info)
    $card.Child = $grid
    $card
}

function Update-AWDashboard {
    $ui.DriveCards.Children.Clear()
    foreach ($d in (Get-AWFixedDrives)) { [void]$ui.DriveCards.Children.Add((New-AWDriveCard $d)) }

    $sys = Get-AWFixedDrives | Where-Object { $_.Name -eq "$env:SystemDrive\" } | Select-Object -First 1
    if ($sys) {
        $usedPct = ($sys.TotalSize - $sys.TotalFreeSpace) * 100.0 / $sys.TotalSize
        $ui.SideDriveBar.Value = $usedPct
        $ui.SideDriveText.Text = '{0} free of {1}' -f (Format-AWSize $sys.TotalFreeSpace), (Format-AWSize $sys.TotalSize)
    }

    $ui.HomeFreed.Text  = Format-AWSize $script:State.TotalFreed
    $ui.HomeCleans.Text = '{0} clean{1} with Computer Doctor' -f $script:State.Cleans, $(if ($script:State.Cleans -eq 1) { '' } else { 's' })
    if ($script:State.LastClean) {
        try {
            $dt = [datetime]::Parse($script:State.LastClean, [Globalization.CultureInfo]::InvariantCulture)
            $days = [int]((Get-Date) - $dt).TotalDays
            $ui.HomeLast.Text = if ($days -le 0) { 'Today' } elseif ($days -eq 1) { 'Yesterday' } else { "$days days ago" }
            $ui.HomeLastSub.Text = $dt.ToString('ddd MMM d, h:mm tt')
        } catch { $ui.HomeLast.Text = 'Unknown' }
    }

    $ui.SysInfo.Children.Clear()
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $up = (Get-Date) - $os.LastBootUpTime
        $memTotal = [long]$os.TotalVisibleMemorySize * 1KB
        $memUsed  = $memTotal - [long]$os.FreePhysicalMemory * 1KB
        $rows = [ordered]@{
            'Computer' = $env:COMPUTERNAME
            'User'     = [Security.Principal.WindowsIdentity]::GetCurrent().Name
            'Windows'  = ($os.Caption -replace '^Microsoft\s+', '')
            'Build'    = $os.BuildNumber
            'Uptime'   = '{0}d {1}h {2}m' -f $up.Days, $up.Hours, $up.Minutes
            'Memory'   = '{0} of {1} in use' -f (Format-AWSize $memUsed), (Format-AWSize $memTotal)
        }
    } catch {
        $rows = [ordered]@{ 'Computer' = $env:COMPUTERNAME; 'User' = "$env:USERDOMAIN\$env:USERNAME" }
    }
    $rows['PowerShell'] = $PSVersionTable.PSVersion.ToString()
    $rows['Rights'] = if ($script:IsAdmin) { 'Administrator' } else { 'Standard user' }
    foreach ($k in $rows.Keys) { [void]$ui.SysInfo.Children.Add((New-AWInfoRow $k ([string]$rows[$k]))) }
    if ($script:ElevationNote) {
        $n = New-AWText $script:ElevationNote 12 $script:Res.Amber; $n.TextWrapping = 'Wrap'; $n.Margin = '0,10,0,0'
        [void]$ui.SysInfo.Children.Add($n)
    }
}

$ui.HomeQuick.Add_Click({ Select-AWView 'Cleaner'; Start-AWAnalyze })
$ui.HomeScan.Add_Click({ Select-AWView 'Map'; Start-AWMapScan "$env:SystemDrive\" })
$ui.HomeStartup.Add_Click({ Select-AWView 'Startup' })
#endregion

#region ---------------------------------------------------------------- Cleaner
$script:CleanerChecks = New-Object System.Collections.Generic.List[object]
$script:CleanerBusy = $false

# Rules that live in the signed-in user's profile only make sense on this PC.
function Test-AWUserScopeRule($Rule) {
    if ($Rule.UserScope -or $Rule.Kind -eq 'RecycleBin' -or $Rule.Action -eq 'Clipboard') { return $true }
    foreach ($t in $Rule.Targets) { if ($t.Path -match '%(TEMP|LOCALAPPDATA|APPDATA|USERPROFILE)%') { return $true } }
    $false
}
function Test-AWRuleAllowed($Rule) {
    if (Test-AWRemote) { return -not (Test-AWUserScopeRule $Rule) }
    $script:IsAdmin -or -not $Rule.Admin
}

function Initialize-AWCleaner {
    $ui.CleanerItems.Children.Clear()
    $script:CleanerChecks.Clear()
    $lastGroup = ''
    foreach ($rule in $script:CleanerRules) {
        if ($rule.Group -ne $lastGroup) {
            $h = New-AWText $rule.Group.ToUpper() 11 $script:Res.Dim 'Bold'
            $h.Margin = if ($lastGroup) { '0,16,0,6' } else { '0,8,0,6' }
            [void]$ui.CleanerItems.Children.Add($h)
            $lastGroup = $rule.Group
        }
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Margin = '0,5'
        $cb.Tag = $rule
        $allowed = Test-AWRuleAllowed $rule
        $cb.IsEnabled = $allowed
        $cb.IsChecked = $rule.Default -and $allowed
        $cb.ToolTip = if ((Test-AWRemote) -and -not $allowed) { "$($rule.Desc)`n`nPer-user item - only available on this PC." } else { $rule.Desc }
        if ((Test-AWRemote) -and -not $allowed) { [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($cb, $true) }

        $sp = New-Object System.Windows.Controls.StackPanel; $sp.Orientation = 'Horizontal'
        [void]$sp.Children.Add((New-AWText $rule.Name 13))
        if ($rule.Admin) { [void]$sp.Children.Add((New-AWPill 'ADMIN' (Test-AWCanAdmin))) }
        $cb.Content = $sp
        [void]$ui.CleanerItems.Children.Add($cb)
        $script:CleanerChecks.Add($cb)
    }
    $ui.BtnAdminReport.Visibility = if (-not $script:IsAdmin -and -not (Test-AWRemote)) { 'Visible' } else { 'Collapsed' }
    if (Test-AWRemote) { $ui.AdminReportBar.Visibility = 'Collapsed' }
    Update-AWAutoCleanCard
}

function Get-AWSelectedRules {
    @($script:CleanerChecks | Where-Object { $_.IsChecked -and $_.IsEnabled } | ForEach-Object { $_.Tag })
}

function Set-AWCleanerBusy([bool]$Busy) {
    $script:CleanerBusy = $Busy
    $ui.BtnAnalyze.IsEnabled = -not $Busy
    $ui.BtnClean.IsEnabled   = -not $Busy
    $ui.BtnAdminReport.IsEnabled = -not $Busy
    $ui.AcRunNow.IsEnabled = -not $Busy -and -not (Test-AWRemote)
    foreach ($cb in $script:CleanerChecks) { if (Test-AWRuleAllowed $cb.Tag) { $cb.IsEnabled = -not $Busy } }
}

function Show-AWCleanResults($Result, [string]$Mode) {
    $rows = New-Object System.Collections.Generic.List[object]
    $subs = @{}
    [long]$total = 0; [long]$files = 0
    foreach ($r in $Result) {
        if ($null -eq $r -or $null -eq $r.Name) { continue }
        $dot = if ($r.Note -match 'running|Skipped|skipped|Error') { $script:Res.Amber } elseif ([long]$r.Bytes -gt 0) { $script:Res.Teal } else { $script:Res.Dim }
        $row = [pscustomobject]@{
            Name  = $(if ($r.Sub) { '      ' + $r.Name } else { $r.Name })
            Group = $r.Group
            Files = '{0:N0}' -f [long]$r.Files
            Size  = Format-AWSize ([long]$r.Bytes)
            Note  = $r.Note
            Dot   = $dot
            Bytes = [long]$r.Bytes
            Id    = $r.Id
        }
        # Per-app lines of the rules found by looking go under their rule's line and aren't counted twice.
        if ($r.Sub) { if (-not $subs[$r.Id]) { $subs[$r.Id] = New-Object System.Collections.Generic.List[object] }; $subs[$r.Id].Add($row); continue }
        $total += [long]$r.Bytes; $files += [long]$r.Files
        $rows.Add($row)
    }
    $ui.CleanResults.ItemsSource = @(foreach ($row in @($rows | Sort-Object Bytes -Descending)) { $row; if ($subs[$row.Id]) { $subs[$row.Id] } })
    $ui.CleanProgress.Value = 100

    if ($Mode -eq 'Analyze') {
        $ui.CleanSummary.Text = '{0} to clean' -f (Format-AWSize $total)
        $ui.CleanSubtext.Text = '{0:N0} files across {1} rule(s). Review the list, then press Run Cleaner.' -f $files, $rows.Count
        $script:IdleStatus = "Analysis complete - $(Format-AWSize $total) can be removed"
    } else {
        $ui.CleanSummary.Text = '{0} freed' -f (Format-AWSize $total)
        $ui.CleanSubtext.Text = '{0:N0} files removed. Files that were in use were skipped safely.' -f $files
        if ($Mode -eq 'Auto') {
            # "Run now" of automatic cleanup: recorded like a scheduled run (last run, what it freed, what was skipped).
            [long]$held = 0; $open = @()
            foreach ($r in $Result) {
                if (-not ($r -is [hashtable]) -or -not $r.Skipped) { continue }
                if ($r.Sub) { $open += $r.Name; continue }
                $held += [long]$r.Held; $open += @($r.Blockers | ForEach-Object { $_.Label })
            }
            $open = @($open | Where-Object { $_ } | Select-Object -Unique)
            Write-AWAction 'AutoClean' ($rows | ForEach-Object Id) @{ Bytes = $total; Files = $files; SkippedOpen = $open; RunNow = $true } 'Done'
            Save-AWAutoCleanRun $total $held $open
            Update-AWAutoCleanSummary
        } else {
            Write-AWAction 'Clean' ($rows | ForEach-Object Name) @{ Bytes = $total; Files = $files } 'Done'
            $script:State.TotalFreed += $total
            $script:State.Cleans++
            $script:State.LastClean = (Get-Date).ToString('o')
            Save-AWState
        }
        Update-AWDashboard
        $script:IdleStatus = "Clean complete - $(Format-AWSize $total) freed"
    }
}

function Start-AWAnalyze {
    if ($script:CleanerBusy) { return }
    $rules = Get-AWSelectedRules
    if ($rules.Count -eq 0) { Show-AWMessage 'Select at least one cleaning rule first.'; return }
    Set-AWCleanerBusy $true
    $ui.CleanSummary.Text = 'Analyzing...'
    $ui.CleanSubtext.Text = 'Measuring temp files and caches. Nothing is deleted during analysis.'
    $ui.CleanProgress.Value = 0
    Start-AWTask -Name 'Analyze' -Arguments @{ Rules = $rules } -Work {
        $i = 0
        foreach ($rule in $Rules) {
            $Sync.Status = "Analyzing: $($rule.Name)"
            $Sync.Progress = [int]($i * 100 / $Rules.Count)
            try { Invoke-WTarget { param($r) Measure-WItem $r } -ArgumentList @(, $rule) }
            catch { @{ Id = $rule.Id; Name = $rule.Name; Group = $rule.Group; Files = 0; Bytes = [long]0; Note = "Error: $($_.Exception.Message)" } }
            $i++
        }
        $Sync.Progress = 100
    } -OnComplete {
        param($Result)
        Show-AWCleanResults $Result 'Analyze'
        Set-AWCleanerBusy $false
    }
}

function Start-AWClean($Rules = $null, [string]$Mode = 'Clean') {
    if ($script:CleanerBusy) { return }
    $rules = if ($null -ne $Rules) { @($Rules) } else { Get-AWSelectedRules }
    if ($rules.Count -eq 0) { Show-AWMessage 'Select at least one cleaning rule first.'; return }
    $script:CleanMode = $Mode
    if (Test-AWRemote) { Confirm-AWClean $rules @(); return }
    # On this PC, look for apps that are open first: their rules would be skipped, so offer to close them.
    $script:PendingCleanRules = $rules
    Set-AWCleanerBusy $true
    $ui.CleanSubtext.Text = 'Checking for open apps...'
    Start-AWTask -Name 'Check open apps' -Arguments @{ Rules = $rules } -Work {
        foreach ($rule in $Rules) {
            if (-not $rule.Process -and $rule.Kind -ne 'Found') { continue }
            $bl = @(Get-WRuleBlockers $rule)
            if (-not $bl.Count) { continue }
            if ($rule.Kind -eq 'Found') {
                foreach ($b in $bl) { [long]$n = 0; foreach ($t in $b.Set.Targets) { foreach ($f in (Get-WFoundFiles $t)) { $n += $f.Length } }; $b.Bytes = $n; $b.Remove('Set'); $b }
            } else {
                $m = try { [long](@(Measure-WItem $rule) | Select-Object -First 1).Bytes } catch { [long]0 }
                $first = $true
                foreach ($b in $bl) { $b.Bytes = $(if ($first) { $m } else { [long]0 }); $first = $false; $b }
            }
        }
    } -OnComplete {
        param($Result)
        Set-AWCleanerBusy $false
        $ui.CleanSubtext.Text = ''
        Confirm-AWClean $script:PendingCleanRules @($Result | Where-Object { $_ -is [hashtable] -and $_.Label })
    }
}

# "Close these apps to clean them": returns 'Close', 'Rest' or 'Cancel'.
function Show-AWCloseAppsDialog($Blockers) {
    [xml]$dx = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Close these apps to clean them" Width="480" SizeToContent="Height" WindowStartupLocation="CenterOwner" ResizeMode="NoResize"
        Background="#151922" Foreground="#E6E9F0" FontFamily="Segoe UI" ShowInTaskbar="False">
  <StackPanel Margin="22,18">
    <TextBlock Text="Close these apps to clean them" FontSize="17" FontWeight="SemiBold"/>
    <ItemsControl x:Name="Apps" Margin="0,12,0,0">
      <ItemsControl.ItemTemplate><DataTemplate><TextBlock Text="{Binding}" Margin="0,3" TextWrapping="Wrap" FontWeight="SemiBold"/></DataTemplate></ItemsControl.ItemTemplate>
    </ItemsControl>
    <TextBlock Text="They close normally, as if you clicked X. Browsers bring your tabs back next time; anything unsaved will ask first."
               Foreground="#AEB4C2" TextWrapping="Wrap" Margin="0,12,0,0" FontSize="12.5"/>
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,18,0,0">
      <Button x:Name="BCancel" Content="Cancel" Padding="14,7" Margin="0,0,8,0" Background="#2C3341" Foreground="#E6E9F0" BorderThickness="0" IsCancel="True"/>
      <Button x:Name="BRest" Content="Clean the rest" Padding="14,7" Margin="0,0,8,0" Background="#2C3341" Foreground="#E6E9F0" BorderThickness="0"/>
      <Button x:Name="BClose" Content="Close them and clean" Padding="14,7" Background="#2563EB" Foreground="White" BorderThickness="0" IsDefault="True"/>
    </StackPanel>
  </StackPanel>
</Window>
'@
    $d = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $dx))
    $d.Owner = $window
    $lines = foreach ($g in @($Blockers | Group-Object { $_.Label })) {
        [long]$b = 0; foreach ($x in $g.Group) { $b += [long]$x.Bytes }
        '{0} - {1}{2}' -f $g.Name, ((@($g.Group | ForEach-Object { $_.RuleName } | Select-Object -Unique)) -join ', '), $(if ($b -gt 0) { ', ' + (Format-AWSize $b) } else { '' })
    }
    $d.FindName('Apps').ItemsSource = @($lines)
    $script:CloseAppsAnswer = 'Cancel'
    $d.FindName('BClose').Add_Click({ $script:CloseAppsAnswer = 'Close'; $script:CloseAppsDlg.Close() })
    $d.FindName('BRest').Add_Click({ $script:CloseAppsAnswer = 'Rest'; $script:CloseAppsDlg.Close() })
    $script:CloseAppsDlg = $d
    [void]$d.ShowDialog()
    $script:CloseAppsAnswer
}

function Confirm-AWClean($Rules, $Blockers) {
    $rules = @($Rules); $closeFirst = @()
    $names = ($rules | ForEach-Object { "  - $($_.Name)" }) -join "`n"
    $where = if (Test-AWRemote) { " on $($script:Target.ComputerName)" } else { '' }
    $warn = @()
    if (@($rules | Where-Object { $_.Kind -eq 'RecycleBin' }).Count) { $warn += 'WARNING: the Recycle Bin will be emptied PERMANENTLY. Its items can no longer be restored (not even from Recovery > Recycle Bin).' }
    if (@($rules | Where-Object { $_.Id -eq 'MemDumps' }).Count) { $warn += 'WARNING: system memory dumps will be deleted. The Crashes tab can no longer analyze those past blue screens.' }
    $warnText = if ($warn.Count) { "`n`n" + ($warn -join "`n`n") } else { '' }
    if (-not (Confirm-AW "Computer Doctor will permanently delete the files matched by these rules$($where) (nothing goes to the Recycle Bin):`n`n$names$warnText`n`nFiles that are in use are skipped. Continue?")) { return }
    # Then, if apps that hold back some of these rules are open: close them first, or clean the rest.
    if (@($Blockers).Count) {
        $ans = Show-AWCloseAppsDialog $Blockers
        if ($ans -eq 'Cancel') { return }
        if ($ans -eq 'Close') { $closeFirst = @($Blockers) }
        else {
            # Clean the rest: leave out the rules whose app is open (rules found by looking skip open apps themselves).
            $held = @($Blockers | ForEach-Object { $_.RuleId } | Select-Object -Unique)
            $rules = @($rules | Where-Object { $_.Kind -eq 'Found' -or $held -notcontains $_.Id })
            if (-not $rules.Count) { return }
        }
    }
    Set-AWCleanerBusy $true
    $ui.CleanSummary.Text = 'Cleaning...'
    $ui.CleanSubtext.Text = $(if ($closeFirst.Count) { 'Closing the open apps, then removing files. Locked files are skipped automatically.' } else { 'Removing files. Locked files are skipped automatically.' })
    $ui.CleanProgress.Value = 0
    Start-AWTask -Name 'Clean' -Arguments @{ Rules = $rules; Blockers = $closeFirst } -Work {
        $still = @()
        if (@($Blockers).Count) {
            $Sync.Status = 'Closing apps...'
            [void](Close-WBlockers $Blockers)
            Write-WLog ('Asked ' + ((@($Blockers | ForEach-Object { $_.Label } | Select-Object -Unique)) -join ', ') + ' to close')
            $still = @(Wait-WBlockersClosed $Blockers 15)
            if ($still.Count) { Write-WLog "Still open, skipped: $($still -join ', ')" 'WARN' }
        }
        $i = 0
        foreach ($rule in $Rules) {
            $Sync.Status = "Cleaning: $($rule.Name)"
            $Sync.Progress = [int]($i * 100 / $Rules.Count)
            $out = try { @(Invoke-WTarget { param($r) Invoke-WClean $r } -ArgumentList @(, $rule)) }
            catch {
                Write-WLog "$($rule.Name): $($_.Exception.Message)" 'ERROR'
                @(@{ Id = $rule.Id; Name = $rule.Name; Group = $rule.Group; Files = 0; Bytes = [long]0; Note = "Error: $($_.Exception.Message)" })
            }
            foreach ($x in $out) {
                if ($still.Count -and $x -is [hashtable] -and $x.Skipped) {
                    $names = @(if ($x.Sub) { if ($still -contains $x.Name) { $x.Name } } else { @($x.Blockers | ForEach-Object { $_.Label } | Where-Object { $still -contains $_ } | Select-Object -Unique) })
                    if ($names.Count) { $x.Note = "$($names -join ', ') still open - skipped" }
                }
                $x
            }
            $i++
        }
        $Sync.Progress = 100
    } -OnComplete {
        param($Result)
        Show-AWCleanResults $Result $script:CleanMode
        Set-AWCleanerBusy $false
    }
}

# ---- Automatic cleanup card (this PC, this account, rules that don't need admin)
$script:AcDays = @('Daily', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
$script:AcLoading = $false

function Update-AWAutoCleanSummary {
    $ac = $script:State.AutoClean
    $when = if ($ac.Day -eq 'Daily') { "every day at $($ac.Time)" } else { "every $($ac.Day) at $($ac.Time)" }
    $last = 'Not run yet.'
    if ($ac.LastRun) {
        $t = try { ([datetime]::Parse([string]$ac.LastRun, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind)).ToLocalTime().ToString('MMM d, HH:mm') } catch { [string]$ac.LastRun }
        $last = "Last run $($t): $(if ($ac.LastResult) { $ac.LastResult } else { 'freed ' + (Format-AWSize ([long]$ac.LastFreed)) })."
    }
    $n = @(Get-AWAutoCleanRules).Count
    $ui.AcSummary.Text = if ($ac.Enabled) { "On - $when, $n rule(s). $last" }
                         else { 'Off - cleans the rules you choose on a schedule, for your account only (no administrator rights needed).' + $(if ($ac.LastRun) { " $last" } else { '' }) }
}

function Update-AWAutoCleanCard {
    $remote = Test-AWRemote
    $ac = $script:State.AutoClean
    $ui.AcRemoteNote.Visibility = if ($remote) { 'Visible' } else { 'Collapsed' }
    foreach ($c in 'AcOn', 'AcMore', 'AcRunNow') { $ui[$c].IsEnabled = -not $remote -and -not $script:CleanerBusy }
    if ($remote) { $ui.AcDetails.Visibility = 'Collapsed' }
    $script:AcLoading = $true
    try {
        $ui.AcOn.IsChecked = [bool]$ac.Enabled
        $ui.AcDay.SelectedIndex = [Math]::Max(0, [array]::IndexOf($script:AcDays, [string]$ac.Day))
        $ui.AcTime.Text = [string]$ac.Time
        # Never set up: the rules that are on by default and don't need admin, without the Recycle Bin.
        $sel = if (@($ac.Rules).Count -or $ac.Enabled) { @($ac.Rules) } else { Get-AWAutoCleanDefaultIds }
        $ui.AcRules.Children.Clear()
        foreach ($rule in @($script:CleanerRules | Where-Object { -not $_.Admin })) {
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content = $rule.Name; $cb.Tag = $rule.Id; $cb.ToolTip = $rule.Desc; $cb.Width = 230; $cb.Margin = '0,3'
            $cb.IsChecked = $sel -contains $rule.Id
            $cb.Add_Click({ Save-AWAutoCleanRules })
            [void]$ui.AcRules.Children.Add($cb)
        }
    } finally { $script:AcLoading = $false }
    Update-AWAutoCleanSummary
}

function Get-AWAutoCleanTicked { @($ui.AcRules.Children | Where-Object { $_.IsChecked } | ForEach-Object { [string]$_.Tag }) }
function Save-AWAutoCleanRules {
    $script:State.AutoClean.Rules = @(Get-AWAutoCleanTicked)
    Save-AWState
    Update-AWAutoCleanSummary
}

# The task runs a copy of this script from %LOCALAPPDATA%\ComputerDoctor\AutoClean, so it still works if the downloaded
# copy moves. Signed-in user only, no admin, doesn't wake the PC, catches up after a missed start, stops after an hour.
function Register-AWAutoCleanTask {
    $ac = $script:State.AutoClean
    $dir = Join-Path $script:DataDir 'AutoClean'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $copy = Join-Path $dir 'ComputerDoctor.ps1'
    if ($PSCommandPath -and $PSCommandPath -ne $copy) { Copy-Item -LiteralPath $PSCommandPath -Destination $copy -Force -ErrorAction Stop }
    $exe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $action = New-ScheduledTaskAction -Execute $exe -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$copy`" -AutoClean"
    $at = [datetime]::ParseExact([string]$ac.Time, 'H:mm', $null)
    $trigger = if ($ac.Day -eq 'Daily') { New-ScheduledTaskTrigger -Daily -At $at } else { New-ScheduledTaskTrigger -Weekly -DaysOfWeek $ac.Day -At $at }
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)
    $principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $script:AutoCleanTask -TaskPath '\' -Action $action -Trigger $trigger -Settings $settings -Principal $principal `
        -Description 'Automatic cleanup set up in Computer Doctor (Cleaner > Automatic cleanup).' -Force -ErrorAction Stop | Out-Null
}

function Set-AWAutoCleanOn([bool]$On) {
    if ($script:AcLoading) { return }
    $ac = $script:State.AutoClean
    if ($On) {
        $ac.Rules = @(Get-AWAutoCleanTicked)
        if (-not $ac.Rules.Count) { $ac.Rules = @(Get-AWAutoCleanDefaultIds) }
        try {
            Register-AWAutoCleanTask
            $ac.Enabled = $true
            Write-AWLog "Automatic cleanup on: $($ac.Day) at $($ac.Time), $(@(Get-AWAutoCleanRules).Count) rule(s)"
            Write-AWAction 'AutoCleanSchedule' @("$($ac.Day) $($ac.Time)") @{ Rules = @($ac.Rules) } 'Done'
        } catch {
            $ac.Enabled = $false
            Show-AWMessage "Could not schedule automatic cleanup:`n$($_.Exception.Message)" 'Error'
        }
    } else {
        $ac.Enabled = $false
        try {
            if (Get-ScheduledTask -TaskName $script:AutoCleanTask -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $script:AutoCleanTask -Confirm:$false -ErrorAction Stop }
            Write-AWLog 'Automatic cleanup off - scheduled task removed'
            Write-AWAction 'AutoCleanSchedule' @('removed') @{} 'Done'
        } catch { Write-AWLog "Could not remove the automatic cleanup task: $($_.Exception.Message)" 'WARN' }
    }
    Save-AWState
    Update-AWAutoCleanCard
}

# Day or time changed: save, and move the task when it's on.
function Save-AWAutoCleanSchedule {
    if ($script:AcLoading) { return }
    $ac = $script:State.AutoClean
    $time = $ui.AcTime.Text.Trim()
    if ($time -notmatch '^([01]?\d|2[0-3]):[0-5]\d$') { Show-AWMessage 'Enter the time as HH:mm, e.g. 12:00.'; $ui.AcTime.Text = $ac.Time; return }
    $day = if ($ui.AcDay.SelectedItem) { [string]$ui.AcDay.SelectedItem.Content } else { 'Sunday' }
    if ($day -eq $ac.Day -and $time -eq $ac.Time) { return }
    $ac.Day = $day; $ac.Time = $time
    if ($ac.Enabled) {
        try { Register-AWAutoCleanTask; Write-AWLog "Automatic cleanup moved to $day at $time" }
        catch { Show-AWMessage "Could not update the schedule:`n$($_.Exception.Message)" 'Error' }
    }
    Save-AWState
    Update-AWAutoCleanSummary
}

function Start-AWAutoCleanNow {
    $ids = @(Get-AWAutoCleanTicked)
    $rules = @($script:CleanerRules | Where-Object { -not $_.Admin -and $ids -contains $_.Id })
    if (-not $rules.Count) { Show-AWMessage 'Choose at least one rule for automatic cleanup (Settings).'; return }
    $script:State.AutoClean.Rules = $ids; Save-AWState
    Start-AWClean $rules 'Auto'
}

$ui.AcOn.Add_Checked({ Set-AWAutoCleanOn $true })
$ui.AcOn.Add_Unchecked({ Set-AWAutoCleanOn $false })
$ui.AcMore.Add_Click({ $ui.AcDetails.Visibility = if ($ui.AcDetails.Visibility -eq 'Visible') { 'Collapsed' } else { 'Visible' } })
$ui.AcRunNow.Add_Click({ Start-AWAutoCleanNow })
$ui.AcDay.Add_SelectionChanged({ Save-AWAutoCleanSchedule })
$ui.AcTime.Add_LostFocus({ Save-AWAutoCleanSchedule })
$ui.AcTime.Add_KeyDown({ param($s, $e) if ($e.Key -eq 'Return') { Save-AWAutoCleanSchedule } })

# ---- Report for an administrator (when not running as admin): the admin cleanups, sized where readable, with steps.
function Start-AWAdminReport {
    if ($script:CleanerBusy) { return }
    $rules = @($script:CleanerChecks | Where-Object { $_.Tag.Admin -and ($_.IsChecked -or $_.Tag.Default) } | ForEach-Object { $_.Tag })
    if (-not $rules.Count) { Show-AWMessage 'No cleanups that need administrator rights are chosen.'; return }
    Set-AWCleanerBusy $true
    $ui.AdminReportInfo.Text = 'Building the report...'; $ui.AdminReportBar.Visibility = 'Visible'
    Start-AWTask -Name 'Report for an administrator' -Arguments @{ Rules = $rules; ScriptPath = $PSCommandPath } -Work {
        $items = foreach ($rule in $Rules) {
            # Measured only where this account can read the folders; otherwise the admin measures it.
            $roots = if ($rule.Kind -eq 'Found') { @($rule.Discover.Bases | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_) }) } else { @($rule.Targets | ForEach-Object { Resolve-WTarget $_.Path }) }
            $readable = $true
            foreach ($r in $roots) {
                try { $en = [IO.Directory]::EnumerateFileSystemEntries($r).GetEnumerator(); [void]$en.MoveNext() }
                catch { if ($_.Exception -is [UnauthorizedAccessException] -or $_.Exception.InnerException -is [UnauthorizedAccessException]) { $readable = $false } }
            }
            $b = [long]-1
            if ($readable) { try { $b = [long](@(Measure-WItem $rule) | Select-Object -First 1).Bytes } catch { $b = [long]-1 } }
            @{ Id = $rule.Id; Name = $rule.Name; Desc = $rule.Desc; Bytes = $b }
        }
        $os = try { Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch { $null }
        $d = New-Object IO.DriveInfo $env:SystemDrive
        $info = @{
            Computer = $env:COMPUTERNAME; User = "$env:USERDOMAIN\$env:USERNAME"; Date = (Get-Date).ToString('yyyy-MM-dd HH:mm')
            Windows = $(if ($os) { "$($os.Caption) ($($os.Version))" } else { [Environment]::OSVersion.VersionString })
            Drive = $(try { '{0} {1} free of {2}' -f $env:SystemDrive, (Format-WSize $d.AvailableFreeSpace), (Format-WSize $d.TotalSize) } catch { $env:SystemDrive })
        }
        New-WAdminReport $info @($items) $ScriptPath
    } -OnComplete {
        param($Result)
        Set-AWCleanerBusy $false
        $rep = @($Result | Where-Object { $_ -is [hashtable] -and $_.Html }) | Select-Object -Last 1
        if (-not $rep) { $ui.AdminReportInfo.Text = 'The report could not be built - see the Activity log.'; return }
        $file = Join-Path ([Environment]::GetFolderPath('MyDocuments')) ('Computer Doctor admin cleanup - {0} - {1:yyyy-MM-dd}.html' -f $env:COMPUTERNAME, (Get-Date))
        try {
            [IO.File]::WriteAllText($file, $rep.Html, (New-Object System.Text.UTF8Encoding $true))
            $script:AdminReportText = $rep.Text
            $ui.BtnAdminReportCopy.Visibility = 'Visible'
            $ui.AdminReportInfo.Text = "Saved to $file"
            $ui.AdminReportInfo.ToolTip = $file
            Write-AWLog "Report for an administrator saved to $file"
            Start-Process -FilePath $file
        } catch { $ui.AdminReportInfo.Text = "Could not save the report: $($_.Exception.Message)" }
    }
}
$ui.BtnAdminReport.Add_Click({ Start-AWAdminReport })
$ui.BtnAdminReportCopy.Add_Click({
    if ($script:AdminReportText) { [System.Windows.Clipboard]::SetText($script:AdminReportText); $ui.AdminReportInfo.Text = 'Copied as text - paste it into an email or chat.' }
})

$ui.BtnAnalyze.Add_Click({ Start-AWAnalyze })
$ui.BtnClean.Add_Click({ Start-AWClean })
$ui.RulesAll.Add_Click({     foreach ($cb in $script:CleanerChecks) { if ($cb.IsEnabled) { $cb.IsChecked = $true } } })
$ui.RulesNone.Add_Click({    foreach ($cb in $script:CleanerChecks) { $cb.IsChecked = $false } })
$ui.RulesDefault.Add_Click({ foreach ($cb in $script:CleanerChecks) { $cb.IsChecked = $cb.IsEnabled -and $cb.Tag.Default } })
#endregion

#region ---------------------------------------------------------------- Space Map
$script:Scanner = $null
$script:MapRoot = $null
$script:MapCurrent = $null
$script:MapSelected = $null
$script:MapSelectedBorder = $null
$script:MapMaxDepth = 2
$script:ScanExpected = 0
$script:BrushCache = @{}
$script:MapPalette = @{
    Dir   = @('#075985', '#0369A1', '#0284C7', '#0EA5E9')
    File  = @('#1E40AF', '#2563EB', '#3B82F6', '#60A5FA')
    Group = @('#242A36', '#2C3341', '#353C4B', '#3F4757')
}
$script:MapEdge = New-Brush '#0B0D12'
$script:MapSelEdge = New-Brush '#FFFFFF'

# ---- "Highlight what you can clean": green = inside a target of a rule that doesn't need admin, or an old installer
# in Downloads; red = a folder this account can't delete or read. This PC only.
$script:MapGreenEdge = New-Brush '#4ADE80'; $script:MapRedEdge = New-Brush '#F87171'
$script:MapGreenFill = New-Object System.Windows.Media.LinearGradientBrush(([System.Windows.Media.Color]::FromRgb(0x1F, 0x7A, 0x45)), ([System.Windows.Media.Color]::FromRgb(0x16, 0x65, 0x34)), 90); $script:MapGreenFill.Freeze()
$script:MapRedFill = New-Object System.Windows.Media.LinearGradientBrush(([System.Windows.Media.Color]::FromRgb(0x99, 0x24, 0x24)), ([System.Windows.Media.Color]::FromRgb(0x7F, 0x1D, 0x1D)), 90); $script:MapRedFill.Freeze()
$script:CleanMapState = ''        # '' = not loaded, 'Loading', 'Ready'
$script:MapRightsPending = $false
$script:MapInstallerExt = @('.exe', '.msi', '.msix', '.msixbundle', '.appx', '.iso')
$script:MapDownloads = try {
    $p = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop).'{374DE290-123F-4565-9164-39C4925E467B}'
    if ($p) { [Environment]::ExpandEnvironmentVariables($p).TrimEnd('\') } else { Join-Path $env:USERPROFILE 'Downloads' }
} catch { Join-Path $env:USERPROFILE 'Downloads' }

function Test-AWMapHighlight { [bool]$script:State.MapHighlight -and -not (Test-AWRemote) -and -not $script:ScanRemote }

# The folders cleaner rules would empty, expanded on this PC (found in the background once per session).
function Start-AWCleanMapLoad {
    if ($script:CleanMapState) { return }
    $script:CleanMapState = 'Loading'
    Start-AWTask -Name 'Find what can be cleaned' -Arguments @{ Rules = @($script:CleanerRules | Where-Object { -not $_.Admin }) } -Work {
        Get-WCleanMapEntries $Rules
    } -OnComplete {
        param($Result)
        [ComputerDoctor.CleanMap]::Clear()
        foreach ($e in @($Result | Where-Object { $_ -is [hashtable] -and $_.Path })) { [ComputerDoctor.CleanMap]::Add($e.Path, $e.Filter, [bool]$e.Recurse, $e.Reason) }
        $script:CleanMapState = 'Ready'
        if ($script:MapCurrent) { Request-AWMapRedraw }
    }
}

# Why a tile is green or red: @{ Green; Text; Rule } or $null.
function Get-AWMapMark($Node) {
    if ($Node.IsGroup -or $Node.IsDir) {
        $r = [ComputerDoctor.CleanMap]::Match($Node.FullPath, $true)
        if ($r) { return @{ Green = $true; Text = "Junk you can clean: $r"; Rule = $true } }
        if ($Node.IsGroup) { return $null }
        $st = if ($Node.Denied) { 3 } else { [ComputerDoctor.FolderRights]::Get($Node.FullPath) }
        if ($st -eq 0) { $script:MapRightsPending = $true; return $null }
        if ($st -ge 2) { return @{ Green = $false; Text = "Your account can't delete this" + $(if ($script:IsAdmin) { ' - protected by Windows' } else { ' - run as administrator to clean here' }); Rule = $false } }
        return $null
    }
    $r = [ComputerDoctor.CleanMap]::Match($Node.FullPath, $false)
    if ($r) { return @{ Green = $true; Text = "Junk you can clean: $r"; Rule = $true } }
    if ($script:MapDownloads -and $Node.FullPath.StartsWith($script:MapDownloads + '\', [StringComparison]::OrdinalIgnoreCase) -and
        $script:MapInstallerExt -contains [IO.Path]::GetExtension($Node.Name).ToLowerInvariant() -and
        $Node.Modified -ne [datetime]::MinValue -and $Node.Modified -lt (Get-Date).AddDays(-30)) {
        return @{ Green = $true; Text = 'Old installer in Downloads'; Rule = $false }
    }
    $null
}

# Folder rights are checked in the background for the tiles drawn; redraw once they're known.
$script:MapRightsTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:MapRightsTimer.Interval = [TimeSpan]::FromMilliseconds(400)
$script:MapRightsTimer.Add_Tick({
    if ([ComputerDoctor.FolderRights]::Pending -gt 0) { return }
    $script:MapRightsTimer.Stop()
    Show-AWTreeMap
})

function Get-AWMapBrush($Node, [int]$Depth) {
    $kind = if ($Node.IsGroup) { 'Group' } elseif ($Node.IsDir) { 'Dir' } else { 'File' }
    $key = "$kind$Depth"
    if (-not $script:BrushCache.ContainsKey($key)) {
        $hex  = $script:MapPalette[$kind][[Math]::Min($Depth, 3)]
        $base = [System.Windows.Media.ColorConverter]::ConvertFromString($hex)
        $top  = [System.Windows.Media.Color]::FromRgb(
            [byte][Math]::Min(255, $base.R + 28), [byte][Math]::Min(255, $base.G + 28), [byte][Math]::Min(255, $base.B + 28))
        $b = New-Object System.Windows.Media.LinearGradientBrush($top, $base, 90)
        $b.Freeze()
        $script:BrushCache[$key] = $b
    }
    $script:BrushCache[$key]
}

# Shared right-click menu
$script:MapMenu = New-Object System.Windows.Controls.ContextMenu
$script:MapMenu.Style = $window.FindResource('CtxMenu')
$script:MapMenuNode = $null
function Add-AWMenuItem($Menu, [string]$Header, [scriptblock]$Action) {
    $mi = New-Object System.Windows.Controls.MenuItem
    $mi.Header = $Header; $mi.Style = $window.FindResource('CtxItem'); $mi.Tag = $Action
    $mi.Add_Click({ param($s, $e) & $s.Tag })
    [void]$Menu.Items.Add($mi)
    $mi
}
$script:MenuZoom = Add-AWMenuItem $script:MapMenu 'Zoom in'           { if ($script:MapMenuNode) { Set-AWMapCurrent $script:MapMenuNode } }
[void](Add-AWMenuItem $script:MapMenu 'Open in Explorer'              { if ($script:MapMenuNode) { Open-AWExplorer $script:MapMenuNode.FullPath } })
[void](Add-AWMenuItem $script:MapMenu 'Copy path'                     { if ($script:MapMenuNode) { [System.Windows.Clipboard]::SetText($script:MapMenuNode.FullPath) } })
$script:MenuRecycle = Add-AWMenuItem $script:MapMenu 'Send to Recycle Bin' { if ($script:MapMenuNode) { Remove-AWMapNodeToRecycle $script:MapMenuNode } }
$script:MenuOpenCleaner = Add-AWMenuItem $script:MapMenu 'Open Cleaner' { Select-AWView 'Cleaner' }

function Select-AWMapNode($Node, $Border) {
    if ($script:MapSelectedBorder) {
        $m = $script:MapSelectedBorder.DataContext
        if ($m -and $m.Edge) { $script:MapSelectedBorder.BorderBrush = $m.Edge; $script:MapSelectedBorder.BorderThickness = 2 }
        else { $script:MapSelectedBorder.BorderBrush = $script:MapEdge; $script:MapSelectedBorder.BorderThickness = 1 }
    }
    $script:MapSelected = $Node
    $script:MapSelectedBorder = $Border
    if ($Border) { $Border.BorderBrush = $script:MapSelEdge; $Border.BorderThickness = 2 }
    $ui.MapSelReason.Visibility = 'Collapsed'; $ui.MapOpenCleaner.Visibility = 'Collapsed'
    if (-not $Node) {
        $ui.MapSelName.Text = 'Nothing selected'; $ui.MapSelPath.Text = ''; $ui.MapSelSize.Text = ''; $ui.MapSelMeta.Text = ''
        $ui.MapOpen.IsEnabled = $false; $ui.MapZoom.IsEnabled = $false; $ui.MapRecycle.IsEnabled = $false
        return
    }
    if (Test-AWMapHighlight) {
        $mark = Get-AWMapMark $Node
        if ($mark) {
            $ui.MapSelReason.Text = $mark.Text
            $ui.MapSelReason.Foreground = if ($mark.Green) { $script:MapGreenEdge } else { $script:MapRedEdge }
            $ui.MapSelReason.Visibility = 'Visible'
            if ($mark.Rule) { $ui.MapOpenCleaner.Visibility = 'Visible' }
        }
    }
    $ui.MapSelName.Text = $Node.Name
    $ui.MapSelPath.Text = $Node.FullPath
    $ui.MapSelSize.Text = $Node.SizeText
    $ui.MapSelMeta.Text = '{0} - {1:N0} file(s) - {2:0.0}% of parent' -f $Node.Kind, $Node.FileCount, $Node.PercentOfParent
    $ui.MapOpen.IsEnabled = $true
    $ui.MapZoom.IsEnabled = $Node.IsDir -and $Node.Children.Count -gt 0
    $ui.MapRecycle.IsEnabled = -not $Node.IsGroup -and $Node.Parent
}

function Set-AWMapCurrent($Node) {
    if (-not $Node -or -not $Node.IsDir) { return }
    $script:MapCurrent = $Node
    Select-AWMapNode $null $null
    $ui.MapTopList.ItemsSource = @($Node.Children | Select-Object -First 15)
    Show-AWTreeMap
}

function Add-AWTreeMapLevel($Node, [double]$X, [double]$Y, [double]$W, [double]$H, [int]$Depth) {
    $rects = [ComputerDoctor.Treemap]::Layout($Node.Children, $X, $Y, $W, $H)
    $hl = Test-AWMapHighlight
    foreach ($r in $rects) {
        if ($script:MapElementCount -gt 4000) { return }
        if ($r.W -lt 3 -or $r.H -lt 3) { continue }
        $n = $r.Node
        $b = New-Object System.Windows.Controls.Border
        $b.Width = [Math]::Max(1, $r.W - 2); $b.Height = [Math]::Max(1, $r.H - 2)
        [System.Windows.Controls.Canvas]::SetLeft($b, $r.X + 1)
        [System.Windows.Controls.Canvas]::SetTop($b, $r.Y + 1)
        $b.CornerRadius = if ($r.W -gt 24 -and $r.H -gt 24) { '5' } else { '2' }
        $b.Background = Get-AWMapBrush $n $Depth
        $b.BorderBrush = $script:MapEdge; $b.BorderThickness = 1
        $b.Tag = $n
        $b.Cursor = 'Hand'
        $b.ToolTip = "{0}`n{1}  ({2:0.0}%)`n{3}" -f $n.Name, $n.SizeText, $n.PercentOfParent, $n.FullPath
        if ($hl) {
            $mark = Get-AWMapMark $n
            if ($mark) {
                $edge = if ($mark.Green) { $script:MapGreenEdge } else { $script:MapRedEdge }
                $b.Background = if ($mark.Green) { $script:MapGreenFill } else { $script:MapRedFill }
                $b.BorderBrush = $edge; $b.BorderThickness = 2
                $b.DataContext = [pscustomobject]@{ Edge = $edge }
                $b.ToolTip = "$($b.ToolTip)`n`n$($mark.Text)" + $(if ($mark.Rule) { ' (Open Cleaner from the Selected panel or the right-click menu)' } else { '' })
            }
        }
        $b.ContextMenu = $script:MapMenu

        $canNest = $n.IsDir -and $Depth -lt $script:MapMaxDepth -and $r.W -gt 64 -and $r.H -gt 44 -and $n.Children.Count -gt 0
        if ($r.W -gt 42 -and $r.H -gt 17) {
            $sp = New-Object System.Windows.Controls.StackPanel
            $sp.Margin = '6,3,6,0'; $sp.IsHitTestVisible = $false
            $t1 = New-AWText $n.Name 11 $null 'SemiBold'
            $t1.Foreground = [System.Windows.Media.Brushes]::White; $t1.TextTrimming = 'CharacterEllipsis'
            [void]$sp.Children.Add($t1)
            if ($canNest) { $t1.Text = '{0}   {1}' -f $n.Name, $n.SizeText }
            elseif ($r.H -gt 36) {
                $t2 = New-AWText $n.SizeText 10.5; $t2.Foreground = New-Brush '#DCE0EA'; $t2.Opacity = 0.85
                [void]$sp.Children.Add($t2)
            }
            $b.Child = $sp
        }

        $b.Add_MouseLeftButtonDown({
            param($s, $e)
            if ($e.ClickCount -ge 2) { if ($s.Tag.IsDir) { Set-AWMapCurrent $s.Tag } }
            else { Select-AWMapNode $s.Tag $s }
            $e.Handled = $true
        })
        $b.Add_ContextMenuOpening({
            param($s, $e)
            $script:MapMenuNode = $s.Tag
            $script:MenuZoom.IsEnabled = $s.Tag.IsDir -and $s.Tag.Children.Count -gt 0
            $mk = if (Test-AWMapHighlight) { Get-AWMapMark $s.Tag } else { $null }
            $script:MenuOpenCleaner.Visibility = if ($mk -and $mk.Rule) { 'Visible' } else { 'Collapsed' }
            $script:MenuRecycle.IsEnabled = -not $s.Tag.IsGroup -and $s.Tag.Parent
            Select-AWMapNode $s.Tag $s
        })
        [void]$ui.MapCanvas.Children.Add($b)
        $script:MapElementCount++

        if ($canNest) { Add-AWTreeMapLevel $n ($r.X + 4) ($r.Y + 20) ($r.W - 8) ($r.H - 24) ($Depth + 1) }
    }
}

function Show-AWTreeMap {
    $ui.MapCanvas.Children.Clear()
    $script:MapSelectedBorder = $null
    $node = $script:MapCurrent
    if (-not $node) { return }
    $ui.MapHint.Visibility = 'Collapsed'
    $ui.MapCrumb.Text = $node.FullPath
    $ui.MapCurSize.Text = '{0}  -  {1:N0} files' -f $node.SizeText, $node.FileCount
    $ui.MapUp.IsEnabled = [bool]$node.Parent
    $w = $ui.MapCanvas.ActualWidth; $h = $ui.MapCanvas.ActualHeight
    if ($w -lt 20 -or $h -lt 20) { return }
    $script:MapElementCount = 0
    $script:MapRightsPending = $false
    if (Test-AWMapHighlight) { Start-AWCleanMapLoad }
    Add-AWTreeMapLevel $node 0 0 $w $h 0
    if ($script:MapRightsPending) { $script:MapRightsTimer.Start() }
    if ($script:MapSelected) { Select-AWMapNode $script:MapSelected $null }
}

# Debounced redraw on resize
$script:MapRedrawTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:MapRedrawTimer.Interval = [TimeSpan]::FromMilliseconds(180)
$script:MapRedrawTimer.Add_Tick({ $script:MapRedrawTimer.Stop(); Show-AWTreeMap })
function Request-AWMapRedraw { $script:MapRedrawTimer.Stop(); $script:MapRedrawTimer.Start() }
$ui.MapCanvas.Add_SizeChanged({ Request-AWMapRedraw })
$ui.MapCanvas.Add_MouseLeftButtonDown({ Select-AWMapNode $null $null })

# The UI thread needs the worker library's file-kind table too.
. ([scriptblock]::Create([regex]::Match($Sync.WorkerLib, '(?s)function Get-WFileKind\(.*?\r?\n\}\r?\n').Value))

# Rolls the per-extension totals up into kinds (Videos, Pictures, Installers...).
function Get-AWKindStats($ExtensionList) {
    $tot = @{}; $cnt = @{}; $all = [long]0
    foreach ($e in $ExtensionList) {
        $k = Get-WFileKind ([string]$e.Extension)
        $tot[$k] = [long]$tot[$k] + $e.Size; $cnt[$k] = [long]$cnt[$k] + $e.Count; $all += $e.Size
    }
    if ($all -le 0) { return @() }
    $max = ($tot.Values | Measure-Object -Maximum).Maximum
    $plural = @{ Installer = 'Installers'; 'Disk image' = 'Disk images'; Archive = 'Archives'; Video = 'Videos'; Picture = 'Pictures'; Document = 'Documents' }
    foreach ($k in ($tot.Keys | Sort-Object { $tot[$_] } -Descending)) {
        $x = New-Object ComputerDoctor.ExtStat
        $x.Extension = if ($plural[$k]) { $plural[$k] } else { $k }
        $x.Size = $tot[$k]; $x.Count = $cnt[$k]; $x.Percent = $tot[$k] * 100.0 / $all; $x.RelPercent = $tot[$k] * 100.0 / $max
        $x
    }
}

# ---- Scanning a remote PC: through its admin share (\\PC\C$) when reachable, otherwise by running the
# scanner on that PC over WinRM and rebuilding a trimmed tree here. $script:ScanRemote describes the
# PC the current scan came from ($null = this PC); paths are kept in that PC's own form (C:\...).
$script:SelfPath = $PSCommandPath
$script:ScanRemote = $null
$script:RemoteDrives = @()
function Test-AWMapRemote { (Test-AWRemote) -and $ui.MapOnRemote.IsChecked }
function Get-AWCsSource {
    if (-not $script:CsSource) { $script:CsSource = [regex]::Match([IO.File]::ReadAllText($script:SelfPath), "Add-Type -TypeDefinition @'\r?\n(.*?)\r?\n'@", 'Singleline').Groups[1].Value }
    $script:CsSource
}
function ConvertTo-AWShareUnc([string]$HostName, [string]$Path) {
    if ($Path -match '^([A-Za-z]):\\?(.*)$') { "\\$HostName\$($Matches[1].ToUpper())`$" + $(if ($Matches[2]) { '\' + $Matches[2] } else { '\' }) } else { $Path }
}
function ConvertFrom-AWShareUnc([string]$Path) {
    if ($Path -match '^\\\\[^\\]+\\([A-Za-z])\$(\\.*)?$') { "$($Matches[1].ToUpper()):" + $(if ($Matches[2]) { $Matches[2] } else { '\' }) } else { $Path }
}
# Protected locations on another PC (its own environment isn't known here, so the standard layout is used).
function Test-AWProtectedRemotePath([string]$Path) {
    $p = (ConvertFrom-AWShareUnc $Path).TrimEnd('\')
    if ($p -match '^[A-Za-z]:$') { return $true }
    $rest = $p.Substring(2)
    if ($rest -match '^\\(Windows|Program Files|Program Files \(x86\)|ProgramData|Users|Recovery|System Volume Information|\$Recycle\.Bin|Boot|EFI)(\\.*)?$' -and
        ($Matches[1] -eq 'Windows' -or -not $Matches[2] -or ($Matches[1] -eq 'Users' -and $Matches[2] -match '^\\[^\\]+$'))) { return $true }
    $false
}

function Update-AWMapScope {
    $remote = Test-AWRemote
    $ui.MapScope.Visibility = if ($remote) { 'Visible' } else { 'Collapsed' }
    if ($remote) {
        $ui.MapOnRemote.Content = $script:Target.ComputerName
        $ui.MapScopeText.Text = if ($ui.MapOnRemote.IsChecked) { "Scanning $($script:Target.ComputerName). Drives are read through its \\$($script:Target.ComputerName)\C`$ share, or on that PC over WinRM if the share isn't reachable. Removing files there is permanent (no Recycle Bin over the network)." }
                                else { "Scanning THIS PC ($env:COMPUTERNAME), not $($script:Target.ComputerName)." }
    }
    Update-AWMapHighlightUI
    $ui.MapBrowse.IsEnabled = -not (Test-AWMapRemote)
    $ui.MapBrowse.ToolTip = if (Test-AWMapRemote) { 'Type a folder on the remote PC, e.g. C:\Users' } else { 'Browse for a folder' }
    Initialize-AWMapDrives
    Update-AWViewTitle (Get-AWCurrentView)
}

function Start-AWMapScan([string]$Path) {
    if ($Sync.Scanning) { return }
    if (-not $Path) { $Path = $ui.MapPath.Text }
    $Path = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
    if ($Path -match '^[A-Za-z]:$') { $Path += '\' }
    if (Test-AWMapRemote) { Start-AWRemoteMapScan (ConvertFrom-AWShareUnc $Path); return }
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) { Show-AWMessage "Folder not found:`n$Path" 'Warning'; return }
    $ui.MapPath.Text = $Path
    $script:ScanRemote = $null

    $script:ScanExpected = 0
    $ui.MapKindList.ItemsSource = $null
    try {
        $di = New-Object System.IO.DriveInfo($Path)
        if ($di.RootDirectory.FullName -eq (New-Object System.IO.DirectoryInfo($Path)).FullName) {
            $script:ScanExpected = $di.TotalSize - $di.TotalFreeSpace
        }
    } catch { }

    $script:Scanner = New-Object ComputerDoctor.DiskScanner
    [ComputerDoctor.FolderRights]::Clear()
    $ui.MapDenied.Visibility = 'Collapsed'
    $Sync.Scanning = $true
    $ui.MapScan.IsEnabled = $false; $ui.MapStop.IsEnabled = $true; $ui.LargeScan.IsEnabled = $false
    $ui.MapCanvas.Children.Clear(); $ui.MapHint.Visibility = 'Collapsed'
    $ui.MapCrumb.Text = "Scanning $Path ..."; $ui.MapCurSize.Text = ''
    Select-AWMapNode $null $null

    Start-AWTask -Name "Scan $Path" -Arguments @{ Scanner = $script:Scanner; ScanPath = $Path } -Work {
        [void]$Scanner.Scan($ScanPath)
    } -OnComplete { param($Result) Complete-AWMapScan }
}

function Complete-AWMapScan {
    $Sync.Scanning = $false; $Sync.ScanVia = $null
    $s = $script:Scanner
    $ui.MapScan.IsEnabled = $true; $ui.MapStop.IsEnabled = $false; $ui.LargeScan.IsEnabled = $true
    if (-not $s -or -not $s.Root) { $ui.MapCrumb.Text = 'Scan failed - see the Activity log'; return }
    $script:MapRoot = $s.Root
    # Folders the scan couldn't read (counted for scans of this PC).
    $ui.MapDenied.Visibility = 'Collapsed'
    if (-not $script:ScanRemote -and $s.DeniedFolders -gt 0) {
        $ui.MapDenied.Text = "{0:N0} folders couldn't be read ({1})" -f $s.DeniedFolders, $(if ($script:IsAdmin) { 'protected by Windows' } else { 'needs admin' })
        $ui.MapDenied.Visibility = 'Visible'
    }
    Update-AWMapHighlightUI
    Set-AWMapCurrent $s.Root
    $ui.MapExtList.ItemsSource = @($s.ExtensionList | Select-Object -First 12)
    $ui.MapKindList.ItemsSource = @(Get-AWKindStats $s.ExtensionList)
    Update-AWLargeList
    $state = if ($s.Completed) { 'Scan complete' } else { 'Scan stopped (partial results)' }
    $where = if ($script:ScanRemote) { " on $($script:ScanRemote.ComputerName) (via $($script:ScanRemote.Via))" } else { '' }
    $script:IdleStatus = '{0}{5}: {1:N0} files, {2} in {3:0.0}s - {4:N0} folders unreadable' -f $state, $s.FilesScanned, (Format-AWSize $s.BytesScanned), $s.ElapsedSeconds, $s.Errors, $where
    Write-AWLog $script:IdleStatus
    if ($s.Errors -gt 0 -and -not $script:IsAdmin -and -not $script:ScanRemote) { $script:IdleStatus += ' (run as admin to read protected folders)' }
}

function Start-AWRemoteMapScan([string]$Path) {
    if ($Path -notmatch '^[A-Za-z]:\\') { Show-AWMessage "Type a folder on $($script:Target.ComputerName) like C:\ or D:\Data." 'Warning'; return }
    $ui.MapPath.Text = $Path
    $t = $script:Target
    $drive = $Path.Substring(0, 1).ToUpper()
    $script:ScanExpected = 0
    if ($Path.Length -le 3) { $d = $script:RemoteDrives | Where-Object { $_.Letter -eq $drive } | Select-Object -First 1; if ($d) { $script:ScanExpected = $d.Used } }
    $ui.MapKindList.ItemsSource = $null
    $script:Scanner = New-Object ComputerDoctor.DiskScanner
    $script:ScanRemote = [pscustomobject]@{ Host = $t.Host; ComputerName = $t.ComputerName; Via = 'share' }
    $Sync.Scanning = $true; $Sync.ScanVia = 'Connecting'
    $ui.MapScan.IsEnabled = $false; $ui.MapStop.IsEnabled = $true; $ui.LargeScan.IsEnabled = $false
    $ui.MapCanvas.Children.Clear(); $ui.MapHint.Visibility = 'Collapsed'
    $ui.MapCrumb.Text = "Scanning $Path on $($t.ComputerName)..."; $ui.MapCurSize.Text = ''
    Select-AWMapNode $null $null
    Start-AWTask -Name "Scan $Path on $($t.ComputerName)" -Arguments @{ Scanner = $script:Scanner; LocalPath = $Path; Drive = $drive; CsSrc = (Get-AWCsSource) } -Work {
        $share = "\\$($Target.Host)\$Drive`$"
        $unc = $share + $LocalPath.Substring(2)
        $Sync.Status = "Connecting to $share..."
        $ok = $false
        try {
            if ($Target.Credential) {
                $c = $Target.Credential.GetNetworkCredential()
                $u = if ($c.Domain) { "$($c.Domain)\$($c.UserName)" } else { $c.UserName }
                $rc = [ComputerDoctor.Native]::ConnectShare($share, $u, $c.Password)
                if ($rc -and $rc -ne 1219) { Write-WLog "Could not connect to $share (error $rc) - scanning over WinRM instead" 'WARN' }
            }
            $ok = [IO.Directory]::Exists($unc)
        } catch { }
        if ($ok) { $Sync.ScanVia = 'Share'; [void]$Scanner.Scan($unc); return [pscustomobject]@{ Via = 'share' } }
        if (-not $Target.Credential) { Write-WLog "$share isn't reachable (File and Printer Sharing may be blocked) - scanning on $($Target.ComputerName) over WinRM instead" 'WARN' }
        $Sync.ScanVia = 'WinRM'; $Sync.Status = "Scanning $LocalPath on $($Target.ComputerName) over WinRM (no live progress; large drives take a few minutes)..."
        $text = Invoke-WTarget {
            param($Src, $P)
            if (-not ('ComputerDoctor.DiskScanner' -as [type])) { Add-Type -TypeDefinition $Src }
            $s = New-Object ComputerDoctor.DiskScanner
            [void]$s.Scan($P)
            $s.Export([Math]::Max(1MB, [long]($s.Root.Size / 40000)))
        } -ArgumentList $CsSrc, $LocalPath
        [pscustomobject]@{ Via = 'WinRM'; Text = (@($text) | Where-Object { $_ -is [string] -and $_.StartsWith('H') } | Select-Object -First 1) }
    } -OnComplete {
        param($Result)
        $r = @($Result | Where-Object { $_ -and $_.Via }) | Select-Object -Last 1
        if ($r.Via -eq 'WinRM') {
            if ($r.Text) {
                $script:Scanner = [ComputerDoctor.DiskScanner]::Import($r.Text)
                # Paths come back in the remote PC's own form (C:\...).
                $script:ScanRemote.Via = 'WinRM'
            } else { $script:Scanner = $null }
        } elseif ($r) {
            # Convert \\PC\C$\... back to C:\... so open / delete work the same for both routes.
            $s = $script:Scanner
            $stack = New-Object System.Collections.Generic.Stack[object]; $stack.Push($s.Root)
            while ($stack.Count) { $n = $stack.Pop(); $n.FullPath = ConvertFrom-AWShareUnc $n.FullPath; foreach ($c in $n.Children) { $stack.Push($c) } }
            foreach ($f in $s.TopFiles) { $f.FullPath = ConvertFrom-AWShareUnc $f.FullPath; $f.Folder = ConvertFrom-AWShareUnc $f.Folder }
            $s.Root.Name = $s.Root.FullPath
        }
        if (-not $script:Scanner) { $script:ScanRemote = $null }
        Complete-AWMapScan
    }
}

# Open a scanned item: local path, or the remote PC's admin share.
function Open-AWScanPath([string]$Path) {
    if (-not $script:ScanRemote) { Open-AWExplorer $Path; return }
    $unc = ConvertTo-AWShareUnc $script:ScanRemote.Host $Path
    if (Test-Path -LiteralPath $unc) { Open-AWExplorer $unc } else { Show-AWMessage "Can't open $Path on $($script:ScanRemote.ComputerName) from here - its \\$($script:ScanRemote.ComputerName)\C`$ share isn't reachable." 'Warning' }
}

# Delete items from a remote scan: permanently, on that PC, over WinRM. Returns the paths removed.
function Remove-AWRemoteScanItems([string[]]$Paths, [scriptblock]$OnDone) {
    if (-not (Test-AWRemote) -or $script:Target.Host -ne $script:ScanRemote.Host) { Show-AWMessage "This scan came from $($script:ScanRemote.ComputerName). Connect to it again (title bar) to remove files there." 'Warning'; return }
    $script:PendingRemoteDelete = $OnDone
    Write-AWAction 'DeleteRemoteFiles' @($Paths | Select-Object -First 50) @{ Count = $Paths.Count } 'Started'
    Start-AWTask -Name "Delete $($Paths.Count) item(s) on $($script:ScanRemote.ComputerName)" -Arguments @{ P = $Paths } -Work {
        Invoke-WTarget {
            param($List)
            foreach ($x in $List) {
                try { Remove-Item -LiteralPath $x -Recurse -Force -ErrorAction Stop; Write-WLog "Deleted $x"; $x } catch { Write-WLog "Could not delete $($x): $($_.Exception.Message)" 'WARN' }
            }
        } -ArgumentList (, $P)
    } -OnComplete { param($r) & $script:PendingRemoteDelete @($r | Where-Object { $_ -is [string] }) }
}
function Remove-AWMapNode($Node) {
    $p = $Node.Parent
    if (-not $p) { return }
    [void]$p.Children.Remove($Node)
    $a = $p
    while ($a) { $a.Size -= $Node.Size; $a.FileCount -= $Node.FileCount; $a = $a.Parent }
}

function Test-AWProtectedPath([string]$Path) {
    $p = $Path.TrimEnd('\')
    $protected = @(
        $env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData,
        (Split-Path $env:USERPROFILE -Parent), $env:USERPROFILE, "$env:SystemDrive\Recovery", "$env:SystemDrive\System Volume Information"
    ) | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') }
    if ($p -match '^[A-Za-z]:$') { return $true }
    foreach ($x in $protected) { if ($p -ieq $x) { return $true } }
    if ($p -like "$env:SystemRoot\*") { return $true }
    $false
}

function Send-AWToRecycle([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Container) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
    } else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
    }
}

function Remove-AWMapNodeToRecycle($Node) {
    if (-not $Node -or $Node.IsGroup -or -not $Node.Parent) { return }
    if ($script:ScanRemote) {
        if (Test-AWProtectedRemotePath $Node.FullPath) { Show-AWMessage "Computer Doctor won't remove protected system locations:`n$($Node.FullPath)" 'Warning'; return }
        if (-not (Confirm-AW ("PERMANENTLY delete this {0} on {1}?`n`n{2}`n{3}`n`nFiles on another PC don't go to a Recycle Bin - this can't be undone." -f $Node.Kind.ToLower(), $script:ScanRemote.ComputerName, $Node.FullPath, $Node.SizeText))) { return }
        $script:PendingMapNode = $Node
        Remove-AWRemoteScanItems @($Node.FullPath) {
            param($done)
            if (@($done).Count) { Remove-AWMapNode $script:PendingMapNode; Set-AWMapCurrent $script:MapCurrent }
            else { Show-AWMessage 'Nothing was deleted - see the Activity log.' 'Warning' }
        }
        return
    }
    if (Test-AWProtectedPath $Node.FullPath) { Show-AWMessage "Computer Doctor won't remove protected system locations:`n$($Node.FullPath)" 'Warning'; return }
    if (-not (Confirm-AW ("Send this {0} to the Recycle Bin?`n`n{1}`n{2}" -f $Node.Kind.ToLower(), $Node.FullPath, $Node.SizeText))) { return }
    try {
        Send-AWToRecycle $Node.FullPath
        Write-AWLog "Recycled $($Node.FullPath) ($($Node.SizeText))"
        Remove-AWMapNode $Node
        Set-AWMapCurrent $script:MapCurrent
    } catch {
        Show-AWMessage "Could not recycle:`n$($_.Exception.Message)" 'Error'
    }
}

function Update-AWMapHighlightUI {
    $remote = Test-AWRemote
    $ui.MapHighlight.IsEnabled = -not $remote
    $ui.MapHlNote.Visibility = if ($remote) { 'Visible' } else { 'Collapsed' }
    $ui.MapHlLegend.Visibility = if (Test-AWMapHighlight) { 'Visible' } else { 'Collapsed' }
}
$ui.MapHighlight.IsChecked = [bool]$script:State.MapHighlight
Update-AWMapHighlightUI
$ui.MapHighlight.Add_Click({
    $script:State.MapHighlight = [bool]$ui.MapHighlight.IsChecked
    Save-AWState
    Update-AWMapHighlightUI
    if ($script:MapCurrent) { Show-AWTreeMap }
})
$ui.MapOpenCleaner.Add_Click({ Select-AWView 'Cleaner' })

$ui.MapScan.Add_Click({ Start-AWMapScan $ui.MapPath.Text })
$ui.MapPath.Add_KeyDown({ param($s, $e) if ($e.Key -eq 'Return') { Start-AWMapScan $ui.MapPath.Text } })
$ui.MapStop.Add_Click({ if ($script:Scanner) { $script:Scanner.Cancel = $true; $ui.MapStop.IsEnabled = $false } })
$ui.MapUp.Add_Click({ if ($script:MapCurrent -and $script:MapCurrent.Parent) { Set-AWMapCurrent $script:MapCurrent.Parent } })
$ui.MapBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Choose a folder to map'
    if ($ui.MapPath.Text -and (Test-Path -LiteralPath $ui.MapPath.Text)) { $dlg.SelectedPath = $ui.MapPath.Text }
    if ($dlg.ShowDialog() -eq 'OK') { $ui.MapPath.Text = $dlg.SelectedPath; Start-AWMapScan $dlg.SelectedPath }
})
$ui.MapOpen.Add_Click({ if ($script:MapSelected) { Open-AWScanPath $script:MapSelected.FullPath } })
$ui.MapOnRemote.Add_Checked({ Update-AWMapScope })
$ui.MapOnLocal.Add_Checked({ Update-AWMapScope })
$ui.MapZoom.Add_Click({ if ($script:MapSelected) { Set-AWMapCurrent $script:MapSelected } })
$ui.MapRecycle.Add_Click({ if ($script:MapSelected) { Remove-AWMapNodeToRecycle $script:MapSelected } })
$ui.MapTopList.Add_SelectionChanged({ if ($ui.MapTopList.SelectedItem) { Select-AWMapNode $ui.MapTopList.SelectedItem $null } })
$ui.MapTopList.Add_MouseDoubleClick({ $n = $ui.MapTopList.SelectedItem; if ($n -and $n.IsDir) { Set-AWMapCurrent $n } })
$window.Add_PreviewMouseDown({
    param($s, $e)
    # Mouse "back" button goes up a level on the map
    if ($e.ChangedButton -eq 'XButton1' -and $ui.ViewMap.Visibility -eq 'Visible' -and $script:MapCurrent -and $script:MapCurrent.Parent) {
        Set-AWMapCurrent $script:MapCurrent.Parent; $e.Handled = $true
    }
})

function Initialize-AWMapDrives {
    $ui.MapDrives.Children.Clear()
    if (Test-AWMapRemote) {
        $ui.MapPath.Text = 'C:\'
        Start-AWTask -Name "List drives on $($script:Target.ComputerName)" -Work {
            Invoke-WTarget { Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { [pscustomobject]@{ Letter = $_.DeviceID.Substring(0, 1); Size = [long]$_.Size; Free = [long]$_.FreeSpace } } }
        } -OnComplete {
            param($r)
            if (-not (Test-AWMapRemote)) { return }
            $script:RemoteDrives = @($r | Where-Object { $_ -and $_.Letter } | ForEach-Object { [pscustomobject]@{ Letter = $_.Letter; Size = $_.Size; Free = $_.Free; Used = $_.Size - $_.Free } })
            $ui.MapDrives.Children.Clear()
            foreach ($d in $script:RemoteDrives) {
                $b = New-Object System.Windows.Controls.Button
                $b.Content = "$($d.Letter):"; $b.Tag = "$($d.Letter):\"
                $b.Style = $window.FindResource('BtnChip')
                $b.ToolTip = '{0} on {1}: {2} free of {3}' -f "$($d.Letter):", $script:Target.ComputerName, (Format-AWSize $d.Free), (Format-AWSize $d.Size)
                $b.Add_Click({ param($s, $e) Start-AWMapScan $s.Tag })
                [void]$ui.MapDrives.Children.Add($b)
            }
        }
        return
    }
    foreach ($d in (Get-AWFixedDrives)) {
        $b = New-Object System.Windows.Controls.Button
        $b.Content = $d.Name.TrimEnd('\'); $b.Tag = $d.RootDirectory.FullName
        $b.Style = $window.FindResource('BtnChip')
        $b.ToolTip = '{0} free of {1}' -f (Format-AWSize $d.TotalFreeSpace), (Format-AWSize $d.TotalSize)
        $b.Add_Click({ param($s, $e) Start-AWMapScan $s.Tag })
        [void]$ui.MapDrives.Children.Add($b)
    }
    $ui.MapPath.Text = "$env:SystemDrive\"
}
#endregion

#region ---------------------------------------------------------------- Large files
# Three lists share one view: the Space Map's largest files, old files and duplicate groups.
$script:LargeTab = 'Largest'
$script:OldFiles = New-Object System.Collections.Generic.List[object]
$script:DupeFiles = New-Object System.Collections.Generic.List[object]
$script:DupeNote = ''

function Get-AWLargeSource {
    switch ($script:LargeTab) {
        'Old'   { $script:OldFiles }
        'Dupes' { $script:DupeFiles }
        default { if ($script:Scanner -and $script:Scanner.TopFiles) { $script:Scanner.TopFiles } else { $null } }
    }
}

function Update-AWLargeList {
    $all = Get-AWLargeSource
    if (-not $all -or $all.Count -eq 0) {
        $ui.LargeList.ItemsSource = $null
        $ui.LargeInfo.Text = switch ($script:LargeTab) {
            'Old'   { if ($script:OldSearched) { 'No files of that size went unused since {0:MMM d, yyyy} in {1}.' -f $script:OldSince, (($script:State.OldFolders | ForEach-Object { if ($_ -match '\\') { Split-Path $_ -Leaf } else { $_ } }) -join ', ') } else { "Lists files in your $(($script:State.OldFolders | ForEach-Object { if ($_ -match '\\') { Split-Path $_ -Leaf } else { $_ } }) -join ', ') folder(s) that haven't been modified or opened in a while. Nothing is ticked unless it's an obvious leftover." } }
            'Dupes' { if ($script:DupeNote) { $script:DupeNote } else { 'Pick a folder and find exact copies (byte-for-byte) or similar photos.' } }
            default { 'Run a scan in Space Map to list the largest files.' }
        }
        Add-AWLargeScope
        return
    }
    $q = $ui.LargeSearch.Text.Trim()
    $kind = if ($script:LargeTab -eq 'Old' -and $ui.OldKind.SelectedIndex -gt 0) { [string]$ui.OldKind.SelectedItem.Content } else { '' }
    $items = @(foreach ($f in $all) {
        if ($kind -and $f.Status -notlike "$kind*") { continue }
        if (-not $q -or $f.Name -like "*$q*" -or $f.Folder -like "*$q*" -or $f.Extension -like "*$q*" -or $f.Status -like "*$q*") { $f }
    })
    $ui.LargeList.ItemsSource = $items
    [long]$sum = 0; foreach ($f in $items) { $sum += $f.Size }
    $ui.LargeInfo.Text = switch ($script:LargeTab) {
        'Old'   { '{0:N0} file(s) not modified or opened since {1:MMM d, yyyy} - {2} total{3}' -f $items.Count, $script:OldSince, (Format-AWSize $sum), $(if ($kind) { " ($kind only)" } else { '' }) }
        'Dupes' { $script:DupeNote }
        default { '{0:N0} files - {1} total - from scan of {2}' -f $items.Count, (Format-AWSize $sum), $script:Scanner.Root.FullPath }
    }
    Add-AWLargeScope
}

# When a remote PC is targeted, say which PC each list is about.
function Add-AWLargeScope {
    if (-not (Test-AWRemote)) { return }
    $who = if ($script:LargeTab -eq 'Largest' -and $script:ScanRemote) { $script:ScanRemote.ComputerName } else { "this PC ($env:COMPUTERNAME)" }
    $ui.LargeInfo.Text = "On $who" + $(if ($script:LargeTab -ne 'Largest') { ' - Old files and Duplicates always look at this PC' } else { '' }) + ": " + $ui.LargeInfo.Text
}

function Get-AWCheckedLarge { @(foreach ($f in (Get-AWLargeSource)) { if ($f.IsChecked) { $f } }) }

function Set-AWLargeTab([string]$Tab) {
    $script:LargeTab = $Tab
    $ui.OldBar.Visibility = if ($Tab -eq 'Old') { 'Visible' } else { 'Collapsed' }
    $ui.DupeBar.Visibility = if ($Tab -eq 'Dupes') { 'Visible' } else { 'Collapsed' }
    $ui.DupeKeep.Visibility = if ($Tab -eq 'Dupes') { 'Visible' } else { 'Collapsed' }
    $ui.LargeScan.Visibility = if ($Tab -eq 'Largest') { 'Visible' } else { 'Collapsed' }
    $ui.LargeStatusCol.Header = if ($Tab -eq 'Old') { 'Kind' } else { 'Group' }
    $ui.LargeStatusCol.Width = if ($Tab -eq 'Largest') { 0 } elseif ($Tab -eq 'Old') { 230 } else { 170 }
    if ($Tab -eq 'Dupes' -and -not $ui.DupePath.Text) { $ui.DupePath.Text = $env:USERPROFILE }
    Update-AWLargeList
    Update-AWViewTitle 'Large'
}
$ui.LTabLargest.Add_Checked({ Set-AWLargeTab 'Largest' })
$ui.LTabOld.Add_Checked({ Set-AWLargeTab 'Old' })
$ui.LTabDupes.Add_Checked({ Set-AWLargeTab 'Dupes' })

# ---- Old files: which folders to look in (remembered between runs)
$script:OldKnown = 'Downloads', 'Desktop', 'Documents', 'Pictures', 'Videos', 'Music'
$script:OldSince = Get-Date
function Update-AWOldFolderButton {
    $names = @($script:State.OldFolders | ForEach-Object { if ($_ -match '\\') { Split-Path $_ -Leaf } else { $_ } })
    $ui.OldFolders.Content = 'Folders: ' + $(if ($names.Count -le 2) { $names -join ', ' } else { "$($names[0]) +$($names.Count - 1)" }) + "  $([char]0x25BE)"
    $ui.OldFolders.ToolTip = 'Looking in: ' + ($names -join ', ')
}
function Build-AWOldFolderMenu {
    $m = $ui.OldFolders.ContextMenu
    $m.Items.Clear()
    $style = $window.FindResource('CtxItem')
    $custom = @($script:State.OldFolders | Where-Object { $_ -notin $script:OldKnown })
    foreach ($f in @($script:OldKnown) + $custom) {
        $on = $script:State.OldFolders -contains $f
        $mi = New-Object System.Windows.Controls.MenuItem
        $mi.Style = $style; $mi.StaysOpenOnClick = $true; $mi.Tag = $f
        $mi.Header = '{0}  {1}' -f $(if ($on) { [char]0x2714 } else { [char]0x2003 }), $f
        $mi.Add_Click({
            param($s, $e)
            $f = [string]$s.Tag
            if ($script:State.OldFolders -contains $f) {
                if (@($script:State.OldFolders).Count -le 1) { return }                     # keep at least one
                $script:State.OldFolders = @($script:State.OldFolders | Where-Object { $_ -ne $f })
            } else { $script:State.OldFolders = @($script:State.OldFolders) + $f }
            Save-AWState; Update-AWOldFolderButton; Build-AWOldFolderMenu
        })
        [void]$m.Items.Add($mi)
    }
    $add = New-Object System.Windows.Controls.MenuItem
    $add.Style = $style; $add.Header = "$([char]0x2003)  Add another folder..."
    $add.Add_Click({
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = 'Choose another folder to look for old files in'
        if ($dlg.ShowDialog() -eq 'OK' -and $script:State.OldFolders -notcontains $dlg.SelectedPath) {
            if (Test-AWProtectedPath $dlg.SelectedPath) { Show-AWMessage "Computer Doctor won't look for old files in system locations:`n$($dlg.SelectedPath)" 'Warning'; return }
            $script:State.OldFolders = @($script:State.OldFolders) + $dlg.SelectedPath
            Save-AWState; Update-AWOldFolderButton; Build-AWOldFolderMenu
        }
    })
    [void]$m.Items.Add($add)
}
$ui.OldFolders.Add_Click({ Build-AWOldFolderMenu; $ui.OldFolders.ContextMenu.PlacementTarget = $ui.OldFolders; $ui.OldFolders.ContextMenu.Placement = 'Bottom'; $ui.OldFolders.ContextMenu.IsOpen = $true })
$ui.OldKind.Add_SelectionChanged({ if ($script:LargeTab -eq 'Old') { Update-AWLargeList } })
$ui.OldDays.Add_SelectionChanged({ $script:OldSearched = $false })
$ui.OldMin.Add_SelectionChanged({ $script:OldSearched = $false })
Update-AWOldFolderButton

$ui.OldFind.Add_Click({
    if (Test-AWRemote) { Show-AWMessage 'Old files looks in your own folders on this PC.' }
    $days = [int]$ui.OldDays.SelectedItem.Tag
    $min = [long]$ui.OldMin.SelectedItem.Tag
    $script:OldSince = (Get-Date).AddDays(-$days)
    $ui.OldFind.IsEnabled = $false
    Start-AWTask -Name 'Finding old files' -Arguments @{ Days = $days; MinBytes = $min; Folders = @($script:State.OldFolders) } -Work { @(Get-WOldFiles $Folders $Days $MinBytes) } -OnComplete {
        param($r)
        $ui.OldFind.IsEnabled = $true
        $script:OldFiles.Clear(); $script:OldSearched = $true
        $ticked = 0
        foreach ($x in @($r | Sort-Object Size -Descending)) {
            $fe = New-Object ComputerDoctor.FileEntry
            $fe.Name = $x.Name; $fe.FullPath = $x.Path; $fe.Folder = $x.Folder; $fe.Size = $x.Size; $fe.Extension = $x.Extension; $fe.Modified = $x.Modified
            $fe.Status = '{0}{1} - {2}' -f $x.Kind, $(if ($x.Extracted) { ' (already extracted)' } else { '' }), $x.Root
            # Only the obvious leftovers are pre-ticked: installers and disk images in Downloads, and archives already extracted.
            $fe.IsChecked = ($x.Root -eq 'Downloads' -and $x.Kind -in 'Installer', 'Disk image') -or $x.Extracted
            if ($fe.IsChecked) { $ticked++ }
            $script:OldFiles.Add($fe)
        }
        Update-AWLargeList
        $script:IdleStatus = "Found $($script:OldFiles.Count) old file(s)" + $(if ($ticked) { " - $ticked obvious leftover(s) ticked (installers and disk images in Downloads, archives already extracted)" } else { '' })
        Set-AWStatus $script:IdleStatus
    }
})

$ui.DupeBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Choose a folder to search for duplicates'
    if ($ui.DupePath.Text -and (Test-Path -LiteralPath $ui.DupePath.Text)) { $dlg.SelectedPath = $ui.DupePath.Text }
    if ($dlg.ShowDialog() -eq 'OK') { $ui.DupePath.Text = $dlg.SelectedPath }
})
$ui.DupeStop.Add_Click({ if ($script:Dupes) { $script:Dupes.Cancel = $true }; $Sync.DupeCancel = $true; $ui.DupeStop.IsEnabled = $false })

$ui.DupeFind.Add_Click({
    $path = [Environment]::ExpandEnvironmentVariables($ui.DupePath.Text.Trim().Trim('"'))
    if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Container)) { Show-AWMessage "Folder not found:`n$path" 'Warning'; return }
    $script:DupeFiles.Clear(); $script:DupeNote = ''; Update-AWLargeList
    $ui.DupeFind.IsEnabled = $false; $ui.DupeStop.IsEnabled = $true
    $Sync.DupeCancel = $false
    if ($ui.DupeExact.IsChecked) {
        $script:Dupes = New-Object ComputerDoctor.DuplicateFinder
        $script:DupeRunning = $true
        Start-AWTask -Name "Finding duplicates in $path" -Arguments @{ Finder = $script:Dupes; Root = $path } -Work { $Finder.Scan($Root, 1024) } -OnComplete {
            param($r)
            $script:DupeRunning = $false; $ui.DupeFind.IsEnabled = $true; $ui.DupeStop.IsEnabled = $false
            $d = $script:Dupes
            foreach ($f in $d.Results) { $script:DupeFiles.Add($f) }
            $script:DupeNote = if ($d.Error) { "Search failed: $($d.Error)" } else {
                '{0:N0} group(s) of identical files - {1} could be freed by keeping one copy of each{2}' -f $d.Groups, (Format-AWSize $d.WastedBytes), $(if (-not $d.Completed) { ' (stopped early)' } else { '' }) }
            Update-AWLargeList
            $script:IdleStatus = $script:DupeNote; Set-AWStatus $script:IdleStatus
        }
    } else {
        $script:Dupes = $null
        Start-AWTask -Name "Finding similar photos in $path" -Arguments @{ Root = $path } -Work {
            Add-Type -AssemblyName PresentationCore
            $exts = '.jpg', '.jpeg', '.png', '.bmp', '.gif', '.tif', '.tiff', '.webp', '.heic'
            $files = @(Get-ChildItem -LiteralPath $Root -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.Extension.ToLowerInvariant() -in $exts -and $_.Length -ge 8KB -and -not ([int]$_.Attributes -band 0x400) -and -not ([int]$_.Attributes -band 0x440000) })
            $hashes = New-Object System.Collections.Generic.List[uint64]; $keep = New-Object System.Collections.Generic.List[object]
            $px = New-Object byte[] 72
            $i = 0
            foreach ($f in $files) {
                if ($Sync.DupeCancel) { break }
                $i++; if ($i % 20 -eq 0) { $Sync.Status = "Fingerprinting photos: $i of $($files.Count)"; $Sync.Progress = [int]($i * 100 / $files.Count) }
                try {
                    $bi = New-Object System.Windows.Media.Imaging.BitmapImage
                    $bi.BeginInit(); $bi.CacheOption = 'OnLoad'; $bi.CreateOptions = 'IgnoreColorProfile'
                    $bi.UriSource = New-Object Uri($f.FullName); $bi.DecodePixelWidth = 9; $bi.DecodePixelHeight = 8; $bi.EndInit()
                    $g = New-Object System.Windows.Media.Imaging.FormatConvertedBitmap($bi, [System.Windows.Media.PixelFormats]::Gray8, $null, 0)
                    $sc = New-Object System.Windows.Media.Imaging.TransformedBitmap($g, (New-Object System.Windows.Media.ScaleTransform((9.0 / $g.PixelWidth), (8.0 / $g.PixelHeight))))
                    if ($sc.PixelWidth -ne 9 -or $sc.PixelHeight -ne 8) { continue }
                    $sc.CopyPixels($px, 9, 0)
                    [uint64]$h = 0
                    for ($y = 0; $y -lt 8; $y++) { for ($x = 0; $x -lt 8; $x++) { $h = $h -shl 1; if ($px[$y * 9 + $x] -gt $px[$y * 9 + $x + 1]) { $h = $h -bor 1 } } }
                    $hashes.Add($h); $keep.Add($f)
                } catch { }
            }
            $groups = [ComputerDoctor.PhotoMatch]::Group($hashes.ToArray(), 8)
            $out = New-Object System.Collections.Generic.List[object]
            $n = 0
            foreach ($grp in @(0..($keep.Count - 1) | Where-Object { $keep.Count } | Group-Object { $groups[$_] } | Where-Object Count -gt 1)) {
                $n++
                foreach ($ix in $grp.Group) { $f = $keep[[int]$ix]; $out.Add([pscustomobject]@{ Name = $f.Name; Path = $f.FullName; Folder = $f.DirectoryName; Size = $f.Length; Extension = $f.Extension.ToLowerInvariant(); Modified = $f.LastWriteTime; Group = "Group $n ($($grp.Count) photos)" }) }
            }
            [pscustomobject]@{ Files = $out.ToArray(); Groups = $n; Scanned = $keep.Count; Stopped = [bool]$Sync.DupeCancel }
        } -OnComplete {
            param($r)
            $ui.DupeFind.IsEnabled = $true; $ui.DupeStop.IsEnabled = $false
            $r = @($r)[0]
            if (-not $r) { $script:DupeNote = 'Search failed - see the log'; Update-AWLargeList; return }
            foreach ($x in $r.Files) {
                $fe = New-Object ComputerDoctor.FileEntry
                $fe.Name = $x.Name; $fe.FullPath = $x.Path; $fe.Folder = $x.Folder; $fe.Size = $x.Size; $fe.Extension = $x.Extension; $fe.Modified = $x.Modified; $fe.Status = $x.Group
                $script:DupeFiles.Add($fe)
            }
            $script:DupeNote = '{0:N0} group(s) of similar photos among {1:N0} checked{2} - look before you tick: edits and bursts count as similar' -f $r.Groups, $r.Scanned, $(if ($r.Stopped) { ' (stopped early)' } else { '' })
            Update-AWLargeList
            $script:IdleStatus = $script:DupeNote; Set-AWStatus $script:IdleStatus
        }
    }
})

# In every group keep the newest copy (or the largest photo) and tick the rest.
$ui.DupeKeep.Add_Click({
    if (-not $script:DupeFiles.Count) { return }
    foreach ($g in ($script:DupeFiles | Group-Object Status)) {
        $best = $g.Group | Sort-Object @{ e = 'Size'; Descending = $true }, @{ e = 'Modified'; Descending = $true } | Select-Object -First 1
        foreach ($f in $g.Group) { $f.IsChecked = -not [object]::ReferenceEquals($f, $best) }
    }
    $ui.LargeList.Items.Refresh()
    $n = @(Get-AWCheckedLarge).Count; [long]$sum = 0; foreach ($f in (Get-AWCheckedLarge)) { $sum += $f.Size }
    Set-AWStatus ("Ticked {0:N0} extra cop(ies) - {1}. Review them, then Recycle checked." -f $n, (Format-AWSize $sum))
})

$ui.LargeSearch.Add_TextChanged({ Update-AWLargeList })
$ui.LargeScan.Add_Click({ Select-AWView 'Map' })
$ui.LargeOpen.Add_Click({
    $f = $ui.LargeList.SelectedItem
    if (-not $f) { $f = Get-AWCheckedLarge | Select-Object -First 1 }
    if (-not $f) { Show-AWMessage 'Select a file first.'; return }
    if ($script:LargeTab -eq 'Largest') { Open-AWScanPath $f.FullPath } else { Open-AWExplorer $f.FullPath }
})
$ui.LargeRecycle.Add_Click({
    $src = Get-AWLargeSource
    if (-not $src) { return }
    $sel = Get-AWCheckedLarge
    if ($sel.Count -eq 0) { Show-AWMessage 'Tick the files you want to remove first.'; return }
    if ($script:LargeTab -eq 'Dupes') {
        $all = @($src | Group-Object Status | Where-Object { @($_.Group | Where-Object { -not $_.IsChecked }).Count -eq 0 } | ForEach-Object Name)
        if ($all.Count) { Show-AWMessage ("Every copy is ticked in {0} - leave at least one unticked:`n{1}" -f $(if ($all.Count -eq 1) { 'this group' } else { "$($all.Count) groups" }), (($all | Select-Object -First 5) -join "`n")) 'Warning'; return }
    }
    [long]$sum = 0; foreach ($f in $sel) { $sum += $f.Size }
    if ($script:LargeTab -eq 'Largest' -and $script:ScanRemote) {
        $blocked = @($sel | Where-Object { Test-AWProtectedRemotePath $_.FullPath })
        $go = @($sel | Where-Object { -not (Test-AWProtectedRemotePath $_.FullPath) })
        if (-not $go.Count) { Show-AWMessage 'Those are protected system locations.' 'Warning'; return }
        if (-not (Confirm-AW ("PERMANENTLY delete {0} file(s) ({1}) on {2}?`n`nFiles on another PC don't go to a Recycle Bin - this can't be undone.{3}" -f $go.Count, (Format-AWSize $sum), $script:ScanRemote.ComputerName, $(if ($blocked.Count) { "`n$($blocked.Count) protected item(s) will be skipped." } else { '' })))) { return }
        Remove-AWRemoteScanItems @($go | ForEach-Object FullPath) {
            param($done)
            $gone = @{}; foreach ($p in $done) { $gone[$p] = $true }
            foreach ($f in @($script:Scanner.TopFiles | Where-Object { $gone[$_.FullPath] })) { [void]$script:Scanner.TopFiles.Remove($f) }
            Update-AWLargeList
            $script:IdleStatus = "Deleted $(@($done).Count) file(s) on $($script:ScanRemote.ComputerName) - rescan to refresh the Space Map"; Set-AWStatus $script:IdleStatus
        }
        return
    }
    $inCloud = @($sel | Where-Object { $_.Status -like '*(OneDrive)*' }).Count
    $cloudNote = if ($inCloud) { "`n`n$inCloud of them are in OneDrive: they'll also disappear from OneDrive and your other devices (OneDrive keeps them in its own recycle bin for about 30 days)." } else { '' }
    if (-not (Confirm-AW ("Send {0} file(s) ({1}) to the Recycle Bin?{2}" -f $sel.Count, (Format-AWSize $sum), $cloudNote))) { return }
    $ok = 0; $fail = 0
    foreach ($f in $sel) {
        if (Test-AWProtectedPath $f.FullPath) { $fail++; continue }
        try {
            Send-AWToRecycle $f.FullPath
            [void]$src.Remove($f)
            Write-AWLog "Recycled $($f.FullPath) ($($f.SizeText))"
            $ok++
        } catch { $fail++; Write-AWLog "Could not recycle $($f.FullPath): $($_.Exception.Message)" 'WARN' }
    }
    Update-AWLargeList
    $script:IdleStatus = "Recycled $ok file(s)" + $(if ($fail) { ", $fail failed" } else { '' }) + $(if ($script:LargeTab -eq 'Largest') { ' - rescan to refresh the Space Map' } else { '' })
    Set-AWStatus $script:IdleStatus
})
$ui.LargeExport.Add_Click({
    $src = Get-AWLargeSource
    if (-not $src -or -not $src.Count) { Show-AWMessage 'Nothing to export yet.'; return }
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = 'CSV file (*.csv)|*.csv'
    $dlg.FileName = 'ComputerDoctor-{0}-{1:yyyyMMdd-HHmm}.csv' -f @{ Largest = 'LargeFiles'; Old = 'OldFiles'; Dupes = 'Duplicates' }[$script:LargeTab], (Get-Date)
    if ($dlg.ShowDialog($window)) {
        $src | Select-Object Name, Size, SizeText, Extension, ModifiedText, Status, FullPath |
            Export-Csv -LiteralPath $dlg.FileName -NoTypeInformation -Encoding UTF8
        Write-AWLog "Exported large files list to $($dlg.FileName)"
        Set-AWStatus "Exported to $($dlg.FileName)"
    }
})
#endregion

#region ---------------------------------------------------------------- Startup manager
# The list is read and changed by Get-WStartupItems / Set-WStartupState in the worker library, so it
# works on a remote PC too. There, only all-users entries are shown: "current user" over WinRM would
# be the admin account Computer Doctor connected with, not the person who uses that PC.
function Update-AWStartupList {
    $remote = Test-AWRemote
    $ui.StartupInfo.Text = 'Reading startup entries...'
    $ui.StartupRefresh.IsEnabled = $false
    Start-AWTask -Name 'Read startup entries' -Arguments @{ MachineOnly = $remote } -Work { Invoke-WTarget { param($M) @(Get-WStartupItems $M) } -ArgumentList $MachineOnly } -OnComplete {
        param($r)
        $ui.StartupRefresh.IsEnabled = $true
        $items = @($r | Where-Object { $_ -and $_.ValueName } | Sort-Object Name)
        $ui.StartupList.ItemsSource = $items
        $on = @($items | Where-Object { $_.Enabled }).Count
        $ui.StartupInfo.Text = "$($items.Count) startup entries, $on enabled. Disabled items stay installed, they just won't launch at sign-in." +
            $(if (Test-AWRemote) { " Showing entries for all users on $($script:Target.ComputerName); each user's own entries are only listed when Computer Doctor runs on that PC." } elseif (-not $script:IsAdmin) { ' All-users entries need admin rights to change.' } else { '' })
    }
}

function Get-AWExeFromCommand([string]$Command) {
    $c = [Environment]::ExpandEnvironmentVariables($Command).Trim()
    if ($c.StartsWith('"')) { $end = $c.IndexOf('"', 1); if ($end -gt 1) { return $c.Substring(1, $end - 1) } }
    $m = [regex]::Match($c, '^(.+?\.(exe|cmd|bat|lnk|vbs|ps1|com))(\s|$)', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    ($c -split '\s+')[0]
}

$ui.StartupList.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    param($s, $e)
    $cb = $e.OriginalSource
    if ($cb -isnot [System.Windows.Controls.CheckBox]) { return }
    $item = $cb.DataContext
    $want = [bool]$cb.IsChecked
    $script:PendingStartup = @{ Item = $item; Box = $cb; Want = $want }
    Start-AWTask -Name "Startup: $($item.Name)" -Arguments @{ Item = $item; Want = $want } -Work {
        try { Invoke-WTarget { param($I, $W) Set-WStartupState $I $W; 'ok' } -ArgumentList $Item, $Want } catch { [pscustomobject]@{ Error = $_.Exception.Message } }
    } -OnComplete {
        param($r)
        $p = $script:PendingStartup; $x = @($r) | Select-Object -Last 1
        if ($x -ne 'ok') {
            $p.Box.IsChecked = $p.Item.Enabled
            Show-AWMessage "Could not change '$($p.Item.Name)':`n$(if ($x.Error) { $x.Error } else { 'see the Activity log' })" 'Error'; return
        }
        $p.Item.Enabled = $p.Want
        Write-AWAction 'StartupItem' @("$($p.Item.Name) -> $(if ($p.Want) { 'enabled' } else { 'disabled' })") @{} 'Done'
        Set-AWStatus ("{0} will {1}launch at sign-in" -f $p.Item.Name, $(if ($p.Want) { '' } else { 'no longer ' }))
    }
})
$ui.StartupRefresh.Add_Click({ Update-AWStartupList })
$ui.StartupOpen.Add_Click({
    $it = $ui.StartupList.SelectedItem
    if (-not $it) { Show-AWMessage 'Select a startup entry first.'; return }
    if (Test-AWRemote) { Show-AWMessage "This entry is on $($script:Target.ComputerName):`n$($it.Command)"; return }
    $target = if ($it.FilePath) { $it.FilePath } else { Get-AWExeFromCommand $it.Command }
    if ($target -and (Test-Path -LiteralPath $target)) { Open-AWExplorer $target }
    else { Show-AWMessage "Couldn't find the file for this entry:`n$($it.Command)" 'Warning' }
})

# ---- Right-click menu entries (shell extensions and added commands)
$script:MenuItems = @()
function Set-AWStartupTab([string]$Tab) {
    $menu = $Tab -eq 'Menu'
    $ui.MenuList.Visibility = if ($menu) { 'Visible' } else { 'Collapsed' }
    $ui.StartupList.Visibility = if ($menu) { 'Collapsed' } else { 'Visible' }
    $ui.MenuButtons.Visibility = if ($menu) { 'Visible' } else { 'Collapsed' }
    $ui.StartupButtons.Visibility = if ($menu) { 'Collapsed' } else { 'Visible' }
    $ui.StartupTitle.Text = if ($menu) { 'Right-click menu' } else { 'Startup programs' }
    if ($menu) { if (-not $script:MenuItems.Count) { Update-AWMenuList } else { Update-AWMenuView } }
    else { Update-AWStartupList }
}
function Update-AWMenuView {
    $items = @(if ($ui.MenuShowMs.IsChecked) { $script:MenuItems } else { $script:MenuItems | Where-Object { -not $_.Microsoft } })
    $ui.MenuList.ItemsSource = $items
    $off = @($script:MenuItems | Where-Object { -not $_.Enabled }).Count
    $ui.StartupInfo.Text = "$($items.Count) entries added by programs$(if ($off) { ", $off turned off" }). Turning one off hides it from the menu without uninstalling anything - a slow or crashing entry is a common cause of a sluggish right-click. Windows 11's new top-level menu entries from Store apps aren't listed; most of these show under 'Show more options'." +
        $(if (Test-AWRemote) { " Showing all-users entries on $($script:Target.ComputerName); changes apply after its users sign out and back in." } elseif (-not $script:IsAdmin) { ' All-users commands need admin rights to change.' } else { '' })
}
function Update-AWMenuList {
    $ui.StartupInfo.Text = 'Reading right-click menu entries...'
    $ui.MenuRefresh.IsEnabled = $false
    $remote = Test-AWRemote
    $ui.MenuRestart.IsEnabled = -not $remote
    $ui.MenuRestart.ToolTip = if ($remote) { "On $($script:Target.ComputerName), changes show up after its users sign out and back in" } else { 'Changes show up after Explorer restarts' }
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($ui.MenuRestart, $true)
    Start-AWTask -Name 'Read right-click menu entries' -Arguments @{ MachineOnly = $remote } -Work { Invoke-WTarget { param($M) @(Get-WContextMenu $M) } -ArgumentList $MachineOnly } -OnComplete {
        param($r)
        $ui.MenuRefresh.IsEnabled = $true
        $script:MenuItems = @($r | Where-Object { $_ -and $_.Id } | Sort-Object @{ e = 'Microsoft' }, Name)
        Update-AWMenuView
    }
}
$ui.STabStartup.Add_Checked({ Set-AWStartupTab 'Startup' })
$ui.STabMenu.Add_Checked({ Set-AWStartupTab 'Menu' })
$ui.MenuShowMs.Add_Click({ Update-AWMenuView })
$ui.MenuRefresh.Add_Click({ Update-AWMenuList })
$ui.MenuRestart.Add_Click({ Restart-AWExplorer })
$ui.MenuOpen.Add_Click({
    $it = $ui.MenuList.SelectedItem
    if (-not $it) { Show-AWMessage 'Select an entry first.'; return }
    if (Test-AWRemote) { Show-AWMessage "This entry is on $($script:Target.ComputerName):`n$($it.Command)"; return }
    $target = if ($it.Kind -eq 'Handler') { $it.Command } else { Get-AWExeFromCommand $it.Command }
    if ($target -and (Test-Path -LiteralPath $target)) { Open-AWExplorer $target }
    else { Show-AWMessage "Couldn't find the file for this entry:`n$($it.Command)" 'Warning' }
})
$ui.MenuList.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    param($s, $e)
    $cb = $e.OriginalSource
    if ($cb -isnot [System.Windows.Controls.CheckBox]) { return }
    $item = $cb.DataContext
    $want = [bool]$cb.IsChecked
    $script:PendingMenu = @{ Item = $item; Box = $cb; Want = $want }
    Start-AWTask -Name "Right-click menu: $($item.Name)" -Arguments @{ Item = $item; Want = $want } -Work {
        try { Invoke-WTarget { param($I, $W) Set-WContextMenuItem $I $W } -ArgumentList $Item, $Want } catch { [pscustomobject]@{ Error = $_.Exception.Message } }
    } -OnComplete {
        param($r)
        $p = $script:PendingMenu; $r = @($r | Where-Object { $_ -and ($_.Error -or $_.UndoKind) })[0]
        if (-not $r -or $r.Error) {
            $p.Box.IsChecked = $p.Item.Enabled
            Show-AWMessage "Could not change '$($p.Item.Name)':`n$(if ($r) { $r.Error } else { 'see the log' })" 'Error'; return
        }
        $p.Item.Enabled = $p.Want
        $uid = Add-AWUndoEntry $r
        Write-AWAction 'ContextMenu' @("$($p.Item.Name) ($($p.Item.Where)) -> $(if ($p.Want) { 'on' } else { 'off' })") @{} 'Done' $uid
        Update-AWMenuView
        Set-AWStatus ("'{0}' turned {1} - restart Explorer (button above) to see the change" -f $p.Item.Name, $(if ($p.Want) { 'on' } else { 'off' }))
    }
})
#endregion

#region ---------------------------------------------------------------- Programs
$script:Programs = @()

function Update-AWProgramView {
    $q = $ui.ProgSearch.Text.Trim()
    $items = @(if ($q) { $script:Programs | Where-Object { $_.Name -like "*$q*" -or $_.Publisher -like "*$q*" } } else { $script:Programs })
    # Installed for: "Just me" = this account's Uninstall key (HKCU), "All users" = HKLM (64- and 32-bit).
    $scope = $script:State.ProgramsScope
    if ($scope -ne 'All') { $items = @($items | Where-Object { $_.For -eq $scope }) }
    $ui.ProgList.ItemsSource = $items
    [long]$sum = 0; foreach ($p in $items) { $sum += $p.SizeBytes }
    $ui.ProgInfo.Text = '{0:N0} programs - {1} reported size' -f $items.Count, (Format-AWSize $sum)
}

function Update-AWProgramList {
    $ui.ProgInfo.Text = 'Loading installed programs...'
    $ui.ProgRefresh.IsEnabled = $false
    $remote = Test-AWRemote
    $ui.ProgUninstall.IsEnabled = -not $remote
    $ui.ProgOpen.IsEnabled = -not $remote
    $ui.ProgUninstall.ToolTip = if ($remote) { 'Uninstalling is only available on this PC.' } else { $null }
    $ui.ProgNote.Visibility = if (-not $remote -and -not $script:IsAdmin) { 'Visible' } else { 'Collapsed' }
    Start-AWTask -Name 'Read installed programs' -Work {
        $raw = Invoke-WTarget {
            $paths = @(
                @{ P = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*';             S = 'Machine' }
                @{ P = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'; S = 'Machine (x86)' }
                @{ P = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*';             S = 'User' }
            )
            $seen = @{}
            foreach ($src in $paths) {
                foreach ($e in (Get-ItemProperty -Path $src.P -ErrorAction SilentlyContinue)) {
                    if (-not $e.DisplayName -or $e.SystemComponent -eq 1 -or $e.ParentKeyName -or $e.ReleaseType -match 'Update|Hotfix') { continue }
                    if (-not $e.UninstallString) { continue }
                    $key = "$($e.DisplayName)|$($e.DisplayVersion)"
                    if ($seen.ContainsKey($key)) { continue }
                    $seen[$key] = $true
                    $installed = ''
                    if ($e.InstallDate -match '^\d{8}$') {
                        try { $installed = [datetime]::ParseExact($e.InstallDate, 'yyyyMMdd', $null).ToString('yyyy-MM-dd') } catch { }
                    }
                    [pscustomobject]@{
                        Name = [string]$e.DisplayName; Publisher = [string]$e.Publisher; Version = [string]$e.DisplayVersion; Installed = $installed
                        SizeBytes = $(if ($e.EstimatedSize) { [long]$e.EstimatedSize * 1KB } else { [long]0 })
                        Scope = $src.S; Uninstall = [string]$e.UninstallString; Location = [string]$e.InstallLocation
                    }
                }
            }
        }
        # Rebuild locally so remote (deserialized) results bind and sort like local ones.
        foreach ($r in $raw) {
            [pscustomobject]@{
                Name = $r.Name; Publisher = $r.Publisher; Version = $r.Version; Installed = $r.Installed
                SizeBytes = [long]$r.SizeBytes; SizeText = $(if ($r.SizeBytes) { [ComputerDoctor.Fmt]::Size([long]$r.SizeBytes) } else { '' })
                Scope = $r.Scope; For = $(if ($r.Scope -eq 'User') { 'Just me' } else { 'All users' }); Uninstall = $r.Uninstall; Location = $r.Location
            }
        }
    } -OnComplete {
        param($Result)
        $script:Programs = @($Result | Where-Object { $_ } | Sort-Object Name)
        $ui.ProgRefresh.IsEnabled = $true
        Update-AWProgramView
    }
}

$ui.ProgSearch.Add_TextChanged({ Update-AWProgramView })
switch ($script:State.ProgramsScope) { 'Just me' { $ui.ProgForMe.IsChecked = $true } 'All users' { $ui.ProgForUsers.IsChecked = $true } default { $ui.ProgForAll.IsChecked = $true } }
foreach ($rb in @($ui.ProgForAll, $ui.ProgForMe, $ui.ProgForUsers)) {
    $rb.Add_Checked({
        param($s, $e)
        $script:State.ProgramsScope = [string]$s.Content
        Save-AWState
        Update-AWProgramView
    })
}
$ui.ProgRefresh.Add_Click({ Update-AWProgramList })
$ui.ProgOpen.Add_Click({
    $p = $ui.ProgList.SelectedItem
    if (-not $p) { Show-AWMessage 'Select a program first.'; return }
    if ($p.Location -and (Test-Path -LiteralPath $p.Location)) { Open-AWExplorer $p.Location }
    else { Show-AWMessage "$($p.Name) doesn't report an install folder." }
})
$ui.ProgUninstall.Add_Click({
    $p = $ui.ProgList.SelectedItem
    if (-not $p) { Show-AWMessage 'Select a program first.'; return }
    $adminNote = if ($p.For -eq 'All users' -and -not $script:IsAdmin) { "`n`n$($p.Name) is installed for all users, so Windows will ask for administrator rights to uninstall it." } else { '' }
    if (-not (Confirm-AW "Start the uninstaller for:`n`n$($p.Name) $($p.Version)`n`nThe program's own uninstaller will open.$adminNote")) { return }
    try {
        $cmd = $p.Uninstall
        if ($cmd -match 'msiexec' -and $cmd -match '\{[0-9A-Fa-f\-]{36}\}') {
            Start-Process msiexec.exe -ArgumentList "/x $($Matches[0])"
        } else {
            Start-Process cmd.exe -ArgumentList "/c `"$cmd`"" -WindowStyle Hidden
        }
        Write-AWLog "Started uninstaller for $($p.Name)"
        Set-AWStatus "Uninstaller started for $($p.Name). Press Refresh when it finishes."
    } catch { Show-AWMessage "Could not start the uninstaller:`n$($_.Exception.Message)" 'Error' }
})
#endregion

#region ---------------------------------------------------------------- Shared actions
function Restart-AWExplorer {
    Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 1200
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Write-AWLog 'Explorer restarted'; Set-AWStatus 'Explorer restarted'
}

function Start-AWRestorePoint([string]$Description = 'Computer Doctor checkpoint') {
    if (-not (Test-AWCanAdmin)) { Show-AWMessage 'Creating a restore point needs administrator rights.'; return }
    if (-not $Description) { $Description = 'Computer Doctor checkpoint' }
    Start-AWTask -Name 'Create restore point' -Arguments @{ Desc = $Description } -Work {
        $Sync.Status = 'Creating System Restore point...'
        try { [bool](@(Invoke-WTarget { param($d) New-WRestorePoint $d } -ArgumentList @($Desc)) | Select-Object -Last 1) }
        catch { Write-WLog "Restore point failed: $($_.Exception.Message)" 'ERROR'; $false }
    } -OnComplete {
        param($r)
        $ok = [bool](@($r) | Select-Object -Last 1)
        Write-AWAction 'RestorePoint' @('create') @{} $(if ($ok) { 'Done' } else { 'Failed' })
        $script:IdleStatus = if ($ok) { 'Restore point created' } else { 'Restore point was not created - see Activity log' }
        if ($script:RecLoadedTabs['RP']) { Update-AWRestorePoints }
    }
}

# DISM repair or .NET 3.5 install from Windows media in the Resources folder (local PC, no internet).
function Start-AWOfflineRepair([string]$Kind, $Media) {
    $what = if ($Kind -eq 'NetFx3') { 'Install .NET Framework 3.5' } else { 'Repair the Windows image' }
    if (-not (Confirm-AW "$what using $($Media.Name) from the Resources folder?`n`nNo internet is used. Computer Doctor picks the image that matches this PC's edition and warns if the media is older than this PC's updates. This can take 10-30 minutes.")) { return }
    Write-AWAction $(if ($Kind -eq 'NetFx3') { 'NetFx3Offline' } else { 'DismRepairOffline' }) @($Media.Path) @{} 'Started'
    $path = $Media.Path -replace "'", "''"
    $step = if ($Kind -eq 'NetFx3') {
        'if (-not $src.Sxs) { Write-WLog "No sources\sxs folder on this media" "ERROR"; "AWEXIT 1"; return }
         Write-WLog "Installing .NET 3.5 from $($src.Sxs)"
         & dism.exe /Online /Enable-Feature /FeatureName:NetFx3 /All "/Source:$($src.Sxs)" /LimitAccess /NoRestart 2>&1'
    } else {
        'Write-WLog "Repairing from image $($src.Index) ($($src.ImageName)), build $($src.Build).$($src.Ubr)"
         & dism.exe /Online /Cleanup-Image /RestoreHealth (Get-WDismSourceArg $src) /LimitAccess /NoRestart 2>&1'
    }
    $body = @"
`$src = Open-WRepairSource '$path'
try {
    if (`$src.Warning) { Write-WLog `$src.Warning `$(if (`$src.Usable) { 'WARN' } else { 'ERROR' }) }
    if (-not `$src.Usable -and '$Kind' -ne 'NetFx3') { 'AWEXIT 1'; return }
    $step
    "AWEXIT `$LASTEXITCODE"
} finally { Close-WRepairSource `$src }
"@
    $saved = $script:Target; $script:Target = $null        # the media is on this PC
    try { Start-AWCommandTask $what ([scriptblock]::Create($body)) } finally { $script:Target = $saved }
}

function Get-WRegValueLocal([string]$Path, [string]$Name) {
    try { (Get-Item -LiteralPath $Path -ErrorAction Stop).GetValue($Name, $null) } catch { $null }
}

# Runs a console command on the target and streams its output to the Activity log.
# Lines containing a percentage drive the progress bar. The body should end with "AWEXIT $LASTEXITCODE".
function Start-AWCommandTask([string]$Name, [scriptblock]$Body) {
    Write-AWAction 'Tool' @($Name) @{} 'Started'
    Start-AWTask -Name $Name -Arguments @{ Label = $Name; Body = $Body.ToString() } -Work {
        $Sync.Status = "$Label running..."
        Invoke-WTarget ([scriptblock]::Create($Body)) | ForEach-Object {
            foreach ($seg in (("$_" -replace "`0", '') -split "`r")) {
                $l = $seg.Trim()
                if (-not $l) { continue }
                if ($l -match '^AWEXIT (-?\d+)$') { Write-WLog "$Label finished with exit code $($Matches[1])"; continue }
                if ($l -match '(\d+(\.\d+)?)\s*%') { $Sync.Progress = [int][double]$Matches[1]; $Sync.Status = "$Label - $l"; continue }
                if ($l -notmatch '^\[=*') { Write-WLog "${Label}: $l" }
            }
        }
        "$Label finished"
    } -OnComplete {
        param($r)
        $m = @($r | Where-Object { $_ })
        $script:IdleStatus = if ($m.Count) { "$($m[-1]) - see Activity log" } else { 'Task failed - see Activity log' }
    }
}
#endregion

#region ---------------------------------------------------------------- Debloat
$script:AllApps = @()
$script:TweakChecks = New-Object System.Collections.Generic.List[object]
$script:TweakState = @{}
$script:PendingExplorerRestart = $false

# HKCU tweaks would land in the remote admin's own profile, so only machine-wide tweaks run remotely.
function Test-AWTweakRemoteOk($Tweak) { -not @($Tweak.Values | Where-Object { $_.Path -notlike 'HKLM:*' }) }
function Test-AWTweakAllowed($Tweak) {
    if (Test-AWRemote) { return Test-AWTweakRemoteOk $Tweak }
    $script:IsAdmin -or -not $Tweak.Admin
}

function Update-AWAppView {
    $q = $ui.AppSearch.Text.Trim()
    $all = [bool]$ui.AppsShowAll.IsChecked
    $items = @($script:AllApps | Where-Object { ($all -or $_.Category -ne 'Other') -and (-not $q -or $_.Name -like "*$q*" -or $_.Package -like "*$q*") })
    $ui.AppList.ItemsSource = $items
    $ui.AppsInfo.Text = '{0} app(s) shown' -f $items.Count
}

function Update-AWAppList {
    $ui.AppsInfo.Text = 'Reading installed apps...'
    $ui.AppsRemove.IsEnabled = $false
    $ui.AppsProvisioned.IsEnabled = Test-AWCanAdmin
    Start-AWTask -Name 'Read Store apps' -Arguments @{ Catalog = $script:BloatCatalog; Protected = $script:ProtectedApps; AllUsers = [bool](Test-AWCanAdmin) } -Work {
        $raw = Invoke-WTarget { param($AllUsers) Get-WStoreAppsRaw $AllUsers } -ArgumentList @($AllUsers)

        $seen = @{}
        foreach ($p in $raw) {
            if ($seen[$p.Name]) { continue }
            $seen[$p.Name] = $true
            $match = $null
            foreach ($c in $Catalog) { if ($p.Name -like $c.Pattern) { $match = $c; break } }
            if (-not $match) {
                $prot = $false
                foreach ($x in $Protected) { if ($p.Name -like $x) { $prot = $true; break } }
                if ($prot) { continue }
            }
            $e = New-Object ComputerDoctor.AppEntry
            $e.Package = $p.Name; $e.FullName = $p.FullName; $e.Version = $p.Version; $e.Publisher = $p.Publisher; $e.Provisioned = $p.Prov
            if ($match) { $e.Name = $match.Name; $e.Category = $match.Category; $e.Recommended = $match.Recommended; $e.Note = $match.Note }
            else { $e.Name = $p.Name -replace '^[^.]+\.(?=.)', ''; $e.Category = 'Other'; $e.Note = "Version $($p.Version)" }
            $e.IsChecked = $e.Recommended
            $e
        }
    } -OnComplete {
        param($Result)
        $script:AllApps = @($Result | Where-Object { $_ } | Sort-Object Category, Name)
        $ui.AppsRemove.IsEnabled = $true
        Update-AWAppView
    }
}

function Start-AWAppRemoval {
    $apps = @($script:AllApps | Where-Object { $_.IsChecked })
    if ($apps.Count -eq 0) { Show-AWMessage 'Check at least one app first.'; return }
    $prov  = [bool]$ui.AppsProvisioned.IsChecked -and (Test-AWCanAdmin)
    $scope = if (Test-AWCanAdmin) { 'for all users' } else { 'for your account' }
    $where = if (Test-AWRemote) { " on $($script:Target.ComputerName)" } else { '' }
    $list  = ($apps | Select-Object -First 20 | ForEach-Object { "  - $($_.Name)" }) -join "`n"
    if ($apps.Count -gt 20) { $list += "`n  ...and $($apps.Count - 20) more" }
    if (-not (Confirm-AW "Remove $($apps.Count) app(s) $scope$($where)?`n`n$list`n`nMost of these can be reinstalled from the Microsoft Store.")) { return }

    $ui.AppsRemove.IsEnabled = $false
    $pk = @($apps | ForEach-Object { @{ Name = $_.Name; Package = $_.Package; Provisioned = $_.Provisioned } })
    Write-AWAction 'RemoveApps' ($apps | ForEach-Object Package) @{ AllUsers = [bool](Test-AWCanAdmin); Provisioned = $prov }
    Start-AWTask -Name 'Remove Store apps' -Arguments @{ Pk = $pk; AllUsers = [bool](Test-AWCanAdmin); Prov = $prov; AutoRP = (Get-AWAutoRP 'removing Store apps') } -Work {
        if ($AutoRP) { $Sync.Status = 'Creating a restore point first...'; [void](Invoke-WTarget { param($d) New-WRestorePoint $d } -ArgumentList @($AutoRP)) }
        $i = 0
        foreach ($a in $Pk) {
            $Sync.Status = "Removing $($a.Name)..."
            $Sync.Progress = [int]($i * 100 / $Pk.Count); $i++
            try { Invoke-WTarget { param($App, $AllUsers, $Prov) Remove-WStoreApp $App $AllUsers $Prov } -ArgumentList @($a, $AllUsers, $Prov) }
            catch { Write-WLog "$($a.Name): $($_.Exception.Message)" 'ERROR' }
        }
        $Sync.Progress = 100
    } -OnComplete {
        param($r)
        $script:IdleStatus = 'App removal finished - see Activity log'
        Update-AWAppList
        if ($script:Loaded['Rebloat']) { Update-AWRebloatList }
    }
}

function Initialize-AWTweaks {
    $ui.TweakItems.Children.Clear()
    $script:TweakChecks.Clear()
    $script:TweakState = @{}
    $lastGroup = ''
    foreach ($tw in $script:Tweaks) {
        if ($tw.Group -ne $lastGroup) {
            $h = New-AWText $tw.Group.ToUpper() 11 $script:Res.Dim 'Bold'
            $h.Margin = if ($lastGroup) { '0,16,0,6' } else { '0,8,0,6' }
            [void]$ui.TweakItems.Children.Add($h)
            $lastGroup = $tw.Group
        }
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Margin = '0,5'; $cb.Tag = $tw
        $allowed = Test-AWTweakAllowed $tw
        $cb.IsEnabled = $allowed
        $cb.IsChecked = $tw.Default -and $allowed
        $cb.ToolTip = if ((Test-AWRemote) -and -not $allowed) { "$($tw.Desc)`n`nPer-user setting - only available on this PC." } else { $tw.Desc }
        [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($cb, $true)

        $sp = New-Object System.Windows.Controls.StackPanel; $sp.Orientation = 'Horizontal'
        [void]$sp.Children.Add((New-AWText $tw.Name 13))
        if ($tw.Admin) { [void]$sp.Children.Add((New-AWPill 'ADMIN' (Test-AWCanAdmin))) }
        $on = New-AWPill 'ON' $true 'Teal'; $on.Visibility = 'Collapsed'
        [void]$sp.Children.Add($on)
        $script:TweakState[$tw.Id] = $on
        $cb.Content = $sp
        [void]$ui.TweakItems.Children.Add($cb)
        $script:TweakChecks.Add($cb)
    }
}

function Update-AWTweakStatus {
    $list = @($script:Tweaks | Where-Object { Test-AWTweakAllowed $_ })
    Start-AWTask -Name 'Read tweak status' -Arguments @{ Tw = $list } -Work {
        Invoke-WTarget { param($Items) foreach ($t in $Items) { [pscustomobject]@{ Id = $t.Id; On = [bool](Test-WTweak $t) } } } -ArgumentList @(, $Tw)
    } -OnComplete {
        param($Result)
        foreach ($p in $script:TweakState.Values) { $p.Visibility = 'Collapsed' }
        foreach ($r in $Result) { if ($r -and $r.On -and $script:TweakState[[string]$r.Id]) { $script:TweakState[[string]$r.Id].Visibility = 'Visible' } }
    }
}

# $Selected / $RestartExplorer let Rebloat reuse this with its own list and checkbox.
function Start-AWTweaks([bool]$Apply, $Selected = $null, $RestartExplorer = $null) {
    $sel = @(if ($null -ne $Selected) { $Selected } else { $script:TweakChecks | Where-Object { $_.IsChecked -and $_.IsEnabled } | ForEach-Object { $_.Tag } })
    if ($sel.Count -eq 0) { Show-AWMessage 'Check at least one tweak first.'; return }
    if ($null -eq $RestartExplorer) { $RestartExplorer = [bool]$ui.TweaksRestartExplorer.IsChecked }
    $verb  = if ($Apply) { 'Apply' } else { 'Revert' }
    $where = if (Test-AWRemote) { " on $($script:Target.ComputerName)" } else { '' }
    $names = ($sel | ForEach-Object { "  - $($_.Name)" }) -join "`n"
    if (-not (Confirm-AW "$verb these tweaks$($where)?`n`n$names")) { return }
    $script:PendingExplorerRestart = (-not (Test-AWRemote)) -and [bool]$RestartExplorer -and @($sel | Where-Object { $_.Explorer }).Count -gt 0
    $ui.TweaksApply.IsEnabled = $false; $ui.TweaksRevert.IsEnabled = $false; $ui.RebloatRevert.IsEnabled = $false
    $autoRP = if ($Apply) { Get-AWAutoRP 'applying tweaks' } else { $null }
    Start-AWTask -Name "$verb tweaks" -Arguments @{ Sel = $sel; Apply = $Apply; AutoRP = $autoRP } -Work {
        if ($AutoRP) { $Sync.Status = 'Creating a restore point first...'; [void](Invoke-WTarget { param($d) New-WRestorePoint $d } -ArgumentList @($AutoRP)) }
        foreach ($t in $Sel) {
            $Sync.Status = "$($t.Name)..."
            try { Invoke-WTarget { param($Tw, $On) Set-WTweak $Tw $On } -ArgumentList @($t, $Apply) }
            catch { Write-WLog "$($t.Name): $($_.Exception.Message)" 'ERROR' }
        }
    } -OnComplete {
        param($r)
        foreach ($cap in @($r | Where-Object { $_ -and $_.UndoKind })) {
            $uid = Add-AWUndoEntry $cap
            Write-AWAction $(if ($cap.Applied) { 'ApplyTweak' } else { 'RevertTweak' }) @($cap.TweakId) @{} 'Done' $uid
        }
        if ($script:Loaded['Rebloat']) { Update-AWUndoList }
        $ui.TweaksApply.IsEnabled = $true; $ui.TweaksRevert.IsEnabled = $true; $ui.RebloatRevert.IsEnabled = $true
        if ($script:PendingExplorerRestart) { Restart-AWExplorer }
        $script:PendingExplorerRestart = $false
        $script:IdleStatus = 'Tweaks updated - some changes take effect after signing out'
        Update-AWTweakStatus
        if ($script:Loaded['Rebloat']) { Update-AWRebloatTweaks }
    }
}

$ui.AppSearch.Add_TextChanged({ Update-AWAppView })
$ui.AppsShowAll.Add_Checked({ Update-AWAppView })
$ui.AppsShowAll.Add_Unchecked({ Update-AWAppView })
$ui.AppsRecommended.Add_Click({ foreach ($a in $script:AllApps) { $a.IsChecked = $a.Recommended }; $ui.AppList.Items.Refresh() })
$ui.AppsNone.Add_Click({ foreach ($a in $script:AllApps) { $a.IsChecked = $false }; $ui.AppList.Items.Refresh() })
$ui.AppsRemove.Add_Click({ Start-AWAppRemoval })
$ui.DebloatRefresh.Add_Click({ Update-AWAppList; Update-AWTweakStatus })
$ui.DebloatRestore.Add_Click({ Start-AWRestorePoint })
$ui.TweaksDefault.Add_Click({ foreach ($cb in $script:TweakChecks) { $cb.IsChecked = $cb.IsEnabled -and $cb.Tag.Default } })
$ui.TweaksNone.Add_Click({ foreach ($cb in $script:TweakChecks) { $cb.IsChecked = $false } })
$ui.TweaksApply.Add_Click({ Start-AWTweaks $true })
$ui.TweaksRevert.Add_Click({ Start-AWTweaks $false })
#endregion

#region ---------------------------------------------------------------- Rebloat
$script:RebloatApps = @()
$script:RebloatTweakChecks = New-Object System.Collections.Generic.List[object]

function Update-AWRebloatView {
    $q = $ui.RebloatSearch.Text.Trim()
    $items = @(if ($q) { $script:RebloatApps | Where-Object { $_.Name -like "*$q*" -or $_.Package -like "*$q*" } } else { $script:RebloatApps })
    $ui.RebloatList.ItemsSource = $items
    $ui.RebloatInfo.Text = if ($script:RebloatApps.Count) { '{0} app(s) can be put back' -f $items.Count } else { 'Every app Computer Doctor knows about is installed.' }
    if ((Test-AWOffline) -and $script:RebloatApps.Count) {
        $ui.RebloatInfo.Text += ' - offline: only apps marked "Windows copy" or "Resources" can come back now'
    }
}

# Catalog apps missing for the signed-in user, with where each one can come back from:
# a copy still on disk (installed for another user or provisioned), the Store by product ID, or a Store search.
function Update-AWRebloatList {
    if (Test-AWRemote) {
        $script:RebloatApps = @(); $ui.RebloatList.ItemsSource = $null
        $ui.RebloatInfo.Text = 'Reinstalling apps is only available on this PC - Store apps install per user.'
        $ui.RebloatInstall.IsEnabled = $false
        return
    }
    $ui.RebloatInfo.Text = 'Looking for removed apps...'
    $ui.RebloatInstall.IsEnabled = $false
    Start-AWTask -Name 'Find removed apps' -Arguments @{
        Catalog = $script:BloatCatalog; StoreIds = $script:StoreIds; Retired = $script:RetiredApps; Admin = [bool]$script:IsAdmin; ResRoot = [string](Find-AWResources)
    } -Work {
        if ($PSVersionTable.PSVersion.Major -ge 7) { Import-Module Appx -UseWindowsPowerShell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue }
        $mine = @(Get-AppxPackage | ForEach-Object { $_.Name })
        $disk = @{}
        if ($Admin) {
            foreach ($p in @(Get-AppxPackage -AllUsers)) {
                if (-not $disk.ContainsKey($p.Name) -and $p.InstallLocation) {
                    $m = Join-Path $p.InstallLocation 'AppxManifest.xml'
                    if (Test-Path -LiteralPath $m) { $disk[$p.Name] = $m }
                }
            }
            try {
                foreach ($p in @(Get-AppxProvisionedPackage -Online -ErrorAction Stop)) {
                    if (-not $disk.ContainsKey($p.DisplayName) -and $p.InstallLocation) {
                        $m = [Environment]::ExpandEnvironmentVariables($p.InstallLocation)
                        if (Test-Path -LiteralPath $m) { $disk[$p.DisplayName] = $m }
                    }
                }
            } catch { Write-WLog "Could not read provisioned apps: $($_.Exception.Message)" 'WARN' }
        }
        $seen = @{}
        foreach ($c in $Catalog) {
            if ($seen[$c.Name]) { continue }
            $seen[$c.Name] = $true
            if (@($mine | Where-Object { $_ -like $c.Pattern }).Count) { continue }
            $pkg = @($disk.Keys | Where-Object { $_ -like $c.Pattern }) | Select-Object -First 1
            $sid = $StoreIds[$c.Pattern]
            if (-not $pkg -and $Retired -contains $c.Pattern) { continue }
            $e = New-Object ComputerDoctor.AppEntry
            $e.Name = $c.Name; $e.Category = $c.Category; $e.Note = $c.Note; $e.StoreId = $sid
            $e.Package = if ($pkg) { $pkg } else { $c.Pattern }
            # A package staged by Fetch in Resources\appx\<name>\ (bundle + Dependencies) works without internet.
            $staged = $null
            if ($ResRoot) {
                $sdir = Join-Path $ResRoot ("appx\" + ($c.Pattern -replace '[\\/:*?"<>|]', '_'))
                if (Test-Path -LiteralPath $sdir) { $staged = @(Get-ChildItem -LiteralPath $sdir -Recurse -File -Include '*.msixbundle', '*.appxbundle', '*.msix', '*.appx' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\Dependencies\\' } | Sort-Object Length -Descending) | Select-Object -First 1 }
            }
            if ($pkg) { $e.Manifest = $disk[$pkg]; $e.Source = 'Windows copy'; if (-not $e.Note) { $e.Note = 'Quick - no download needed' } }
            elseif ($staged) { $e.Manifest = $staged.FullName; $e.Source = 'Resources'; if (-not $e.Note) { $e.Note = 'Staged package on the Resources stick - no internet needed' } }
            elseif ($sid) { $e.Source = 'Microsoft Store' }
            else { $e.Source = 'Store search'; if (-not $e.Note) { $e.Note = 'Opens the Microsoft Store so you can pick it' } }
            $e
        }
    } -OnComplete {
        param($Result)
        $script:RebloatApps = @($Result | Where-Object { $_ -is [ComputerDoctor.AppEntry] } | Sort-Object Category, Name)
        $ui.RebloatInstall.IsEnabled = $true
        Update-AWRebloatView
        if (-not $script:IsAdmin -and $script:RebloatApps.Count) { $ui.RebloatInfo.Text += ' - run as admin to also use copies already on disk' }
    }
}

function Start-AWRebloat {
    $sel = @($script:RebloatApps | Where-Object { $_.IsChecked })
    if ($sel.Count -eq 0) { Show-AWMessage 'Check the apps you want back first.'; return }
    if (Test-AWOffline) {
        $net = @($sel | Where-Object { $_.Source -notin 'Windows copy', 'Resources' })
        if ($net.Count) {
            if ($net.Count -eq $sel.Count) { Show-AWMessage "These apps can only come back from the Microsoft Store, and this PC is offline.`n`nConnect to the internet (or turn off offline mode), or run Computer Doctor as admin to find copies still on disk."; return }
            Write-AWLog "Offline: skipping $($net.Count) app(s) that need the Microsoft Store" 'WARN'
            $sel = @($sel | Where-Object { $_.Source -in 'Windows copy', 'Resources' })
        }
    }
    $search = @($sel | Where-Object { $_.Source -eq 'Store search' })
    $work = @($sel | Where-Object { $_.Source -ne 'Store search' } | ForEach-Object { @{ Name = $_.Name; Manifest = $_.Manifest; StoreId = $_.StoreId; Source = $_.Source } })
    $list = ($sel | Select-Object -First 20 | ForEach-Object { "  - $($_.Name)  ($($_.Source))" }) -join "`n"
    if ($sel.Count -gt 20) { $list += "`n  ...and $($sel.Count - 20) more" }
    $extra = if ($search.Count) { "`n`nApps marked Store search open in the Microsoft Store so you can install them there." } else { '' }
    if (-not (Confirm-AW "Reinstall $($sel.Count) app(s) for your account?`n`n$list$extra")) { return }
    Write-AWAction 'ReinstallApps' ($sel | ForEach-Object Name) @{} 'Started'

    foreach ($s in ($search | Select-Object -First 5)) {
        Start-Process ('ms-windows-store://search/?query=' + [uri]::EscapeDataString($s.Name))
    }
    if ($search.Count -gt 5) { Write-AWLog "Opened the Store for the first 5 of $($search.Count) apps - run Reinstall again for the rest" 'WARN' }
    if ($work.Count -eq 0) { return }

    $ui.RebloatInstall.IsEnabled = $false
    Start-AWTask -Name 'Reinstall apps' -Arguments @{ Work = $work } -Work {
        if ($PSVersionTable.PSVersion.Major -ge 7) { Import-Module Appx -UseWindowsPowerShell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue }
        $i = 0; $ok = 0
        foreach ($a in $Work) {
            $Sync.Status = "Reinstalling $($a.Name)..."; $Sync.Progress = [int]($i * 100 / $Work.Count); $i++
            if ($a.Source -eq 'Resources') {
                try {
                    $deps = @(Get-ChildItem -LiteralPath (Split-Path $a.Manifest) -Recurse -File -Include '*.appx', '*.msix' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match '\\Dependencies\\' -and $_.Name -match $(if ([Environment]::Is64BitOperatingSystem) { 'x64|neutral' } else { 'x86|neutral' }) } | ForEach-Object FullName)
                    if ($deps.Count) { Add-AppxPackage -Path $a.Manifest -DependencyPath $deps -ErrorAction Stop } else { Add-AppxPackage -Path $a.Manifest -ErrorAction Stop }
                    Write-WLog "Reinstalled $($a.Name) from the Resources folder"; $ok++; continue
                } catch { Write-WLog "$($a.Name): installing the staged package failed ($($_.Exception.Message))" 'WARN' }
            }
            elseif ($a.Manifest) {
                try {
                    Add-AppxPackage -Register $a.Manifest -DisableDevelopmentMode -ErrorAction Stop
                    Write-WLog "Reinstalled $($a.Name) from the copy on disk"; $ok++; continue
                } catch { Write-WLog "$($a.Name): re-registering the copy on disk failed ($($_.Exception.Message))" 'WARN' }
            }
            if (-not $a.StoreId) { Write-WLog "$($a.Name): no Microsoft Store ID - install it from the Store" 'ERROR'; continue }
            & winget.exe install --id $a.StoreId --source msstore --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 | ForEach-Object {
                $l = ("$_" -replace "`0", '').Trim()
                if ($l -and $l -notmatch '^[\s\-\\|/]+$' -and $l -notmatch '[\u2580-\u259F]') { Write-WLog "winget: $l" }
            }
            # -1978335189 = already installed / no applicable upgrade
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) { Write-WLog "Reinstalled $($a.Name) from the Microsoft Store"; $ok++ }
            else { Write-WLog "$($a.Name): winget exit code $LASTEXITCODE" 'ERROR' }
        }
        "Reinstalled $ok of $($Work.Count) app(s)"
    } -OnComplete {
        param($r)
        $msg = @($r | Where-Object { $_ -is [string] }) | Select-Object -Last 1
        $script:IdleStatus = if ($msg) { "$msg - see Activity log" } else { 'Reinstall finished - see Activity log' }
        Update-AWRebloatList
        if ($script:Loaded['Debloat']) { Update-AWAppList }
    }
}

# Lists the debloat tweaks currently in effect so they can be set back to Windows defaults.
function Update-AWRebloatTweaks {
    $list = @($script:Tweaks | Where-Object { Test-AWTweakAllowed $_ })
    Start-AWTask -Name 'Read tweak status' -Arguments @{ Tw = $list } -Work {
        Invoke-WTarget { param($Items) foreach ($t in $Items) { [pscustomobject]@{ Id = $t.Id; On = [bool](Test-WTweak $t) } } } -ArgumentList @(, $Tw)
    } -OnComplete {
        param($Result)
        $on = @{}; foreach ($r in $Result) { if ($r -and $r.On) { $on[[string]$r.Id] = $true } }
        $ui.RebloatTweakItems.Children.Clear(); $script:RebloatTweakChecks.Clear()
        $lastGroup = ''
        foreach ($tw in $script:Tweaks) {
            if (-not $on[$tw.Id]) { continue }
            if ($tw.Group -ne $lastGroup) {
                $h = New-AWText $tw.Group.ToUpper() 11 $script:Res.Dim 'Bold'
                $h.Margin = if ($lastGroup) { '0,16,0,6' } else { '0,8,0,6' }
                [void]$ui.RebloatTweakItems.Children.Add($h)
                $lastGroup = $tw.Group
            }
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Margin = '0,5'; $cb.Tag = $tw; $cb.IsChecked = $true; $cb.ToolTip = $tw.Desc
            $sp = New-Object System.Windows.Controls.StackPanel; $sp.Orientation = 'Horizontal'
            [void]$sp.Children.Add((New-AWText $tw.Name 13))
            if ($tw.Admin) { [void]$sp.Children.Add((New-AWPill 'ADMIN' (Test-AWCanAdmin))) }
            $cb.Content = $sp
            $cb.IsEnabled = $script:IsAdmin -or (Test-AWRemote) -or -not $tw.Admin
            [void]$ui.RebloatTweakItems.Children.Add($cb)
            $script:RebloatTweakChecks.Add($cb)
        }
        if ($script:RebloatTweakChecks.Count -eq 0) {
            $t = New-AWText 'Nothing to restore - no debloat tweaks are in effect.' 12.5 $script:Res.Muted
            $t.TextWrapping = 'Wrap'; $t.Margin = '0,10,0,0'
            [void]$ui.RebloatTweakItems.Children.Add($t)
        }
        $ui.RebloatRevert.IsEnabled = $script:RebloatTweakChecks.Count -gt 0
    }
}

function Initialize-AWRebloat {
    Update-AWRebloatList
    Update-AWRebloatTweaks
    Update-AWUndoList
}

$ui.RebloatRefresh.Add_Click({ Initialize-AWRebloat })
$ui.RebloatSearch.Add_TextChanged({ Update-AWRebloatView })
$ui.RebloatAll.Add_Click({ foreach ($a in $script:RebloatApps) { $a.IsChecked = $true }; $ui.RebloatList.Items.Refresh() })
$ui.RebloatNone.Add_Click({ foreach ($a in $script:RebloatApps) { $a.IsChecked = $false }; $ui.RebloatList.Items.Refresh() })
$ui.RebloatInstall.Add_Click({ Start-AWRebloat })
$ui.RebloatRevert.Add_Click({
    $sel = @($script:RebloatTweakChecks | Where-Object { $_.IsChecked -and $_.IsEnabled } | ForEach-Object { $_.Tag })
    Start-AWTweaks $false $sel ([bool]$ui.RebloatRestartExplorer.IsChecked)
})
#endregion

#region ---------------------------------------------------------------- Remote target
$script:ConnPending = $null
$script:ConnLoadedSaved = $null

function Get-AWCredTarget([string]$TargetHost) { [ComputerDoctor.CredMan]::Prefix + $TargetHost.ToLowerInvariant() }
function Get-AWSavedCred([string]$TargetHost) { try { [ComputerDoctor.CredMan]::ReadHost($TargetHost) } catch { $null } }

# Short names get the domain appended; IPs and FQDNs are used as typed.
function Resolve-AWHost {
    $h = $ui.ConnHost.Text.Trim()
    $d = $ui.ConnDomain.Text.Trim().TrimStart('.')
    if ($h -and $d -and $h -notmatch '[.:]') { "$h.$d" } else { $h }
}
function Resolve-AWUser([string]$User) {
    $d = $ui.ConnDomain.Text.Trim().TrimStart('.')
    if (-not $User -or -not $d -or $User -match '[\\@]') { return $User }
    if ($d -match '\.') { "$User@$d" } else { "$d\$User" }
}
function Test-AWIsAddress([string]$TargetHost) { $TargetHost -match '^\d{1,3}(\.\d{1,3}){3}$' -or $TargetHost -match ':' }

function Show-AWConnMsg([string]$Text, [bool]$Trust = $false) {
    $ui.ConnMsg.Text = $Text
    $ui.ConnMsgBox.Visibility = if ($Text) { 'Visible' } else { 'Collapsed' }
    $ui.ConnTrust.Visibility = if ($Trust) { 'Visible' } else { 'Collapsed' }
}

function Update-AWRecentChips {
    $ui.ConnRecent.Children.Clear()
    $saved = @()
    try { $saved = @([ComputerDoctor.CredMan]::List([ComputerDoctor.CredMan]::Prefix + '*') | ForEach-Object { $_.Substring([ComputerDoctor.CredMan]::Prefix.Length) }) } catch { }
    $hosts = @(@($script:State.RecentTargets) + $saved | Where-Object { $_ } | Select-Object -Unique | Select-Object -First 8)
    foreach ($h in $hosts) {
        $b = New-Object System.Windows.Controls.Button
        $b.Style = $window.FindResource('BtnChip'); $b.Margin = '0,0,6,6'; $b.Tag = $h
        $sp = New-Object System.Windows.Controls.StackPanel; $sp.Orientation = 'Horizontal'
        if ($saved -contains $h.ToLowerInvariant()) {
            $k = New-AWText ([string][char]0xE8D7) 11 $script:Res.Teal; $k.FontFamily = $window.FindResource('IconFont'); $k.Margin = '0,0,6,0'
            $k.VerticalAlignment = 'Center'
            [void]$sp.Children.Add($k)
            $b.ToolTip = 'Credentials saved in Windows Credential Manager'
        }
        [void]$sp.Children.Add((New-AWText $h 12))
        $b.Content = $sp
        $b.Add_Click({ param($s, $e) $ui.ConnHost.Text = $s.Tag; $ui.ConnHost.CaretIndex = $s.Tag.Length })
        [void]$ui.ConnRecent.Children.Add($b)
    }
    $ui.ConnRecent.Visibility = if ($hosts.Count) { 'Visible' } else { 'Collapsed' }
}

function Update-AWConnSaved {
    $h = Resolve-AWHost
    $ui.ConnResolved.Text = if ($h -and $h -ne $ui.ConnHost.Text.Trim()) { "Connects to $h" } else { '' }
    $saved = if ($h) { Get-AWSavedCred $h } else { $null }
    if ($saved) {
        $ui.ConnUseOther.IsChecked = $true
        $ui.ConnUser.Text = $saved[0]; $ui.ConnPass.Password = $saved[1]; $ui.ConnSave.IsChecked = $true
        $ui.ConnForget.Visibility = 'Visible'
        $ui.ConnSavedNote.Text = "Using credentials saved in Windows Credential Manager for $h"
        $ui.ConnSavedNote.Visibility = 'Visible'
        $script:ConnLoadedSaved = $h
    } else {
        $ui.ConnForget.Visibility = 'Collapsed'; $ui.ConnSavedNote.Visibility = 'Collapsed'
        if ($script:ConnLoadedSaved) {
            $ui.ConnUser.Text = ''; $ui.ConnPass.Clear(); $ui.ConnSave.IsChecked = $false
            $script:ConnLoadedSaved = $null
        }
    }
}

function Show-AWConnect {
    Show-AWConnMsg ''
    $ui.ConnProgress.Visibility = 'Collapsed'; $ui.ConnGo.IsEnabled = $true
    $ui.ConnLocal.Visibility = if (Test-AWRemote) { 'Visible' } else { 'Collapsed' }
    $ui.ConnCurrentText.Text = "Current ($env:USERNAME)"
    if (-not $ui.ConnDomain.Text -and $env:USERDNSDOMAIN) { $ui.ConnDomain.Text = $env:USERDNSDOMAIN.ToLowerInvariant() }
    if (Test-AWRemote) { $ui.ConnHost.Text = $script:Target.Host }
    Update-AWRecentChips
    Update-AWConnSaved
    $ui.ConnectOverlay.Visibility = 'Visible'
    [void]$ui.ConnHost.Focus(); $ui.ConnHost.SelectAll()
}
function Hide-AWConnect {
    $ui.ConnectOverlay.Visibility = 'Collapsed'
    $ui.ConnPass.Clear(); $script:ConnLoadedSaved = $null
}

function Update-AWTargetUI {
    if (Test-AWRemote) {
        $ui.TargetText.Text = $script:Target.ComputerName
        $ui.TargetIcon.Foreground = $script:Res.Purple
        $ui.TargetBtn.BorderBrush = $script:Res.Purple
        $ui.TargetBtn.ToolTip = "Working on $($script:Target.ComputerName) ($($script:Target.OS)) as $($script:Target.User)`nClick to change"
        $window.Title = "Computer Doctor - $($script:Target.ComputerName)"
    } else {
        $ui.TargetText.Text = 'This PC'
        $ui.TargetIcon.Foreground = $script:Res.Teal
        $ui.TargetBtn.ClearValue([System.Windows.Controls.Control]::BorderBrushProperty)
        $ui.TargetBtn.ToolTip = 'Choose which computer Computer Doctor works on'
        $window.Title = 'Computer Doctor'
    }
}

function Set-AWTarget($NewTarget) {
    $script:Target = $NewTarget
    Update-AWTargetUI
    Initialize-AWCleaner
    Initialize-AWTools
    Initialize-AWTweaks
    $ui.CleanResults.ItemsSource = $null
    $ui.CleanSummary.Text = 'Ready to analyze'
    $ui.CleanSubtext.Text = if (Test-AWRemote) { "Machine-wide rules run on $($NewTarget.ComputerName). Per-user rules are only available on this PC." } else { 'Pick the rules on the left, then Analyze to see what can be removed.' }
    $ui.CleanProgress.Value = 0
    $script:AllApps = @(); $ui.AppList.ItemsSource = $null; $script:Programs = @(); $ui.ProgList.ItemsSource = $null
    $script:HTabLoaded = @{}; $script:ATabLoaded = @{}
    [void]$script:Loaded.Remove('Programs'); [void]$script:Loaded.Remove('Debloat'); [void]$script:Loaded.Remove('Recovery'); [void]$script:Loaded.Remove('Rebloat'); [void]$script:Loaded.Remove('Health'); [void]$script:Loaded.Remove('Drivers'); [void]$script:Loaded.Remove('Bios'); [void]$script:Loaded.Remove('Admin')
    $ui.MapOnRemote.IsChecked = $true
    Update-AWMapScope
    $script:MenuItems = @(); [void]$script:Loaded.Remove('Startup')
    $cur = Get-AWCurrentView
    Update-AWViewTitle $cur
    if ($cur -eq 'Startup')  { $script:Loaded['Startup'] = $true; if ($ui.STabMenu.IsChecked) { Update-AWMenuList } else { Update-AWStartupList } }
    if ($cur -eq 'Large')    { Update-AWLargeList }
    if ($cur -eq 'Programs') { $script:Loaded['Programs'] = $true; Update-AWProgramList }
    if ($cur -eq 'Debloat')  { $script:Loaded['Debloat'] = $true; Update-AWAppList; Update-AWTweakStatus }
    if ($cur -eq 'Recovery') { $script:Loaded['Recovery'] = $true; Initialize-AWRecovery }
    if ($cur -eq 'Rebloat')  { $script:Loaded['Rebloat'] = $true; Initialize-AWRebloat }
    if ($cur -eq 'Health')   { $script:Loaded['Health'] = $true; Start-AWHealthCheck; foreach ($k in 'Events', 'Boot', 'Sec', 'Priv', 'Crash', 'Sleep') { if ($ui["HTab$k"].IsChecked) { Show-AWHealthTab $k } } }
    if ($cur -eq 'Drivers')  { $script:Loaded['Drivers'] = $true; Start-AWDriverInventory }
    if ($cur -eq 'Bios')     { $script:Loaded['Bios'] = $true; Start-AWBiosRead }
    if ($cur -eq 'Admin')    { $script:Loaded['Admin'] = $true; foreach ($k in 'Profiles', 'Printers', 'Help', 'Software', 'Baseline', 'Time') { if ($ui["ATab$k"].IsChecked) { Show-AWAdminTab $k } } }
    if (Test-AWRemote) {
        Write-AWLog "Target is now $($NewTarget.ComputerName) ($($NewTarget.Host)) - $($NewTarget.OS), signed in as $($NewTarget.User)"
        $script:IdleStatus = "Connected to $($NewTarget.ComputerName)"
    } else {
        Write-AWLog 'Target is now this PC'
        $script:IdleStatus = 'Working on this PC'
    }
    Set-AWStatus $script:IdleStatus
}

function Start-AWConnect {
    if ($script:Jobs.Count -gt 0) { Show-AWConnMsg 'Wait for the running task to finish before switching computers.'; return }
    $h = Resolve-AWHost
    if (-not $h) { Show-AWConnMsg 'Enter a hostname, FQDN or IP address.'; return }
    $cred = $null
    if ($ui.ConnUseOther.IsChecked) {
        $u = Resolve-AWUser $ui.ConnUser.Text.Trim()
        if (-not $u -or $ui.ConnPass.SecurePassword.Length -eq 0) { Show-AWConnMsg 'Enter a username and password, or choose Current credentials.'; return }
        $cred = New-Object System.Management.Automation.PSCredential($u, $ui.ConnPass.SecurePassword.Copy())
    }
    $script:ConnPending = @{ Host = $h; Credential = $cred; Save = ($null -ne $cred -and [bool]$ui.ConnSave.IsChecked) }
    Show-AWConnMsg ''
    $ui.ConnGo.IsEnabled = $false
    $ui.ConnProgress.Visibility = 'Visible'
    Start-AWTask -Name "Connect to $h" -Arguments @{ Cand = @{ Host = $h; Credential = $cred } } -Work {
        $Sync.Status = "Connecting to $($Cand.Host)..."
        $p = @{ ComputerName = $Cand.Host; ErrorAction = 'Stop'; ScriptBlock = {
            $os = Get-CimInstance Win32_OperatingSystem
            $id = [Security.Principal.WindowsIdentity]::GetCurrent()
            [pscustomobject]@{
                ComputerName = $env:COMPUTERNAME; OS = ($os.Caption -replace '^Microsoft\s+', ''); User = $id.Name
                Admin = ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            }
        } }
        if ($Cand.Credential) { $p.Credential = $Cand.Credential }
        try { @{ Ok = $true; Info = (Invoke-Command @p) } }
        catch { @{ Ok = $false; Error = $_.Exception.Message } }
    } -OnComplete { param($Result) Complete-AWConnect $Result }
}

function Complete-AWConnect($Result) {
    $ui.ConnGo.IsEnabled = $true
    $ui.ConnProgress.Visibility = 'Collapsed'
    $res = @($Result | Where-Object { $_ }) | Select-Object -Last 1
    $pend = $script:ConnPending
    if (-not $res -or -not $res.Ok) {
        $err = if ($res) { [string]$res.Error } else { 'The connection attempt failed.' }
        $isAddr = Test-AWIsAddress $pend.Host
        $hint = if ($err -match 'TrustedHosts|Kerberos|0x8009030e|0x80090311|authentication scheme') {
            if ($isAddr) { 'Connecting by IP address needs Other credentials, and the address must be in this PC''s WinRM TrustedHosts list. You can also use the computer''s name instead.' }
            else { 'Kerberos could not authenticate. Use the full name (FQDN) of a domain-joined PC, or choose Other credentials and add the computer to TrustedHosts.' }
        } elseif ($err -match 'Access is denied|access denied') {
            'Access denied. The account needs admin rights on the remote PC, or the username or password is wrong.'
        } elseif ($err -match 'cannot be resolved|cannot find the computer|could not resolve|network path|WinRM cannot complete|firewall|did not respond') {
            'The computer could not be reached. Check the name, make sure it is on, and that PowerShell remoting is enabled on it (Enable-PSRemoting -Force).'
        } else { 'Could not connect.' }
        if ($err.Length -gt 320) { $err = $err.Substring(0, 320) + '...' }
        $trust = $err -match 'TrustedHosts|Kerberos|0x8009030e|0x80090311|authentication scheme'
        Show-AWConnMsg "$hint`n`n$err" $trust
        Write-AWLog "Connect to $($pend.Host) failed: $err" 'WARN'
        return
    }
    $info = $res.Info
    if ($pend.Save) {
        try {
            [ComputerDoctor.CredMan]::Write((Get-AWCredTarget $pend.Host), $pend.Credential.UserName, $ui.ConnPass.Password)
            Write-AWLog "Saved credentials for $($pend.Host) to Windows Credential Manager"
        } catch { Write-AWLog "Could not save credentials: $($_.Exception.Message)" 'WARN' }
    }
    $script:State.RecentTargets = @(@($pend.Host) + @($script:State.RecentTargets | Where-Object { $_ -and $_ -ne $pend.Host }) | Select-Object -First 8)
    Save-AWState
    if (-not $info.Admin) { Write-AWLog "Connected to $($pend.Host) without admin rights - most actions will fail" 'WARN' }
    Hide-AWConnect
    Set-AWTarget @{ Host = $pend.Host; Credential = $pend.Credential; ComputerName = [string]$info.ComputerName; OS = [string]$info.OS; User = [string]$info.User }
}

$ui.TargetBtn.Add_Click({ Show-AWConnect })
$ui.ConnClose.Add_Click({ Hide-AWConnect })
$ui.ConnCancel.Add_Click({ Hide-AWConnect })
$ui.ConnGo.Add_Click({ Start-AWConnect })
$ui.ConnLocal.Add_Click({
    if ($script:Jobs.Count -gt 0) { Show-AWConnMsg 'Wait for the running task to finish before switching computers.'; return }
    Hide-AWConnect; Set-AWTarget $null
})
$ui.ConnPass.Add_PasswordChanged({ $ui.ConnPassHint.Visibility = if ($ui.ConnPass.SecurePassword.Length) { 'Collapsed' } else { 'Visible' } })
$ui.ConnHost.Add_TextChanged({ Update-AWConnSaved })
$ui.ConnDomain.Add_TextChanged({ Update-AWConnSaved })
$ui.ConnUseOther.Add_Checked({ $ui.ConnOtherPanel.Visibility = 'Visible' })
$ui.ConnUseCurrent.Add_Checked({ $ui.ConnOtherPanel.Visibility = 'Collapsed' })
foreach ($c in @($ui.ConnHost, $ui.ConnDomain, $ui.ConnUser, $ui.ConnPass)) {
    $c.Add_KeyDown({ param($s, $e) if ($e.Key -eq 'Return') { $e.Handled = $true; if ($ui.ConnGo.IsEnabled) { Start-AWConnect } } })
}
$ui.ConnForget.Add_Click({
    $h = Resolve-AWHost
    if ($h -and (Confirm-AW "Remove the saved credentials for $h from Windows Credential Manager?")) {
        [void][ComputerDoctor.CredMan]::Delete((Get-AWCredTarget $h))
        [void][ComputerDoctor.CredMan]::Delete([ComputerDoctor.CredMan]::OldPrefix + $h.ToLowerInvariant())   # saved before the rename
        Write-AWLog "Removed saved credentials for $h"
        $ui.ConnSave.IsChecked = $false
        Update-AWConnSaved; Update-AWRecentChips
    }
})
$ui.ConnTrust.Add_Click({
    $h = Resolve-AWHost
    if (-not $script:IsAdmin) { Show-AWConnMsg 'Changing TrustedHosts needs Computer Doctor to run as administrator. Use "Restart as admin", then try again.'; return }
    if (-not (Confirm-AW "Add $h to this PC's WinRM TrustedHosts list?`n`nThis lets PowerShell remoting connect to it with a username and password (NTLM). Only do this for computers you trust.")) { return }
    try {
        if ((Get-Service WinRM).Status -ne 'Running') { Start-Service WinRM -ErrorAction Stop }
        Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $h -Concatenate -Force -ErrorAction Stop
        Write-AWLog "Added $h to WinRM TrustedHosts"
        $ui.ConnUseOther.IsChecked = $true
        Show-AWConnMsg "Added $h to TrustedHosts. Enter credentials under Other credentials and connect again."
    } catch { Show-AWConnMsg "Could not update TrustedHosts: $($_.Exception.Message)" }
})
$window.Add_PreviewKeyDown({
    param($s, $e)
    if ($e.Key -eq 'Escape' -and $ui.ConnectOverlay.Visibility -eq 'Visible') { Hide-AWConnect; $e.Handled = $true }
})
#endregion

#region ---------------------------------------------------------------- Tools
$script:ToolPanel = $null

function Add-AWToolSection([string]$Title) {
    $h = New-AWText $Title.ToUpper() 11 $script:Res.Dim 'Bold'
    $h.Margin = if ($ui.ToolCards.Children.Count) { '4,6,0,10' } else { '4,0,0,10' }
    [void]$ui.ToolCards.Children.Add($h)
    $script:ToolPanel = New-Object System.Windows.Controls.WrapPanel
    [void]$ui.ToolCards.Children.Add($script:ToolPanel)
}

function New-AWToolCard {
    param([string]$Glyph, [string]$Title, [string]$Desc, [string]$ButtonText, [bool]$Admin, [scriptblock]$Action,
          [string]$Accent = 'Teal', [bool]$Remote = $false, [string]$Unavailable = '')
    $card = New-Object System.Windows.Controls.Border
    $card.Style = $window.FindResource('Card'); $card.Width = 300; $card.Margin = '0,0,14,14'; $card.Padding = '18,16'
    $sp = New-Object System.Windows.Controls.StackPanel

    $head = New-Object System.Windows.Controls.StackPanel; $head.Orientation = 'Horizontal'
    $ico = New-Object System.Windows.Controls.Border
    $ico.Width = 34; $ico.Height = 34; $ico.CornerRadius = '10'
    $ico.Background = if ($Accent -eq 'Purple') { $script:Res.PurpleGrad } else { $script:Res.TealGrad }
    $it = New-AWText $Glyph 15; $it.FontFamily = $window.FindResource('IconFont'); $it.Foreground = [System.Windows.Media.Brushes]::White
    $it.HorizontalAlignment = 'Center'; $it.VerticalAlignment = 'Center'
    $ico.Child = $it
    [void]$head.Children.Add($ico)
    $tt = New-AWText $Title 14.5 $null 'SemiBold'; $tt.Margin = '12,0,0,0'; $tt.VerticalAlignment = 'Center'
    [void]$head.Children.Add($tt)
    $localOnly = (Test-AWRemote) -and -not $Remote
    if ($localOnly) { [void]$head.Children.Add((New-AWPill 'THIS PC' $false)) }
    elseif ($Admin) { [void]$head.Children.Add((New-AWPill 'ADMIN' (Test-AWCanAdmin))) }
    [void]$sp.Children.Add($head)

    $d = New-AWText $Desc 12.5 $script:Res.Muted; $d.TextWrapping = 'Wrap'; $d.Margin = '0,10,0,14'; $d.Height = 52
    $d.TextTrimming = 'CharacterEllipsis'; $d.ToolTip = $Desc
    [void]$sp.Children.Add($d)

    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = $ButtonText; $btn.Style = $window.FindResource('BtnChip'); $btn.HorizontalAlignment = 'Left'
    $btn.Tag = $Action
    $btn.IsEnabled = -not $localOnly -and -not $Unavailable -and (-not $Admin -or (Test-AWCanAdmin))
    if ($Unavailable) { $btn.ToolTip = $Unavailable }
    elseif ($localOnly) { $btn.ToolTip = 'Only available on this PC' }
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($btn, $true)
    $btn.Add_Click({ param($s, $e) try { & $s.Tag } catch { Show-AWMessage $_.Exception.Message 'Error' } })
    [void]$sp.Children.Add($btn)
    $card.Child = $sp
    [void]$script:ToolPanel.Children.Add($card)
}

function Get-AWWhere { if (Test-AWRemote) { " on $($script:Target.ComputerName)" } else { '' } }

# Copies Computer Doctor and a profile to an admin-only folder and schedules it as SYSTEM.
# (A SYSTEM task must never run a script that ordinary users can edit.)
function New-AWScheduledMaintenance {
    if (-not $script:IsAdmin) { Show-AWMessage 'Scheduling maintenance needs administrator rights.'; return }
    $existing = Get-ScheduledTask -TaskName 'ComputerDoctor Maintenance' -ErrorAction SilentlyContinue
    if ($existing) {
        $ans = [System.Windows.MessageBox]::Show($window, "Scheduled maintenance is already set up.`n`nYes = replace it with a new schedule`nNo = remove it`nCancel = keep it", 'Computer Doctor', 'YesNoCancel', 'Question')
        if ($ans -eq 'Cancel') { return }
        if ($ans -eq 'No') {
            Unregister-ScheduledTask -TaskName 'ComputerDoctor Maintenance' -Confirm:$false
            Write-AWAction 'ScheduledMaintenance' @('removed') @{} 'Done'; Write-AWLog 'Scheduled maintenance removed'; Initialize-AWTools; return
        }
    }
    $dir = Join-Path $env:ProgramData 'ComputerDoctor\Scheduled'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $profileDest = Join-Path $dir 'maintenance.json'
    if (Confirm-AW "Use your own profile file?`n`nYes = choose a JSON profile`nNo = use the default: restore point, default cleaning rules and a health check") {
        $dlg = New-Object System.Windows.Forms.OpenFileDialog; $dlg.Filter = 'Computer Doctor profile (*.json)|*.json'
        if ($dlg.ShowDialog() -ne 'OK') { return }
        try { [void](Read-AWConfig $dlg.FileName) } catch { Show-AWMessage "That profile can't be read: $($_.Exception.Message)" 'Error'; return }
        Copy-Item -LiteralPath $dlg.FileName -Destination $profileDest -Force
    } else {
        ConvertTo-Json -InputObject ([ordered]@{ RestorePoint = 'Computer Doctor scheduled maintenance'; Clean = @('Default'); HealthCheck = $true }) | Set-Content -LiteralPath $profileDest -Encoding UTF8
    }
    $when = [Microsoft.VisualBasic.Interaction]::InputBox("When should it run? Examples: 'Daily 19:00', 'Sunday 03:00', 'Weekly 02:30' (= Sunday).", 'Computer Doctor - Scheduled maintenance', 'Sunday 03:00')
    if ($when -notmatch '^\s*(Daily|Weekly|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\s+([01]?\d|2[0-3]):([0-5]\d)\s*$') { if ($when) { Show-AWMessage 'Use a form like "Daily 19:00" or "Sunday 03:00".' }; return }
    $day = $Matches[1]; $at = [datetime]::ParseExact("$($Matches[2]):$($Matches[3])", 'H:mm', $null)
    $results = Join-Path $env:ProgramData 'ComputerDoctor\Results'
    $dlg2 = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg2.Description = 'Where should results go? Choose a shared folder to collect them centrally, or cancel to keep them in ProgramData\ComputerDoctor\Results.'
    if ($dlg2.ShowDialog() -eq 'OK') { $results = $dlg2.SelectedPath }
    New-Item -ItemType Directory -Path $results -Force -ErrorAction SilentlyContinue | Out-Null

    Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $dir 'ComputerDoctor.ps1') -Force
    # Admins and SYSTEM full control, users read-only, no inherited write access.
    & icacls.exe $dir /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' 2>&1 | Out-Null
    $exe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $dir 'ComputerDoctor.ps1')`" -Config `"$profileDest`" -Yes -Format Json -OutFile `"$(Join-Path $results '{computer}-{date}.json')`""
    $trigger = if ($day -eq 'Daily') { New-ScheduledTaskTrigger -Daily -At $at } else { New-ScheduledTaskTrigger -Weekly -DaysOfWeek $(if ($day -eq 'Weekly') { 'Sunday' } else { $day }) -At $at }
    try {
        Register-ScheduledTask -TaskName 'ComputerDoctor Maintenance' -Action (New-ScheduledTaskAction -Execute $exe -Argument $arg) -Trigger $trigger `
            -Principal (New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest) `
            -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 4)) -Description 'Computer Doctor scheduled maintenance' -Force | Out-Null
        Write-AWAction 'ScheduledMaintenance' @("$day $($at.ToString('HH:mm'))") @{ Results = $results } 'Done'
        Write-AWLog "Scheduled maintenance: $day at $($at.ToString('HH:mm')), results to $results"
        Show-AWMessage "Scheduled: $day at $($at.ToString('HH:mm')).`n`nComputer Doctor and the profile were copied to $dir (admins only can change them). Results are saved to $results as <computer>-<date>.json."
    } catch { Show-AWMessage "Could not schedule it: $($_.Exception.Message)" 'Error' }
    Initialize-AWTools
}

function Start-AWFleetInventory {
    $def = if ($script:State.FleetHosts) { $script:State.FleetHosts } else { (@($env:COMPUTERNAME) + @($script:State.RecentTargets)) -join ', ' }
    $in = [Microsoft.VisualBasic.Interaction]::InputBox("Computers to inventory (names or addresses, separated by commas). Credentials saved in Credential Manager are used where present; otherwise your current sign-in.", 'Computer Doctor - Fleet inventory', $def)
    $hosts = @($in -split '[,;\s]+' | Where-Object { $_ } | Select-Object -Unique)
    if (-not $hosts.Count) { return }
    $script:State.FleetHosts = $hosts -join ', '; Save-AWState
    Write-AWAction 'FleetInventory' $hosts @{} 'Started'
    $saved = $script:Target; $script:Target = $null
    try {
        Start-AWTask -Name 'Fleet inventory' -Arguments @{ Hosts = $hosts; Root = (Join-Path $script:DataDir 'Inventory') } -Work { Invoke-WFleetInventory $Hosts $Root } -OnComplete {
            param($r)
            $res = @($r | Where-Object { $_ -and $_.Html }) | Select-Object -Last 1
            if (-not $res) { Show-AWMessage 'The inventory did not complete - see the Activity log.' 'Warning'; return }
            $script:IdleStatus = "Fleet inventory: $($res.Count) collected, $($res.Failed) not reached, $($res.Changed) changed"
            Start-Process $res.Html
        }
    } finally { $script:Target = $saved }
}

function Initialize-AWTools {
    $ui.ToolCards.Children.Clear()
    $script:ResourcesRoot = Find-AWResources

    # ---------------- Offline kit
    Add-AWToolSection 'Offline kit'
    $resDesc = if ($script:ResourcesRoot) {
        $have = @($script:ResourceDirs | Where-Object { @(Get-ChildItem -LiteralPath (Join-Path $script:ResourcesRoot $_) -Force -ErrorAction SilentlyContinue).Count })
        "Using $($script:ResourcesRoot)" + $(if ($have.Count) { " - has $($have -join ', ')" } else { ' - still empty' })
    } else { 'None found. Create one (e.g. on a USB stick) to repair Windows and update Defender without internet.' }
    New-AWToolCard ([string][char]0xE8B7) 'Resources folder' $resDesc $(if ($script:ResourcesRoot) { 'Open' } else { 'Create...' }) $false {
        if ($script:ResourcesRoot) { Open-AWExplorer $script:ResourcesRoot; return }
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = 'Choose where to create the Resources folder (a USB stick works well)'
        if ($dlg.ShowDialog() -ne 'OK') { return }
        $root = Join-Path $dlg.SelectedPath 'ComputerDoctor\Resources'
        if ((Split-Path $dlg.SelectedPath -Leaf) -eq 'Resources') { $root = $dlg.SelectedPath }
        New-AWResourceLayout $root
        $script:State.ResourcesPath = $root; Save-AWState
        Write-AWLog "Created Resources folder at $root"
        Initialize-AWTools; Open-AWExplorer $root
    }
    New-AWToolCard ([string][char]0xE838) 'Use another folder' 'Point Computer Doctor at a Resources folder somewhere else, such as a network share or a different USB stick.' 'Choose...' $false {
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = 'Choose a Computer Doctor Resources folder'
        if ($dlg.ShowDialog() -ne 'OK') { return }
        $script:State.ResourcesPath = $dlg.SelectedPath; Save-AWState
        Write-AWLog "Resources folder set to $($dlg.SelectedPath)"
        Initialize-AWTools
    } -Accent 'Purple'
    New-AWToolCard ([string][char]0xE9D5) 'Verify Resources' 'Checks every file against manifest.json (SHA-256) so a corrupted or tampered stick is caught before use.' 'Verify' $false {
        Start-AWTask -Name 'Verify Resources' -Arguments @{ Root = $script:ResourcesRoot } -Work { Test-WResourceManifest $Root } -OnComplete {
            param($r)
            $res = @($r | Where-Object { $_ -and $null -ne $_.Ok }) | Select-Object -Last 1
            $script:IdleStatus = if (-not $res) { 'No manifest.json - build one on a trusted copy first' } elseif ($res.Bad) { "Resources check: $($res.Bad) problem(s) - see Activity log" } else { "Resources check: all $($res.Ok) file(s) OK" }
            if ($res -and $res.Bad) { Show-AWMessage "$($res.Bad) file(s) in the Resources folder are missing or don't match the manifest. See the Activity log for the list." 'Warning' }
        }
    } -Unavailable $(if ($script:ResourcesRoot) { '' } else { 'No Resources folder yet' })
    New-AWToolCard ([string][char]0xE8C8) 'Build manifest' 'Hashes every file in the Resources folder into manifest.json. Do this once on a trusted, complete copy.' 'Build' $false {
        if (-not (Confirm-AW "Hash every file in $($script:ResourcesRoot) and write manifest.json? Large ISOs take a minute or two.")) { return }
        Start-AWTask -Name 'Build Resources manifest' -Arguments @{ Root = $script:ResourcesRoot } -Work { New-WResourceManifest $Root } -OnComplete {
            param($r) $script:IdleStatus = "Manifest written ($(@($r)[-1]) files)"; Write-AWAction 'BuildManifest' @($script:ResourcesRoot) @{} 'Done'
        }
    } -Accent 'Purple' -Unavailable $(if ($script:ResourcesRoot) { '' } else { 'No Resources folder yet' })

    $needCount = if ($script:ResourcesRoot) { @(Get-ChildItem -LiteralPath (Join-Path $script:ResourcesRoot 'needs') -Filter '*.json' -ErrorAction SilentlyContinue).Count } else { 0 }
    New-AWToolCard ([string][char]0xE74E) 'Export needs list' "Offline PC: saves the updates, drivers, apps and definitions this PC is missing to Resources\needs, for a connected PC to fetch." 'Export' $false {
        Export-AWNeedsList
    } -Unavailable $(if ($script:ResourcesRoot) { '' } else { 'No Resources folder yet' })
    New-AWToolCard ([string][char]0xE896) 'Fetch downloads' ("Connected PC: downloads everything the needs lists ask for into the Resources folder" + $(if ($needCount) { " ($needCount list(s) waiting)." } else { ', plus the update scan file and Defender definitions.' })) 'Fetch' $false {
        Start-AWFetch
    } -Accent 'Purple' -Unavailable $(if (-not $script:ResourcesRoot) { 'No Resources folder yet' } elseif (Test-AWOffline) { 'Needs internet - run this on a connected PC' } else { '' })

    $defs = if ($script:ResourcesRoot) { Join-Path $script:ResourcesRoot 'defs\x64\mpam-fe.exe' } else { $null }
    $haveDefs = $defs -and (Test-Path -LiteralPath $defs)
    $defsDesc = if ($haveDefs) { "Installs the definitions in Resources\defs ($(((Get-Item -LiteralPath $defs).LastWriteTime).ToString('yyyy-MM-dd'))) - no internet needed." }
                else { "Keeps Microsoft Defender current on offline PCs. Download mpam-fe.exe on a connected PC into Resources\defs\x64." }
    New-AWToolCard ([string][char]0xE83D) 'Defender offline update' $defsDesc $(if ($haveDefs) { 'Update now' } else { 'Get the file' }) $haveDefs {
        $f = if ($script:ResourcesRoot) { Join-Path $script:ResourcesRoot 'defs\x64\mpam-fe.exe' } else { $null }
        if ($f -and (Test-Path -LiteralPath $f)) {
            if (-not (Confirm-AW "Update Microsoft Defender from`n$f ?")) { return }
            Write-AWAction 'DefenderOfflineUpdate' @($f) @{} 'Started'
            $saved = $script:Target; $script:Target = $null
            try { Start-AWCommandTask 'Defender offline update' ([scriptblock]::Create("& '$($f -replace "'", "''")' 2>&1; ""AWEXIT `$LASTEXITCODE""")) } finally { $script:Target = $saved }
        } elseif (Test-AWOffline) { Show-AWMessage "On a PC with internet, download the 64-bit definition file (mpam-fe.exe) from Microsoft's Defender updates page and save it as Resources\defs\x64\mpam-fe.exe on your USB stick." }
        else { Start-Process 'https://www.microsoft.com/en-us/wdsi/defenderupdates' }
    } -Unavailable $(if (Test-AWRemote) { '' } else { '' })

    # ---------------- Automation
    Add-AWToolSection 'Automation'
    $mt = Get-ScheduledTask -TaskName 'ComputerDoctor Maintenance' -ErrorAction SilentlyContinue
    $mtDesc = if ($mt) { "Scheduled: $(@($mt.Triggers | ForEach-Object { if ($_.DaysOfWeek) { 'weekly' } else { 'daily' } })[0]) at $(([datetime]@($mt.Triggers)[0].StartBoundary).ToString('HH:mm')), as SYSTEM. Click to change or remove." }
              else { 'Runs a maintenance profile (clean, tweaks, health check...) daily or weekly as SYSTEM and saves the results - e.g. to a shared folder.' }
    New-AWToolCard ([string][char]0xE787) 'Scheduled maintenance' $mtDesc $(if ($mt) { 'Change...' } else { 'Set up...' }) $true {
        New-AWScheduledMaintenance
    } -Accent 'Purple'

    # ---------------- Fleet
    Add-AWToolSection 'Fleet'
    New-AWToolCard ([string][char]0xE7F4) 'Fleet inventory' 'Collects hardware, Windows, BIOS, security and installed programs from several PCs over WinRM into one report, and shows what changed since last time.' 'Run...' $false {
        Start-AWFleetInventory
    } -Accent 'Purple'

    # ---------------- Quick fixes
    Add-AWToolSection 'Quick fixes'

    New-AWToolCard ([string][char]0xE774) 'Flush DNS cache' 'Clears cached name lookups. Handy after DNS or hosts-file changes.' 'Flush now' $false {
        Start-AWCommandTask 'Flush DNS' { & ipconfig.exe /flushdns 2>&1; "AWEXIT $LASTEXITCODE" }
    } -Remote $true

    New-AWToolCard ([string][char]0xE8B7) 'Group Policy update' 'Re-applies Group Policy now (gpupdate /force) instead of waiting for the next refresh.' 'Update' $false {
        Start-AWCommandTask 'Group Policy update' {
            # Answer "N" to any restart / log-off prompt. Remotely only computer policy applies.
            if ($Sync.Remote) { & cmd.exe /c 'echo N| gpupdate /target:computer /force' 2>&1 } else { & cmd.exe /c 'echo N| gpupdate /force' 2>&1 }
            "AWEXIT $LASTEXITCODE"
        }
    } -Remote $true -Unavailable $(if (-not (Test-AWRemote) -and -not (Test-Path "$env:SystemRoot\System32\gpupdate.exe")) { 'gpupdate is not available on this edition of Windows' } else { '' })

    New-AWToolCard ([string][char]0xE72C) 'Restart Explorer' 'Restarts the Windows shell. Fixes a frozen taskbar or Start menu without signing out.' 'Restart' $false {
        Restart-AWExplorer
    }

    New-AWToolCard ([string][char]0xE7AC) 'Reset default apps' 'Removes custom default-app associations (DISM), then opens Default apps where Reset restores Microsoft defaults.' 'Reset' $true {
        if (-not (Confirm-AW "Remove the custom default app associations$(Get-AWWhere)?")) { return }
        Start-AWCommandTask 'Reset default app associations' { & dism.exe /Online /Remove-DefaultAppAssociations 2>&1; "AWEXIT $LASTEXITCODE" }
        if (-not (Test-AWRemote)) { Start-Process 'ms-settings:defaultapps' }
    } -Accent 'Purple' -Remote $true

    New-AWToolCard ([string][char]0xE74D) 'Junk file cleanup' 'Temp folders, error reports, crash dumps, update and Delivery Optimization caches live in the Cleaner.' 'Open Cleaner' $false {
        Select-AWView 'Cleaner'
    } -Remote $true

    New-AWToolCard ([string][char]0xE74D) 'Empty Recycle Bin' 'Permanently removes everything in the Recycle Bin on all drives.' 'Empty' $false {
        if (Confirm-AW 'Permanently empty the Recycle Bin on all drives?') {
            [void][ComputerDoctor.Native]::SHEmptyRecycleBin([IntPtr]::Zero, $null, 7)
            Write-AWLog 'Recycle Bin emptied'; Set-AWStatus 'Recycle Bin emptied'; Update-AWDashboard
        }
    } -Accent 'Purple'

    # ---------------- Repair
    Add-AWToolSection 'Repair'

    New-AWToolCard ([string][char]0xE9F5) 'System File Checker' 'Runs sfc /scannow to find and repair corrupted Windows system files. Takes 10-20 minutes.' 'Run SFC' $true {
        if (-not (Confirm-AW "Run System File Checker$(Get-AWWhere)? This can take 10-20 minutes.")) { return }
        Start-AWCommandTask 'System File Checker' { & sfc.exe /scannow 2>&1; "AWEXIT $LASTEXITCODE" }
    } -Remote $true

    # With Windows media in Resources\ISO the repair runs fully offline; otherwise it needs Windows Update.
    $media = @(Get-AWRepairMedia $script:ResourcesRoot) | Select-Object -First 1
    $useMedia = $media -and -not (Test-AWRemote)
    $dismDesc = if ($useMedia) { "Repairs system files from $($media.Name) in your Resources folder - no internet needed. Run it when SFC cannot fix files." }
                elseif (Test-AWOffline) { 'Repairs system files. This PC is offline: put Windows install media (ISO) for this version in Resources\ISO.' }
                else { 'DISM /RestoreHealth repairs the component store from Windows Update. Run it when SFC cannot fix files.' }
    $dismBlock = if (-not $useMedia -and (Test-AWOffline)) { 'Needs internet, or Windows media in Resources\ISO' } else { '' }
    New-AWToolCard ([string][char]0xE90F) 'Repair Windows image' $dismDesc 'Run DISM' $true {
        $m = @(Get-AWRepairMedia $script:ResourcesRoot) | Select-Object -First 1
        if ($m -and -not (Test-AWRemote)) { Start-AWOfflineRepair 'RestoreHealth' $m; return }
        if (-not (Confirm-AW "Run DISM RestoreHealth$(Get-AWWhere)? This can take 10-30 minutes and needs internet access.")) { return }
        Start-AWCommandTask 'DISM RestoreHealth' { & dism.exe /Online /Cleanup-Image /RestoreHealth /NoRestart 2>&1; "AWEXIT $LASTEXITCODE" }
    } -Accent 'Purple' -Remote $true -Unavailable $dismBlock

    $fx = if (Test-AWRemote) { $null } else { Get-WRegValueLocal 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5' 'Install' }
    $fxDesc = if ($fx -eq 1) { '.NET Framework 3.5 is already installed on this PC.' }
              elseif ($useMedia -and $media.Kind) { "Installs .NET 3.5 (needed by older apps and games) from the Windows media in Resources - no internet needed." }
              else { 'Installs .NET 3.5, needed by many older apps and games. Uses Windows Update, or Windows media in Resources\ISO when offline.' }
    $fxBlock = if ($fx -eq 1) { 'Already installed' } elseif (-not $useMedia -and (Test-AWOffline)) { 'Needs internet, or Windows media in Resources\ISO' } else { '' }
    New-AWToolCard ([string][char]0xE943) '.NET Framework 3.5' $fxDesc 'Install' $true {
        $m = @(Get-AWRepairMedia $script:ResourcesRoot) | Select-Object -First 1
        if ($m -and -not (Test-AWRemote)) { Start-AWOfflineRepair 'NetFx3' $m; return }
        if (-not (Confirm-AW "Install .NET Framework 3.5$(Get-AWWhere) from Windows Update?")) { return }
        Start-AWCommandTask 'Install .NET 3.5' { & dism.exe /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart 2>&1; "AWEXIT $LASTEXITCODE" }
    } -Remote $true -Unavailable $fxBlock

    New-AWToolCard ([string][char]0xE895) 'Reset Windows Update' 'Stops update services, renames SoftwareDistribution and catroot2, then restarts them. Fixes stuck updates.' 'Reset' $true {
        if (-not (Confirm-AW "Reset the Windows Update components$(Get-AWWhere)?`n`nUpdate history shown in Settings will be cleared; installed updates are not affected.")) { return }
        Start-AWCommandTask 'Reset Windows Update' {
            $svcs = @('wuauserv', 'bits', 'cryptsvc', 'msiserver')
            foreach ($s in $svcs) {
                try { Stop-Service -Name $s -Force -ErrorAction Stop; Write-WLog "Stopped $s" }
                catch { Write-WLog "Could not stop ${s}: $($_.Exception.Message)" 'WARN' }
            }
            foreach ($d in @("$env:SystemRoot\SoftwareDistribution", "$env:SystemRoot\System32\catroot2")) {
                $old = "$d.old"
                if (Test-Path -LiteralPath $old) { Remove-Item -LiteralPath $old -Recurse -Force -ErrorAction SilentlyContinue }
                try { Rename-Item -LiteralPath $d -NewName ((Split-Path $d -Leaf) + '.old') -ErrorAction Stop; Write-WLog "Renamed $d to $old" }
                catch { Write-WLog "Could not rename ${d}: $($_.Exception.Message)" 'WARN' }
            }
            [array]::Reverse($svcs)
            foreach ($s in $svcs) {
                try { Start-Service -Name $s -ErrorAction Stop; Write-WLog "Started $s" }
                catch { Write-WLog "Could not start ${s}: $($_.Exception.Message)" 'WARN' }
            }
            'AWEXIT 0'
        }
    } -Remote $true

    $ccm = "$env:SystemRoot\CCM\ccmrepair.exe"
    New-AWToolCard ([string][char]0xE7B8) 'Repair Software Center' 'Repairs the Configuration Manager (SCCM) client that powers Software Center. Runs in the background.' 'Repair' $true {
        if (-not (Confirm-AW "Start a Configuration Manager client repair$(Get-AWWhere)?")) { return }
        Start-AWCommandTask 'ConfigMgr client repair' {
            $exe = "$env:SystemRoot\CCM\ccmrepair.exe"
            if (Test-Path -LiteralPath $exe) {
                Start-Process -FilePath $exe
                'Repair started. Progress is logged to C:\Windows\CCM\Logs\ccmrepair.log and ccmsetup.log'
                'AWEXIT 0'
            } else { 'The ConfigMgr client is not installed on this computer'; 'AWEXIT 1' }
        }
    } -Accent 'Purple' -Remote $true -Unavailable $(if (-not (Test-AWRemote) -and -not (Test-Path -LiteralPath $ccm)) { 'The Configuration Manager client is not installed on this PC' } else { '' })

    # ---------------- Maintenance
    Add-AWToolSection 'Maintenance'

    New-AWToolCard ([string][char]0xE90F) 'Component store cleanup' 'Runs DISM /StartComponentCleanup to remove superseded Windows update components. Can take 5-15 minutes.' 'Run DISM' $true {
        if (-not (Confirm-AW "Run DISM component store cleanup$(Get-AWWhere)? This can take several minutes.")) { return }
        Start-AWCommandTask 'DISM component cleanup' { & dism.exe /Online /Cleanup-Image /StartComponentCleanup /NoRestart 2>&1; "AWEXIT $LASTEXITCODE" }
    } -Remote $true

    New-AWToolCard ([string][char]0xE777) 'Restore points' 'Create, review and delete restore points, and set how much space they may use (Recovery > Restore points).' 'Open' $false {
        Select-AWView 'Recovery'; $ui.RecTabRP.IsChecked = $true
    } -Accent 'Purple'

    $hibDesc = 'Turns off hibernation and Fast Startup and deletes hiberfil.sys. Re-enable with powercfg /h on.'
    if (-not (Test-AWRemote)) {
        try { $hf = Get-Item -LiteralPath "$env:SystemDrive\hiberfil.sys" -Force -ErrorAction Stop; $hibDesc = "Frees $(Format-AWSize $hf.Length) by deleting hiberfil.sys. Also turns off Fast Startup. Undo: powercfg /h on." }
        catch { }
    }
    New-AWToolCard ([string][char]0xE708) 'Disable hibernation' $hibDesc 'Disable' $true {
        if (-not (Confirm-AW "Turn off hibernation$(Get-AWWhere)?`n`nThis also disables Fast Startup. Sleep is not affected.")) { return }
        Start-AWCommandTask 'Disable hibernation' { & powercfg.exe /hibernate off 2>&1; "AWEXIT $LASTEXITCODE" }
    } -Remote $true

    New-AWToolCard ([string][char]0xE7C3) 'Windows Disk Cleanup' 'Opens the built-in Disk Cleanup for anything Computer Doctor does not cover, like old Windows installations.' 'Open' $false {
        Start-Process cleanmgr.exe
    }

    New-AWToolCard ([string][char]0xEB05) 'Storage Sense' 'Opens Windows Storage settings to schedule automatic cleanup of temp files and the Recycle Bin.' 'Open settings' $false {
        Start-Process 'ms-settings:storagesense'
    } -Accent 'Purple'

    New-AWToolCard ([string][char]0xE713) 'Refresh dashboard' 'Re-reads drive space and system information after big changes.' 'Refresh' $false {
        Update-AWDashboard; Initialize-AWMapDrives; Initialize-AWTools; Set-AWStatus 'Dashboard refreshed'
    }
}

$ui.LogClear.Add_Click({ $ui.LogBox.Clear() })
$ui.LogOpen.Add_Click({ Start-Process explorer.exe -ArgumentList "`"$script:DataDir`"" })
#endregion

#region ---------------------------------------------------------------- Drivers
$script:DrvInv = $null          # Get-WDriverInventory result
$script:DrvUpdates = $null      # Get-WDriverUpdates result ($null = not checked yet)
$script:DrvEntries = @()
$script:DrvOemInfo = $null

# Joins the installed drivers with Windows Update's offers (matched on hardware / compatible IDs).
function Build-AWDriverEntries {
    if (-not $script:DrvInv) { return }
    $byHw = @{}
    $list = New-Object System.Collections.Generic.List[object]
    foreach ($d in $script:DrvInv.Drivers) {
        $e = New-Object ComputerDoctor.DriverEntry
        $e.Name = $d.Name; $e.Class = $d.Class; $e.Provider = $d.Provider; $e.Version = $d.Version; $e.Date = $d.Date
        $e.Inf = $d.Inf; $e.DeviceId = $d.DeviceId; $e.ErrorCode = $d.ErrorCode
        $e.HardwareId = (@($d.HardwareIds) | Select-Object -First 1)
        $v = Resolve-AWDriverVendor $d.Provider $d.HardwareIds
        $e.Vendor = $v.Name; $e.VendorUrl = $v.Url
        $e.IsMicrosoft = $d.Provider -match '^Microsoft' -or -not $d.Provider     # no provider = generic / no driver package
        $e.Note = "Provider: $($d.Provider)`nINF: $($d.Inf)`n" + ((@($d.HardwareIds) | Select-Object -First 4) -join "`n")
        if ($d.ErrorCode -ne 0) { $e.Status = 'Problem'; $e.UpdateText = "Device Manager reports code $($d.ErrorCode)" }
        else {
            $e.Status = 'OK'
            if (-not $e.IsMicrosoft -and $d.Date -ne [datetime]::MinValue -and $d.Date -lt (Get-Date).AddYears(-3)) {
                $e.UpdateText = "Over 3 years old - worth checking the vendor's site"
            }
        }
        foreach ($h in @($d.HardwareIds)) { $k = $h.ToLowerInvariant(); if (-not $byHw.ContainsKey($k)) { $byHw[$k] = New-Object System.Collections.Generic.List[object] }; $byHw[$k].Add($e) }
        $list.Add($e)
    }
    foreach ($u in @($script:DrvUpdates)) {
        if (-not $u) { continue }
        $hits = if ($u.HardwareId) { $byHw[$u.HardwareId.ToLowerInvariant()] } else { $null }
        $when = if ($u.VerDate -ne [datetime]::MinValue) { $u.VerDate.ToString('yyyy-MM-dd') } else { 'new' }
        if ($hits) {
            foreach ($e in $hits) {
                if ($u.VerDate -gt $e.Date -or $e.Date -eq [datetime]::MinValue) {
                    $e.HasUpdate = $true; $e.Status = 'Update available'; $e.UpdateId = $u.UpdateId; $e.IsChecked = $true
                    $label = if ($u.Model -and $u.Model -ne $e.Name) { "$($u.Model), " } else { '' }
                    $e.UpdateText = "$label$when - from $($u.Source)"; $e.Note = "$($u.Title)`n$($e.Note)"
                    if ($u.Provider -and $u.Provider -notmatch '^Microsoft') { $e.Vendor = (Resolve-AWDriverVendor $u.Provider @($u.HardwareId)).Name }
                } elseif (-not $e.UpdateText) { $e.UpdateText = "Windows Update offers a $when driver (not newer)" }
            }
        } else {
            $e = New-Object ComputerDoctor.DriverEntry
            $e.Name = $(if ($u.Model) { $u.Model } else { $u.Title }); $e.Class = $u.Class; $e.Provider = $u.Provider
            $v = Resolve-AWDriverVendor $u.Provider @($u.HardwareId)
            $e.Vendor = $v.Name; $e.VendorUrl = $v.Url; $e.HardwareId = $u.HardwareId
            $e.HasUpdate = $true; $e.IsChecked = $true; $e.Status = 'Update available'; $e.UpdateId = $u.UpdateId
            $e.UpdateText = "$when - from $($u.Source)"; $e.Note = $u.Title
            $list.Add($e)
        }
    }
    $script:DrvEntries = $list.ToArray()     # (@($list) throws "Argument types do not match" in PS 5.1 here)
}

function Update-AWDrvView {
    $q = $ui.DrvSearch.Text.Trim()
    $hide = [bool]$ui.DrvHideMs.IsChecked; $only = [bool]$ui.DrvOnlyIssues.IsChecked
    $items = @($script:DrvEntries | Where-Object {
        (-not $hide -or -not $_.IsMicrosoft -or $_.HasUpdate -or $_.ErrorCode) -and
        (-not $only -or $_.HasUpdate -or $_.ErrorCode) -and
        (-not $q -or $_.Name -like "*$q*" -or $_.Vendor -like "*$q*" -or $_.Class -like "*$q*" -or $_.Provider -like "*$q*")
    } | Sort-Object SortRank, Vendor, Name)
    $ui.DrvList.ItemsSource = $items
    $upd = @($script:DrvEntries | Where-Object { $_.HasUpdate }).Count
    $prob = @($script:DrvEntries | Where-Object { $_.ErrorCode }).Count
    $state = if ($null -eq $script:DrvUpdates) { 'not checked for updates yet' } else { "$upd update(s) available" }
    $ui.DrvInfo.Text = "$($items.Count) shown - $state - $prob problem(s)"
    $local = -not (Test-AWRemote)
    $ui.DrvInstall.IsEnabled = $upd -gt 0 -and $script:IsAdmin -and $local
    $ui.DrvInstall.ToolTip = if (-not $local) { 'Installing driver updates is only available on this PC' } elseif (-not $script:IsAdmin) { 'Needs administrator rights' } else { $null }
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($ui.DrvInstall, $true)
    foreach ($c in @($ui.DrvBackup, $ui.DrvRestore)) {
        $c.IsEnabled = $local -and $script:IsAdmin
        $c.ToolTip = if (-not $local) { 'Only available on this PC' } elseif (-not $script:IsAdmin) { 'Needs administrator rights' } else { $c.ToolTip }
        [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($c, $true)
    }
}

function Start-AWDriverInventory {
    $ui.DrvSystem.Text = 'Reading drivers...'
    $script:DrvUpdates = $null
    Start-AWTask -Name 'Read drivers' -Work { Invoke-WTarget { Get-WDriverInventory } } -OnComplete {
        param($Result)
        $inv = @($Result | Where-Object { $_ -and $_.System }) | Select-Object -Last 1
        if (-not $inv) { $ui.DrvSystem.Text = 'Could not read drivers - see Activity log.'; return }
        $script:DrvInv = $inv
        $s = $inv.System
        $script:DrvOemInfo = Get-AWOemSupport $s
        $biosDate = if ($s.BiosDate -ne [datetime]::MinValue) { ' (' + $s.BiosDate.ToString('yyyy-MM-dd') + ')' } else { '' }
        $ui.DrvSystem.Text = "$($script:DrvOemInfo.Maker) $($script:DrvOemInfo.Model) - BIOS $($s.Bios)$biosDate - $(@($inv.Drivers).Count) drivers"
        $ui.DrvOem.Content = "$($script:DrvOemInfo.Maker) driver page"
        $ui.DrvOem.IsEnabled = -not (Test-AWOffline)
        $ui.DrvOem.ToolTip = "Opens $($script:DrvOemInfo.Url)" + $(if ($script:DrvOemInfo.SendsSerial) { "`nThe link includes this PC's service tag so Dell shows the exact model." } else { '' })
        if (@($s.Tools).Count) {
            $ui.DrvTools.Text = "Maker update tools installed: $(@($s.Tools) -join ', ') - they can update drivers customized for this model."
            $ui.DrvTools.Visibility = 'Visible'
        } else { $ui.DrvTools.Visibility = 'Collapsed' }
        Build-AWDriverEntries
        Update-AWDrvView
    }
}

function Start-AWDriverCheck {
    if (Test-AWOffline) {
        Show-AWMessage "Checking for driver updates needs internet, and this PC is offline.`n`nOffline, install drivers you've downloaded elsewhere with 'Install from folder...' - for example a backup in your Resources\drivers folder."
        return
    }
    if (-not $script:DrvInv) { Start-AWDriverInventory }
    $ui.DrvCheck.IsEnabled = $false
    $ui.DrvInfo.Text = 'Asking Windows Update which driver updates this PC is offered (10-60 seconds)...'
    Start-AWTask -Name 'Check for driver updates' -Work { Invoke-WTarget { Get-WDriverUpdates } } -OnComplete {
        param($Result)
        $ui.DrvCheck.IsEnabled = $true
        $script:DrvUpdates = @($Result | Where-Object { $_ -and $_.UpdateId })
        Write-AWLog "Windows Update offers $($script:DrvUpdates.Count) driver update(s)"
        Build-AWDriverEntries
        Update-AWDrvView
        if (-not $script:DrvUpdates.Count) { $script:IdleStatus = "Windows Update has no driver updates for this PC - the vendor and $($script:DrvOemInfo.Maker) pages may still have newer ones" }
    }
}

function Start-AWDriverInstall {
    $sel = @($script:DrvEntries | Where-Object { $_.HasUpdate -and $_.IsChecked })
    $ids = @($sel | ForEach-Object UpdateId | Select-Object -Unique)
    if (-not $ids.Count) { Show-AWMessage 'Check the updates you want to install first.'; return }
    $names = ($sel | Select-Object -First 15 | ForEach-Object { "  - $($_.Name)  ($($_.UpdateText))" }) -join "`n"
    if (-not (Confirm-AW "Install $($ids.Count) driver update(s) from Windows Update?`n`n$names`n`nA restore point is created first (if turned on). Some updates need a restart.")) { return }
    Write-AWAction 'DriverUpdates' ($sel | ForEach-Object Name) @{ UpdateIds = $ids } 'Started'
    $ui.DrvInstall.IsEnabled = $false; $ui.DrvCheck.IsEnabled = $false
    $saved = $script:Target; $script:Target = $null
    try {
        Start-AWTask -Name 'Install driver updates' -Arguments @{ Ids = $ids; AutoRP = (Get-AWAutoRP 'installing driver updates') } -Work {
            if ($AutoRP) { $Sync.Status = 'Creating a restore point first...'; [void](New-WRestorePoint $AutoRP) }
            Install-WDriverUpdates $Ids
        } -OnComplete {
            param($r)
            $ui.DrvCheck.IsEnabled = $true
            $res = @($r | Where-Object { $_ -and $null -ne $_.Installed }) | Select-Object -Last 1
            if ($res) {
                Write-AWAction 'DriverUpdates' @("$($res.Installed) installed, $($res.Failed) failed") @{} $(if ($res.Failed) { 'Partly failed' } else { 'Done' })
                Show-AWMessage ("{0} driver update(s) installed{1}.{2}" -f $res.Installed, $(if ($res.Failed) { ", $($res.Failed) failed (see Activity log)" } else { '' }), $(if ($res.Reboot) { "`n`nRestart the PC to finish." } else { '' }))
            }
            Start-AWDriverInventory
        }
    } finally { $script:Target = $saved }
}

# Most useful search term for the Update Catalog: PCI\VEN_xxxx&DEV_xxxx or USB\VID_xxxx&PID_xxxx, else the full ID.
function Get-AWCatalogQuery([string]$HardwareId) {
    if ($HardwareId -match '^((PCI|HDAUDIO|INTELAUDIO)\\.*?(VEN_[0-9A-F]{4})&(DEV_[0-9A-F]{4}))') { return $Matches[1] }
    if ($HardwareId -match '^(USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4})') { return $Matches[1] }
    $HardwareId
}

function Get-AWDriverFolder {
    $sys = $script:DrvInv.System
    $name = ('{0}_{1}' -f $script:DrvOemInfo.Maker, $script:DrvOemInfo.Model) -replace '[\\/:*?"<>|]', '_' -replace '\s+', '-'
    if ($script:ResourcesRoot) { return (Join-Path $script:ResourcesRoot "drivers\$name") }
    $null
}

$ui.DrvCheck.Add_Click({ Start-AWDriverCheck })
$ui.DrvInstall.Add_Click({ Start-AWDriverInstall })
$ui.DrvSearch.Add_TextChanged({ Update-AWDrvView })
foreach ($c in @($ui.DrvHideMs, $ui.DrvOnlyIssues)) { $c.Add_Checked({ Update-AWDrvView }); $c.Add_Unchecked({ Update-AWDrvView }) }
$ui.DrvOem.Add_Click({ if ($script:DrvOemInfo) { Start-Process $script:DrvOemInfo.Url } })
$ui.DrvVendor.Add_Click({
    $e = $ui.DrvList.SelectedItem
    if (-not $e) { Show-AWMessage 'Select a device first.'; return }
    if (Test-AWOffline) { Show-AWMessage 'This PC is offline. Use "Copy hardware ID" and look the driver up on a connected PC.'; return }
    if ($e.VendorUrl) { Start-Process $e.VendorUrl }
    elseif ($e.IsMicrosoft) { Show-AWMessage "$($e.Name) uses a driver built into Windows; it's updated by Windows Update. Use 'Search Update Catalog' for alternatives." }
    else { Show-AWMessage "Computer Doctor doesn't know $($e.Vendor)'s download page. Try the $($script:DrvOemInfo.Maker) driver page or 'Search Update Catalog'." }
})
$ui.DrvCatalog.Add_Click({
    $e = $ui.DrvList.SelectedItem
    if (-not $e -or -not $e.HardwareId) { Show-AWMessage 'Select a device first.'; return }
    if (Test-AWOffline) { Show-AWMessage 'This PC is offline. Use "Copy hardware ID" and search the Microsoft Update Catalog on a connected PC.'; return }
    Start-Process ('https://www.catalog.update.microsoft.com/Search.aspx?q=' + [uri]::EscapeDataString((Get-AWCatalogQuery $e.HardwareId)))
})
$ui.DrvCopyId.Add_Click({
    $e = $ui.DrvList.SelectedItem
    if (-not $e) { Show-AWMessage 'Select a device first.'; return }
    $d = @($script:DrvInv.Drivers | Where-Object { $_.DeviceId -eq $e.DeviceId }) | Select-Object -First 1
    $text = if ($d) { (@($d.HardwareIds) -join "`r`n") } else { [string]$e.HardwareId }
    [System.Windows.Clipboard]::SetText("$($e.Name)`r`n$text")
    Set-AWStatus "Copied the hardware IDs of $($e.Name)"
})
$ui.DrvBackup.Add_Click({
    $dest = Get-AWDriverFolder
    if (-not $dest) {
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = 'Back up all third-party drivers into this folder'
        if ($dlg.ShowDialog() -ne 'OK') { return }
        $dest = $dlg.SelectedPath
    }
    if (-not (Confirm-AW "Export every third-party driver on this PC to`n$dest ?`n`nUse 'Install from folder' to put them back - e.g. after reinstalling Windows, with no internet.")) { return }
    if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
    Write-AWAction 'DriverBackup' @($dest) @{} 'Started'
    $saved = $script:Target; $script:Target = $null
    try { Start-AWCommandTask 'Back up drivers' ([scriptblock]::Create("& pnputil.exe /export-driver * '$($dest -replace "'", "''")' 2>&1; ""AWEXIT `$LASTEXITCODE""")) }
    finally { $script:Target = $saved }
})
$ui.DrvRestore.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Install every driver (.inf) found in this folder and its subfolders'
    $def = Get-AWDriverFolder
    if ($def -and (Test-Path -LiteralPath $def)) { $dlg.SelectedPath = $def }
    if ($dlg.ShowDialog() -ne 'OK') { return }
    $dir = $dlg.SelectedPath
    $n = @(Get-ChildItem -LiteralPath $dir -Filter '*.inf' -Recurse -File -ErrorAction SilentlyContinue).Count
    if (-not $n) { Show-AWMessage 'No driver (.inf) files were found in that folder.'; return }
    if (-not (Confirm-AW "Install drivers from $n .inf file(s) in`n$dir ?`n`nWindows only uses a driver if it matches a device and is better than the current one. A restore point is created first (if turned on).")) { return }
    Write-AWAction 'DriverInstallFromFolder' @($dir) @{ InfCount = $n } 'Started'
    $rp = Get-AWAutoRP 'installing drivers'
    $pre = if ($rp) { "[void](New-WRestorePoint '$($rp -replace "'", "''")')`n" } else { '' }
    $saved = $script:Target; $script:Target = $null
    try { Start-AWCommandTask 'Install drivers from folder' ([scriptblock]::Create("$pre& pnputil.exe /add-driver '$((Join-Path $dir '*.inf') -replace "'", "''")' /subdirs /install 2>&1; ""AWEXIT `$LASTEXITCODE""")) }
    finally { $script:Target = $saved }
})
#endregion

#region ---------------------------------------------------------------- BIOS (view only)
$script:BiosRows = @()

function Update-AWBiosView {
    $q = $ui.BiosSearch.Text.Trim()
    $items = @(if ($q) { $script:BiosRows | Where-Object { $_.Name -like "*$q*" -or $_.Value -like "*$q*" -or $_.Section -like "*$q*" } } else { $script:BiosRows })
    $ui.BiosList.ItemsSource = $items
    $setup = @($script:BiosRows | Where-Object { $_.Section -like 'BIOS setup (*' }).Count
    $ui.BiosInfo.Text = "$($items.Count) item(s)" + $(if ($setup) { " - including $setup BIOS setup option(s) read from the firmware" } else { '' })
}

function Start-AWBiosRead {
    $ui.BiosSummary.Text = 'Reading firmware settings...'
    $local = -not (Test-AWRemote)
    $ui.BiosRestart.IsEnabled = $local -and $script:IsAdmin
    $ui.BiosAdvStart.IsEnabled = $local
    $ui.BiosAdvStart.ToolTip = if ($local) { 'Restarts into the Windows recovery menu: Startup Repair, System Restore, Safe Mode, UEFI settings' } else { 'Only available on this PC' }
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($ui.BiosAdvStart, $true)
    $ui.BiosRestart.ToolTip = if (-not $local) { 'Only available on this PC' } elseif (-not $script:IsAdmin) { 'Needs administrator rights' } else { 'Restarts this PC straight into its UEFI firmware setup screen' }
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($ui.BiosRestart, $true)
    Start-AWTask -Name 'Read firmware settings' -Work { Invoke-WTarget { Get-WFirmwareInfo } } -OnComplete {
        param($Result)
        $script:BiosRows = @($Result | Where-Object { $_ -and $_.Section })
        if (-not $script:BiosRows.Count) { $ui.BiosSummary.Text = 'Could not read firmware settings - see Activity log.'; return }
        $get = { param($n) (@($script:BiosRows | Where-Object { $_.Name -eq $n }) | Select-Object -First 1).Value }
        $warn = @($script:BiosRows | Where-Object { $_.Flag -eq 'Warn' }).Count
        $ui.BiosSummary.Text = "$(& $get 'Maker') $(& $get 'Version') ($(& $get 'Release date')) - $(& $get 'Boot mode') - Secure Boot $(& $get 'Secure Boot')" +
            $(if ($warn) { " - $warn item(s) worth a look" } else { '' })
        $ui.BiosExport.IsEnabled = $true
        if ((& $get 'Boot mode') -ne 'UEFI') { $ui.BiosRestart.IsEnabled = $false; $ui.BiosRestart.ToolTip = 'Only UEFI firmware supports restarting straight into setup' }
        Update-AWBiosView
        Update-AWBiosUpdateCard
    }
}

# Where this PC's BIOS updates come from, and whether Windows Update already offers one.
function Update-AWBiosUpdateCard {
    $get = { param($n) [string](@($script:BiosRows | Where-Object { $_.Name -eq $n }) | Select-Object -First 1).Value }
    $sys = [pscustomobject]@{ Manufacturer = (& $get 'Manufacturer'); Model = (& $get 'Model'); Serial = (& $get 'Serial number')
                              BoardMaker = (& $get 'Board maker'); BoardModel = (& $get 'Board model'); Family = '' }
    $script:BiosOem = Get-AWOemSupport $sys
    $custom = Test-AWGenericMaker $sys.Manufacturer
    $who = if ($custom) { "This looks like a custom-built PC, so BIOS updates come from the motherboard maker: $($script:BiosOem.Maker) $($script:BiosOem.Model)." }
           else { "BIOS updates for the $($script:BiosOem.Maker) $($script:BiosOem.Model) come from $($script:BiosOem.Maker)'s support page, listed under BIOS or Firmware." }
    $rel = & $get 'Release date'
    $ui.BiosUpdText.Text = "$who Installed: $(& $get 'Version') from $rel."
    $ui.BiosFind.ToolTip = "Opens $($script:BiosOem.Url)" + $(if ($script:BiosOem.SendsSerial) { "`nThe link includes this PC's service tag so Dell shows the exact model." } else { '' })
    $ui.BiosFind.IsEnabled = -not (Test-AWOffline)
    $ui.BiosWu.IsEnabled = -not (Test-AWOffline)
    $blOn = (& $get "BitLocker on $($env:SystemDrive)") -eq 'On'
    $ui.BiosBitlocker.Visibility = if ($blOn -and $script:IsAdmin -and -not (Test-AWRemote)) { 'Visible' } else { 'Collapsed' }
    if ($blOn) { $ui.BiosUpdTips.Text = "Before updating: make sure the BitLocker recovery key is saved off this PC (Recovery > Readiness), suspend BitLocker (button), plug a laptop into power, close your apps, follow the maker's instructions, and never turn the PC off during the update." }
}

function Start-AWBiosWuCheck {
    $ui.BiosWu.IsEnabled = $false
    $ui.BiosUpdText.Text = 'Asking Windows Update whether it offers a BIOS / firmware update for this PC (10-60 seconds)...'
    Start-AWTask -Name 'Check Windows Update for BIOS' -Work { Invoke-WTarget { Get-WDriverUpdates } } -OnComplete {
        param($Result)
        $ui.BiosWu.IsEnabled = $true
        $all = @($Result | Where-Object { $_ -and $_.UpdateId })
        $script:DrvUpdates = $all                     # share with the Drivers view
        if ($script:DrvInv) { Build-AWDriverEntries; Update-AWDrvView }
        $fw = @($all | Where-Object { $_.Class -match 'Firmware' })
        Update-AWBiosUpdateCard
        $suffix = if ($fw.Count) {
            'Windows Update offers: ' + (($fw | ForEach-Object { '{0} ({1:yyyy-MM-dd})' -f $(if ($_.Model) { $_.Model } else { $_.Title }), $_.VerDate }) -join '; ') + " - install it from Drivers > Install checked updates, or get it from the maker's page."
        } else { "Windows Update doesn't offer a BIOS update for this PC - check the maker's page." }
        $ui.BiosUpdText.Text = $ui.BiosUpdText.Text + ' ' + $suffix
        Write-AWLog "BIOS update check: Windows Update offers $($fw.Count) firmware update(s)"
    }
}

$ui.BiosFind.Add_Click({
    if (-not $script:BiosOem) { return }
    Write-AWAction 'OpenBiosSupportPage' @($script:BiosOem.Url) @{} 'Done'
    Start-Process $script:BiosOem.Url
})
$ui.BiosWu.Add_Click({ Start-AWBiosWuCheck })
$ui.BiosBitlocker.Add_Click({
    if (-not (Confirm-AW "Suspend BitLocker on $($env:SystemDrive) until the next restart?`n`nDo this right before installing a BIOS update. Protection turns back on automatically after one restart; the drive stays encrypted the whole time.")) { return }
    try {
        $vol = Get-CimInstance -Namespace root/cimv2/Security/MicrosoftVolumeEncryption -ClassName Win32_EncryptableVolume -Filter "DriveLetter='$($env:SystemDrive)'" -ErrorAction Stop
        $r = Invoke-CimMethod -InputObject $vol -MethodName DisableKeyProtectors -Arguments @{ DisableCount = [uint32]1 } -ErrorAction Stop
        if ($r.ReturnValue -ne 0) { throw "BitLocker returned code $($r.ReturnValue)" }
        Write-AWLog "BitLocker suspended on $($env:SystemDrive) for one restart"
        Write-AWAction 'SuspendBitLocker' @($env:SystemDrive) @{ RebootCount = 1 } 'Done'
        Show-AWMessage 'BitLocker is suspended until the next restart. You can install the BIOS update now.'
        Start-AWBiosRead
    } catch { Show-AWMessage "Could not suspend BitLocker: $($_.Exception.Message)" 'Error' }
})

function Export-AWBios {
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $who = if (Test-AWRemote) { $script:Target.ComputerName } else { $env:COMPUTERNAME }
    $dlg.FileName = 'ComputerDoctor-bios-{0}-{1:yyyyMMdd}' -f $who, (Get-Date)
    $dlg.Filter = 'CSV (*.csv)|*.csv|JSON (*.json)|*.json'
    if (-not $dlg.ShowDialog($window)) { return }
    $rows = $script:BiosRows | Select-Object Section, Name, Value, Note
    if ($dlg.FileName -like '*.json') { ConvertTo-Json -InputObject @($rows) -Depth 3 | Set-Content -LiteralPath $dlg.FileName -Encoding UTF8 }
    else { $rows | Export-Csv -LiteralPath $dlg.FileName -NoTypeInformation -Encoding UTF8 }
    Write-AWLog "Firmware settings exported to $($dlg.FileName)"
}

$ui.BiosRefresh.Add_Click({ Start-AWBiosRead })
$ui.BiosAdvStart.Add_Click({ Restart-AWAdvancedStartup })
$ui.BiosExport.Add_Click({ Export-AWBios })
$ui.BiosSearch.Add_TextChanged({ Update-AWBiosView })
$ui.BiosRestart.Add_Click({
    if (-not (Confirm-AW "Restart this PC into its BIOS / UEFI setup now?`n`nSave your work first - open apps will be closed. In setup, use the maker's 'Exit without saving' option if you only want to look.")) { return }
    Write-AWAction 'RestartToFirmware' @($env:COMPUTERNAME) @{} 'Started'
    Update-AWLogView
    try { & shutdown.exe /r /fw /t 5 /c 'Computer Doctor: restarting into BIOS setup' 2>&1 | Out-Null; if ($LASTEXITCODE) { throw "shutdown.exe exit code $LASTEXITCODE" } }
    catch { Show-AWMessage "Could not restart into setup: $($_.Exception.Message)" 'Error' }
})
#endregion

#region ---------------------------------------------------------------- Health Check
$script:HealthResults = @()
$script:HealthChecked = $null

function Get-AWStatusStyle([string]$Status) {
    switch ($Status) {
        'Good'    { @{ Label = 'GOOD';    Bg = '#0F2E25'; Border = '#1F7A5C'; Fg = $script:Res.Success } }
        'Warning' { @{ Label = 'WARNING'; Bg = '#33280E'; Border = '#7A5E14'; Fg = $script:Res.Amber } }
        'Problem' { @{ Label = 'PROBLEM'; Bg = '#3A1619'; Border = '#8C3A3A'; Fg = $script:Res.Danger } }
        'Info'    { @{ Label = 'INFO';    Bg = '#1A1E27'; Border = '#353C4B'; Fg = $script:Res.Muted } }
        default   { @{ Label = 'N/A';     Bg = '#1A1E27'; Border = '#252A35'; Fg = $script:Res.Dim } }
    }
}

# Fix / follow-up button for a health row. Local-only actions are hidden while a remote PC is targeted.
function Get-AWHealthAction([string]$Id) {
    $defs = if ($script:ResourcesRoot) { Join-Path $script:ResourcesRoot 'defs\x64\mpam-fe.exe' } else { $null }
    switch ($Id) {
        'Cleaner'     { @{ Text = 'Open Cleaner'; Local = $false; Run = { Select-AWView 'Cleaner' } } }
        'Reliability' { @{ Text = 'Reliability Monitor'; Local = $true; Run = { Start-Process perfmon.exe -ArgumentList '/rel' } } }
        'Devices'     { @{ Text = 'Device Manager'; Local = $true; Run = { Start-Process devmgmt.msc } } }
        'Readiness'   { @{ Text = 'Open Readiness'; Local = $false; Run = { Select-AWView 'Recovery'; $ui.RecTabReady.IsChecked = $true } } }
        'Memory'      { @{ Text = 'Test memory'; Local = $true; Run = {
                            if (Confirm-AW "Windows Memory Diagnostic restarts the PC and tests memory before Windows starts (about 15-30 minutes).`n`nSave your work, then choose 'Restart now' in the next window. Results show up here afterwards.") { Start-Process mdsched.exe }
                        } } }
        'Defender'    {
            if ($defs -and (Test-Path -LiteralPath $defs)) {
                @{ Text = 'Update from Resources'; Local = $true; Run = {
                    $exe = Join-Path $script:ResourcesRoot 'defs\x64\mpam-fe.exe'
                    if (-not $script:IsAdmin) { Show-AWMessage 'Updating Defender definitions needs administrator rights.'; return }
                    Write-AWAction 'DefenderOfflineUpdate' @($exe) @{} 'Started'
                    Start-AWCommandTask 'Defender offline update' ([scriptblock]::Create("& '$($exe -replace "'", "''")' 2>&1; ""AWEXIT `$LASTEXITCODE"""))
                } }
            } else { @{ Text = 'Windows Security'; Local = $true; Run = { Start-Process 'windowsdefender://threat' } } }
        }
        default { $null }
    }
}

function Show-AWHealth($Rows) {
    $ui.HealthRows.Children.Clear()
    $ui.HealthCounts.Children.Clear()
    $order = @{ Problem = 0; Warning = 1; Info = 2; NA = 3; Good = 4 }
    foreach ($r in @($Rows | Sort-Object { $order[[string]$_.Status] }, Name)) {
        $st = Get-AWStatusStyle $r.Status
        $row = New-Object System.Windows.Controls.Border
        $row.CornerRadius = 10; $row.Padding = '14,10'; $row.Margin = '0,4'
        $row.Background = New-Brush '#1A1E27'; $row.BorderBrush = $window.FindResource('LineBrush'); $row.BorderThickness = 1
        $g = New-Object System.Windows.Controls.Grid
        foreach ($w in 'Auto', '*', 'Auto') { $c = New-Object System.Windows.Controls.ColumnDefinition; $c.Width = $w; $g.ColumnDefinitions.Add($c) }
        $pill = New-Object System.Windows.Controls.Border
        $pill.CornerRadius = 9; $pill.Padding = '0,3'; $pill.Width = 78; $pill.VerticalAlignment = 'Center'; $pill.BorderThickness = 1
        $pill.Background = New-Brush $st.Bg; $pill.BorderBrush = New-Brush $st.Border
        $pt = New-AWText $st.Label 10 $st.Fg 'Bold'; $pt.HorizontalAlignment = 'Center'; $pill.Child = $pt
        [void]$g.Children.Add($pill)
        $sp = New-Object System.Windows.Controls.StackPanel; $sp.Margin = '16,0,12,0'; $sp.VerticalAlignment = 'Center'
        [void]$sp.Children.Add((New-AWText $r.Name 14 $null 'SemiBold'))
        $d = New-AWText ([string]$r.Detail) 12.5 $script:Res.Muted; $d.TextWrapping = 'Wrap'; $d.Margin = '0,3,0,0'
        [void]$sp.Children.Add($d)
        [System.Windows.Controls.Grid]::SetColumn($sp, 1); [void]$g.Children.Add($sp)
        $act = Get-AWHealthAction $r.Action
        if ($act -and -not ($act.Local -and (Test-AWRemote)) -and ($r.Status -ne 'Good' -or $r.Action -eq 'Reliability')) {
            $b = New-Object System.Windows.Controls.Button
            $b.Content = $act.Text; $b.Style = $window.FindResource('BtnChip'); $b.Margin = '0'; $b.VerticalAlignment = 'Center'; $b.Tag = $act.Run
            $b.Add_Click({ param($s, $e) try { & $s.Tag } catch { Show-AWMessage $_.Exception.Message 'Error' } })
            [System.Windows.Controls.Grid]::SetColumn($b, 2); [void]$g.Children.Add($b)
        }
        $row.Child = $g
        [void]$ui.HealthRows.Children.Add($row)
    }
    $cnt = @{}; foreach ($s in 'Good', 'Warning', 'Problem', 'Info', 'NA') { $cnt[$s] = @($Rows | Where-Object { $_.Status -eq $s }).Count }
    foreach ($s in 'Problem', 'Warning', 'Good', 'Info', 'NA') {
        if (-not $cnt[$s]) { continue }
        $st = Get-AWStatusStyle $s
        $chip = New-Object System.Windows.Controls.Border
        $chip.CornerRadius = 11; $chip.Padding = '10,4'; $chip.Margin = '0,0,8,0'; $chip.BorderThickness = 1
        $chip.Background = New-Brush $st.Bg; $chip.BorderBrush = New-Brush $st.Border
        $chip.Child = New-AWText ("{0}  {1}" -f $cnt[$s], $st.Label) 11 $st.Fg 'Bold'
        [void]$ui.HealthCounts.Children.Add($chip)
    }
    $who = if (Test-AWRemote) { $script:Target.ComputerName } else { 'this PC' }
    $ui.HealthTitle.Text = if ($cnt.Problem) { "$($cnt.Problem) problem(s) found" } elseif ($cnt.Warning) { 'A few things need attention' } else { 'Looks healthy' }
    $na = if ($cnt.NA) { " $($cnt.NA) check(s) aren't available on this hardware, so they're not counted as healthy." } else { '' }
    $ui.HealthSummary.Text = "Checked $who at $((Get-Date).ToString('h:mm tt')).$na"
}

function Start-AWHealthCheck {
    $ui.HealthRun.IsEnabled = $false
    $ui.HealthTitle.Text = 'Checking...'
    $ui.HealthSummary.Text = 'Reading disks, event logs, devices, battery and antivirus status. This takes a few seconds.'
    Start-AWTask -Name 'Health check' -Work { Invoke-WTarget { Get-WHealth } } -OnComplete {
        param($Result)
        $ui.HealthRun.IsEnabled = $true
        $script:HealthResults = @($Result | Where-Object { $_ -and $_.Status })
        $script:HealthChecked = Get-Date
        if (-not $script:HealthResults.Count) { $ui.HealthTitle.Text = 'Health check failed'; $ui.HealthSummary.Text = 'See the Activity log for details.'; return }
        Show-AWHealth $script:HealthResults
        $ui.HealthSave.IsEnabled = $true
        $p = @($script:HealthResults | Where-Object { $_.Status -eq 'Problem' }).Count
        Write-AWLog ("Health check: {0} problem(s), {1} warning(s)" -f $p, @($script:HealthResults | Where-Object { $_.Status -eq 'Warning' }).Count)
    }
}

function Save-AWHealthReport {
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $who = if (Test-AWRemote) { $script:Target.ComputerName } else { $env:COMPUTERNAME }
    $dlg.FileName = 'ComputerDoctor-health-{0}-{1:yyyyMMdd-HHmm}' -f $who, (Get-Date)
    $dlg.Filter = 'Web page (*.html)|*.html|JSON (*.json)|*.json'
    if (-not $dlg.ShowDialog($window)) { return }
    if ($dlg.FileName -like '*.json') {
        ConvertTo-Json -InputObject ([ordered]@{ Computer = $who; Checked = $script:HealthChecked.ToString('o'); Results = @($script:HealthResults) }) -Depth 4 | Set-Content -LiteralPath $dlg.FileName -Encoding UTF8
    } else {
        $enc = { param($s) [System.Net.WebUtility]::HtmlEncode([string]$s) }
        $colors = @{ Good = '#1f9e8f'; Warning = '#c98a12'; Problem = '#c8344f'; Info = '#6b7499'; NA = '#8a90a8' }
        $rows = foreach ($r in $script:HealthResults) { "<tr><td><b style='color:$($colors[[string]$r.Status])'>$(& $enc $r.Status)</b></td><td>$(& $enc $r.Name)</td><td>$(& $enc $r.Detail)</td></tr>" }
        @"
<!doctype html><html><head><meta charset="utf-8"><title>Health check - $(& $enc $who)</title>
<style>body{font-family:Segoe UI,sans-serif;margin:32px;color:#1c2140}table{border-collapse:collapse;width:100%}td,th{padding:8px 10px;border-bottom:1px solid #dde;text-align:left;vertical-align:top}th{color:#667}</style></head>
<body><h1>Health check - $(& $enc $who)</h1><p>Checked $($script:HealthChecked.ToString('f')) by Computer Doctor $script:AppVersion. "N/A" means the data isn't available on this hardware - it is not counted as healthy.</p>
<table><tr><th>Status</th><th>Check</th><th>Details</th></tr>
$($rows -join "`n")
</table></body></html>
"@ | Set-Content -LiteralPath $dlg.FileName -Encoding UTF8
    }
    Write-AWLog "Health report saved to $($dlg.FileName)"
}

$ui.HealthRun.Add_Click({ Start-AWHealthCheck })
$ui.HealthSave.Add_Click({ Save-AWHealthReport })

# ---------------- Health tabs: events, startup time, security, privacy
$script:HTabLoaded = @{}

function Show-AWHealthTab([string]$Tab) {
    foreach ($k in 'Checks', 'Events', 'Boot', 'Sec', 'Priv', 'Crash', 'Sleep') { $ui["HPanel$k"].Visibility = if ($k -eq $Tab) { 'Visible' } else { 'Collapsed' } }
    if (-not $script:HTabLoaded[$Tab]) {
        $script:HTabLoaded[$Tab] = $true
        switch ($Tab) { 'Events' { Start-AWEventTriage } 'Boot' { Start-AWBootHistory } 'Sec' { Start-AWSecurityCheck } 'Priv' { Start-AWPrivacyCheck } 'Crash' { Start-AWCrashList } 'Sleep' { Start-AWSleepInfo } }
    }
}

function Start-AWEventTriage {
    $days = if ($ui.EvtDays30.IsChecked) { 30 } else { 7 }
    $ui.EvtInfo.Text = "Reading the last $days days of event logs..."
    Start-AWTask -Name 'Event triage' -Arguments @{ Days = $days } -Work { Invoke-WTarget { param($d) Get-WEventTriage $d } -ArgumentList @($Days) } -OnComplete {
        param($Result)
        $order = @{ Problem = 0; Warning = 1; Info = 2 }
        $rows = @($Result | Where-Object { $_ -and $_.Title } | ForEach-Object {
            [pscustomobject]@{ Severity = $_.Severity; Title = $_.Title; Count = $_.Count; Last = $_.Last; LastText = ([datetime]$_.Last).ToString('MMM d, h:mm tt'); Source = $_.Source; Why = $_.Why; Log = $_.Log; Ids = $_.Ids }
        } | Sort-Object { $order[$_.Severity] }, { - $_.Count })
        $ui.EvtList.ItemsSource = $rows
        $ui.EvtInfo.Text = if ($rows.Count) { "$($rows.Count) kind(s) of problem found" } else { 'Nothing notable in this period' }
        $script:EvtRows = $rows
    }
}

function Start-AWBootHistory {
    $ui.BootSummary.Text = 'Reading startup history...'
    $ui.BootChart.Children.Clear()
    Start-AWTask -Name 'Startup time history' -Work { Invoke-WTarget { Get-WBootHistory 60 } } -OnComplete {
        param($Result)
        $h = @($Result | Where-Object { $_ -and $null -ne $_.Boots }) | Select-Object -Last 1
        $boots = @($h.Boots)
        if (-not $boots.Count) {
            $ui.BootSummary.Text = if (-not $script:IsAdmin -and -not (Test-AWRemote)) { 'Windows only lets administrators read the startup-performance log. Use "Restart as admin" to see this.' } else { 'Windows has not recorded any startups in the last 60 days.' }
            $ui.BootList.ItemsSource = $null; return
        }
        $last = $boots[-1]
        $avg = ($boots | Measure-Object BootMs -Average).Average
        $ui.BootSummary.Text = ('Last startup took {0:N1} s ({1:N1} s until the desktop, {2:N1} s more until it settled). Average of the last {3}: {4:N1} s.' -f ($last.BootMs / 1000), ($last.MainMs / 1000), ($last.PostMs / 1000), $boots.Count, ($avg / 1000))
        # Bar chart: teal = until desktop, purple = settling after sign-in.
        $c = $ui.BootChart; $c.Children.Clear()
        $w = [Math]::Max(300, $c.ActualWidth); $hgt = 150
        $max = [Math]::Max(1, ($boots | Measure-Object BootMs -Maximum).Maximum)
        $bw = [Math]::Min(40, ($w - 20) / $boots.Count - 6)
        for ($i = 0; $i -lt $boots.Count; $i++) {
            $b = $boots[$i]; $x = 10 + $i * ($bw + 6)
            $mainH = ($hgt - 24) * $b.MainMs / $max; $postH = ($hgt - 24) * $b.PostMs / $max
            foreach ($seg in @(@{ H = $mainH; Y = $hgt - 18 - $mainH; Brush = $script:Res.TealGrad }, @{ H = $postH; Y = $hgt - 18 - $mainH - $postH; Brush = $script:Res.PurpleGrad })) {
                $r = New-Object System.Windows.Shapes.Rectangle
                $r.Width = $bw; $r.Height = [Math]::Max(1, $seg.H); $r.Fill = $seg.Brush; $r.RadiusX = 3; $r.RadiusY = 3
                $r.ToolTip = '{0:ddd MMM d, h:mm tt}: {1:N1} s total ({2:N1} s to desktop)' -f $b.Time, ($b.BootMs / 1000), ($b.MainMs / 1000)
                [System.Windows.Controls.Canvas]::SetLeft($r, $x); [System.Windows.Controls.Canvas]::SetTop($r, $seg.Y)
                [void]$c.Children.Add($r)
            }
            if ($i -eq 0 -or $i -eq $boots.Count - 1) {
                $lbl = New-AWText ($b.Time.ToString('MMM d')) 10 $script:Res.Dim
                [System.Windows.Controls.Canvas]::SetLeft($lbl, $x); [System.Windows.Controls.Canvas]::SetTop($lbl, $hgt - 14)
                [void]$c.Children.Add($lbl)
            }
        }
        $ui.BootList.ItemsSource = @($h.Culprits | ForEach-Object {
            [pscustomobject]@{ Kind = $_.Kind; Name = $_.Name; File = $_.File; Times = $_.Times; DelayText = ('{0:N1} s' -f $_.AvgSeconds); LastText = ([datetime]$_.Last).ToString('MMM d, h:mm tt') }
        })
    }
}

function Start-AWSecurityCheck {
    $ui.SecInfo.Text = 'Checking...'
    Start-AWTask -Name 'Security checks' -Work { Invoke-WTarget { Get-WSecurityPosture } } -OnComplete {
        param($Result)
        $order = @{ Problem = 0; Warning = 1; Info = 2; NA = 3; Good = 4 }
        $items = @($Result | Where-Object { $_ -and $_.Name } | Sort-Object { $order[[string]$_.Status] } | ForEach-Object {
            $s = New-Object ComputerDoctor.SecItem
            $s.Id = $_.Id; $s.Name = $_.Name; $s.Status = $_.Status; $s.Detail = $_.Detail; $s.Fix = $_.Fix; $s.Policy = [bool]$_.Policy
            $s.IsChecked = $s.CanFix -and $s.Status -eq 'Problem'
            $s
        })
        $ui.SecList.ItemsSource = $items
        $p = @($items | Where-Object { $_.Status -eq 'Problem' }).Count; $w = @($items | Where-Object { $_.Status -eq 'Warning' }).Count
        $ui.SecInfo.Text = "$p problem(s), $w warning(s), $(@($items | Where-Object { $_.CanFix }).Count) item(s) Computer Doctor can fix."
        $ui.SecFix.IsEnabled = (Test-AWCanAdmin)
    }
}

function Start-AWSecurityFix {
    $sel = @(@($ui.SecList.ItemsSource) | Where-Object { $_ -and $_.IsChecked -and $_.CanFix })
    if (-not $sel.Count) { Show-AWMessage 'Check the items to fix first (only items with a checkbox can be fixed).'; return }
    $pol = @($sel | Where-Object { $_.Policy })
    $extra = if ($pol.Count) { "`n`n$($pol.Count) of these are set by Group Policy, which may undo the fix at the next policy refresh." } else { '' }
    if (-not (Confirm-AW "Apply these fixes$(Get-AWWhere)?`n`n$(($sel | ForEach-Object { "  - $($_.Name)" }) -join "`n")$extra`n`nEach one can be undone from Rebloat > Undo history.")) { return }
    Write-AWAction 'SecurityFix' ($sel | ForEach-Object Fix) @{} 'Started'
    Start-AWTask -Name 'Security fixes' -Arguments @{ Ids = @($sel | ForEach-Object Fix) } -Work {
        foreach ($id in $Ids) {
            try { Invoke-WTarget { param($x) Invoke-WSecurityFix $x } -ArgumentList @($id) } catch { Write-WLog "$($id): $($_.Exception.Message)" 'ERROR' }
        }
    } -OnComplete {
        param($r)
        foreach ($cap in @($r | Where-Object { $_ -and $_.UndoKind })) { $uid = Add-AWUndoEntry $cap; Write-AWAction 'SecurityFix' @($cap.Label) @{} 'Done' $uid }
        if ($script:Loaded['Rebloat']) { Update-AWUndoList }
        Start-AWSecurityCheck
    }
}

function Start-AWPrivacyCheck {
    $ui.PrivInfo.Text = 'Reading...'; $ui.PupInfo.Text = 'Sweeping...'
    Start-AWTask -Name 'Privacy and adware sweep' -Work {
        [pscustomobject]@{ Usage = @(Invoke-WTarget { Get-WPrivacyUsage }); Pup = @(Invoke-WTarget { Get-WPupSweep }) }
    } -OnComplete {
        param($Result)
        $r = @($Result | Where-Object { $_ -and $null -ne $_.Usage }) | Select-Object -Last 1
        $use = @($r.Usage | Where-Object { $_ } | Sort-Object LastUsed -Descending | ForEach-Object {
            [pscustomobject]@{ Capability = $_.Capability; App = $_.App; LastText = ([datetime]$_.LastUsed).ToString('MMM d yyyy, h:mm tt'); NowText = $(if ($_.InUse) { 'IN USE' } else { '' }) }
        })
        $ui.PrivList.ItemsSource = $use
        $now = @($use | Where-Object { $_.NowText }).Count
        $ui.PrivInfo.Text = "$($use.Count) app(s) on record" + $(if ($now) { " - $now in use right now" } else { '' }) + '. Windows keeps only the most recent use per app.' + $(if (Test-AWRemote) { ' On a remote PC this shows the connecting account and system apps only.' } else { '' })
        $pup = @($r.Pup | Where-Object { $_ })
        $ui.PupList.ItemsSource = $pup
        $warn = @($pup | Where-Object { $_.Severity -eq 'Warning' }).Count
        $ui.PupInfo.Text = if (-not $pup.Count) { 'Nothing suspicious found: no forced extensions, hijacked browser settings or unsigned startup programs in user folders.' } else { "$($pup.Count) item(s), $warn worth a look. Report only - nothing is changed." }
    }
}

function New-AWSupportBundle {
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.FileName = 'ComputerDoctor-support-{0}-{1:yyyyMMdd-HHmm}.zip' -f $env:COMPUTERNAME, (Get-Date)
    $dlg.Filter = 'Zip file (*.zip)|*.zip'
    $dlg.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    if (-not $dlg.ShowDialog($window)) { return }
    $zip = $dlg.FileName
    Write-AWAction 'SupportBundle' @($zip) @{} 'Started'
    $saved = $script:Target; $script:Target = $null
    try {
        Start-AWTask -Name 'Create support bundle' -Arguments @{ Zip = $zip; Health = @($script:HealthResults); Version = $script:AppVersion; LogFile = $script:LogFile } -Work {
            $dir = Join-Path ([IO.Path]::GetTempPath()) ('ComputerDoctor-support-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $dir | Out-Null
            $q = '*[System[TimeCreated[timediff(@SystemTime) <= 604800000]]]'
            foreach ($log in 'System', 'Application') {
                $Sync.Status = "Exporting the $log log..."
                & wevtutil.exe epl $log (Join-Path $dir "$log.evtx") "/q:$q" 2>&1 | Out-Null
            }
            $Sync.Status = 'Collecting system information...'
            & systeminfo.exe /fo list 2>&1 | Out-File (Join-Path $dir 'systeminfo.txt') -Encoding UTF8
            & ipconfig.exe /all 2>&1 | Out-File (Join-Path $dir 'ipconfig.txt') -Encoding UTF8
            & driverquery.exe /v /fo csv 2>&1 | Out-File (Join-Path $dir 'drivers.csv') -Encoding UTF8
            $rows = if ($Health.Count) { $Health } else { @(Get-WHealth) }
            ConvertTo-Json -InputObject @($rows) -Depth 4 | Out-File (Join-Path $dir 'health.json') -Encoding UTF8
            ConvertTo-Json -InputObject @(Get-WEventTriage 30) -Depth 4 | Out-File (Join-Path $dir 'events-triage.json') -Encoding UTF8
            Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
                Where-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Export-Csv (Join-Path $dir 'programs.csv') -NoTypeInformation -Encoding UTF8
            if (Test-Path -LiteralPath $LogFile) { Get-Content -LiteralPath $LogFile -Tail 2000 | Out-File (Join-Path $dir 'ComputerDoctor.log') -Encoding UTF8 }
            "Created by Computer Doctor $Version on $(Get-Date -Format o) for $env:COMPUTERNAME. Contains the last 7 days of System/Application events, system and network info, drivers, installed programs and Computer Doctor's health and event reports. Review before sharing - it includes your computer and user names." |
                Out-File (Join-Path $dir 'README.txt') -Encoding UTF8
            if (Test-Path -LiteralPath $Zip) { Remove-Item -LiteralPath $Zip -Force }
            Compress-Archive -Path (Join-Path $dir '*') -DestinationPath $Zip
            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
            Write-WLog "Support bundle saved: $Zip"
            $Zip
        } -OnComplete { param($r) $z = @($r | Where-Object { $_ -is [string] }) | Select-Object -Last 1; if ($z -and (Test-Path -LiteralPath $z)) { Open-AWExplorer $z; $script:IdleStatus = 'Support bundle created' } }
    } finally { $script:Target = $saved }
}

$ui.HTabChecks.Add_Checked({ Show-AWHealthTab 'Checks' })
$ui.HTabEvents.Add_Checked({ Show-AWHealthTab 'Events' })
$ui.HTabBoot.Add_Checked({ Show-AWHealthTab 'Boot' })
$ui.HTabSec.Add_Checked({ Show-AWHealthTab 'Sec' })
$ui.HTabPriv.Add_Checked({ Show-AWHealthTab 'Priv' })
$ui.EvtDays7.Add_Checked({ if ($script:HTabLoaded['Events']) { Start-AWEventTriage } })
$ui.EvtDays30.Add_Checked({ if ($script:HTabLoaded['Events']) { Start-AWEventTriage } })
$ui.EvtViewer.Add_Click({ Start-Process eventvwr.msc })
$ui.EvtBundle.Add_Click({ New-AWSupportBundle })
$ui.BootStartup.Add_Click({ Select-AWView 'Startup' })
$ui.SecRefresh.Add_Click({ Start-AWSecurityCheck })
$ui.SecFix.Add_Click({ Start-AWSecurityFix })
$ui.PrivRefresh.Add_Click({ Start-AWPrivacyCheck })
$ui.PrivSettings.Add_Click({ Start-Process 'ms-settings:privacy-webcam' })
$ui.PupOpen.Add_Click({
    $i = $ui.PupList.SelectedItem
    if (-not $i) { Show-AWMessage 'Select an item first.'; return }
    if ($i.Path -like 'HK*') { Show-AWMessage "This is in the registry:`n$($i.Path)`n`nOpen Registry Editor (regedit) to review it." }
    elseif (Test-Path -LiteralPath $i.Path) { Open-AWExplorer $i.Path }
    else { Show-AWMessage "$($i.Path) no longer exists." }
})
#endregion

#region ---------------------------------------------------------------- Windows updates tab (Drivers view)
$script:WuMissing = $null

function Show-AWDriversTab([string]$Tab) {
    $isUpd = $Tab -eq 'Updates'
    $ui.DrvHeader.Visibility = if ($isUpd) { 'Collapsed' } else { 'Visible' }
    $ui.DrvBody.Visibility = if ($isUpd) { 'Collapsed' } else { 'Visible' }
    $ui.WuPanel.Visibility = if ($isUpd) { 'Visible' } else { 'Collapsed' }
    if ($isUpd) { Update-AWUpdateButtons }
}

function Get-AWUpdateFolder { if ($script:ResourcesRoot) { Join-Path $script:ResourcesRoot 'updates' } else { $null } }

function Update-AWUpdateButtons {
    $script:ResourcesRoot = Find-AWResources
    $cab = if (Get-AWUpdateFolder) { Join-Path (Get-AWUpdateFolder) 'wsusscn2.cab' } else { $null }
    $local = -not (Test-AWRemote)
    $ui.WuScanOnline.IsEnabled = $local -and -not (Test-AWOffline)
    $ui.WuScanOffline.IsEnabled = $local -and $script:IsAdmin -and $cab -and (Test-Path -LiteralPath $cab)
    $ui.WuScanOffline.ToolTip = if (-not $cab -or -not (Test-Path -LiteralPath $cab)) { 'Put wsusscn2.cab in Resources\updates first (Tools > Fetch downloads does it on a connected PC)' } elseif (-not $script:IsAdmin) { 'Needs administrator rights' } else { "Uses $cab ($(((Get-Item -LiteralPath $cab).LastWriteTime).ToString('yyyy-MM-dd'))) - no internet" }
    $ui.WuInstall.IsEnabled = $local -and $script:IsAdmin -and [bool](Get-AWUpdateFolder)
    $ui.WuNeeds.IsEnabled = $local -and [bool]$script:ResourcesRoot
    foreach ($c in @($ui.WuScanOffline, $ui.WuInstall, $ui.WuNeeds)) { [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($c, $true) }
    if (-not $local) { $ui.WuInfo.Text = 'Windows updates can only be scanned and installed on this PC.' }
}

function Get-AWUpdateFiles([string]$KB) {
    $dir = Join-Path (Get-AWUpdateFolder) $KB
    if (-not (Test-Path -LiteralPath $dir)) { return @() }
    $all = @(Get-ChildItem -LiteralPath $dir -File -Include '*.msu', '*.cab' -Recurse -ErrorAction SilentlyContinue)
    # The package named after the KB is the one to install; prerequisites in the same folder are picked up by DISM.
    $main = @($all | Where-Object { $_.Name -match [regex]::Escape($KB.ToLower().Replace('kb', '')) })
    @($(if ($main.Count) { $main } else { $all }) | ForEach-Object FullName)
}

function Show-AWUpdateList {
    $rows = foreach ($u in @($script:WuMissing)) {
        $r = New-Object ComputerDoctor.AdminRow
        $r.Key = $u.KB; $r.Name = $u.Title; $r.Kind = $u.Severity; $r.Size = [long]($u.SizeMB * 1MB)
        $files = if ($u.KB -and (Get-AWUpdateFolder)) { @(Get-AWUpdateFiles $u.KB) } else { @() }
        $r.Status = if ($files.Count) { "Yes ($($files.Count) file(s))" } else { '' }
        $r.Path = ($files -join '|'); $r.CanCheck = $files.Count -gt 0; $r.IsChecked = $r.CanCheck
        $r
    }
    $ui.WuList.ItemsSource = @($rows)
}

function Start-AWUpdateScan([bool]$OfflineScan) {
    $cab = if ($OfflineScan) { Join-Path (Get-AWUpdateFolder) 'wsusscn2.cab' } else { '' }
    $ui.WuInfo.Text = if ($OfflineScan) { 'Scanning offline with the scan file - this takes a few minutes and uses a lot of memory...' } else { 'Asking Windows Update which updates are missing (up to a minute)...' }
    $ui.WuScanOnline.IsEnabled = $false; $ui.WuScanOffline.IsEnabled = $false
    $saved = $script:Target; $script:Target = $null
    try {
        Start-AWTask -Name $(if ($OfflineScan) { 'Offline update scan' } else { 'Windows Update scan' }) -Arguments @{ Cab = $cab } -Work { Get-WMissingUpdates $Cab } -OnComplete {
            param($Result)
            $script:WuMissing = @($Result | Where-Object { $_ -and $_.Title })
            Show-AWUpdateList
            $have = @(@($ui.WuList.ItemsSource) | Where-Object { $_.CanCheck }).Count
            $ui.WuInfo.Text = if ($script:WuMissing.Count) { "$($script:WuMissing.Count) update(s) missing, $have already in the Resources folder." + $(if ($have -lt $script:WuMissing.Count) { ' Export a needs list to fetch the rest on a connected PC.' } else { '' }) } else { 'No missing updates found - this PC is up to date for the scan used.' }
            Write-AWLog "Update scan: $($script:WuMissing.Count) missing"
            Update-AWUpdateButtons
        }
    } finally { $script:Target = $saved }
}

function Start-AWUpdateInstall {
    $rows = @(@($ui.WuList.ItemsSource) | Where-Object { $_ -and $_.IsChecked -and $_.Path })
    $files = @($rows | ForEach-Object { $_.Path -split '\|' } | Where-Object { $_ })
    if (-not $files.Count) {
        # No scan yet: offer everything in Resources\updates (DISM skips what doesn't apply).
        $files = @(Get-ChildItem -LiteralPath (Get-AWUpdateFolder) -Directory -ErrorAction SilentlyContinue | ForEach-Object { Get-AWUpdateFiles $_.Name })
        if (-not $files.Count) { Show-AWMessage 'There are no update packages in Resources\updates yet.'; return }
        if (-not (Confirm-AW "Install all $($files.Count) update package(s) found in Resources\updates?`n`nUpdates that don't apply to this PC are skipped.")) { return }
    } elseif (-not (Confirm-AW "Install $($files.Count) update package(s) from the Resources folder?`n`nA restore point is created first (if turned on). Most updates need a restart.")) { return }
    Write-AWAction 'InstallUpdates' ($files | ForEach-Object { [IO.Path]::GetFileName($_) }) @{} 'Started'
    $ui.WuInstall.IsEnabled = $false
    $saved = $script:Target; $script:Target = $null
    try {
        Start-AWTask -Name 'Install updates' -Arguments @{ Files = $files; AutoRP = (Get-AWAutoRP 'installing updates') } -Work {
            if ($AutoRP) { $Sync.Status = 'Creating a restore point first...'; [void](New-WRestorePoint $AutoRP) }
            Install-WUpdatePackages $Files
        } -OnComplete {
            param($r)
            $res = @($r | Where-Object { $_ -and $null -ne $_.Installed }) | Select-Object -Last 1
            Update-AWUpdateButtons
            if ($res) {
                Write-AWAction 'InstallUpdates' @("$($res.Installed) installed, $($res.Failed) failed") @{} $(if ($res.Failed) { 'Partly failed' } else { 'Done' })
                Show-AWMessage ("{0} update package(s) installed{1}.{2}" -f $res.Installed, $(if ($res.Failed) { ", $($res.Failed) failed (see Activity log)" } else { '' }), $(if ($res.Reboot) { "`n`nRestart the PC to finish." } else { '' }))
            }
        }
    } finally { $script:Target = $saved }
}

function Export-AWNeedsList {
    $script:ResourcesRoot = Find-AWResources
    if (-not $script:ResourcesRoot) { Show-AWMessage 'Create or choose a Resources folder first (Tools > Offline kit) - the needs list is saved there.'; return }
    $apps = if ($script:RebloatApps) { @($script:RebloatApps | Where-Object { $_.IsChecked -and $_.StoreId }) } else { @() }
    $saved = $script:Target; $script:Target = $null
    try {
        Start-AWTask -Name 'Export needs list' -Arguments @{ Missing = @($script:WuMissing); Apps = $apps; Root = $script:ResourcesRoot } -Work {
            $n = Get-WNeedsList $Missing $Apps
            $dir = Join-Path $Root 'needs'; New-Item -ItemType Directory -Path $dir -Force | Out-Null
            $f = Join-Path $dir "$env:COMPUTERNAME.json"
            ConvertTo-Json -InputObject $n -Depth 5 | Set-Content -LiteralPath $f -Encoding UTF8
            Write-WLog "Needs list saved: $f ($(@($n.MissingUpdates).Count) update(s), $(@($n.Apps).Count) app(s), $(@($n.ProblemDevices).Count) problem device(s))"
            $f
        } -OnComplete {
            param($r)
            $f = @($r | Where-Object { $_ -is [string] }) | Select-Object -Last 1
            if ($f) {
                Write-AWAction 'ExportNeedsList' @($f) @{} 'Done'
                $hint = if ($null -eq $script:WuMissing) { "`n`nTip: run an update scan first so missing updates are included." } else { '' }
                Show-AWMessage "Saved $f.`n`nTake the Resources folder to a PC with internet, open Computer Doctor there and use Tools > Fetch downloads (or run ComputerDoctor.ps1 -Fetch). Then bring it back and install.$hint"
            }
        }
    } finally { $script:Target = $saved }
}

function Start-AWFetch {
    $script:ResourcesRoot = Find-AWResources
    if (-not $script:ResourcesRoot) { Show-AWMessage 'Choose the Resources folder (USB stick) first - Tools > Offline kit.'; return }
    if (Test-AWOffline) { Show-AWMessage 'Fetching needs internet. Run this on a connected PC with the Resources folder plugged in.'; return }
    $needs = @(Get-ChildItem -LiteralPath (Join-Path $script:ResourcesRoot 'needs') -Filter '*.json' -ErrorAction SilentlyContinue)
    $what = if ($needs.Count) { "$($needs.Count) needs list(s): $(($needs | ForEach-Object BaseName) -join ', ')" } else { 'no needs lists yet (only the scan file and Defender definitions will be fetched)' }
    if (-not (Confirm-AW "Download into $($script:ResourcesRoot)?`n`nFound $what.`n`nThis gets the offline update scan file (~650 MB, if older than a week), Defender definitions (~200 MB), and the updates, Store apps and drivers the lists ask for. It can take a while.")) { return }
    Write-AWAction 'Fetch' @($script:ResourcesRoot) @{ Needs = @($needs | ForEach-Object BaseName) } 'Started'
    $saved = $script:Target; $script:Target = $null
    try {
        Start-AWTask -Name 'Fetch downloads' -Arguments @{ Root = $script:ResourcesRoot } -Work {
            $s = Invoke-WFetch $Root
            $Sync.Status = 'Updating the Resources manifest...'
            [void](New-WResourceManifest $Root)
            $s
        } -OnComplete {
            param($r)
            $s = @($r | Where-Object { $_ -and $null -ne $_.Updates }) | Select-Object -Last 1
            if ($s) {
                $msg = "Fetched: $($s.Updates) update(s), $($s.Apps) app(s), $($s.Drivers) driver(s)" + $(if ($s.ScanCab) { ', the update scan file' } else { '' }) + $(if ($s.Defender) { ', Defender definitions' } else { '' }) + $(if ($s.Errors) { ". $($s.Errors) problem(s) - see the Activity log." } else { '.' })
                Write-AWAction 'Fetch' @($msg) @{} $(if ($s.Errors) { 'Partly failed' } else { 'Done' })
                Show-AWMessage "$msg`n`nThe manifest was refreshed. Take the Resources folder back to the offline PC."
            }
            Initialize-AWTools
        }
    } finally { $script:Target = $saved }
}

$ui.DTabDrivers.Add_Checked({ Show-AWDriversTab 'Drivers' })
$ui.DTabUpdates.Add_Checked({ Show-AWDriversTab 'Updates' })
$ui.WuScanOnline.Add_Click({ Start-AWUpdateScan $false })
$ui.WuScanOffline.Add_Click({ Start-AWUpdateScan $true })
$ui.WuInstall.Add_Click({ Start-AWUpdateInstall })
$ui.WuNeeds.Add_Click({ Export-AWNeedsList })
#endregion

#region ---------------------------------------------------------------- Health: crashes and sleep tabs
$script:CrashFix = @{ Memory = 'Test memory'; Drivers = 'Update drivers'; Disk = 'Check the disk'; Sfc = 'Repair system files'; Bios = 'Update the BIOS'; Hardware = 'Check hardware errors' }

function Start-AWCrashList {
    $ui.CrashInfo.Text = 'Reading crash dumps and events...'
    Start-AWTask -Name 'Read crash dumps' -Work { Invoke-WTarget { Get-WCrashDumps } } -OnComplete {
        param($Result)
        $rows = @($Result | Where-Object { $_ -and $_.Code } | ForEach-Object {
            [pscustomobject]@{ WhenText = ([datetime]$_.Time).ToString('yyyy-MM-dd HH:mm'); Code = $_.Code; Name = $_.Name; Meaning = $_.Meaning; Action = $_.Action
                FixText = [string]$script:CrashFix[[string]$_.Action]; Parameters = "Parameters: $($_.Parameters)"; Source = $_.Source }
        })
        $ui.CrashList.ItemsSource = $rows
        $common = @($rows | Group-Object Name | Sort-Object Count -Descending | Select-Object -First 1)
        $ui.CrashInfo.Text = if (-not $rows.Count) {
            'No blue screens recorded.' + $(if (-not $script:IsAdmin -and -not (Test-AWRemote)) { ' (Reading the crash dump files needs administrator rights; the event log was checked.)' } else { '' })
        } else { "$($rows.Count) crash(es). Most frequent: $($common[0].Name) ($($common[0].Count)x). Select one and use 'Do suggested fix'." }
    }
}

function Invoke-AWCrashFix {
    $c = $ui.CrashList.SelectedItem
    if (-not $c) { Show-AWMessage 'Select a crash first.'; return }
    switch ($c.Action) {
        'Memory'   { if (Confirm-AW 'Windows Memory Diagnostic restarts the PC and tests memory before Windows starts (15-30 minutes). Save your work first. Continue?') { Start-Process mdsched.exe } }
        'Drivers'  { Select-AWView 'Drivers' }
        'Disk'     { Select-AWView 'Health'; $ui.HTabChecks.IsChecked = $true }
        'Sfc'      { Select-AWView 'Tools' }
        'Bios'     { Select-AWView 'Bios' }
        'Hardware' { $ui.HTabEvents.IsChecked = $true }
        default    { Show-AWMessage "No automatic fix for $($c.Name). Search the code ($($c.Code)) online for details." }
    }
}

function Start-AWSleepInfo {
    $ui.SleepInfo.Text = 'Reading...'
    Start-AWTask -Name 'Sleep and wake info' -Work { Invoke-WTarget { Get-WSleepInfo } } -OnComplete {
        param($Result)
        $s = @($Result | Where-Object { $_ -and $null -ne $_.Wakes }) | Select-Object -Last 1
        if (-not $s) { $ui.SleepInfo.Text = 'Could not read sleep information.'; return }
        $ui.SleepWakes.ItemsSource = @($s.Wakes | ForEach-Object { [pscustomobject]@{ WhenText = ([datetime]$_.Time).ToString('MMM d, h:mm tt'); Name = $_.Source } })
        $ui.SleepInfo.Text = if (@($s.Wakes).Count) { 'Recent wake-ups and what caused them. A network adapter or mouse waking the PC is the usual surprise.' } else { 'No wake-ups recorded recently (or this PC uses Modern Standby, which logs differently - try the Sleep study report).' }
        $ui.SleepArmed.ItemsSource = @($s.Armed)
        $ui.SleepReq.ItemsSource = @($s.Requests | ForEach-Object { [pscustomobject]@{ Kind = $_.Kind; Name = $_.Requester } })
        $ui.SleepStates.Text = 'Available: ' + $(if (@($s.States).Count) { (@($s.States) -join '; ') } else { 'unknown' })
        $ui.SleepTimers.Text = if (-not $s.Admin) { 'Wake timers and what keeps the PC awake need administrator rights.' } elseif (@($s.Timers).Count) { 'Wake timers: ' + (@($s.Timers) -join ' ') } else { 'No wake timers are set.' }
    }
}

$ui.HTabCrash.Add_Checked({ Show-AWHealthTab 'Crash' })
$ui.HTabSleep.Add_Checked({ Show-AWHealthTab 'Sleep' })
$ui.CrashFix.Add_Click({ Invoke-AWCrashFix })
$ui.CrashFolder.Add_Click({ $d = Join-Path $env:SystemRoot 'Minidump'; if (Test-Path -LiteralPath $d) { Open-AWExplorer $d } else { Show-AWMessage 'There is no Minidump folder - Windows has not saved small crash dumps on this PC.' } })
$ui.SleepRefresh.Add_Click({ Start-AWSleepInfo })
$ui.SleepBattery.Add_Click({
    $f = Join-Path ([IO.Path]::GetTempPath()) 'computerdoctor-battery-report.html'
    & powercfg.exe /batteryreport /output $f 2>&1 | Out-Null
    if (Test-Path -LiteralPath $f) { Start-Process $f } else { Show-AWMessage 'No battery report - this PC may not have a battery.' }
})
$ui.SleepStudy.Add_Click({
    if (-not $script:IsAdmin) { Show-AWMessage 'The sleep study needs administrator rights.'; return }
    $f = Join-Path ([IO.Path]::GetTempPath()) 'computerdoctor-sleepstudy.html'
    & powercfg.exe /sleepstudy /output $f 2>&1 | Out-Null
    if (Test-Path -LiteralPath $f) { Start-Process $f } else { Show-AWMessage 'No sleep study is available - it only exists on PCs that use Modern Standby.' }
})
$ui.SleepNoWake.Add_Click({
    $d = $ui.SleepArmed.SelectedItem
    if (-not $d) { Show-AWMessage 'Select a device first.'; return }
    if (-not (Test-AWCanAdmin)) { Show-AWMessage 'Changing wake settings needs administrator rights.'; return }
    if (-not (Confirm-AW "Stop '$d' from waking the PC$(Get-AWWhere)?`n`nYou can undo this from Rebloat > Undo history.")) { return }
    Start-AWTask -Name 'Disable device wake' -Arguments @{ Dev = [string]$d } -Work {
        Invoke-WTarget { param($n) & powercfg.exe /devicedisablewake $n 2>&1 | Out-Null; Write-WLog "$n can no longer wake the PC"
            [pscustomobject]@{ UndoKind = 'Script'; Label = "Stopped '$n' waking the PC"; Revert = "& powercfg.exe /deviceenablewake `"$n`" | Out-Null"
                AppRevert = @([pscustomobject]@{ Tool = 'powercfg.exe'; Args = "/deviceenablewake `"$n`"" }) } } -ArgumentList @($Dev)
    } -OnComplete {
        param($r)
        foreach ($cap in @($r | Where-Object { $_ -and $_.UndoKind })) { $uid = Add-AWUndoEntry $cap; Write-AWAction 'DisableDeviceWake' @($cap.Label) @{} 'Done' $uid }
        Start-AWSleepInfo
    }
})
#endregion

#region ---------------------------------------------------------------- IT Admin
$script:ATabLoaded = @{}

function Show-AWAdminTab([string]$Tab) {
    foreach ($k in 'Profiles', 'Printers', 'Help', 'Software', 'Baseline', 'Time') { $ui["APanel$k"].Visibility = if ($k -eq $Tab) { 'Visible' } else { 'Collapsed' } }
    if (-not $script:ATabLoaded[$Tab]) {
        $script:ATabLoaded[$Tab] = $true
        switch ($Tab) {
            'Profiles' { Start-AWProfiles } 'Printers' { Start-AWPrinters } 'Help' { Start-AWHelpdesk } 'Time' { Start-AWTimeStatus }
            'Baseline' { if (-not $ui.BlFile.Text -and $script:ResourcesRoot) { $f = @(Get-ChildItem -LiteralPath (Join-Path $script:ResourcesRoot 'baselines') -Filter '*.csv' -ErrorAction SilentlyContinue) | Select-Object -First 1; if ($f) { $ui.BlFile.Text = $f.FullName } } }
        }
    }
}

# ---- profiles
function Start-AWProfiles {
    $ui.ProfInfo.Text = 'Reading profiles and measuring their size...'
    Start-AWTask -Name 'Read user profiles' -Work { Invoke-WTarget { Get-WUserProfiles $true } } -OnComplete {
        param($Result)
        $rows = @($Result | Where-Object { $_ -and $_.Sid } | ForEach-Object {
            $r = New-Object ComputerDoctor.AdminRow
            $r.Name = $_.User; $r.Key = $_.Sid; $r.Path = $_.Path; $r.Size = [long]$_.SizeBytes
            $r.When = if ($_.LastUsed) { [datetime]$_.LastUsed } else { [datetime]::MinValue }
            $r.Status = (@($(if ($_.Loaded) { 'In use' }), $_.Flags) | Where-Object { $_ }) -join ', '
            $r.CanCheck = -not $_.Loaded
            $r
        } | Sort-Object Size -Descending)
        $ui.ProfList.ItemsSource = $rows
        [long]$tot = 0; foreach ($r in $rows) { $tot += $r.Size }
        $ui.ProfInfo.Text = "$($rows.Count) profile(s), $(Format-AWSize $tot) in total" + $(if (@($rows | Where-Object { $_.Status -match 'Temporary|Corrupted' }).Count) { ' - some are temporary or corrupted (a common sign-in problem)' } else { '' })
    }
}

function Remove-AWProfiles {
    $sel = @(@($ui.ProfList.ItemsSource) | Where-Object { $_ -and $_.IsChecked -and $_.CanCheck })
    if (-not $sel.Count) { Show-AWMessage 'Check the profiles to remove first (profiles in use cannot be removed).'; return }
    [long]$tot = 0; foreach ($r in $sel) { $tot += $r.Size }
    $list = ($sel | ForEach-Object { "  - $($_.Name)  ($($_.SizeText), last used $($_.WhenText))" }) -join "`n"
    $typed = [Microsoft.VisualBasic.Interaction]::InputBox("This PERMANENTLY deletes these profiles$(Get-AWWhere) - their documents, desktop and settings on this PC ($(Format-AWSize $tot)). It cannot be undone.`n`n$list`n`nType DELETE to confirm.", 'Computer Doctor - Remove profiles', '')
    if ($typed -cne 'DELETE') { Set-AWStatus 'Profile removal cancelled'; return }
    Write-AWAction 'RemoveProfiles' ($sel | ForEach-Object { "$($_.Name) ($($_.Key))" }) @{ Bytes = $tot } 'Started'
    Start-AWTask -Name 'Remove profiles' -Arguments @{ Sids = @($sel | ForEach-Object Key) } -Work {
        foreach ($sid in $Sids) { try { Invoke-WTarget { param($s) Remove-WUserProfile $s } -ArgumentList @($sid) } catch { Write-WLog "Profile $($sid): $($_.Exception.Message)" 'ERROR' } }
    } -OnComplete { param($r) Write-AWAction 'RemoveProfiles' @() @{} 'Done'; Start-AWProfiles }
}

# ---- printers
function Start-AWPrinters {
    $ui.PrnInfo.Text = 'Reading printers...'
    Start-AWTask -Name 'Read printers' -Work { Invoke-WTarget { Get-WPrinterInfo } } -OnComplete {
        param($Result)
        $rows = @($Result | Where-Object { $_ -and $_.Name } | ForEach-Object {
            $r = New-Object ComputerDoctor.AdminRow; $r.Kind = $_.Kind; $r.Name = $_.Name; $r.Status = $_.Status; $r.Detail = $_.Detail; $r.CanCheck = $true; $r
        })
        $ui.PrnList.ItemsSource = $rows
        $unused = @($rows | Where-Object { $_.Status -eq 'Not used by any printer' }).Count
        $ui.PrnInfo.Text = "$(@($rows | Where-Object { $_.Kind -eq 'Printer' }).Count) printer(s)" + $(if ($unused) { ", $unused leftover port(s) / driver(s) not used by any printer" } else { '' })
    }
}

function Remove-AWPrinterItems {
    $sel = @(@($ui.PrnList.ItemsSource) | Where-Object { $_ -and $_.IsChecked })
    if (-not $sel.Count) { Show-AWMessage 'Check what to remove first.'; return }
    if (-not (Confirm-AW "Remove these$(Get-AWWhere)?`n`n$(($sel | ForEach-Object { "  - $($_.Kind): $($_.Name)" }) -join "`n")")) { return }
    $order = @{ Printer = 0; Port = 1; Driver = 2 }
    $items = @($sel | Sort-Object { $order[$_.Kind] } | ForEach-Object { @{ Kind = $_.Kind; Name = $_.Name } })
    Write-AWAction 'RemovePrinterItems' ($items | ForEach-Object { "$($_.Kind): $($_.Name)" }) @{} 'Started'
    Start-AWTask -Name 'Remove printer items' -Arguments @{ Items = $items } -Work {
        foreach ($i in $Items) { try { Invoke-WTarget { param($k, $n) Remove-WPrinterItem $k $n } -ArgumentList @($i.Kind, $i.Name) } catch { Write-WLog "$($i.Kind) $($i.Name): $($_.Exception.Message)" 'ERROR' } }
    } -OnComplete { param($r) Start-AWPrinters }
}

function Add-AWPrinterByIp {
    $ip = [Microsoft.VisualBasic.Interaction]::InputBox('Printer IP address (it must accept standard TCP/IP printing on port 9100):', 'Computer Doctor - Add printer', '')
    if (-not $ip) { return }
    if ($ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$' -and $ip -notmatch '^[A-Za-z0-9.-]+$') { Show-AWMessage 'That is not a valid address.'; return }
    $name = [Microsoft.VisualBasic.Interaction]::InputBox('Name for the printer:', 'Computer Doctor - Add printer', "Printer at $ip")
    if (-not $name) { return }
    $drv = [Microsoft.VisualBasic.Interaction]::InputBox("Driver to use. 'Microsoft PCL6 Class Driver' works with most office printers; for PostScript printers use 'Microsoft PS Class Driver'. Any installed driver name works.", 'Computer Doctor - Add printer', 'Microsoft PCL6 Class Driver')
    if (-not $drv) { return }
    Write-AWAction 'AddPrinter' @("$name ($ip)") @{ Driver = $drv } 'Started'
    Start-AWTask -Name 'Add printer' -Arguments @{ Ip = $ip; Name = $name; Drv = $drv } -Work {
        try { Invoke-WTarget { param($a, $b, $c) Add-WPrinterByIp $a $b $c } -ArgumentList @($Ip, $Name, $Drv) } catch { Write-WLog "Add printer: $($_.Exception.Message)" 'ERROR' }
    } -OnComplete { param($r) Start-AWPrinters }
}

# ---- helpdesk
function Start-AWHelpdesk {
    Start-AWTask -Name 'Read sessions and processes' -Work { [pscustomobject]@{ S = @(Invoke-WTarget { Get-WSessions }); P = @(Invoke-WTarget { Get-WTopProcesses }) } } -OnComplete {
        param($Result)
        $x = @($Result | Where-Object { $_ -and $null -ne $_.S }) | Select-Object -Last 1
        $ui.HdSessions.ItemsSource = @($x.S | ForEach-Object { $r = New-Object ComputerDoctor.AdminRow; $r.Name = $_.User; $r.Kind = $_.Session; $r.Key = [string]$_.Id; $r.Status = $_.State; $r.Detail = (@($_.Idle, $_.Logon) | Where-Object { $_ }) -join ' / '; $r })
        $ui.HdProcs.ItemsSource = @($x.P | ForEach-Object { $r = New-Object ComputerDoctor.AdminRow; $r.Name = $_.Name; $r.Key = [string]$_.Id; $r.Size = [long]$_.MemMB * 1MB; $r.Detail = "$($_.CpuSec) s"; $r.Status = $(if ($_.Responding) { 'Running' } else { 'Not responding' }); $r })
    }
}

function Invoke-AWHelpCommand([string]$Name, [scriptblock]$Script, $ArgList = @()) {
    Write-AWAction 'Helpdesk' @($Name) @{} 'Started'
    Start-AWTask -Name $Name -Arguments @{ Body = $Script.ToString(); A = @($ArgList) } -Work {
        try { Invoke-WTarget ([scriptblock]::Create($Body)) -ArgumentList $A } catch { Write-WLog "$($_.Exception.Message)" 'ERROR' }
    } -OnComplete { param($r) Start-AWHelpdesk }
}

# ---- software push
function Start-AWSoftwarePush {
    $file = $ui.SwFile.Text.Trim()
    if (-not $file -or -not (Test-Path -LiteralPath $file)) { Show-AWMessage 'Choose the installer (.msi or .exe) first.'; return }
    $hosts = @($ui.SwHosts.Text -split '[,;\s]+' | Where-Object { $_ } | Select-Object -Unique)
    if (-not $hosts.Count) { Show-AWMessage 'Enter at least one computer (localhost for this PC).'; return }
    $args2 = $ui.SwArgs.Text.Trim()
    if ($file -like '*.exe' -and -not $args2) { if (-not (Confirm-AW "No silent switch was given for this .exe. Without one, the installer may wait for someone to click through it on each PC and never finish.`n`nContinue anyway?")) { return } }
    if (-not (Confirm-AW "Install $([IO.Path]::GetFileName($file)) on $($hosts.Count) PC(s)?`n`n$($hosts -join ', ')")) { return }
    Write-AWAction 'SoftwarePush' $hosts @{ Installer = $file; Arguments = $args2 } 'Started'
    $ui.SwRun.IsEnabled = $false
    $saved = $script:Target; $script:Target = $null
    try {
        Start-AWTask -Name 'Software push' -Arguments @{ Hosts = $hosts; File = $file; A = $args2 } -Work { Invoke-WSoftwarePush $Hosts $File $A } -OnComplete {
            param($Result)
            $ui.SwRun.IsEnabled = $true
            $rows = @($Result | Where-Object { $_ -and $_.Computer } | ForEach-Object { $r = New-Object ComputerDoctor.AdminRow; $r.Name = $_.Computer; $r.Status = $_.Result; $r.Key = [string]$_.Code; $r.Detail = $_.Log; $r })
            $ui.SwResults.ItemsSource = $rows
            $ok = @($Result | Where-Object { $_.Ok }).Count
            Write-AWAction 'SoftwarePush' @("$ok of $($rows.Count) succeeded") @{} $(if ($ok -eq $rows.Count) { 'Done' } else { 'Partly failed' })
            $script:IdleStatus = "Software push: $ok of $($rows.Count) PC(s) succeeded"
        }
    } finally { $script:Target = $saved }
}

# ---- baseline audit
$script:BlResults = @()
function Update-AWBaselineView {
    $only = [bool]$ui.BlFailed.IsChecked
    $ui.BlList.ItemsSource = @($script:BlResults | Where-Object { -not $only -or $_.Result -eq 'Failed' } | Sort-Object @{ e = { switch ($_.Severity) { 'High' { 0 } 'Medium' { 1 } 'Low' { 2 } default { 3 } } } }, Category)
}

function Start-AWBaselineAudit {
    $f = $ui.BlFile.Text.Trim()
    if (-not $f -or -not (Test-Path -LiteralPath $f)) { Show-AWMessage 'Choose a baseline list (.csv) first. Tools > Fetch downloads saves a few to Resources\baselines, or download one from the HardeningKitty project.'; return }
    $text = Get-Content -LiteralPath $f -Raw
    $ui.BlInfo.Text = "Auditing against $([IO.Path]::GetFileName($f))..."
    $ui.BlRun.IsEnabled = $false
    Start-AWTask -Name 'Baseline audit' -Arguments @{ Csv = $text } -Work {
        Invoke-WTarget { param($t) $p = Join-Path ([IO.Path]::GetTempPath()) ('computerdoctor-baseline-{0}.csv' -f [guid]::NewGuid().ToString('N')); Set-Content -LiteralPath $p -Value $t -Encoding UTF8; try { Invoke-WBaselineAudit $p } finally { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue } } -ArgumentList @($Csv)
    } -OnComplete {
        param($Result)
        $ui.BlRun.IsEnabled = $true
        $script:BlResults = @($Result | Where-Object { $_ -and $_.Result })
        $g = @{}; foreach ($x in $script:BlResults) { $g[$x.Result] = 1 + [int]$g[$x.Result] }
        $scored = [int]$g['Passed'] + [int]$g['Failed']
        $pct = if ($scored) { [Math]::Round(100.0 * [int]$g['Passed'] / $scored) } else { 0 }
        $ui.BlInfo.Text = "$pct% compliant: $([int]$g['Passed']) passed, $([int]$g['Failed']) failed" + $(if ($g['Needs admin']) { ", $($g['Needs admin']) need admin" } else { '' }) + $(if ($g['Not supported']) { ", $($g['Not supported']) not supported by Computer Doctor" } else { '' }) + '. Audit only - nothing was changed.'
        $ui.BlExport.IsEnabled = $true
        Update-AWBaselineView
        Write-AWAction 'BaselineAudit' @($ui.BlFile.Text) @{ Passed = [int]$g['Passed']; Failed = [int]$g['Failed'] } 'Done'
    }
}

# ---- time and network
function Start-AWTimeStatus {
    $ui.TimeStatus.Text = 'Reading...'
    Start-AWTask -Name 'Read time status' -Work { Invoke-WTarget { Get-WTimeStatus } } -OnComplete {
        param($Result)
        $s = @($Result | Where-Object { $_ -and $_.Source }) | Select-Object -Last 1
        if (-not $s) { $ui.TimeStatus.Text = 'Could not read the time service status.'; return }
        $mode = switch ($s.Type) { 'NT5DS' { 'from the domain' } 'NTP' { "from $($s.NtpServer)" } 'NoSync' { 'not syncing' } default { $s.Type } }
        $ui.TimeStatus.Text = "Syncing $mode. Current source: $($s.Source). Last successful sync: $($s.LastSync)." + $(if (-not $s.Running) { ' The Windows Time service is not running.' } else { '' })
    }
}

$ui.ATabProfiles.Add_Checked({ Show-AWAdminTab 'Profiles' })
$ui.ATabPrinters.Add_Checked({ Show-AWAdminTab 'Printers' })
$ui.ATabHelp.Add_Checked({ Show-AWAdminTab 'Help' })
$ui.ATabSoftware.Add_Checked({ Show-AWAdminTab 'Software' })
$ui.ATabBaseline.Add_Checked({ Show-AWAdminTab 'Baseline' })
$ui.ATabTime.Add_Checked({ Show-AWAdminTab 'Time' })

$ui.ProfRefresh.Add_Click({ Start-AWProfiles })
$ui.ProfRemove.Add_Click({ Remove-AWProfiles })
$ui.ProfStale.Add_Click({
    $d = 0; if (-not [int]::TryParse($ui.ProfDays.Text.Trim(), [ref]$d) -or $d -lt 1) { Show-AWMessage 'Enter a number of days.'; return }
    foreach ($r in @($ui.ProfList.ItemsSource)) { $r.IsChecked = $r.CanCheck -and $r.AgeDays -ge $d }
    $ui.ProfList.Items.Refresh()
    Set-AWStatus "$(@(@($ui.ProfList.ItemsSource) | Where-Object { $_.IsChecked }).Count) profile(s) unused for $d+ days checked"
})

$ui.PrnRefresh.Add_Click({ Start-AWPrinters })
$ui.PrnRemove.Add_Click({ Remove-AWPrinterItems })
$ui.PrnAdd.Add_Click({ Add-AWPrinterByIp })
$ui.PrnUnused.Add_Click({ foreach ($r in @($ui.PrnList.ItemsSource)) { $r.IsChecked = $r.Status -eq 'Not used by any printer' }; $ui.PrnList.Items.Refresh() })
$ui.PrnSpooler.Add_Click({
    if (-not (Confirm-AW "Restart the print spooler$(Get-AWWhere) and delete all waiting print jobs?")) { return }
    Write-AWAction 'ResetSpooler' @() @{} 'Started'
    Start-AWTask -Name 'Reset print spooler' -Work { try { Invoke-WTarget { Reset-WSpooler } } catch { Write-WLog $_.Exception.Message 'ERROR' } } -OnComplete { param($r) Start-AWPrinters }
})

$ui.HdRefresh.Add_Click({ Start-AWHelpdesk })
$ui.HdKill.Add_Click({
    $p = $ui.HdProcs.SelectedItem
    if (-not $p) { Show-AWMessage 'Select a program first.'; return }
    if (-not (Confirm-AW "End $($p.Name) (PID $($p.Key))$(Get-AWWhere)? Unsaved work in it is lost.")) { return }
    Invoke-AWHelpCommand "End $($p.Name)" { param($id) Stop-Process -Id $id -Force -ErrorAction Stop; Write-WLog "Ended process $id" } @([int]$p.Key)
})
$ui.HdMessage.Add_Click({
    $m = [Microsoft.VisualBasic.Interaction]::InputBox("Message to show to everyone signed in$(Get-AWWhere):", 'Computer Doctor - Send message', '')
    if (-not $m) { return }
    Invoke-AWHelpCommand 'Send message' { param($t) if (Get-Command msg.exe -ErrorAction SilentlyContinue) { & msg.exe * /time:300 $t; Write-WLog 'Message sent' } else { Write-WLog 'msg.exe is not available on this edition of Windows (Home)' 'WARN' } } @($m)
})
$ui.HdLogoff.Add_Click({
    $s = $ui.HdSessions.SelectedItem
    if (-not $s) { Show-AWMessage 'Select a session first.'; return }
    if (-not (Confirm-AW "Sign out $($s.Name) (session $($s.Key))$(Get-AWWhere)? Their unsaved work is lost.")) { return }
    Invoke-AWHelpCommand "Sign out $($s.Name)" { param($id) if (Get-Command logoff.exe -ErrorAction SilentlyContinue) { & logoff.exe $id; Write-WLog "Signed out session $id" } else { Write-WLog 'logoff.exe is not available on this edition of Windows' 'WARN' } } @([int]$s.Key)
})
$ui.HdRestart.Add_Click({
    $mins = [Microsoft.VisualBasic.Interaction]::InputBox("Restart$(Get-AWWhere) in how many minutes? Signed-in users see a countdown with your message.", 'Computer Doctor - Restart', '5')
    $n = 0; if (-not [int]::TryParse($mins, [ref]$n) -or $n -lt 0) { return }
    $msg = [Microsoft.VisualBasic.Interaction]::InputBox('Message for the user:', 'Computer Doctor - Restart', 'IT is restarting this PC to finish maintenance. Please save your work.')
    Invoke-AWHelpCommand 'Scheduled restart' { param($s, $m) & shutdown.exe /r /t $s /c $m /d p:4:1; Write-WLog "Restart scheduled in $s s" } @(($n * 60), $msg)
})
$ui.HdCancel.Add_Click({ Invoke-AWHelpCommand 'Cancel restart' { & shutdown.exe /a 2>&1 | Out-Null; Write-WLog 'Pending restart cancelled' } })
$ui.HdAssist.Add_Click({
    if (-not (Test-AWRemote)) { Show-AWMessage 'Remote Assistance offers help to a user on another PC. Connect to that PC first (title bar).'; return }
    Write-AWAction 'RemoteAssistance' @($script:Target.Host) @{} 'Started'
    Start-Process msra.exe -ArgumentList "/offerRA $($script:Target.Host)"
})
$ui.HdShadow.Add_Click({
    $s = $ui.HdSessions.SelectedItem
    if (-not (Test-AWRemote)) { Show-AWMessage 'Viewing a session works for another PC. Connect to it first (title bar).'; return }
    if (-not $s) { Show-AWMessage 'Select the session to view.'; return }
    Write-AWAction 'ShadowSession' @("$($script:Target.Host) session $($s.Key)") @{} 'Started'
    Start-Process mstsc.exe -ArgumentList "/shadow:$($s.Key) /v:$($script:Target.Host) /control"
})

$ui.SwBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = 'Installers (*.msi;*.exe)|*.msi;*.exe'
    if ($script:ResourcesRoot -and (Test-Path -LiteralPath (Join-Path $script:ResourcesRoot 'apps'))) { $dlg.InitialDirectory = Join-Path $script:ResourcesRoot 'apps' }
    if ($dlg.ShowDialog() -eq 'OK') { $ui.SwFile.Text = $dlg.FileName }
})
$ui.SwRun.Add_Click({ Start-AWSoftwarePush })

$ui.BlBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = 'HardeningKitty lists (*.csv)|*.csv'
    if ($script:ResourcesRoot -and (Test-Path -LiteralPath (Join-Path $script:ResourcesRoot 'baselines'))) { $dlg.InitialDirectory = Join-Path $script:ResourcesRoot 'baselines' }
    if ($dlg.ShowDialog() -eq 'OK') { $ui.BlFile.Text = $dlg.FileName }
})
$ui.BlRun.Add_Click({ Start-AWBaselineAudit })
$ui.BlFailed.Add_Checked({ Update-AWBaselineView }); $ui.BlFailed.Add_Unchecked({ Update-AWBaselineView })
$ui.BlExport.Add_Click({
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.FileName = 'ComputerDoctor-baseline-{0}-{1:yyyyMMdd}.csv' -f $(if (Test-AWRemote) { $script:Target.ComputerName } else { $env:COMPUTERNAME }), (Get-Date)
    $dlg.Filter = 'CSV (*.csv)|*.csv'
    if ($dlg.ShowDialog($window)) { $script:BlResults | Export-Csv -LiteralPath $dlg.FileName -NoTypeInformation -Encoding UTF8; Write-AWLog "Baseline results exported to $($dlg.FileName)" }
})

$ui.TimeRefresh.Add_Click({ Start-AWTimeStatus })
$ui.TimeSync.Add_Click({ Invoke-AWHelpCommand 'Sync time' { $r = (& w32tm.exe /resync /force 2>&1) -join ' '; Write-WLog "Time sync: $r" }; Start-AWTimeStatus })
$ui.TimeSet.Add_Click({
    $peer = $ui.TimePeer.Text.Trim()
    if (-not $peer) { Show-AWMessage 'Enter the time server to use.'; return }
    if (-not (Test-AWCanAdmin)) { Show-AWMessage 'Changing the time source needs administrator rights.'; return }
    if (-not (Confirm-AW "Sync the clock from $peer$(Get-AWWhere)?`n`nOn domain PCs this overrides syncing from the domain. Undo it from Rebloat > Undo history.")) { return }
    Start-AWTask -Name 'Set time server' -Arguments @{ Peer = $peer } -Work { Invoke-WTarget { param($p) Set-WTimeSource $p } -ArgumentList @($Peer) } -OnComplete {
        param($r)
        foreach ($cap in @($r | Where-Object { $_ -and $_.UndoKind })) { $uid = Add-AWUndoEntry $cap; Write-AWAction 'SetTimeSource' @($cap.Label) @{} 'Done' $uid }
        Start-AWTimeStatus
    }
})
$ui.LanRun.Add_Click({
    $h = $ui.LanHost.Text.Trim()
    if (-not $h) { Show-AWMessage 'Enter the other PC.'; return }
    $ui.LanResult.Text = "Testing with $h (copies 256 MB each way)..."
    $cred = $null
    $saved = try { [ComputerDoctor.CredMan]::ReadHost($h) } catch { $null }
    if ($saved) { $cred = New-Object System.Management.Automation.PSCredential($saved[0], (ConvertTo-SecureString $saved[1] -AsPlainText -Force)) }
    $st = $script:Target; $script:Target = $null
    try {
        Start-AWTask -Name 'LAN speed test' -Arguments @{ H = $h; C = $cred } -Work { Test-WLanSpeed $H $C } -OnComplete {
            param($r)
            $x = @($r | Where-Object { $_ -and $_.Method }) | Select-Object -Last 1
            $ui.LanResult.Text = if ($x) { "To $($x.Computer): $($x.UploadMBps) MB/s   From it: $($x.DownloadMBps) MB/s   ($([Math]::Round([Math]::Max($x.UploadMBps, $x.DownloadMBps) * 8)) Mbit/s at best)`nMethod: $($x.Method)" } else { 'The test failed - see the Activity log (the other PC needs remoting or its admin share, and you need admin rights there).' }
        }
    } finally { $script:Target = $st }
})
#endregion

#region ---------------------------------------------------------------- Online / offline status
function Update-AWNetUI {
    if ($script:ForceOffline) { $ui.NetText.Text = 'Offline mode'; $ui.NetIcon.Text = [string][char]0xE709; $ui.NetIcon.Foreground = $script:Res.Amber
        $ui.NetBtn.ToolTip = 'Offline mode is on: Computer Doctor never uses the internet and uses your Resources folder instead. Click to turn it off.' }
    elseif ($script:Online -eq $true) { $ui.NetText.Text = 'Online'; $ui.NetIcon.Text = [string][char]0xE774; $ui.NetIcon.Foreground = $script:Res.Success
        $ui.NetBtn.ToolTip = 'Internet is available. Click to switch to offline mode.' }
    elseif ($script:Online -eq $false) { $ui.NetText.Text = 'No internet'; $ui.NetIcon.Text = [string][char]0xE7BA; $ui.NetIcon.Foreground = $script:Res.Amber
        $ui.NetBtn.ToolTip = 'No internet connection detected. Internet-only actions are disabled and offline alternatives are offered. Click to force offline mode.' }
    else { $ui.NetText.Text = 'Checking...'; $ui.NetIcon.Foreground = $script:Res.Muted }
}

# Re-renders the parts of the UI whose options depend on internet access.
function Update-AWOfflineFeatures {
    Update-AWNetUI
    Initialize-AWTools
    if ($script:RecLoadedTabs['Deep']) { Update-AWWinfrStatus }
    if ($script:Loaded['Rebloat']) { Update-AWRebloatView }
}

function Start-AWNetCheck {
    if ($script:ForceOffline) { Update-AWOfflineFeatures; return }
    $script:Online = $null; Update-AWNetUI
    Start-AWTask -Name 'Check internet' -Work ${function:Test-AWInternet} -OnComplete {
        param($r)
        $script:Online = [bool](@($r) | Select-Object -Last 1)
        Write-AWLog $(if ($script:Online) { 'Internet connection detected' } else { 'No internet connection - offline alternatives will be used' })
        Update-AWOfflineFeatures
    }
}

$ui.NetBtn.Add_Click({
    $script:ForceOffline = -not $script:ForceOffline
    $script:State.ForceOffline = $script:ForceOffline; Save-AWState
    Write-AWLog $(if ($script:ForceOffline) { 'Offline mode turned on' } else { 'Offline mode turned off' })
    if ($script:ForceOffline) { Update-AWOfflineFeatures } else { Start-AWNetCheck }
})
#endregion

#region ---------------------------------------------------------------- Undo history
function Update-AWUndoList {
    $items = @(Get-AWUndoJournal | Where-Object { -not $_.Undone } | Sort-Object Time -Descending | Select-Object -First 60 | ForEach-Object {
        $t = try { [datetime]::Parse($_.Time).ToString('MMM d, h:mm tt') } catch { $_.Time }
        [pscustomobject]@{ Id = $_.Id; Label = $_.Label; Sub = "$t on $($_.Target)"; Entry = $_ }
    })
    $ui.UndoList.ItemsSource = $items
    $ui.UndoBtn.IsEnabled = $items.Count -gt 0
}

function Start-AWUndo {
    $sel = $ui.UndoList.SelectedItem
    if (-not $sel) { Show-AWMessage 'Select a change to undo first.'; return }
    $e = $sel.Entry
    $here = if (Test-AWRemote) { $script:Target.ComputerName } else { $env:COMPUTERNAME }
    if ($e.Target -ne $here) { Show-AWMessage "This change was made on $($e.Target). Connect to that computer first (title bar), then undo it."; return }
    if (-not (Confirm-AW "Undo: $($e.Label)?`n`nThe settings go back exactly as they were before that change.")) { return }
    $script:PendingUndo = $e
    Start-AWTask -Name 'Undo change' -Arguments @{ Snap = @($e.Snapshot); Keys = @($e.RemoveKeys); Kind = [string]$e.Kind; Revert = [string]$e.Revert } -Work {
        if ($Kind -eq 'Script') { Invoke-WTarget ([scriptblock]::Create($Revert)) }
        else { Invoke-WTarget { param($s, $k) Restore-WRegSnapshot $s $k } -ArgumentList @($Snap, $Keys) }
        Write-WLog 'Previous values restored'
    } -OnComplete {
        param($r)
        $e = $script:PendingUndo
        $all = @(Get-AWUndoJournal)
        foreach ($x in $all) { if ($x.Id -eq $e.Id) { $x.Undone = $true } }
        Save-AWUndoJournal $all
        Write-AWAction 'Undo' @($e.Label) @{} 'Done' $e.Id
        $script:IdleStatus = "Undone: $($e.Label) - some changes take effect after signing out"
        Update-AWUndoList; Update-AWTweakStatus
        if ($script:Loaded['Rebloat']) { Update-AWRebloatTweaks }
    }
}

$ui.UndoBtn.Add_Click({ Start-AWUndo })
#endregion

#region ---------------------------------------------------------------- Recovery
$script:BinItems = @()
$script:RecDrives = @()
$script:RecLoadedTabs = @{}
$script:SnapRoot = Join-Path $script:DataDir 'Snapshots'
$script:ShadowLiveRoot = ''
$script:DeepSource = $null
$script:WinfrPath = $null
$script:DeepRunning = $false
$Sync.WinfrPid = 0

# How likely a deep scan is to find anything on this drive, in plain words.
function Get-AWDriveVerdict($d) {
    if ($d.FS -eq 'ReFS') { return @{ Level = 'Bad'; Short = 'Not supported'; Text = "$($d.Drive) uses ReFS, which recovery tools don't support." } }
    # USB enclosures often hide the media type, so fall back to the model name.
    $isSsd = $d.Media -eq 'SSD' -or ($d.Media -ne 'HDD' -and $d.Model -match '\bSSD\b|NVMe')
    if ($d.Bus -in 'USB', 'SD', 'MMC') {
        if ($isSsd) { return @{ Level = 'Fair'; Short = 'Possible'; Text = "$($d.Drive) is an external SSD. Many of these pass TRIM through, so deleted data may already be erased - but it's worth a try." } }
        return @{ Level = 'Good'; Short = 'Good chance'; Text = "$($d.Drive) is removable media (USB stick, SD card or external disk), which normally isn't trimmed. Deleted files usually stay recoverable until the space is reused, so stop writing to it." }
    }
    if ($isSsd) {
        if ($d.Trim -eq $false) { return @{ Level = 'Fair'; Short = 'Possible'; Text = "$($d.Drive) is an SSD with TRIM turned off, so deleted data may still be on it." } }
        $trimNote = if ($d.Trim) { ' with TRIM on' } else { '' }
        return @{ Level = 'Bad'; Short = 'Unlikely'; Text = "$($d.Drive) is an SSD$trimNote. Windows tells the drive to erase deleted data, usually within minutes, so a deep scan rarely finds anything. Check the Recycle Bin and previous versions first." }
    }
    if ($d.Media -eq 'HDD') { return @{ Level = 'Good'; Short = 'Good chance'; Text = "$($d.Drive) is a hard disk. Deleted files stay recoverable until their space is reused, so stop writing to it." } }
    @{ Level = 'Fair'; Short = 'Unknown'; Text = "Computer Doctor couldn't tell what kind of disk $($d.Drive) is, so recovery may or may not work." }
}

function Get-AWVerdictColors([string]$Level) {
    switch ($Level) {
        'Good'  { @{ Bg = '#0F2E25'; Border = '#1F7A5C'; Fg = $script:Res.Success } }
        'Bad'   { @{ Bg = '#3A1619'; Border = '#8C3A3A'; Fg = $script:Res.Danger } }
        default { @{ Bg = '#33280E'; Border = '#7A5E14'; Fg = $script:Res.Amber } }
    }
}

function New-AWRecDriveCard($d) {
    $v = Get-AWDriveVerdict $d
    $c = Get-AWVerdictColors $v.Level
    $card = New-Object System.Windows.Controls.Border
    $card.Style = $window.FindResource('Card'); $card.Padding = '14,10'; $card.Margin = '0,0,12,0'; $card.MinWidth = 230
    $card.ToolTip = $v.Text
    $sp = New-Object System.Windows.Controls.StackPanel
    $head = New-Object System.Windows.Controls.StackPanel; $head.Orientation = 'Horizontal'
    [void]$head.Children.Add((New-AWText $d.Drive 16 $null 'Bold'))
    $lbl = New-AWText $(if ($d.Label) { $d.Label } else { 'Local Disk' }) 12.5 $script:Res.Muted; $lbl.Margin = '8,0,0,0'; $lbl.VerticalAlignment = 'Center'
    $lbl.MaxWidth = 120; $lbl.TextTrimming = 'CharacterEllipsis'
    [void]$head.Children.Add($lbl)
    $pill = New-Object System.Windows.Controls.Border
    $pill.Style = $window.FindResource('Pill'); $pill.Background = New-Brush $c.Bg; $pill.BorderBrush = New-Brush $c.Border
    $pill.Child = New-AWText $v.Short.ToUpper() 9 $c.Fg 'Bold'
    [void]$head.Children.Add($pill)
    [void]$sp.Children.Add($head)
    $kind = @($d.Media, $d.Bus | Where-Object { $_ -and $_ -ne 'Unspecified' }) -join ' / '
    if (-not $kind) { $kind = $d.Type }
    $meta = New-AWText ('{0} - {1} - {2}' -f $d.FS, (Format-AWSize $d.Size), $kind) 11.5 $script:Res.Dim
    $meta.Margin = '0,4,0,0'
    [void]$sp.Children.Add($meta)
    $card.Child = $sp
    $card
}

function Update-AWRecoveryDrives {
    Start-AWTask -Name 'Check drives for recovery' -Work {
        Invoke-WTarget { Get-WRecoveryDrives }
    } -OnComplete {
        param($Result)
        $script:RecDrives = @($Result | Where-Object { $_ })
        $ui.RecDrives.Children.Clear()
        foreach ($d in $script:RecDrives) { [void]$ui.RecDrives.Children.Add((New-AWRecDriveCard $d)) }
        Initialize-AWDeepSources
        Initialize-AWUndelSources
    }
}

# ---------------- Recycle Bin
function Update-AWBinView {
    $q = $ui.BinSearch.Text.Trim()
    $items = @(if ($q) { $script:BinItems | Where-Object { $_.Name -like "*$q*" -or $_.OriginalPath -like "*$q*" } } else { $script:BinItems })
    $ui.BinList.ItemsSource = $items
    [long]$sum = 0; foreach ($i in $items) { $sum += $i.Size }
    $ui.BinInfo.Text = '{0:N0} item(s) - {1}' -f $items.Count, (Format-AWSize $sum)
}

function Update-AWBinList {
    $ui.BinInfo.Text = 'Reading Recycle Bins...'
    Start-AWTask -Name 'Read Recycle Bin' -Work {
        foreach ($r in (Invoke-WTarget { Get-WRecycleItems })) {
            $e = New-Object ComputerDoctor.RecycleEntry
            $e.OriginalPath = [string]$r.OriginalPath; $e.IPath = [string]$r.IPath; $e.RPath = [string]$r.RPath
            $e.Name = Split-Path $e.OriginalPath -Leaf; $e.Folder = Split-Path $e.OriginalPath -Parent
            $e.Size = [long]$r.Size; $e.Deleted = [datetime]$r.Deleted; $e.IsDir = [bool]$r.IsDir; $e.Owner = [string]$r.Owner
            $e
        }
    } -OnComplete {
        param($Result)
        $script:BinItems = @($Result | Where-Object { $_ } | Sort-Object Deleted -Descending)
        Update-AWBinView
        if (-not $script:IsAdmin -and -not (Test-AWRemote)) { $ui.BinInfo.Text += ' - your items only (run as admin to see every user)' }
    }
}

function Start-AWBinRestore([string]$ToFolder) {
    $items = @($script:BinItems | Where-Object { $_.IsChecked })
    if ($items.Count -eq 0) { Show-AWMessage 'Check the items you want to restore first.'; return }
    $where = if ($ToFolder) { "to`n$ToFolder" } else { 'to their original locations' }
    $list = ($items | Select-Object -First 15 | ForEach-Object { "  - $($_.Name)" }) -join "`n"
    if ($items.Count -gt 15) { $list += "`n  ...and $($items.Count - 15) more" }
    if (-not (Confirm-AW "Restore $($items.Count) item(s) $where$(Get-AWWhere)?`n`n$list")) { return }
    Write-AWAction 'RecycleBinRestore' ($items | ForEach-Object OriginalPath) @{ To = $ToFolder } 'Started'
    $jobs = @($items | ForEach-Object {
        @{ IPath = $_.IPath; RPath = $_.RPath; Name = $_.Name; Dest = $(if ($ToFolder) { Join-Path $ToFolder $_.Name } else { $_.OriginalPath }) }
    })
    $ui.BinRestore.IsEnabled = $false; $ui.BinRestoreTo.IsEnabled = $false
    Start-AWTask -Name 'Restore from Recycle Bin' -Arguments @{ Jobs = $jobs } -Work {
        $i = 0; $ok = 0
        foreach ($j in $Jobs) {
            $Sync.Status = "Restoring $($j.Name)..."; $Sync.Progress = [int]($i * 100 / $Jobs.Count); $i++
            try {
                [void](Invoke-WTarget { param($a, $b, $c) Restore-WRecycleItem $a $b $c } -ArgumentList @($j.IPath, $j.RPath, $j.Dest))
                $ok++
            } catch { Write-WLog "Could not restore $($j.Name): $($_.Exception.Message)" 'ERROR' }
        }
        "Restored $ok of $($Jobs.Count) item(s)"
    } -OnComplete {
        param($r)
        $msg = @($r | Where-Object { $_ }) | Select-Object -Last 1
        $script:IdleStatus = if ($msg) { "$msg - see Activity log for details" } else { 'Restore finished - see Activity log' }
        Update-AWRecoveryButtons
        Update-AWBinList
    }
}

# ---------------- Previous versions (Volume Shadow Copies)
function Get-AWUniquePath([string]$Path, [string]$Suffix = 'restored') {
    if (-not (Test-Path -LiteralPath $Path)) { return $Path }
    $dir = Split-Path $Path -Parent; $base = [System.IO.Path]::GetFileNameWithoutExtension($Path); $ext = [System.IO.Path]::GetExtension($Path)
    $n = 1
    do { $p = Join-Path $dir ('{0} ({1}{2}){3}' -f $base, $Suffix, $(if ($n -gt 1) { " $n" } else { '' }), $ext); $n++ } while (Test-Path -LiteralPath $p)
    $p
}

# Snapshots are opened through directory symlinks under %LOCALAPPDATA%\ComputerDoctor\Snapshots.
# Only the links are ever removed (non-recursive delete of a reparse point), never their contents.
function Dismount-AWShadows {
    if (-not (Test-Path -LiteralPath $script:SnapRoot)) { return }
    foreach ($d in @(Get-ChildItem -LiteralPath $script:SnapRoot -Directory -Force -ErrorAction SilentlyContinue)) {
        if ($d.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            try { [System.IO.Directory]::Delete($d.FullName) } catch { Write-AWLog "Could not close snapshot link $($d.Name): $($_.Exception.Message)" 'WARN' }
        }
    }
}

function Mount-AWShadow($Shadow) {
    if (-not (Test-Path -LiteralPath $script:SnapRoot)) { New-Item -ItemType Directory -Path $script:SnapRoot -Force | Out-Null }
    $link = Join-Path $script:SnapRoot ('{0}_{1:yyyyMMdd-HHmmss}' -f $Shadow.Drive.TrimEnd(':'), $Shadow.Created)
    if (Test-Path -LiteralPath $link) { return $link }
    $out = & cmd.exe /c mklink /d "$link" "$($Shadow.Device)\" 2>&1
    if (-not (Test-Path -LiteralPath $link)) { throw "Could not open the snapshot: $out" }
    Write-AWLog "Opened snapshot of $($Shadow.Drive) from $($Shadow.CreatedText)"
    $link
}

function Update-AWShadowList {
    if (-not $script:IsAdmin) {
        $ui.ShadowNote.Text = 'Listing previous versions needs administrator rights. Use "Restart as admin" in the title bar.'
        $ui.ShadowList.ItemsSource = $null
        return
    }
    $ui.ShadowNote.Text = 'Looking for snapshots...'
    Start-AWTask -Name 'Read shadow copies' -Work {
        $vols = @{}
        foreach ($v in @(Get-CimInstance Win32_Volume -ErrorAction SilentlyContinue)) { if ($v.DriveLetter) { $vols[[string]$v.DeviceID] = [string]$v.DriveLetter } }
        foreach ($s in @(Get-CimInstance Win32_ShadowCopy -ErrorAction Stop)) {
            [pscustomobject]@{ Id = [string]$s.ID; Device = [string]$s.DeviceObject; Drive = [string]$vols[[string]$s.VolumeName]; Created = [datetime]$s.InstallDate }
        }
    } -OnComplete {
        param($Result)
        $now = Get-Date
        $list = @($Result | Where-Object { $_ -and $_.Drive } | Sort-Object Created -Descending | ForEach-Object {
            $days = [int]($now - $_.Created).TotalDays
            [pscustomobject]@{
                Id = $_.Id; Device = $_.Device; Drive = $_.Drive; Created = $_.Created
                CreatedText = $_.Created.ToString('ddd MMM d yyyy, h:mm tt')
                Age = if ($days -le 0) { 'Today' } elseif ($days -eq 1) { 'Yesterday' } else { "$days days ago" }
            }
        })
        $ui.ShadowList.ItemsSource = $list
        $ui.ShadowNote.Text = if ($list.Count) {
            "$($list.Count) snapshot(s). Windows makes them with restore points and big updates. Pick one, then open it or search it for deleted files."
        } else {
            'No snapshots found. Windows only keeps them when System Protection is turned on for a drive (usually just C:). Turn it on now so future deletions can be undone.'
        }
        if ($list.Count) { $ui.ShadowList.SelectedIndex = 0 }
    }
}

function Start-AWShadowFind {
    $s = $ui.ShadowList.SelectedItem
    if (-not $s) { Show-AWMessage 'Pick a snapshot on the left first.'; return }
    $folder = $ui.ShadowFolder.Text.Trim().TrimEnd('\')
    if ($folder -notmatch '^[A-Za-z]:') { Show-AWMessage 'Enter a full folder path, like C:\Users\you\Documents.'; return }
    if ($folder.Substring(0, 2) -ne $s.Drive) { Show-AWMessage "That folder is on $($folder.Substring(0, 2)), but the snapshot is of $($s.Drive). Pick a snapshot of the same drive."; return }
    try { $link = Mount-AWShadow $s } catch { Show-AWMessage $_.Exception.Message 'Error'; return }
    $rel = $folder.Substring(2).TrimStart('\')
    $snapFolder = if ($rel) { Join-Path $link $rel } else { $link }
    if (-not (Test-Path -LiteralPath $snapFolder)) { Show-AWMessage "$folder did not exist yet when this snapshot was taken."; return }
    $script:ShadowLiveRoot = $folder
    $ui.ShadowFind.IsEnabled = $false
    $ui.ShadowInfo.Text = 'Comparing the snapshot with the folder as it is now...'
    Start-AWTask -Name 'Find deleted files in snapshot' -Arguments @{ SnapFolder = $snapFolder; LiveFolder = $folder; Changed = [bool]$ui.ShadowChanged.IsChecked } -Work {
        $found = 0; $seen = 0
        foreach ($f in @(Get-ChildItem -LiteralPath $SnapFolder -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            $seen++
            if ($seen % 500 -eq 0) { $Sync.Status = "Compared $seen files, $found found..." }
            $live = Join-Path $LiveFolder $f.FullName.Substring($SnapFolder.Length).TrimStart('\')
            $status = $null
            if (-not [System.IO.File]::Exists($live)) { $status = 'Deleted' }
            elseif ($Changed -and [System.IO.File]::GetLastWriteTimeUtc($live) -ne $f.LastWriteTimeUtc) { $status = 'Changed' }
            if (-not $status) { continue }
            $e = New-Object ComputerDoctor.FileEntry
            $e.Name = $f.Name; $e.FullPath = $f.FullName; $e.Folder = Split-Path $live -Parent; $e.Size = $f.Length
            $e.Modified = $f.LastWriteTime; $e.Extension = $f.Extension; $e.Status = $status; $e.IsChecked = ($status -eq 'Deleted')
            $e
            $found++
            if ($found -ge 20000) { Write-WLog 'Stopped at 20,000 results - narrow the folder to see more' 'WARN'; break }
        }
        Write-WLog "Snapshot compare: $seen file(s) checked, $found difference(s)"
    } -OnComplete {
        param($Result)
        $items = @($Result | Where-Object { $_ -is [ComputerDoctor.FileEntry] } | Sort-Object Folder, Name)
        $ui.ShadowResults.ItemsSource = $items
        $del = @($items | Where-Object { $_.Status -eq 'Deleted' }).Count
        $ui.ShadowInfo.Text = if ($items.Count) { "$del deleted, $($items.Count - $del) changed since the snapshot." } else { 'Nothing is missing - every file in the snapshot still exists here.' }
        $ui.ShadowFind.IsEnabled = $true
    }
}

function Start-AWShadowCopy([string]$ToFolder) {
    $items = @(@($ui.ShadowResults.ItemsSource) | Where-Object { $_ -and $_.IsChecked })
    if ($items.Count -eq 0) { Show-AWMessage 'Check the files you want back first.'; return }
    $s = $ui.ShadowList.SelectedItem
    $stamp = if ($s) { $s.Created.ToString('yyyy-MM-dd') } else { 'snapshot' }
    $jobs = @($items | ForEach-Object {
        if ($ToFolder) {
            $rel = $_.Folder.Substring([Math]::Min($script:ShadowLiveRoot.Length, $_.Folder.Length)).TrimStart('\')
            $dest = Join-Path (Join-Path $ToFolder $rel) $_.Name
        } elseif ($_.Status -eq 'Changed') {
            $dest = Join-Path $_.Folder ('{0} ({1}){2}' -f [System.IO.Path]::GetFileNameWithoutExtension($_.Name), $stamp, [System.IO.Path]::GetExtension($_.Name))
        } else { $dest = Join-Path $_.Folder $_.Name }
        @{ Src = $_.FullPath; Dest = $dest }
    })
    $where = if ($ToFolder) { "to`n$ToFolder" } else { 'back to their folders (older versions of changed files are saved next to the current file with the snapshot date in the name)' }
    if (-not (Confirm-AW "Copy $($items.Count) file(s) $where?`n`nNothing is overwritten.")) { return }
    Write-AWAction 'SnapshotRestore' ($items | ForEach-Object { Join-Path $_.Folder $_.Name }) @{ To = $ToFolder } 'Started'
    Start-AWTask -Name 'Restore from snapshot' -Arguments @{ Jobs = $jobs } -Work {
        $i = 0; $ok = 0
        foreach ($j in $Jobs) {
            $Sync.Progress = [int]($i * 100 / $Jobs.Count); $i++
            try {
                $dest = $j.Dest
                if (Test-Path -LiteralPath $dest) {
                    $dir = Split-Path $dest -Parent; $b = [System.IO.Path]::GetFileNameWithoutExtension($dest); $x = [System.IO.Path]::GetExtension($dest); $n = 1
                    do { $dest = Join-Path $dir ('{0} (restored{1}){2}' -f $b, $(if ($n -gt 1) { " $n" } else { '' }), $x); $n++ } while (Test-Path -LiteralPath $dest)
                }
                $dir = Split-Path $dest -Parent
                if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                [System.IO.File]::Copy($j.Src, $dest, $false)
                Write-WLog "Restored $dest"; $ok++
            } catch { Write-WLog "Could not restore $($j.Src): $($_.Exception.Message)" 'ERROR' }
        }
        "Restored $ok of $($Jobs.Count) file(s) from the snapshot"
    } -OnComplete {
        param($r)
        $msg = @($r | Where-Object { $_ }) | Select-Object -Last 1
        $script:IdleStatus = if ($msg) { "$msg - see Activity log" } else { 'Restore finished - see Activity log' }
    }
}

# ---------------- Undelete (native NTFS file-table scan)
$script:Undelete = $null
$script:UndelSource = $null
$script:UndelRunning = $false

function Initialize-AWUndelSources {
    $ui.UndelSources.Children.Clear()
    $prev = $script:UndelSource
    foreach ($d in @($script:RecDrives | Where-Object { $_.FS -eq 'NTFS' })) {
        $rb = New-Object System.Windows.Controls.RadioButton
        $rb.Style = $window.FindResource('SegBtn'); $rb.GroupName = 'UndelSrc'; $rb.Tag = $d.Drive
        $rb.Content = '{0}  {1}' -f $d.Drive, $(if ($d.Label) { $d.Label } else { 'NTFS' })
        $rb.ToolTip = (Get-AWDriveVerdict $d).Text
        $rb.IsEnabled = $script:IsAdmin
        $rb.Add_Checked({ param($s, $e) $script:UndelSource = $s.Tag; Update-AWUndelDest })
        $wrap = New-Object System.Windows.Controls.Border
        $wrap.Background = $window.FindResource('FieldBrush'); $wrap.BorderBrush = $window.FindResource('LineBrush')
        $wrap.BorderThickness = 1; $wrap.CornerRadius = 10; $wrap.Padding = 3; $wrap.Margin = '0,0,8,0'
        $wrap.Child = $rb
        [void]$ui.UndelSources.Children.Add($wrap)
        if ($d.Drive -eq $prev) { $rb.IsChecked = $true }
    }
    if (-not $script:IsAdmin -and -not $script:UndelRunning -and -not $script:Undelete) {
        $ui.UndelStatus.Text = 'Scanning a drive needs administrator rights (use "Restart as admin"). You can still scan an image file.'
    }
    Update-AWUndelButtons
}

function Update-AWUndelButtons {
    $ui.UndelScan.IsEnabled = -not $script:UndelRunning -and $script:IsAdmin -and [bool]$script:UndelSource
    $ui.UndelImage.IsEnabled = -not $script:UndelRunning
    $ui.UndelStop.IsEnabled = $script:UndelRunning
    $ui.UndelRecover.IsEnabled = -not $script:UndelRunning -and $script:Undelete -and $script:Undelete.Completed
}

# Returns an error message when the destination is unsafe, otherwise ''.
function Test-AWUndelDest {
    $dest = $ui.UndelDest.Text.Trim()
    if (-not $dest) { return 'Choose a folder on a different drive to save recovered files to.' }
    if ($dest -notmatch '^[A-Za-z]:\\' -and $dest -notmatch '^\\\\') { return 'Enter a full path, like E:\Recovered.' }
    $u = $script:Undelete
    if ($u -and -not $u.IsImage) {
        $sv = [ComputerDoctor.Native]::VolumeId("$($u.Source)\")
        $dv = [ComputerDoctor.Native]::VolumeId($dest)
        if ($sv -and $dv -and $sv -eq $dv) { return "That folder is on $($u.Source), the drive being recovered. Writing there can overwrite the very files you want back - pick a folder on a different drive." }
    }
    ''
}

function Update-AWUndelDest {
    $msg = if ($ui.UndelDest.Text.Trim()) { Test-AWUndelDest } else { '' }
    $ui.UndelDestMsg.Text = $msg
    $ui.UndelDestMsg.Visibility = if ($msg) { 'Visible' } else { 'Collapsed' }
    Update-AWUndelButtons
}

function Update-AWUndelView {
    $u = $script:Undelete
    if (-not $u -or -not $u.Completed) { return }
    $matched = 0
    $min = if ($ui.UndelLikely.IsChecked) { 2 } else { 0 }
    $list = $u.Filter($ui.UndelSearch.Text.Trim(), $min, 5000, [ref]$matched)
    $ui.UndelList.ItemsSource = $list
    $more = if ($matched -gt 5000) { ' - showing the 5,000 most promising' } else { '' }
    $ui.UndelInfo.Text = '{0:N0} match(es){1}' -f $matched, $more
}

function Start-AWUndelScan([string]$Source) {
    if ($script:UndelRunning -or -not $Source) { return }
    if ($script:Undelete) { $script:Undelete.Dispose(); $script:Undelete = $null }
    $u = New-Object ComputerDoctor.NtfsUndelete $Source
    $script:Undelete = $u
    $script:UndelRunning = $true
    $ui.UndelList.ItemsSource = $null; $ui.UndelInfo.Text = ''
    $label = if ($u.IsImage) { Split-Path $Source -Leaf } else { $Source }
    $ui.UndelStatus.Text = "Opening $label..."
    Update-AWUndelButtons; Update-AWUndelDest
    Write-AWLog "Undelete: scanning $Source (read-only)"
    Start-AWTask -Name "Undelete scan of $label" -Arguments @{ U = $u } -Work {
        try { $U.Open() } catch { $U.Error = $_.Exception.Message; return }
        $U.Scan()
    } -OnComplete {
        param($r)
        $script:UndelRunning = $false
        $u = $script:Undelete
        if ($u.Error) {
            $ui.UndelStatus.Text = "Scan failed: $($u.Error)"
            Write-AWLog "Undelete scan failed: $($u.Error)" 'ERROR'
        } elseif ($u.Completed) {
            $good = $u.CountAtLeast(2)
            $ui.UndelStatus.Text = '{0:N0} deleted files found, {1:N0} look recoverable' -f $u.DeletedFound, $good
            Write-AWLog ('Undelete: {0:N0} records read, {1:N0} deleted files, {2:N0} look recoverable' -f $u.RecordsScanned, $u.DeletedFound, $good)
            $script:IdleStatus = 'Undelete scan complete'
            Update-AWUndelView
        } else { $ui.UndelStatus.Text = 'Scan stopped.' }
        Update-AWUndelButtons
    }
}

function Start-AWUndelRecover {
    $u = $script:Undelete
    if (-not $u -or -not $u.Completed) { return }
    $items = @(@($ui.UndelList.ItemsSource) | Where-Object { $_ -and $_.IsChecked })
    if ($items.Count -eq 0) { Show-AWMessage 'Check the files you want to recover first.'; return }
    $bad = Test-AWUndelDest
    if ($bad) { Show-AWMessage $bad; return }
    $dest = $ui.UndelDest.Text.Trim()
    $poor = @($items | Where-Object { $_.Score -lt 3 }).Count
    $warn = if ($poor) { "`n`n$poor of them are rated below Good, so they may come back damaged or empty." } else { '' }
    if (-not (Confirm-AW "Recover $($items.Count) file(s) to $($dest)?$warn`n`nOriginal folders are recreated inside the destination. Nothing is overwritten.")) { return }
    Write-AWAction 'Undelete' ($items | ForEach-Object FullPath) @{ To = $dest; Source = $u.Source } 'Started'
    if (-not (Test-Path -LiteralPath $dest)) {
        try { New-Item -ItemType Directory -Path $dest -Force | Out-Null } catch { Show-AWMessage "Could not create $($dest): $($_.Exception.Message)" 'Error'; return }
    }
    $ui.UndelRecover.IsEnabled = $false
    Start-AWTask -Name 'Recover deleted files' -Arguments @{ U = $u; Items = $items; Dest = $dest } -Work {
        $U.Refresh()     # re-check allocation right before reading
        $i = 0; $ok = 0
        $bad = [System.IO.Path]::GetInvalidFileNameChars()
        foreach ($f in $Items) {
            $Sync.Status = "Recovering $($f.Name)..."; $Sync.Progress = [int]($i * 100 / $Items.Count); $i++
            try {
                # Rebuild the original folder layout under the destination: C:\Users\x\a.txt -> Dest\Users\x\a.txt
                $rel = ($f.Folder -replace '^(\[image\]|[A-Za-z]:)\\?', '')
                $parts = @($rel -split '\\' | Where-Object { $_ } | ForEach-Object { -join ($_.ToCharArray() | ForEach-Object { if ($bad -contains $_) { '_' } else { $_ } }) })
                $dir = if ($parts.Count) { Join-Path $Dest ($parts -join '\') } else { $Dest }
                if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                $name = -join ($f.Name.ToCharArray() | ForEach-Object { if ($bad -contains $_) { '_' } else { $_ } })
                $target = Join-Path $dir $name
                $n = 1
                while (Test-Path -LiteralPath $target) {
                    $target = Join-Path $dir ('{0} (recovered{1}){2}' -f [System.IO.Path]::GetFileNameWithoutExtension($name), $(if ($n -gt 1) { " $n" } else { '' }), [System.IO.Path]::GetExtension($name)); $n++
                }
                $note = $U.Recover($f, $target)
                if ($note -match 'zeros') { Write-WLog "Recovered $target - but it $note" 'WARN' }
                elseif ($note) { Write-WLog "Recovered $target ($note)" }
                else { Write-WLog "Recovered $target" }
                $ok++
            } catch { Write-WLog "Could not recover $($f.Name): $($_.Exception.Message)" 'ERROR' }
        }
        "Recovered $ok of $($Items.Count) file(s)"
    } -OnComplete {
        param($r)
        $msg = @($r | Where-Object { $_ -is [string] }) | Select-Object -Last 1
        $script:IdleStatus = if ($msg) { "$msg - see Activity log" } else { 'Recovery finished - see Activity log' }
        Update-AWUndelButtons
        Update-AWUndelView
        if (Confirm-AW "$msg.`n`nOpen the destination folder?") { Open-AWExplorer $ui.UndelDest.Text.Trim() }
    }
}

$ui.UndelScan.Add_Click({
    $v = Get-AWDriveVerdict (@($script:RecDrives | Where-Object { $_.Drive -eq $script:UndelSource }) | Select-Object -First 1)
    if ($v.Level -eq 'Bad' -and -not (Confirm-AW "$($v.Text)`n`nScan anyway?")) { return }
    Start-AWUndelScan $script:UndelSource
})
$ui.UndelImage.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Choose a raw NTFS volume image'
    $dlg.Filter = 'Disk images (*.img;*.dd;*.raw;*.bin;*.001)|*.img;*.dd;*.raw;*.bin;*.001|All files (*.*)|*.*'
    if ($dlg.ShowDialog() -eq 'OK') { Start-AWUndelScan $dlg.FileName }
})
$ui.UndelStop.Add_Click({ if ($script:Undelete) { $script:Undelete.Cancel = $true } })
$ui.UndelSearch.Add_TextChanged({ Update-AWUndelView })
$ui.UndelLikely.Add_Checked({ Update-AWUndelView })
$ui.UndelLikely.Add_Unchecked({ Update-AWUndelView })
$ui.UndelDest.Add_TextChanged({ Update-AWUndelDest })
$ui.UndelBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Save recovered files here (must be on a different drive)'
    $dlg.ShowNewFolderButton = $true
    if ($dlg.ShowDialog() -eq 'OK') { $ui.UndelDest.Text = $dlg.SelectedPath }
})
$ui.UndelRecover.Add_Click({ Start-AWUndelRecover })

# ---------------- Deep scan (Windows File Recovery front-end)
function Update-AWWinfrStatus {
    $cmd = Get-Command winfr.exe -ErrorAction SilentlyContinue
    $script:WinfrPath = if ($cmd) { $cmd.Source } else { $null }
    if ($script:WinfrPath) {
        $ui.WinfrStatus.Text = 'Windows File Recovery is installed and ready.'
        $ui.WinfrBox.Background = New-Brush '#0F2E25'; $ui.WinfrBox.BorderBrush = New-Brush '#1F7A5C'
        $ui.WinfrInstall.Visibility = 'Collapsed'; $ui.WinfrStore.Visibility = 'Collapsed'
    } elseif (Test-AWOffline) {
        $ui.WinfrStatus.Text = "Windows File Recovery isn't installed, and it can only be installed from the Microsoft Store. Without internet, use the Undelete tab instead - it reads the drive directly and needs no download."
        $ui.WinfrBox.Background = New-Brush '#33280E'; $ui.WinfrBox.BorderBrush = New-Brush '#7A5E14'
        $ui.WinfrInstall.Visibility = 'Collapsed'; $ui.WinfrStore.Visibility = 'Collapsed'
    } else {
        $ui.WinfrStatus.Text = "Deep scan uses Windows File Recovery, Microsoft's free recovery tool. It isn't installed yet. Install it to a drive other than the one you want to recover from if you can."
        $ui.WinfrBox.Background = New-Brush '#33280E'; $ui.WinfrBox.BorderBrush = New-Brush '#7A5E14'
        $ui.WinfrInstall.Visibility = 'Visible'; $ui.WinfrStore.Visibility = 'Visible'
    }
    Update-AWDeep
}

function Initialize-AWDeepSources {
    $ui.DeepSources.Children.Clear()
    $prev = if ($script:DeepSource) { $script:DeepSource.Drive } else { $null }
    $script:DeepSource = $null
    foreach ($d in $script:RecDrives) {
        $rb = New-Object System.Windows.Controls.RadioButton
        $rb.Style = $window.FindResource('SegBtn'); $rb.GroupName = 'DeepSrc'; $rb.Margin = '0,0,8,8'; $rb.Tag = $d
        $rb.BorderBrush = $window.FindResource('LineBrush')
        $rb.Content = '{0}  {1}' -f $d.Drive, $(if ($d.Label) { $d.Label } else { $d.FS })
        $rb.ToolTip = (Get-AWDriveVerdict $d).Text
        $rb.Add_Checked({ param($s, $e) $script:DeepSource = $s.Tag; Update-AWDeep })
        $wrap = New-Object System.Windows.Controls.Border
        $wrap.Background = $window.FindResource('FieldBrush'); $wrap.BorderBrush = $window.FindResource('LineBrush')
        $wrap.BorderThickness = 1; $wrap.CornerRadius = 10; $wrap.Padding = 3; $wrap.Margin = '0,0,8,8'
        $rb.Margin = 0; $wrap.Child = $rb
        [void]$ui.DeepSources.Children.Add($wrap)
        if ($d.Drive -eq $prev) { $rb.IsChecked = $true }
    }
    Update-AWDeep
}

# Quote one argument for a Windows command line (backslashes before a closing quote are doubled).
function Format-AWArg([string]$Value) {
    if ($Value -notmatch '[\s"]') { return $Value }
    '"' + ($Value -replace '(\\+)$', '$1$1') + '"'
}

function Get-AWDeepArgs {
    $src = $script:DeepSource
    $dest = $ui.DeepDest.Text.Trim()
    if (-not $src) { return $null }
    $d = if ($dest -match '^[A-Za-z]:\\?$') { $dest.Substring(0, 2) } else { $dest.TrimEnd('\') }
    $a = @($src.Drive, (Format-AWArg $(if ($d) { $d } else { 'X:\Recovered' })), $(if ($ui.DeepExtensive.IsChecked) { '/extensive' } else { '/regular' }))
    foreach ($f in @($ui.DeepFilter.Text -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) { $a += '/n'; $a += (Format-AWArg $f) }
    $a + '/a'
}

function Update-AWDeep {
    if (-not $ui.DeepCmd) { return }
    $src = $script:DeepSource
    $ext = [bool]$ui.DeepExtensive.IsChecked
    $hint = if ($ext) { 'Thorough scan for USB sticks, SD cards (FAT/exFAT), formatted or damaged drives and older deletions. Slower.' }
            else { 'Fast scan for files deleted recently from an NTFS drive.' }
    if ($src -and -not $ext -and $src.FS -ne 'NTFS') { $hint += " $($src.Drive) is $($src.FS) - use Extensive for it." }
    $ui.DeepModeHint.Text = $hint

    $ok = [bool]$src
    $dest = $ui.DeepDest.Text.Trim()
    $msg = ''
    if ($dest) {
        if ($dest -notmatch '^[A-Za-z]:\\?' -and $dest -notmatch '^\\\\') { $msg = 'Enter a full path, like E:\Recovered.'; $ok = $false }
        elseif ($src) {
            $sv = [ComputerDoctor.Native]::VolumeId("$($src.Drive)\")
            $dv = [ComputerDoctor.Native]::VolumeId($dest)
            if ($sv -and $dv -and $sv -eq $dv) { $msg = "That folder is on $($src.Drive), the drive you're scanning. Saving there could overwrite the files you're trying to get back. Pick a folder on a different drive."; $ok = $false }
        }
    } else { $ok = $false }
    $ui.DeepDestMsg.Text = $msg
    $ui.DeepDestMsg.Foreground = $script:Res.Danger
    $ui.DeepDestMsg.Visibility = if ($msg) { 'Visible' } else { 'Collapsed' }

    $argv = Get-AWDeepArgs
    $ui.DeepCmd.Text = if ($argv) { 'winfr ' + ($argv -join ' ') } else { 'Pick a drive to scan.' }

    if ($src) {
        $v = Get-AWDriveVerdict $src; $c = Get-AWVerdictColors $v.Level
        $ui.DeepVerdict.Text = $v.Text; $ui.DeepVerdict.Foreground = $c.Fg
        $ui.DeepVerdictBox.Background = New-Brush $c.Bg; $ui.DeepVerdictBox.BorderBrush = New-Brush $c.Border
        $ui.DeepVerdictBox.Visibility = 'Visible'
    } else { $ui.DeepVerdictBox.Visibility = 'Collapsed' }

    $ui.DeepStart.IsEnabled = $ok -and [bool]$script:WinfrPath -and $script:IsAdmin -and -not $script:DeepRunning -and -not (Test-AWRemote)
    $ui.DeepStart.ToolTip = if (-not $script:IsAdmin) { 'Deep scan needs administrator rights.' } elseif (-not $script:WinfrPath) { 'Install Windows File Recovery first.' } else { $null }
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($ui.DeepStart, $true)
}

function Start-AWDeepScan {
    $src = $script:DeepSource
    $argv = Get-AWDeepArgs
    if (-not $src -or -not $argv) { return }
    $dest = $ui.DeepDest.Text.Trim()
    $v = Get-AWDriveVerdict $src
    $warn = if ($v.Level -eq 'Bad') { "`n`nHeads up: $($v.Text)" } else { '' }
    $filters = @($ui.DeepFilter.Text -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $what = if ($filters.Count) { $filters -join ', ' } else { 'everything it can find' }
    if (-not (Confirm-AW "Scan $($src.Drive) for $what and save results to $dest?$warn`n`nAvoid using $($src.Drive) until this finishes.")) { return }
    Write-AWAction 'DeepScan' @($src.Drive) @{ To = $dest; Args = ($argv -join ' ') } 'Started'
    if (-not (Test-Path -LiteralPath $dest)) { try { New-Item -ItemType Directory -Path $dest -Force | Out-Null } catch { Show-AWMessage "Could not create $($dest): $($_.Exception.Message)" 'Error'; return } }

    $script:DeepRunning = $true
    $ui.DeepStop.IsEnabled = $true
    Update-AWDeep
    Start-AWTask -Name 'Windows File Recovery' -Arguments @{ Exe = $script:WinfrPath; ArgLine = ($argv -join ' ') } -Work {
        Write-WLog "winfr $ArgLine"
        $psi = New-Object System.Diagnostics.ProcessStartInfo($Exe, $ArgLine)
        $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.RedirectStandardInput = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        $Sync.WinfrPid = $p.Id
        $p.StandardInput.Close()
        $errText = $p.StandardError.ReadToEndAsync()
        while ($null -ne ($line = $p.StandardOutput.ReadLine())) {
            $l = ($line -replace "`0", '').Trim()
            if (-not $l) { continue }
            if ($l -match '(\d+(\.\d+)?)\s*%') { $Sync.Progress = [int][double]$Matches[1]; $Sync.Status = "Windows File Recovery - $l"; continue }
            Write-WLog "winfr: $l"
        }
        $p.WaitForExit()
        $e = ($errText.Result -replace "`0", '').Trim()
        if ($e) { foreach ($x in ($e -split "`r?`n" | Where-Object { $_.Trim() })) { Write-WLog "winfr: $x" 'WARN' } }
        $Sync.WinfrPid = 0
        "Windows File Recovery finished (exit code $($p.ExitCode))"
    } -OnComplete {
        param($r)
        $script:DeepRunning = $false
        $ui.DeepStop.IsEnabled = $false
        Update-AWDeep
        $msg = @($r | Where-Object { $_ }) | Select-Object -Last 1
        $script:IdleStatus = if ($msg) { "$msg - see Activity log" } else { 'Windows File Recovery stopped - see Activity log' }
        if (Confirm-AW "Recovery finished. Open the destination folder?`n`nRecovered files are in a Recovery_<date> folder there.") { Open-AWExplorer $ui.DeepDest.Text.Trim() }
    }
}

# ---------------- Restore points
function Update-AWRestorePoints {
    $ui.RPAuto.IsChecked = [bool]$script:State.AutoRestorePoint
    if (-not $script:IsAdmin) {
        $ui.RPInfo.Text = 'Managing restore points needs administrator rights. Use "Restart as admin" in the title bar.'
        foreach ($c in @($ui.RPCreate, $ui.RPDelete, $ui.RPEnable, $ui.RPSize5, $ui.RPSize10, $ui.RPSize15)) { $c.IsEnabled = $false }
        return
    }
    $ui.RPInfo.Text = 'Reading restore points...'
    Start-AWTask -Name 'Read restore points' -Work {
        $points = foreach ($p in @(Get-CimInstance -Namespace root/default -ClassName SystemRestore -ErrorAction SilentlyContinue)) {
            $created = try { [datetime]::SpecifyKind([datetime]::ParseExact(([string]$p.CreationTime).Substring(0, 14), 'yyyyMMddHHmmss', $null), 'Utc').ToLocalTime() } catch { [datetime]::MinValue }
            [pscustomobject]@{ Sequence = [int]$p.SequenceNumber; Description = [string]$p.Description; Type = [int]$p.RestorePointType; Created = $created }
        }
        $vols = @{}; foreach ($v in @(Get-CimInstance Win32_Volume -ErrorAction SilentlyContinue)) { $vols[[string]$v.DeviceID] = $v }
        $storage = foreach ($s in @(Get-CimInstance Win32_ShadowStorage -ErrorAction SilentlyContinue)) {
            $v = $vols[[string]$s.Volume.DeviceID]
            [pscustomobject]@{ Drive = [string]$v.DriveLetter; Used = [long]$s.UsedSpace; Max = [decimal]$s.MaxSpace; Capacity = [long]$v.Capacity }
        }
        $interval = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' -ErrorAction SilentlyContinue).RPSessionInterval
        [pscustomobject]@{ Points = @($points); Storage = @($storage); Enabled = ($interval -eq 1) }
    } -OnComplete {
        param($Result)
        $res = @($Result | Where-Object { $_ -and $null -ne $_.Points }) | Select-Object -Last 1
        if (-not $res) { $ui.RPInfo.Text = 'Could not read restore points - see Activity log.'; return }
        $types = @{ 0 = 'App installed'; 1 = 'App removed'; 7 = 'Scheduled'; 10 = 'Driver installed'; 12 = 'Settings change'; 13 = 'Cancelled operation' }
        $list = @($res.Points | Sort-Object Created -Descending | ForEach-Object {
            [pscustomobject]@{ Sequence = $_.Sequence; Description = $_.Description; Created = $_.Created
                CreatedText = $_.Created.ToString('ddd MMM d yyyy, h:mm tt'); TypeText = $(if ($types.ContainsKey($_.Type)) { $types[$_.Type] } else { "Windows ($($_.Type))" }) }
        })
        $ui.RPList.ItemsSource = $list
        $sys = @($res.Storage | Where-Object { $_.Drive -eq $env:SystemDrive }) | Select-Object -First 1
        $on = $res.Enabled -and $sys
        $ui.RPProtect.Text = if ($on) { "System Protection is on for $($env:SystemDrive)." } else { "System Protection is off for $($env:SystemDrive), so Windows can't create restore points or previous versions." }
        $ui.RPProtect.Foreground = if ($on) { $script:Res.Success } else { $script:Res.Amber }
        $ui.RPEnable.Visibility = if ($on) { 'Collapsed' } else { 'Visible' }
        $ui.RPStorage.Text = if ($sys) {
            $max = if ($sys.Max -ge [decimal]::MaxValue / 2 -or $sys.Max -ge 1e18) { 'no limit' } else { '{0} ({1:0}% of the drive)' -f (Format-AWSize ([long]$sys.Max)), ($sys.Max * 100 / [Math]::Max(1, $sys.Capacity)) }
            "$(Format-AWSize $sys.Used) used on $($env:SystemDrive). Limit: $max. Older points are deleted automatically when the limit is reached."
        } else { 'No space is reserved for restore points yet.' }
        foreach ($c in @($ui.RPCreate, $ui.RPDelete, $ui.RPSize5, $ui.RPSize10, $ui.RPSize15)) { $c.IsEnabled = $true }
        $ui.RPInfo.Text = if ($list.Count) { "$($list.Count) restore point(s). Select one or more to delete them." } else { 'No restore points yet.' }
    }
}

function Remove-AWRestorePoints {
    $sel = @($ui.RPList.SelectedItems)
    if ($sel.Count -eq 0) { Show-AWMessage 'Select the restore points to delete first.'; return }
    $names = ($sel | ForEach-Object { "  - $($_.CreatedText): $($_.Description)" }) -join "`n"
    if (-not (Confirm-AW "Permanently delete $($sel.Count) restore point(s)?`n`n$names`n`nYou won't be able to roll back to them, and their previous versions of files go too.")) { return }
    $ok = 0
    foreach ($p in $sel) {
        $rc = [ComputerDoctor.Native]::SRRemoveRestorePoint($p.Sequence)
        if ($rc -eq 0) { $ok++; Write-AWLog "Deleted restore point #$($p.Sequence) ($($p.Description))" }
        else { Write-AWLog "Could not delete restore point #$($p.Sequence) (error $rc)" 'ERROR' }
    }
    Write-AWAction 'DeleteRestorePoints' ($sel | ForEach-Object { "#$($_.Sequence) $($_.Description)" }) @{} "Deleted $ok of $($sel.Count)"
    Update-AWRestorePoints
}

function Set-AWRestoreSpace([int]$Percent) {
    if (-not (Confirm-AW "Let restore points use up to $Percent% of $($env:SystemDrive)? If the new limit is smaller than what's used now, Windows deletes the oldest points to fit.")) { return }
    Write-AWAction 'RestorePointSpace' @("$Percent%") @{} 'Started'
    $saved = $script:Target; $script:Target = $null
    try {
        Start-AWCommandTask 'Resize restore point space' ([scriptblock]::Create("& vssadmin.exe resize shadowstorage /for=$($env:SystemDrive) /on=$($env:SystemDrive) /maxsize=$Percent% 2>&1; ""AWEXIT `$LASTEXITCODE"""))
    } finally { $script:Target = $saved }
}

$ui.RPRefresh.Add_Click({ Update-AWRestorePoints })
$ui.RPOpen.Add_Click({ Start-Process rstrui.exe })
$ui.RPDelete.Add_Click({ Remove-AWRestorePoints })
$ui.RPCreate.Add_Click({
    $saved = $script:Target; $script:Target = $null
    try { Start-AWRestorePoint $ui.RPDesc.Text.Trim() } finally { $script:Target = $saved }
    $ui.RPDesc.Text = ''
})
$ui.RPEnable.Add_Click({
    try {
        $r = Invoke-CimMethod -Namespace root/default -ClassName SystemRestore -MethodName Enable -Arguments @{ Drive = "$($env:SystemDrive)\" } -ErrorAction Stop
        if ($r.ReturnValue -eq 0) { Write-AWLog "System Protection turned on for $($env:SystemDrive)"; Write-AWAction 'EnableSystemProtection' @($env:SystemDrive) @{} 'Done' }
        else { Write-AWLog "Turning on System Protection returned code $($r.ReturnValue)" 'WARN' }
    } catch { Show-AWMessage "Could not turn on System Protection: $($_.Exception.Message)" 'Error' }
    Update-AWRestorePoints
})
foreach ($b in @($ui.RPSize5, $ui.RPSize10, $ui.RPSize15)) { $b.Add_Click({ param($s, $e) Set-AWRestoreSpace ([int]$s.Tag) }) }
$ui.RPAuto.Add_Checked({ $script:State.AutoRestorePoint = $true; Save-AWState })
$ui.RPAuto.Add_Unchecked({ $script:State.AutoRestorePoint = $false; Save-AWState })

# ---------------- Folder backup
function Update-AWBackupUI {
    $b = $script:State.Backup
    $ui.BkSources.ItemsSource = @($b.Sources)
    $ui.BkDest.Text = [string]$b.Dest
    $ui.BkKeep.Text = [string]$b.Keep
    $ui.BkDaily.IsChecked = [bool]$b.Daily
    $ui.BkTime.Text = [string]$b.Time
    Update-AWBackupDestInfo
    $ui.BkLast.Text = if ($b.LastRun) { "Last backup: $(try { ([datetime]$b.LastRun).ToString('ddd MMM d, h:mm tt') } catch { $b.LastRun }) - $($b.LastResult)" } else { 'No backup has run yet.' }
}

function Update-AWBackupDestInfo {
    $b = $script:State.Backup
    $msg = ''; $color = $script:Res.Muted
    if ($b.Dest) {
        if (-not (Test-Path -LiteralPath $b.Dest)) { $msg = 'The backup drive is not connected right now.'; $color = $script:Res.Amber }
        else {
            $vid = [ComputerDoctor.Native]::VolumeId($b.Dest)
            $drv = try { New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($b.Dest)) } catch { $null }
            $free = if ($drv -and $drv.IsReady) { "$(Format-AWSize $drv.AvailableFreeSpace) free" + $(if ($drv.VolumeLabel) { " on $($drv.VolumeLabel)" } else { '' }) } else { '' }
            if ($b.DestVolumeId -and $vid -ne $b.DestVolumeId) { $msg = 'A different drive is using this letter now - choose the backup drive again.'; $color = $script:Res.Danger }
            elseif (@($b.Sources | Where-Object { [ComputerDoctor.Native]::VolumeId($_) -eq $vid }).Count) { $msg = "$free. Warning: some folders are on this same drive - a backup there won't survive the drive failing."; $color = $script:Res.Amber }
            else { $msg = "$free. Backups go to ComputerDoctor-Backup\$env:COMPUTERNAME there."; $color = $script:Res.Success }
        }
    }
    $ui.BkDestInfo.Text = $msg; $ui.BkDestInfo.Foreground = $color
}

# Reads the form into the saved job, and creates / removes the daily scheduled task.
function Save-AWBackupJob([switch]$Quiet) {
    $b = $script:State.Backup
    $keep = 0; if (-not [int]::TryParse($ui.BkKeep.Text.Trim(), [ref]$keep) -or $keep -lt 1) { Show-AWMessage 'Enter how many older versions to keep (1 or more).'; return $false }
    $time = $ui.BkTime.Text.Trim()
    if ($ui.BkDaily.IsChecked -and $time -notmatch '^([01]?\d|2[0-3]):[0-5]\d$') { Show-AWMessage 'Enter the time as HH:mm, e.g. 19:00.'; return $false }
    $b.Keep = $keep; $b.Time = $time; $b.Daily = [bool]$ui.BkDaily.IsChecked
    Save-AWState
    $task = Get-ScheduledTask -TaskName 'ComputerDoctor Backup' -ErrorAction SilentlyContinue
    try {
        if ($b.Daily -and @($b.Sources).Count -and $b.Dest) {
            $exe = (Get-Process -Id $PID).Path
            $action = New-ScheduledTaskAction -Execute $exe -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`" -Backup -Yes"
            $trigger = New-ScheduledTaskTrigger -Daily -At ([datetime]::ParseExact($time, 'H:mm', $null))
            $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 6)
            Register-ScheduledTask -TaskName 'ComputerDoctor Backup' -Action $action -Trigger $trigger -Settings $settings -Description 'Folder backup set up in Computer Doctor (Recovery > Backup).' -Force | Out-Null
            Write-AWLog "Daily backup scheduled at $time"
            Write-AWAction 'BackupSchedule' @("daily $time") @{} 'Done'
        } elseif ($task) {
            Unregister-ScheduledTask -TaskName 'ComputerDoctor Backup' -Confirm:$false
            Write-AWLog 'Daily backup schedule removed'
            Write-AWAction 'BackupSchedule' @('removed') @{} 'Done'
        }
    } catch { Show-AWMessage "Could not update the schedule: $($_.Exception.Message)" 'Error'; return $false }
    if (-not $Quiet) { Set-AWStatus 'Backup settings saved' }
    $true
}

function Start-AWBackupNow {
    $b = $script:State.Backup
    if (-not @($b.Sources).Count) { Show-AWMessage 'Add at least one folder to back up.'; return }
    if (-not $b.Dest) { Show-AWMessage 'Choose the backup drive first.'; return }
    if (-not (Save-AWBackupJob -Quiet)) { return }
    Write-AWAction 'Backup' @($b.Sources) @{ Dest = $b.Dest } 'Started'
    $ui.BkRun.IsEnabled = $false
    $saved = $script:Target; $script:Target = $null
    try {
        Start-AWTask -Name 'Folder backup' -Arguments @{ Job = [pscustomobject]$b } -Work { Invoke-WBackup $Job } -OnComplete {
            param($r)
            $ui.BkRun.IsEnabled = $true
            $res = @($r | Where-Object { $_ -and $null -ne $_.Ok }) | Select-Object -Last 1
            if ($res) {
                $script:State.Backup.LastRun = (Get-Date).ToString('o'); $script:State.Backup.LastResult = $res.Message; Save-AWState
                Write-AWAction 'Backup' @($script:State.Backup.Dest) @{} $(if ($res.Ok) { 'Done' } else { 'Problems' })
                $script:IdleStatus = "Backup: $($res.Message)"
                if (-not $res.Ok) { Show-AWMessage $res.Message 'Warning' }
            }
            Update-AWBackupUI
        }
    } finally { $script:Target = $saved }
}

$ui.BkAddMine.Add_Click({
    $b = $script:State.Backup
    foreach ($f in 'MyDocuments', 'MyPictures', 'Desktop', 'MyVideos', 'MyMusic') {
        $p = [Environment]::GetFolderPath($f)
        if ($p -and (Test-Path -LiteralPath $p) -and $b.Sources -notcontains $p) { $b.Sources = @($b.Sources) + $p }
    }
    Save-AWState; Update-AWBackupUI
})
$ui.BkAdd.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Add a folder to back up'
    if ($dlg.ShowDialog() -ne 'OK') { return }
    $b = $script:State.Backup
    if ($b.Sources -notcontains $dlg.SelectedPath) { $b.Sources = @($b.Sources) + $dlg.SelectedPath }
    Save-AWState; Update-AWBackupUI
})
$ui.BkRemove.Add_Click({
    $sel = $ui.BkSources.SelectedItem
    if (-not $sel) { Show-AWMessage 'Select a folder to remove from the list (nothing is deleted).'; return }
    $script:State.Backup.Sources = @($script:State.Backup.Sources | Where-Object { $_ -ne $sel })
    Save-AWState; Update-AWBackupUI
})
$ui.BkBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Choose where backups go (an external drive is best)'
    $dlg.ShowNewFolderButton = $true
    if ($dlg.ShowDialog() -ne 'OK') { return }
    $script:State.Backup.Dest = $dlg.SelectedPath
    $script:State.Backup.DestVolumeId = [ComputerDoctor.Native]::VolumeId($dlg.SelectedPath)
    Save-AWState; Update-AWBackupUI
})
$ui.BkSave.Add_Click({ [void](Save-AWBackupJob) })
$ui.BkRun.Add_Click({ Start-AWBackupNow })
$ui.BkOpen.Add_Click({
    $d = Join-Path ([string]$script:State.Backup.Dest) "ComputerDoctor-Backup\$env:COMPUTERNAME"
    # A backup made before the rename to Computer Doctor stays in AWiper-Backup until the next backup moves it.
    if (-not (Test-Path -LiteralPath $d)) { $d = Join-Path ([string]$script:State.Backup.Dest) "AWiper-Backup\$env:COMPUTERNAME" }
    if ($script:State.Backup.Dest -and (Test-Path -LiteralPath $d)) { Open-AWExplorer $d } else { Show-AWMessage 'There is no backup on that drive yet.' }
})

# ---------------- Tabs, remote handling, wiring
function Update-AWRecoveryButtons {
    $remote = Test-AWRemote
    $ui.BinRestore.IsEnabled = $true
    $ui.BinRestoreTo.IsEnabled = -not $remote
    $ui.BinOpen.IsEnabled = -not $remote
    $ui.RecTabShadow.IsEnabled = -not $remote
    $ui.RecTabDeep.IsEnabled = -not $remote
    $ui.RecTabUndel.IsEnabled = -not $remote
    $ui.RecTabRP.IsEnabled = -not $remote
    $ui.RecTabBackup.IsEnabled = -not $remote
    $tip = if ($remote) { 'Only available on this PC' } else { $null }
    foreach ($c in @($ui.RecTabShadow, $ui.RecTabDeep, $ui.RecTabUndel, $ui.RecTabRP, $ui.RecTabBackup, $ui.BinRestoreTo, $ui.BinOpen)) {
        $c.ToolTip = $tip; [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($c, $true)
    }
    if ($remote -and -not $ui.RecTabBin.IsChecked) { $ui.RecTabBin.IsChecked = $true }
}

# ---- Readiness: BitLocker key, Secure Boot certificates, Windows RE / QMR / PITR, restore points, backup
$script:Ready = $null
function New-AWReadyRow([string]$Status, [string]$Title, [string[]]$Lines, $Buttons) {
    $st = Get-AWStatusStyle $Status
    $row = New-Object System.Windows.Controls.Border
    $row.CornerRadius = 10; $row.Padding = '14,12'; $row.Margin = '0,5'
    $row.Background = New-Brush '#1A1E27'; $row.BorderBrush = $window.FindResource('LineBrush'); $row.BorderThickness = 1
    $g = New-Object System.Windows.Controls.Grid
    foreach ($w in 'Auto', '*') { $c = New-Object System.Windows.Controls.ColumnDefinition; $c.Width = $w; $g.ColumnDefinitions.Add($c) }
    $pill = New-Object System.Windows.Controls.Border
    $pill.CornerRadius = 9; $pill.Padding = '0,3'; $pill.Width = 78; $pill.VerticalAlignment = 'Top'; $pill.Margin = '0,2,0,0'; $pill.BorderThickness = 1
    $pill.Background = New-Brush $st.Bg; $pill.BorderBrush = New-Brush $st.Border
    $pt = New-AWText $st.Label 10 $st.Fg 'Bold'; $pt.HorizontalAlignment = 'Center'; $pill.Child = $pt
    [void]$g.Children.Add($pill)
    $sp = New-Object System.Windows.Controls.StackPanel; $sp.Margin = '16,0,0,0'
    [void]$sp.Children.Add((New-AWText $Title 14 $null 'SemiBold'))
    foreach ($l in $Lines) { if (-not $l) { continue }; $d = New-AWText $l 12.5 $script:Res.Muted; $d.TextWrapping = 'Wrap'; $d.Margin = '0,3,0,0'; [void]$sp.Children.Add($d) }
    $bp = New-Object System.Windows.Controls.WrapPanel; $bp.Margin = '0,8,0,0'
    foreach ($b in @($Buttons)) {
        if (-not $b) { continue }
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = $b.Text; $btn.Style = $window.FindResource($(if ($b.Primary) { 'BtnPurple' } else { 'BtnChip' })); $btn.Margin = '0,0,8,0'
        if ($b.Primary) { $btn.Padding = '14,6'; $btn.FontSize = 12 }
        $btn.Tag = $b.Run; $btn.IsEnabled = $b.Enabled -ne $false
        if ($b.Tip) { $btn.ToolTip = $b.Tip; [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($btn, $true) }
        $btn.Add_Click({ param($s, $e) try { & $s.Tag } catch { Show-AWMessage $_.Exception.Message 'Error' } })
        [void]$bp.Children.Add($btn)
    }
    if ($bp.Children.Count) { [void]$sp.Children.Add($bp) }
    [System.Windows.Controls.Grid]::SetColumn($sp, 1); [void]$g.Children.Add($sp)
    $row.Child = $g
    [void]$ui.ReadyRows.Children.Add($row)
}

function Update-AWReadiness {
    $ui.ReadyRefresh.IsEnabled = $false
    $ui.ReadyRows.Children.Clear()
    $who = if (Test-AWRemote) { $script:Target.ComputerName } else { 'this PC' }
    $ui.ReadyInfo.Text = "Checking $who..."
    Start-AWTask -Name 'Check recovery readiness' -Work {
        Invoke-WTarget {
            $bl = Get-WBitLockerInfo
            [pscustomobject]@{ SB = (Get-WSecureBootCerts); BL = $bl; BLSum = (Get-WBitLockerSummary $bl); RE = (Get-WRecoveryEnv); Esu = (Get-WEsuEligibility); Admin = (Test-WAdmin) }
        }
    } -OnComplete {
        param($Result)
        $ui.ReadyRefresh.IsEnabled = $true
        $r = @($Result | Where-Object { $_ -and $_.SB }) | Select-Object -Last 1
        if (-not $r) { $ui.ReadyInfo.Text = 'Could not check - see the Activity log.'; return }
        $script:Ready = $r
        Show-AWReadiness
    }
}

function Show-AWReadiness {
    $r = $script:Ready
    $ui.ReadyRows.Children.Clear()
    $remote = Test-AWRemote; $offline = Test-AWOffline
    $adminTip = 'Needs administrator rights - use "Restart as admin" in the title bar'
    $who = if ($remote) { $script:Target.ComputerName } else { 'this PC' }

    # 1. BitLocker recovery key
    $enc = @($r.BL.Volumes | Where-Object { $_.State -in 'On', 'Suspended', 'Encrypting', 'Waiting' })
    $lines = @($r.BLSum.Text)
    foreach ($v in $enc) {
        $lines += '{0} {1}: {2}{3}{4}' -f $v.Mount, $(if ($v.Type -eq 'OperatingSystem') { '(Windows)' } else { '(data)' }), $v.State,
            $(if ($v.RecoveryPasswords -ge 0) { ", $($v.RecoveryPasswords) recovery password(s)" } else { '' }),
            $(if (@($v.EscrowedTo).Count) { ", backed up to $(@($v.EscrowedTo) -join ', ')" } else { '' })
    }
    if ($enc.Count -and -not ($r.BL.Domain -or $r.BL.Entra)) { $lines += 'Signed in with a Microsoft account? Windows usually saves the key there automatically - check that it appears at aka.ms/myrecoverykey. A printed or USB copy is a good second place.' }
    $canKeys = $r.Admin -and @($enc | Where-Object { $_.RecoveryPasswords -gt 0 }).Count
    $noKey = @($enc | Where-Object { $_.State -ne 'Waiting' -and $_.RecoveryPasswords -eq 0 })
    $btns = @()
    if ($enc.Count) {
        $btns += @{ Text = 'Save recovery key...'; Primary = $true; Enabled = [bool]$canKeys; Tip = $(if (-not $r.Admin) { $adminTip } else { 'Saves the recovery password(s) to a file you choose - put it on a USB stick or print it, not on this PC' }); Run = { Save-AWBitLockerKey } }
        if ($noKey.Count) { $btns += @{ Text = 'Add a recovery password'; Enabled = $r.Admin; Tip = $(if (-not $r.Admin) { $adminTip } else { $null }); Run = { Add-AWRecoveryPassword } } }
        if ($r.BL.Entra) { $btns += @{ Text = 'Back up to Entra ID'; Enabled = [bool]$canKeys; Run = { Backup-AWBitLockerKey 'Entra' } } }
        if ($r.BL.Domain) { $btns += @{ Text = 'Back up to Active Directory'; Enabled = [bool]$canKeys; Run = { Backup-AWBitLockerKey 'AD' } } }
        if (-not $remote) { $btns += @{ Text = 'Open aka.ms/myrecoverykey'; Enabled = -not $offline; Run = { Start-Process 'https://aka.ms/myrecoverykey' } } }
    }
    New-AWReadyRow $r.BLSum.Health 'BitLocker recovery key' $lines $btns

    # 2. Secure Boot certificates
    $sb = $r.SB
    $lines = @($sb.Summary)
    if ($sb.Advice) { $lines += $sb.Advice }
    $facts = @()
    if ($sb.Applies) {
        $facts += "Secure Boot $(if ($sb.SecureBootOn) { 'on' } else { 'off' })"
        if ($null -ne $sb.Db2023) { $facts += "2023 CA in firmware DB: $(if ($sb.Db2023) { 'yes' } else { 'no' })" }
        if ($null -ne $sb.Kek2023) { $facts += "2023 KEK: $(if ($sb.Kek2023) { 'yes' } else { 'no' })" }
        if ($sb.LastEvent) { $facts += ('last event {0} on {1:MMM d}: {2}' -f $sb.LastEvent.Id, $sb.LastEvent.Time, $sb.LastEvent.Meaning) }
        $lines += ($facts -join ' - ')
    }
    $btns = @()
    if ($sb.Applies -and $sb.Status -in 'NotStarted', 'InProgress') {
        $btns += @{ Text = 'Update certificates...'; Primary = $true; Enabled = $r.Admin; Tip = $(if (-not $r.Admin) { $adminTip } else { 'Starts the Microsoft-signed certificate update (needs one or two restarts)' }); Run = { Start-AWSecureBootUpdate } }
    }
    if ($sb.Applies -and -not $remote) { $btns += @{ Text = 'Windows Security'; Run = { Start-Process 'windowsdefender://devicesecurity' } } }
    New-AWReadyRow $(if ($sb.Applies) { $sb.Health } else { 'NA' }) 'Secure Boot certificates (2011 -> 2023)' $lines $btns

    # 3. Recovery environment
    $re = $r.RE
    $lines = @()
    $reStatus = 'NA'
    if (-not $re.Admin) { $lines += 'Run as administrator to check Windows RE and Quick Machine Recovery.' }
    else {
        $lines += switch ($re.WinRE) { 'Enabled' { 'Windows RE is enabled - Startup Repair, System Restore from boot and Reset this PC are available.' } 'Disabled' { 'Windows RE is DISABLED - if Windows stops starting, there is no repair menu. Turn it back on.' } default { 'Could not read the Windows RE status.' } }
        $lines += switch ($re.Qmr) { 'On' { 'Quick Machine Recovery is on: if Windows keeps failing to start, it can fetch a fix from Windows Update.' } 'Off' { 'Quick Machine Recovery is off.' } 'NotSupported' { 'Quick Machine Recovery needs Windows 11 24H2 (build 26100.4700) or later.' } default { '' } }
        $reStatus = switch ($re.WinRE) { 'Enabled' { 'Good' } 'Disabled' { 'Problem' } default { 'NA' } }
    }
    $lines += switch ($re.Pitr) { 'On' { 'Point-in-time Restore looks turned on (Settings > System > Recovery).' } 'Off' { 'Point-in-time Restore looks off - it keeps rolling snapshots for up to 72 hours (Settings > System > Recovery).' } 'Available' { 'Point-in-time Restore is available on this PC - check whether it is on in Settings > System > Recovery (it keeps rolling snapshots for up to 72 hours).' } default { '' } }
    $btns = @()
    if ($re.WinRE -eq 'Disabled') { $btns += @{ Text = 'Turn on Windows RE'; Primary = $true; Enabled = $r.Admin; Run = { Enable-AWWinRE } } }
    if (-not $remote) {
        $btns += @{ Text = 'Recovery settings'; Run = { Start-Process 'ms-settings:recovery' } }
        $btns += @{ Text = 'Restart to Advanced Startup'; Run = { Restart-AWAdvancedStartup } }
    }
    New-AWReadyRow $reStatus 'Recovery environment' $lines $btns

    # 4. Restore points and backup
    $lines = @()
    $rpStatus = 'NA'
    if ($re.Admin) {
        if (-not $re.ProtectionOn -and $re.RestorePoints -le 0) { $lines += 'System Protection looks off and there are no restore points.'; $rpStatus = 'Warning' }
        elseif ($re.RestorePoints -gt 0) {
            $age = [int]((Get-Date) - $re.LastRestorePoint).TotalDays
            $lines += ('{0} restore point(s), newest {1:MMM d, yyyy} ({2} day(s) ago).' -f $re.RestorePoints, $re.LastRestorePoint, $age); $rpStatus = $(if ($age -gt 30) { 'Warning' } else { 'Good' })
        } else { $lines += 'No restore points yet.'; $rpStatus = 'Warning' }
    } else { $lines += 'Run as administrator to read restore points.' }
    if (-not $remote) {
        $bk = $script:State.Backup
        $lines += if ($bk.LastRun) { 'Last Computer Doctor backup: {0} - {1}' -f ([datetime]$bk.LastRun).ToString('MMM d, yyyy h:mm tt'), $bk.LastResult } else { 'No Computer Doctor folder backup set up - restore points do not include your files.' }
        if (-not $bk.LastRun -and $rpStatus -eq 'Good') { $rpStatus = 'Info' }
    }
    New-AWReadyRow $rpStatus 'Restore points and backup' $lines @(
        @{ Text = 'Restore points'; Run = { $ui.RecTabRP.IsChecked = $true } }
        $(if (-not $remote) { @{ Text = 'Backup'; Run = { $ui.RecTabBackup.IsChecked = $true } } }))

    # 5. Windows 10 ESU
    if ($r.Esu.Applies) {
        New-AWReadyRow $(if ($r.Esu.Enrolled) { 'Good' } elseif ($r.Esu.Ready) { 'Warning' } else { 'Problem' }) 'Windows 10 security updates' @("Windows 10 support ended Oct 14, 2025; consumer Extended Security Updates run through Oct 12, 2027.", $r.Esu.Summary) @(
            $(if (-not $remote) { @{ Text = 'Windows Update'; Run = { Start-Process 'ms-settings:windowsupdate' } } }))
    }
    $bad = @($ui.ReadyRows.Children | Where-Object { $_.Child.Children[0].Child.Text -in 'PROBLEM', 'WARNING' }).Count
    $ui.ReadyInfo.Text = "Checked $who at $((Get-Date).ToString('h:mm tt'))." + $(if ($bad) { " $bad item(s) need attention." } else { ' Nothing urgent.' })
}

function Save-AWBitLockerKey {
    $mounts = @($script:Ready.BL.Volumes | Where-Object { $_.RecoveryPasswords -gt 0 } | ForEach-Object Mount)
    if (-not $mounts.Count) { return }
    $who = if (Test-AWRemote) { $script:Target.ComputerName } else { $env:COMPUTERNAME }
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = 'Text file (*.txt)|*.txt'; $dlg.FileName = "BitLocker recovery key - $who.txt"
    $dlg.Title = 'Save the recovery key somewhere other than this PC (USB stick, another computer)'
    if (-not $dlg.ShowDialog($window)) { return }
    $file = $dlg.FileName
    if (-not (Test-AWRemote)) {
        $drv = [IO.Path]::GetPathRoot($file).TrimEnd('\')
        if ($drv -in $mounts -and -not (Confirm-AW "That file would be on $drv, which is one of the encrypted drives. If the PC asks for the key, you won't be able to open this file.`n`nSave it there anyway (for example, to copy it elsewhere afterwards)?")) { return }
    }
    $script:PendingKeyFile = $file
    Start-AWTask -Name 'Read BitLocker recovery key' -Arguments @{ Mounts = $mounts } -Work {
        Invoke-WTarget { param($M) foreach ($m in $M) { foreach ($k in @(Get-WBitLockerRecoveryKeys $m)) { [pscustomobject]@{ Mount = $m; Id = $k.Id; Password = $k.Password } } } } -ArgumentList (, $Mounts)
    } -OnComplete {
        param($Result)
        $keys = @($Result | Where-Object { $_ -and $_.Password })
        if (-not $keys.Count) { Show-AWMessage 'Could not read the recovery key - see the Activity log.' 'Error'; return }
        $who = if (Test-AWRemote) { $script:Target.ComputerName } else { $env:COMPUTERNAME }
        $text = "BitLocker recovery key(s) for $who`r`nSaved by Computer Doctor on $((Get-Date).ToString('f'))`r`n`r`nIf the PC asks for a BitLocker recovery key, match the Key ID it shows with the one below and type the 48-digit recovery key.`r`n"
        foreach ($k in $keys) { $text += "`r`nDrive:         $($k.Mount)`r`nKey ID:        $($k.Id)`r`nRecovery key:  $($k.Password)`r`n" }
        try {
            [IO.File]::WriteAllText($script:PendingKeyFile, $text)
            Write-AWAction 'SaveBitLockerKey' @("$(@($keys | ForEach-Object Mount | Select-Object -Unique) -join ', ') -> $($script:PendingKeyFile)") @{} 'Done'   # never the key itself
            if (Confirm-AW "Saved to:`n$($script:PendingKeyFile)`n`nPrint a copy too? (Keep the paper somewhere safe - anyone with it can unlock the drive.)") { Start-Process notepad.exe -ArgumentList "/p `"$($script:PendingKeyFile)`"" }
        } catch { Show-AWMessage "Could not save the file: $($_.Exception.Message)" 'Error' }
        $script:PendingKeyFile = $null
    }
}

function Add-AWRecoveryPassword {
    $mounts = @($script:Ready.BL.Volumes | Where-Object { $_.State -in 'On', 'Suspended', 'Encrypting' -and $_.RecoveryPasswords -eq 0 } | ForEach-Object Mount)
    if (-not (Confirm-AW "Add a 48-digit recovery password to $($mounts -join ', ')?`n`nThis doesn't change how you sign in. Save the new key straight afterwards.")) { return }
    Start-AWTask -Name 'Add BitLocker recovery password' -Arguments @{ Mounts = $mounts } -Work { Invoke-WTarget { param($M) foreach ($m in $M) { Add-WBitLockerRecoveryPassword $m } } -ArgumentList (, $Mounts) } -OnComplete {
        param($r)
        Write-AWAction 'AddBitLockerRecoveryPassword' @($script:Ready.BL.Volumes | ForEach-Object Mount) @{} 'Done'
        Show-AWMessage 'Recovery password added. Use "Save recovery key..." now to keep a copy.'
        Update-AWReadiness
    }
}

function Backup-AWBitLockerKey([string]$To) {
    $mounts = @($script:Ready.BL.Volumes | Where-Object { $_.RecoveryPasswords -gt 0 } | ForEach-Object Mount)
    Start-AWTask -Name "Back up BitLocker key to $To" -Arguments @{ Mounts = $mounts; To = $To } -Work {
        Invoke-WTarget { param($M, $T) $n = 0; foreach ($m in $M) { $n += Backup-WBitLockerKey $m $T }; $n } -ArgumentList $Mounts, $To
    } -OnComplete {
        param($r)
        $n = [int](@($r) | Select-Object -Last 1)
        if ($n) { Write-AWAction 'BackupBitLockerKey' @($script:Ready.BL.Volumes | Where-Object { $_.RecoveryPasswords -gt 0 } | ForEach-Object Mount) @{} 'Done'; Show-AWMessage "$n recovery key(s) backed up." } else { Show-AWMessage 'Nothing was backed up - see the Activity log.' 'Warning' }
        Update-AWReadiness
    }
}

function Start-AWSecureBootUpdate {
    $sysVol = @($script:Ready.BL.Volumes | Where-Object { $_.Type -eq 'OperatingSystem' -and $_.State -in 'On', 'Encrypting' })
    $msg = "Start the Secure Boot certificate update now?`n`nWindows adds Microsoft's 2023 certificates to the firmware and switches to the 2023-signed boot manager. It's the same update Windows rolls out on its own; it needs one or two restarts and can't be undone.`n`nIf the PC maker's firmware rejects it, Windows stops and Computer Doctor will show that a BIOS update is needed."
    if ($sysVol.Count) { $msg += "`n`nBitLocker is on. Make sure the recovery key is saved off this PC first - Computer Doctor will suspend BitLocker for two restarts so the firmware change doesn't trigger a recovery prompt." }
    if (-not (Confirm-AW $msg)) { return }
    if ($sysVol.Count -and -not (Confirm-AW 'Is the BitLocker recovery key saved somewhere other than this PC (Microsoft account, USB stick, paper or your organization)?')) {
        Show-AWMessage 'Save the recovery key first ("Save recovery key..." above), then start the update.'; return
    }
    Write-AWAction 'SecureBootCertUpdate' @($(if (Test-AWRemote) { $script:Target.ComputerName } else { $env:COMPUTERNAME })) @{ SuspendBitLocker = [bool]$sysVol.Count } 'Started'
    Start-AWTask -Name 'Secure Boot certificate update' -Arguments @{ Suspend = [bool]$sysVol.Count } -Work { Invoke-WTarget { param($S) try { Start-WSecureBootUpdate $S } catch { [pscustomobject]@{ Error = $_.Exception.Message } } } -ArgumentList $Suspend } -OnComplete {
        param($res)
        $x = @($res) | Select-Object -Last 1
        if ($x.Error) { Show-AWMessage "The update didn't start:`n$($x.Error)" 'Warning' }
        else { Show-AWMessage "Update requested. Restart the PC (twice if Windows asks), then check again here.`n`nCurrent status: $($x.Summary)" }
        Update-AWReadiness
    }
}

function Enable-AWWinRE {
    if (-not (Confirm-AW 'Turn Windows RE back on (reagentc /enable)?')) { return }
    Start-AWCommandTask 'Turn on Windows RE' { & reagentc.exe /enable 2>&1; "AWEXIT $LASTEXITCODE" }
}

function Restart-AWAdvancedStartup {
    if (-not (Confirm-AW "Restart into Advanced Startup now?`n`nSave your work first. From there you can use Startup Repair, System Restore, Safe Mode, UEFI settings or Reset this PC - or choose Continue to go back to Windows.")) { return }
    Write-AWAction 'RestartToAdvancedStartup' @($env:COMPUTERNAME) @{} 'Started'
    Update-AWLogView
    try { & shutdown.exe /r /o /t 5 /c 'Computer Doctor: restarting into Advanced Startup' 2>&1 | Out-Null; if ($LASTEXITCODE) { throw "shutdown.exe exit code $LASTEXITCODE" } }
    catch { Show-AWMessage "Could not restart into Advanced Startup: $($_.Exception.Message)" 'Error' }
}
$ui.ReadyRefresh.Add_Click({ Update-AWReadiness })
$ui.RecTabReady.Add_Checked({ Show-AWRecoveryTab 'Ready' })

function Show-AWRecoveryTab([string]$Tab) {
    $ui.RecPanelBin.Visibility    = if ($Tab -eq 'Bin')    { 'Visible' } else { 'Collapsed' }
    $ui.RecPanelShadow.Visibility = if ($Tab -eq 'Shadow') { 'Visible' } else { 'Collapsed' }
    $ui.RecPanelDeep.Visibility   = if ($Tab -eq 'Deep')   { 'Visible' } else { 'Collapsed' }
    $ui.RecPanelUndel.Visibility  = if ($Tab -eq 'Undel')  { 'Visible' } else { 'Collapsed' }
    $ui.RecPanelRP.Visibility     = if ($Tab -eq 'RP')     { 'Visible' } else { 'Collapsed' }
    $ui.RecPanelBackup.Visibility = if ($Tab -eq 'Backup') { 'Visible' } else { 'Collapsed' }
    $ui.RecPanelReady.Visibility  = if ($Tab -eq 'Ready')  { 'Visible' } else { 'Collapsed' }
    $ui.RecDrives.Visibility      = if ($Tab -eq 'Ready')  { 'Collapsed' } else { 'Visible' }
    if ($Tab -eq 'Ready') { Update-AWReadiness; return }
    if (-not $script:RecLoadedTabs[$Tab]) {
        $script:RecLoadedTabs[$Tab] = $true
        if ($Tab -eq 'Shadow') { Update-AWShadowList }
        if ($Tab -eq 'Deep')   { Update-AWWinfrStatus }
        if ($Tab -eq 'RP')     { Update-AWRestorePoints }
        if ($Tab -eq 'Backup') { Update-AWBackupUI }
    }
}

function Initialize-AWRecovery {
    $script:RecLoadedTabs = @{ Bin = $true }
    $script:BinItems = @(); $ui.BinList.ItemsSource = $null
    if (-not $ui.ShadowFolder.Text) { $ui.ShadowFolder.Text = [Environment]::GetFolderPath('MyDocuments') }
    Update-AWRecoveryButtons
    Update-AWRecoveryDrives
    Update-AWBinList
    if ($ui.RecTabShadow.IsChecked) { Show-AWRecoveryTab 'Shadow' } elseif ($ui.RecTabDeep.IsChecked) { Show-AWRecoveryTab 'Deep' } elseif ($ui.RecTabUndel.IsChecked) { Show-AWRecoveryTab 'Undel' } elseif ($ui.RecTabRP.IsChecked) { Show-AWRecoveryTab 'RP' } elseif ($ui.RecTabBackup.IsChecked) { Show-AWRecoveryTab 'Backup' } elseif ($ui.RecTabReady.IsChecked) { Show-AWRecoveryTab 'Ready' }
}

$ui.RecTabBin.Add_Checked({ Show-AWRecoveryTab 'Bin' })
$ui.RecTabShadow.Add_Checked({ Show-AWRecoveryTab 'Shadow' })
$ui.RecTabDeep.Add_Checked({ Show-AWRecoveryTab 'Deep' })
$ui.RecTabUndel.Add_Checked({ Show-AWRecoveryTab 'Undel' })
$ui.RecTabRP.Add_Checked({ Show-AWRecoveryTab 'RP' })
$ui.RecTabBackup.Add_Checked({ Show-AWRecoveryTab 'Backup' })

$ui.BinSearch.Add_TextChanged({ Update-AWBinView })
$ui.BinRefresh.Add_Click({ Update-AWBinList })
$ui.BinRestore.Add_Click({ Start-AWBinRestore '' })
$ui.BinRestoreTo.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Restore the checked items into this folder'
    if ($dlg.ShowDialog() -eq 'OK') { Start-AWBinRestore $dlg.SelectedPath }
})
$ui.BinOpen.Add_Click({
    $i = $ui.BinList.SelectedItem
    if (-not $i) { Show-AWMessage 'Select an item first.'; return }
    if (Test-Path -LiteralPath $i.Folder) { Open-AWExplorer $i.Folder } else { Show-AWMessage "$($i.Folder) no longer exists. Restoring the item will recreate it." }
})

$ui.ShadowRefresh.Add_Click({ Update-AWShadowList })
$ui.ShadowFind.Add_Click({ Start-AWShadowFind })
$ui.ShadowFolder.Add_KeyDown({ param($s, $e) if ($e.Key -eq 'Return') { $e.Handled = $true; Start-AWShadowFind } })
$ui.ShadowRestore.Add_Click({ Start-AWShadowCopy '' })
$ui.ShadowCopyTo.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Copy the checked files into this folder (subfolders are kept)'
    if ($dlg.ShowDialog() -eq 'OK') { Start-AWShadowCopy $dlg.SelectedPath }
})
$ui.ShadowExplore.Add_Click({
    $s = $ui.ShadowList.SelectedItem
    if (-not $s) { Show-AWMessage 'Pick a snapshot first.'; return }
    try { Open-AWExplorer (Mount-AWShadow $s) } catch { Show-AWMessage $_.Exception.Message 'Error' }
})
$ui.ShadowProtect.Add_Click({ Start-Process SystemPropertiesProtection.exe })

$ui.WinfrInstall.Add_Click({
    $ui.WinfrInstall.IsEnabled = $false
    $ui.WinfrStatus.Text = 'Installing Windows File Recovery from the Microsoft Store...'
    Start-AWTask -Name 'Install Windows File Recovery' -Work {
        & winget.exe install --id 9N26S50LN705 --source msstore --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 | ForEach-Object {
            $l = ("$_" -replace "`0", '').Trim()
            if ($l -and $l -notmatch '^[\s\-\\|/]+$' -and $l -notmatch '[\u2580-\u259F]') { Write-WLog "winget: $l" }
        }
        "winget exit code $LASTEXITCODE"
    } -OnComplete {
        param($r)
        $ui.WinfrInstall.IsEnabled = $true
        Update-AWWinfrStatus
        if (-not $script:WinfrPath) {
            if (Confirm-AW "Windows File Recovery didn't install automatically (see the Activity log). Open its Microsoft Store page instead?") { Start-Process 'ms-windows-store://pdp/?productid=9N26S50LN705' }
        }
    }
})
$ui.WinfrStore.Add_Click({ Start-Process 'ms-windows-store://pdp/?productid=9N26S50LN705' })
$ui.DeepBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Save recovered files here (must be on a different drive)'
    $dlg.ShowNewFolderButton = $true
    if ($dlg.ShowDialog() -eq 'OK') { $ui.DeepDest.Text = $dlg.SelectedPath }
})
$ui.DeepDest.Add_TextChanged({ Update-AWDeep })
$ui.DeepFilter.Add_TextChanged({ Update-AWDeep })
$ui.DeepRegular.Add_Checked({ Update-AWDeep })
$ui.DeepExtensive.Add_Checked({ Update-AWDeep })
$ui.DeepStart.Add_Click({ Start-AWDeepScan })
$ui.DeepStop.Add_Click({
    if ($Sync.WinfrPid -and (Confirm-AW 'Stop Windows File Recovery? Files recovered so far stay in the destination folder.')) {
        Stop-Process -Id $Sync.WinfrPid -Force -ErrorAction SilentlyContinue
        Write-AWLog 'Windows File Recovery stopped by user' 'WARN'
    }
})
$ui.DeepOpenDest.Add_Click({
    $d = $ui.DeepDest.Text.Trim()
    if ($d -and (Test-Path -LiteralPath $d)) { Open-AWExplorer $d } else { Show-AWMessage 'The destination folder does not exist yet.' }
})
#endregion

#region ---------------------------------------------------------------- Column sorting
function Enable-AWSort($ListView, [hashtable]$Map) {
    $ListView.Tag = $Map
    $ListView.AddHandler([System.Windows.Controls.GridViewColumnHeader]::ClickEvent, [System.Windows.RoutedEventHandler]{
        param($s, $e)
        $h = $e.OriginalSource
        if ($h -isnot [System.Windows.Controls.GridViewColumnHeader] -or -not $h.Column) { return }
        $prop = $s.Tag[[string]$h.Column.Header]
        if (-not $prop -or -not $s.ItemsSource) { return }
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($s.ItemsSource)
        if (-not $view) { return }
        $dir = [System.ComponentModel.ListSortDirection]::Descending
        if ($view.SortDescriptions.Count -gt 0 -and $view.SortDescriptions[0].PropertyName -eq $prop -and
            $view.SortDescriptions[0].Direction -eq [System.ComponentModel.ListSortDirection]::Descending) {
            $dir = [System.ComponentModel.ListSortDirection]::Ascending
        }
        $view.SortDescriptions.Clear()
        $view.SortDescriptions.Add((New-Object System.ComponentModel.SortDescription($prop, $dir)))
    })
}
Enable-AWSort $ui.LargeList    @{ Name = 'Name'; Size = 'Size'; Type = 'Extension'; Modified = 'Modified'; Folder = 'Folder'; Group = 'Status'; Kind = 'Status' }
Enable-AWSort $ui.MenuList     @{ Name = 'Name'; 'Shows on' = 'Where'; Type = 'Kind'; Company = 'Company'; Status = 'Enabled' }
Enable-AWSort $ui.ProgList     @{ Name = 'Name'; Publisher = 'Publisher'; Version = 'Version'; Installed = 'Installed'; Size = 'SizeBytes'; Scope = 'Scope' }
Enable-AWSort $ui.StartupList  @{ Name = 'Name'; Scope = 'Scope'; Source = 'Location'; Status = 'Enabled' }
Enable-AWSort $ui.CleanResults @{ Item = 'Name'; Group = 'Group'; Size = 'Bytes' }
Enable-AWSort $ui.AppList      @{ App = 'Name'; Category = 'Category'; Notes = 'Note' }
Enable-AWSort $ui.DrvList      @{ Device = 'Name'; Status = 'SortRank'; Vendor = 'Vendor'; Version = 'Version'; Date = 'Date'; Class = 'Class' }
Enable-AWSort $ui.BiosList     @{ Section = 'Section'; Setting = 'Name'; Value = 'Value' }
Enable-AWSort $ui.ProfList     @{ User = 'Name'; 'Last used' = 'When'; Size = 'Size'; Status = 'Status' }
Enable-AWSort $ui.PrnList      @{ Type = 'Kind'; Name = 'Name'; Status = 'Status' }
Enable-AWSort $ui.BlList       @{ Result = 'Result'; Severity = 'Severity'; Category = 'Category'; Setting = 'Name' }
Enable-AWSort $ui.WuList       @{ KB = 'Key'; Update = 'Name'; Severity = 'Kind'; Size = 'Size' }
Enable-AWSort $ui.RebloatList  @{ App = 'Name'; Category = 'Category'; 'Comes back from' = 'Source'; Notes = 'Note' }
Enable-AWSort $ui.BinList     @{ Name = 'Name'; Type = 'Kind'; Size = 'Size'; Deleted = 'Deleted'; 'Deleted by' = 'Owner'; 'Original location' = 'Folder' }
Enable-AWSort $ui.ShadowResults @{ Name = 'Name'; Status = 'Status'; Size = 'Size'; Modified = 'Modified'; Folder = 'Folder' }
#endregion

#region ---------------------------------------------------------------- Startup + run
$window.Add_Loaded({
    Move-AWOldRegistrations   # saved connections and scheduled tasks from when the app was called AWiper
    try {
        Update-AWDashboard
        Initialize-AWCleaner
        Initialize-AWMapDrives
        Initialize-AWTools
        Initialize-AWTweaks
        Dismount-AWShadows   # links left behind by a previous session that didn't close cleanly
        Update-AWNetUI
        Start-AWNetCheck
    } catch { Write-AWLog "Startup: $($_.Exception.Message)" 'ERROR' }
    $script:Timer.Start()
    Write-AWLog ("Computer Doctor {0} started - {1} - PowerShell {2}" -f $script:AppVersion, $(if ($script:IsAdmin) { 'administrator' } else { 'standard user' }), $PSVersionTable.PSVersion)
    if ($script:ElevationNote) { Write-AWLog $script:ElevationNote 'WARN' }
    $script:IdleStatus = if ($script:IsAdmin) { 'Ready - running as administrator' } else { 'Ready - standard permissions (admin-only items are disabled)' }
    Set-AWStatus $script:IdleStatus
})

$window.Add_Closing({
    if ($script:Scanner) { $script:Scanner.Cancel = $true }
    if ($Sync.WinfrPid) { Stop-Process -Id $Sync.WinfrPid -Force -ErrorAction SilentlyContinue }
    if ($script:Undelete) { $script:Undelete.Cancel = $true }
    Dismount-AWShadows
    $script:Timer.Stop()
    Update-AWLogView
    foreach ($j in $script:Jobs) { try { $j.PS.Stop(); $j.PS.Dispose(); $j.Runspace.Dispose() } catch { } }
})

$window.Dispatcher.Add_UnhandledException({
    param($s, $e)
    Write-AWLog "Unhandled: $($e.Exception.Message)" 'ERROR'
    $e.Handled = $true
})

try {
    [void]$window.ShowDialog()
}
catch {
    $msg = "Computer Doctor hit an error and has to close:`n`n$($_.Exception.Message)"
    try { Add-Content -LiteralPath $script:LogFile -Value ("{0:HH:mm:ss}  FATAL  {1}" -f (Get-Date), $_.Exception.ToString()) } catch { }
    [void][System.Windows.MessageBox]::Show($msg, 'Computer Doctor', 'OK', 'Error')
}
#endregion
