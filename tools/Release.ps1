#Requires -Version 5.1
<#
.SYNOPSIS
    Publishes a Computer Doctor release: runs the checks, stamps the version into the script and makes the GitHub
    release that SauceStore lists.

.DESCRIPTION
    1. Refuses unless the repository is on main, everything is committed and CHANGELOG.md's "Unreleased" has lines.
    2. Runs the checks that need no admin rights and no internet (tests\Test-Cli, Test-Backup, Test-OldFiles): all
       must pass.
    3. Writes the version into ComputerDoctor.ps1 ($script:AppVersion and the help's Version line), moves
       "Unreleased" in CHANGELOG.md to "## [X.Y.Z] - date", commits "Computer Doctor X.Y.Z" and tags vX.Y.Z with
       those notes.
    4. Copies ComputerDoctor.ps1 into build\ (the name saucestore.json gives) after checking that it parses and
       carries the new version.
    5. Pushes main and the tag together and makes the GitHub release with the script (gh). SauceStore picks it up
       within about 10 minutes.
    6. Releases Computer Doctor (Sauce Edition), the installed app listed under Apps, with the same version: runs
       ..\ComputerDoctor-SauceEdition\tools\Release.ps1, which builds its setup program from this release's script.
       That keeps the two listings in sync. Step 1 refuses if that repo isn't cloned next to this one (-ScriptOnly
       skips this step).
    Never run this unless Andrew asked for the release: a release reaches everyone who installed the app.

.PARAMETER Version
    The new version, X.Y.Z.

.PARAMETER ScriptOnly
    Releases only the script, not Computer Doctor (Sauce Edition). Release that later with the same version so the
    listings match again.

.PARAMETER WhatIf
    Runs the checks and copies the script into build\, and builds the Sauce Edition setup from it, without changing the
    version, committing, tagging, pushing or releasing.

.EXAMPLE
    .\tools\Release.ps1 -Version 1.12.0
#>
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
    [switch]$SkipTests,
    [switch]$ScriptOnly,
    [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $PSScriptRoot
$Tag = "v$Version"
$Asset = 'ComputerDoctor.ps1'
$GhRepo = 'uberwulf-hub/ComputerDoctor'
$Script = Join-Path $Repo $Asset
$AppRelease = Join-Path (Split-Path -Parent $Repo) 'ComputerDoctor-SauceEdition\tools\Release.ps1'
function Step([string]$m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Stop-Release([string]$m) { Write-Host "Not released: $m" -ForegroundColor Red; exit 1 }
function Invoke-Git([string[]]$GitArgs) {
    $ErrorActionPreference = 'Continue'
    $out = & git -C $Repo @GitArgs 2>&1
    if ($LASTEXITCODE -ne 0) { Stop-Release "git $($GitArgs -join ' ') failed: $out" }
    return (($out | ForEach-Object { "$_" }) -join "`n").Trim()
}

# ---- 1. the repository is ready
$changelogFile = Join-Path $Repo 'CHANGELOG.md'
$changelog = [IO.File]::ReadAllText($changelogFile) -replace "`r`n", "`n"
$m = [regex]::Match($changelog, '(?ms)^## \[Unreleased\]\n(.*?)(?=^## \[|\z)')
if (-not $m.Success -or $m.Groups[1].Value -notmatch '(?m)^\s*-\s+\S') { Stop-Release 'CHANGELOG.md has nothing under "## [Unreleased]".' }
$notes = $m.Groups[1].Value.Trim()
if (-not $WhatIf) {
    if ((Invoke-Git @('rev-parse', '--abbrev-ref', 'HEAD')) -ne 'main') { Stop-Release 'not on main.' }
    if (Invoke-Git @('status', '--porcelain')) { Stop-Release 'there are uncommitted changes.' }
    if ((Invoke-Git @('tag', '--list', $Tag))) { Stop-Release "$Tag already exists." }
}
if (-not $ScriptOnly -and -not (Test-Path -LiteralPath $AppRelease)) {
    Stop-Release "ComputerDoctor-SauceEdition isn't cloned next to this repo ($AppRelease), so the app listing would fall behind. Clone it, or use -ScriptOnly."
}
function Invoke-AppRelease([string[]]$AppArgs) {
    Step 'Releasing Computer Doctor (Sauce Edition)'
    # Started in this same window, not piped, so the Android signing step can ask for the key's password.
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$AppRelease`"", '-Version', $Version) + @($AppArgs | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } })
    $p = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $argList -NoNewWindow -Wait -PassThru
    return $p.ExitCode
}

# ---- 2. the checks
if (-not $SkipTests) {
    $exe = (Get-Process -Id $PID).Path
    foreach ($t in 'Test-Cli.ps1', 'Test-Backup.ps1', 'Test-OldFiles.ps1') {
        Step "Running $t"
        $ErrorActionPreference = 'Continue'
        $out = & $exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Repo "tests\$t") 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        if ($code -ne 0) { $out | Where-Object { $_ -match '^FAIL' } | ForEach-Object { Write-Host $_ -ForegroundColor Red }; Stop-Release "$t failed (exit $code)." }
    }
    Step 'All checks passed'
}

# ---- 3. version, changelog, commit, tag
if (-not $WhatIf) {
    $today = (Get-Date).ToString('yyyy-MM-dd')
    $text = [IO.File]::ReadAllText($Script)
    $text = ([regex]"(?m)^\`$script:AppVersion = '[^']*'").Replace($text, "`$`$script:AppVersion = '$Version'", 1)
    $text = ([regex]'(?m)^(\s*Version\s*:\s*)\d+\.\d+\.\d+').Replace($text, "`${1}$Version", 1)
    # the script is plain ASCII with CRLF line ends; ReadAllText/WriteAllText keep both (no BOM is added)
    if ($text -match '[^\x00-\x7F]') { Stop-Release 'ComputerDoctor.ps1 has non-ASCII characters; Windows PowerShell 5.1 would misread them without a BOM.' }
    [IO.File]::WriteAllText($Script, $text)
    $newLog = $changelog.Substring(0, $m.Index) + "## [Unreleased]`n`n## [$Version] - $today`n`n$notes`n`n" + $changelog.Substring($m.Index + $m.Length)
    [IO.File]::WriteAllText($changelogFile, ($newLog.TrimEnd() + "`n"))
    [void](Invoke-Git @('add', '--', $Asset, 'CHANGELOG.md'))
    $msg = Join-Path $env:TEMP ("cd-release-" + [Guid]::NewGuid().ToString('N') + '.txt')
    try {
        [IO.File]::WriteAllText($msg, "Computer Doctor $Version`n`n$notes`n")
        [void](Invoke-Git @('commit', '-F', $msg))
        [IO.File]::WriteAllText($msg, "$notes`n")
        [void](Invoke-Git @('tag', '-a', $Tag, '-F', $msg))
    } finally { Remove-Item -LiteralPath $msg -Force -ErrorAction SilentlyContinue }
    Step "Committed and tagged $Tag"
}

# ---- 4. the release file
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($Script, [ref]$null, [ref]$errors)
if ($errors) { Stop-Release "ComputerDoctor.ps1 doesn't parse: $($errors[0].Message) (line $($errors[0].Extent.StartLineNumber))." }
if (-not $WhatIf -and [IO.File]::ReadAllText($Script) -notmatch "(?m)^\`$script:AppVersion = '$([regex]::Escape($Version))'") {
    Stop-Release 'the version wasn''t written into ComputerDoctor.ps1 (the commit and tag are only on this PC).'
}
$outDir = Join-Path $Repo 'build'
[void][IO.Directory]::CreateDirectory($outDir)
$file = Join-Path $outDir $Asset
Copy-Item -LiteralPath $Script -Destination $file -Force
Step ("Made $Asset ({0:N0} KB)" -f ((Get-Item -LiteralPath $file).Length / 1KB))
if ($WhatIf) {
    if (-not $ScriptOnly -and (Invoke-AppRelease @('-WhatIf', '-Script', $file)) -ne 0) { Stop-Release 'the Sauce Edition setup didn''t build (see above).' }
    Step "Nothing was committed, tagged, pushed or released (-WhatIf). The file is $file"; exit 0
}

# ---- 5. push and the GitHub release
[void](Invoke-Git @('push', '--atomic', 'origin', 'main', $Tag))
Step "Pushed main and $Tag"
$notesFile = Join-Path $env:TEMP ("cd-notes-" + [Guid]::NewGuid().ToString('N') + '.md')
try {
    [IO.File]::WriteAllText($notesFile, "$notes`n")
    $ErrorActionPreference = 'Continue'
    $r = & gh release create $Tag $file --repo $GhRepo --title "Computer Doctor $Version" --notes-file $notesFile --verify-tag --latest 2>&1
    if ($LASTEXITCODE -ne 0) { Stop-Release "gh release create failed: $r (the tag is pushed; run gh release create by hand)" }
} finally { Remove-Item -LiteralPath $notesFile -Force -ErrorAction SilentlyContinue }
Step "Released $Tag. SauceStore lists it within about 10 minutes."

# ---- 6. the app listing, from the same script
if ($ScriptOnly) { Write-Warning "Only the script was released. Release the app with: ..\ComputerDoctor-SauceEdition\tools\Release.ps1 -Version $Version"; exit 0 }
if ((Invoke-AppRelease @()) -ne 0) {
    Write-Host "The script $Tag is released, but Computer Doctor (Sauce Edition) isn't. Fix the problem above, then run ..\ComputerDoctor-SauceEdition\tools\Release.ps1 -Version $Version" -ForegroundColor Red
    exit 1
}
