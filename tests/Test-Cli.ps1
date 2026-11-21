<#
.SYNOPSIS
    Exercises Computer Doctor's headless mode without making changes (no admin needed).
    Checks listings, argument validation, the health check (text and JSON), analyze and preview.
#>
param([string]$Path = (Join-Path $PSScriptRoot '..\ComputerDoctor.ps1'))
$ErrorActionPreference = 'Stop'
$exe = (Get-Process -Id $PID).Path
$fail = 0
function Invoke-AW([string[]]$ArgList) {
    $out = & $exe -NoProfile -ExecutionPolicy Bypass -File $Path @ArgList 2>&1 | Out-String
    [pscustomobject]@{ Code = $LASTEXITCODE; Out = $out }
}
function Check([string]$Name, [bool]$Ok, [string]$Detail = '') {
    if ($Ok) { Write-Host "PASS  $Name" -ForegroundColor Green } else { Write-Host "FAIL  $Name  $Detail" -ForegroundColor Red; $script:fail++ }
}

$r = Invoke-AW @('-ListRules');  Check 'ListRules shows rule IDs' ($r.Code -eq 0 -and $r.Out -match 'UserTemp') "exit $($r.Code)"
$missing = @('INetCache', 'StoreAppCaches', 'ProgramLogs', 'BrowserSW', 'VSCode', 'Slack', 'Spotify', 'OneDriveLogs', 'AppLogs', 'AppCaches', 'NpmCache', 'PipCache', 'NuGetCache', 'YarnCache') | Where-Object { $r.Out -notmatch "\b$_\b" }
Check 'ListRules shows the newer rules' (@($missing).Count -eq 0) "missing: $(@($missing) -join ', ')"
$r = Invoke-AW @('-ListTweaks'); Check 'ListTweaks shows tweak IDs' ($r.Code -eq 0 -and $r.Out -match 'FileExt') "exit $($r.Code)"
$r = Invoke-AW @('-Clean', 'NoSuchRule'); Check 'Unknown rule is rejected with exit 2' ($r.Code -eq 2)
$r = Invoke-AW @('-ApplyTweak', 'NoSuchTweak'); Check 'Unknown tweak is rejected with exit 2' ($r.Code -eq 2)

$tmp = Join-Path ([IO.Path]::GetTempPath()) ('computerdoctor-cli-{0}.json' -f [guid]::NewGuid().ToString('N'))
$r = Invoke-AW @('-HealthCheck', '-Format', 'Json', '-OutFile', $tmp)
$doc = Get-Content -LiteralPath $tmp -Raw | ConvertFrom-Json
$rows = @($doc.Steps | Where-Object { $_.Step -eq 'HealthCheck' } | ForEach-Object { $_.Items })
Check 'Health check returns rows' ($rows.Count -ge 5) "rows=$($rows.Count)"
Check 'Health exit code matches results' (($r.Code -eq 4) -eq [bool]@($rows | Where-Object { $_.Status -eq 'Problem' }).Count) "exit $($r.Code)"
Check 'No health row is missing a status' (-not @($rows | Where-Object { $_.Status -notin 'Good', 'Warning', 'Problem', 'Info', 'NA' }).Count)
Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue

$r = Invoke-AW @('-Analyze', '-Clean', 'UserTemp'); Check 'Analyze reports a size' ($r.Code -eq 0 -and $r.Out -match 'can be cleaned') "exit $($r.Code)"
$r = Invoke-AW @('-ApplyTweak', 'FileExt'); Check 'Without -Yes changes are only previewed' ($r.Out -match 'would apply' -and $r.Out -match 'preview only')

$r = Invoke-AW @('-CheckDrivers', '-Offline'); Check 'CheckDrivers lists the PC and its maker page (offline)' ($r.Code -eq 0 -and $r.Out -match 'BIOS' -and $r.Out -match 'driver page') "exit $($r.Code)"
$r = Invoke-AW @('-Inventory', 'localhost'); Check 'Inventory writes a report for this PC' ($r.Code -eq 0 -and $r.Out -match 'report\.html') "exit $($r.Code)"

if ($fail) { Write-Host "$fail check(s) failed" -ForegroundColor Red; exit 1 } else { Write-Host 'All checks passed' -ForegroundColor Green }
