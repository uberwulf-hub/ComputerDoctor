<#
.SYNOPSIS
    Checks the cleaner's rules found by looking (programs' logs, temp files and caches) on a throwaway folder,
    the Space Map's "what can be cleaned" matching, and the report for an administrator (no admin needed).
#>
param(
    [string]$Path = (Join-Path $PSScriptRoot '..\ComputerDoctor.ps1'),
    [string]$Work = (Join-Path ([IO.Path]::GetTempPath()) 'ComputerDoctorCleanerTest')
)
$ErrorActionPreference = 'Stop'
$src = [IO.File]::ReadAllText($Path)
Add-Type -TypeDefinition ([regex]::Match($src, "Add-Type -TypeDefinition @'\r?\n(.*?)\r?\n'@", 'Singleline').Groups[1].Value)
$Sync = [hashtable]::Synchronized(@{}); $Sync.Log = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'; $Target = $null
. ([scriptblock]::Create([regex]::Match($src, "\`$Sync.WorkerLib = @'\r?\n(.*?)\r?\n'@", 'Singleline').Groups[1].Value))
$fail = 0
function Check([string]$Name, [bool]$Ok) { if ($Ok) { Write-Host "PASS  $Name" -ForegroundColor Green } else { Write-Host "FAIL  $Name" -ForegroundColor Red; $script:fail++ } }

# ---- programs' logs and caches, found by looking
if (Test-Path $Work) { [IO.Directory]::Delete($Work, $true) }
New-Item -ItemType Directory -Path $Work -Force | Out-Null
$Work = [ComputerDoctor.Native]::LongPath($Work)      # %TEMP% can hold 8.3 names (RUNNER~1); results use long paths
$old = (Get-Date).AddDays(-30)
function Mk($p, $when) { New-Item -ItemType Directory -Path (Split-Path $p) -Force | Out-Null; [IO.File]::WriteAllBytes($p, (New-Object byte[] 1024)); (Get-Item $p).LastWriteTime = $when }
Mk "$Work\App1\Logs\old.log" $old
Mk "$Work\App1\Logs\new.log" (Get-Date)
Mk "$Work\App1\app.log" $old
Mk "$Work\App1\settings.json" $old
Mk "$Work\App1\Cache\data_1" $old
Mk "$Work\App1\Local Storage\Logs\keep.log" $old
Mk "$Work\App2\User Data\Default\Cache\c1" $old
Mk "$Work\App2\User Data\Default\Logs\keep.log" $old
Mk "$Work\App2\Crashpad\reports\r.dmp" $old
Mk "$Work\Covered\Cache\covered.bin" $old
Mk "$Work\Never\Logs\never.log" $old
Mk "$Work\Deep\a\b\c\Logs\deep.log" $old

$disc = @{ Bases = @($Work); MaxDepth = 4; MinAgeHours = 168; NeverInside = @("$Work\Never") }
$logs = @{ Id = 'AppLogs'; Name = 'Logs'; Group = 'Applications'; Kind = 'Found'; Covered = @("$Work\Covered")
           Discover = $disc.Clone() }
$logs.Discover.Take = 'Log'; $logs.Discover.TopFiles = @('*.log', '*.log.old', '*.dmp')
$caches = @{ Id = 'AppCaches'; Name = 'Caches'; Group = 'Applications'; Kind = 'Found'; Covered = @("$Work\Covered")
             Discover = $disc.Clone() }
$caches.Discover.Take = 'Cache'; $caches.Discover.MinAgeHours = 0; $caches.Discover.TopFiles = @()

$logFiles = @(Find-WAppFolders $logs | ForEach-Object { $_.Targets } | ForEach-Object { Get-WFoundFiles $_ } | ForEach-Object { $_.FullName })
$cacheFiles = @(Find-WAppFolders $caches | ForEach-Object { $_.Targets } | ForEach-Object { Get-WFoundFiles $_ } | ForEach-Object { $_.FullName })
Check 'Logs: finds old files in Logs folders and log files in the top folder' ($logFiles -contains "$Work\App1\Logs\old.log" -and $logFiles -contains "$Work\App1\app.log")
Check 'Logs: skips files newer than the age limit' ($logFiles -notcontains "$Work\App1\Logs\new.log")
Check 'Logs: finds crash reports (Crashpad\reports)' ($logFiles -contains "$Work\App2\Crashpad\reports\r.dmp")
Check 'Logs: never inside Local Storage, User Data or excluded folders' ($logFiles -notcontains "$Work\App1\Local Storage\Logs\keep.log" -and $logFiles -notcontains "$Work\App2\User Data\Default\Logs\keep.log" -and $logFiles -notcontains "$Work\Never\Logs\never.log")
Check 'Logs: no deeper than 4 levels' ($logFiles -notcontains "$Work\Deep\a\b\c\Logs\deep.log")
Check 'Logs: never settings or data' ($logFiles -notcontains "$Work\App1\settings.json")
Check 'Caches: finds cache folders, also under User Data' ($cacheFiles -contains "$Work\App1\Cache\data_1" -and $cacheFiles -contains "$Work\App2\User Data\Default\Cache\c1")
Check 'Caches: skips folders another rule covers' ($cacheFiles -notcontains "$Work\Covered\Cache\covered.bin")
Check 'Logs and caches never count the same file' (-not @($logFiles | Where-Object { $cacheFiles -contains $_ }).Count)
$m = @(Measure-WItem $logs)
Check 'Analyze shows the rule line, then one line per app' (-not $m[0].Sub -and @($m | Where-Object { $_.Sub -and $_.Name -eq 'App1' }).Count -eq 1 -and $m[0].Note -match 'in \d+ app')

# ---- Space Map: what a rule would clean
[ComputerDoctor.CleanMap]::Clear()
[ComputerDoctor.CleanMap]::Add('C:\Users\x\AppData\Local\Temp', '*', $true, 'User temp files')
[ComputerDoctor.CleanMap]::Add('C:\Users\x\AppData\Local\Microsoft\Windows\Explorer', 'thumbcache_*.db', $false, 'Thumbnail cache')
Check 'Map: a target folder and what is inside it match' ([ComputerDoctor.CleanMap]::Match('C:\Users\x\AppData\Local\Temp', $true) -eq 'User temp files' -and [ComputerDoctor.CleanMap]::Match('C:\Users\x\AppData\Local\Temp\a\b.tmp', $false) -eq 'User temp files')
Check 'Map: the folder above a target does not match' ($null -eq [ComputerDoctor.CleanMap]::Match('C:\Users\x\AppData\Local', $true))
Check 'Map: filtered targets match only their files' ([ComputerDoctor.CleanMap]::Match('C:\Users\x\AppData\Local\Microsoft\Windows\Explorer\thumbcache_96.db', $false) -eq 'Thumbnail cache' -and
    $null -eq [ComputerDoctor.CleanMap]::Match('C:\Users\x\AppData\Local\Microsoft\Windows\Explorer\iconcache_96.db', $false) -and
    $null -eq [ComputerDoctor.CleanMap]::Match('C:\Users\x\AppData\Local\Microsoft\Windows\Explorer', $true))
Check 'Map: this account can delete its own temp folder' ([ComputerDoctor.FolderRights]::Check($Work) -eq [ComputerDoctor.FolderRights]::Ok)

# ---- report for an administrator
$info = @{ Computer = 'PC1'; Windows = 'Windows 11 Pro (10.0.26100)'; User = 'PC1\sam'; Drive = 'C: 12.0 GB free of 237 GB'; Date = '2026-11-18 10:00' }
$items = @(
    @{ Id = 'WinUpdate'; Name = 'Windows Update cache'; Desc = 'Downloaded update packages <already installed>.'; Bytes = [long]3GB }
    @{ Id = 'WinTemp'; Name = 'Windows temp files'; Desc = 'Files in C:\Windows\Temp older than 24 hours.'; Bytes = [long]-1 }
)
$rep = New-WAdminReport $info $items 'C:\Tools\ComputerDoctor.ps1'
Check 'Report text lists each cleanup with its size' ($rep.Text -match 'Windows Update cache \(3\.00 GB\)' -and $rep.Text -match 'size unknown - needs admin to measure')
Check 'Report text has the steps and the command' ($rep.Text -match '3\. Leave these ticked: Windows Update cache, Windows temp files\.' -and
    $rep.Text.Contains('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Tools\ComputerDoctor.ps1" -Clean WinUpdate,WinTemp -Yes') -and
    $rep.Text -match 'Without Computer Doctor: Settings > System > Storage > Temporary files')
Check 'Report text has the PC details' ($rep.Text -match 'PC: PC1' -and $rep.Text -match 'System drive: C: 12\.0 GB free')
Check 'Report HTML is a page with a numbered list and escaped text' ($rep.Html -match '^<!DOCTYPE html>' -and $rep.Html -match '<ol><li>' -and $rep.Html -match '&lt;already installed&gt;' -and $rep.Html -notmatch '<already installed>')

[IO.Directory]::Delete($Work, $true)
if ($fail) { Write-Host "$fail check(s) failed" -ForegroundColor Red; exit 1 } else { Write-Host 'All checks passed' -ForegroundColor Green }
