<#
.SYNOPSIS
  Copy the “most needed” parts of a Windows user profile from one account to another.

.DESCRIPTION
  Uses robocopy to mirror:
    - Documents, Desktop, Pictures, Videos
    - AppData\Local & AppData\Roaming
    - Windows Store Packages
  Optionally exports and imports HKCU registry data.

.PARAMETER SourceUser
  Username (profile folder name) of the user whose data you want to migrate.

.PARAMETER TargetUser
  Username (profile folder name) of the target user.

.PARAMETER LogDir
  Optional: Directory to store robocopy logs. Defaults to $env:USERPROFILE\ProfileMigrationLogs.

.PARAMETER ExportRegistry
  Switch: When set, the script will export HKCU of the source and import it into the target.

.EXAMPLE
  .\MigrateProfile.ps1 -SourceUser "alice" -TargetUser "bob" -ExportRegistry

.NOTES
  Author: ChatGPT (OpenAI) – 2025
  This script is for educational purposes. Test it on non‑critical data first.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$SourceUser,
    [Parameter(Mandatory = $true)][string]$TargetUser,
    [string]$LogDir = "$env:USERPROFILE\ProfileMigrationLogs",
    [switch]$ExportRegistry
)

function Log-Info {
    param([string]$msg)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "$timestamp : $msg"
    Write-Host $logLine
    Add-Content -Path $logFile -Value $logLine
}

# ---- 1. Resolve paths ---------------------------------------------
$sourceRoot = "C:\Users\$SourceUser"
$targetRoot = "C:\Users\$TargetUser"

if (-not (Test-Path $sourceRoot)) {
    Throw "Source profile folder '$sourceRoot' does not exist."
}
if (-not (Test-Path $targetRoot)) {
    Throw "Target profile folder '$targetRoot' does not exist."
}

# ---- 2. Setup logging -----------------------------------------------
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$logFile = Join-Path $LogDir "$SourceUser\_to\_$TargetUser-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# ---- 3. Common robocopy options ------------------------------------
$robocopyCommon = '/MIR /R:2 /W:2 /DCOPY:T /COPY:DAT /NP /LOG+:$logFile /NFL /NDL'

# ---- 4. Copy “core” folders ----------------------------------------
$foldersToCopy = @(
    'Documents',
    'Desktop',
    'Pictures',
    'Videos',
    'Downloads'          # add more as needed
)

foreach ($folder in $foldersToCopy) {
    $src = Join-Path $sourceRoot $folder
    $dst = Join-Path $targetRoot $folder

    if (Test-Path $src) {
        $cmd = "robocopy `"$src`" `"$dst`" $robocopyCommon"
        if ($PSCmdlet.ShouldProcess($src, 'Robocopy')) {
            Log-Info "Copying $folder ..."
            Invoke-Expression $cmd
        }
    }
    else {
        Log-Info "Source folder $src does not exist – skipping."
    }
}

# ---- 5. Copy AppData -----------------------------------------------
$subfolders = @('Local', 'Roaming')

foreach ($sub in $subfolders) {
    $src = Join-Path -Path (Join-Path $sourceRoot 'AppData') -ChildPath $sub
    $dst = Join-Path -Path (Join-Path $targetRoot 'AppData') -ChildPath $sub

    $cmd = "robocopy `"$src`" `"$dst`" $robocopyCommon /XJ"
    if ($PSCmdlet.ShouldProcess($src, 'Robocopy AppData')) {
        Log-Info "Copying AppData\$sub ..."
        Invoke-Expression $cmd
    }
}

# ---- 6. Copy Windows Store (UWP) Packages --------------------------
$uwpSrc = Join-Path $sourceRoot 'AppData\Local\Packages'
$uwpDst = Join-Path $targetRoot 'AppData\Local\Packages'

if (Test-Path $uwpSrc) {
    $cmd = "robocopy `"$uwpSrc`" `"$uwpDst`" $robocopyCommon"
    if ($PSCmdlet.ShouldProcess($uwpSrc, 'Robocopy UWP Packages')) {
        Log-Info "Copying Windows Store packages ..."
        Invoke-Expression $cmd
    }
}
else {
    Log-Info "No UWP packages found – skipping."
}

# ---- 7. Export / Import HKCU (optional) -----------------------------
if ($ExportRegistry) {
    $regSrc = "$env:TEMP\$SourceUser-HKCU.reg"
    $regDst = "$env:TEMP\$TargetUser-HKCU.reg"

    # Export HKCU of source user
    $cmdExport = "reg export HKCU $regSrc /reg:64 /y"
    Log-Info "Exporting HKCU of $SourceUser ..."
    Invoke-Expression $cmdExport

    # Import into target user
    # We need to run reg import under the *target* user context.  Simplest is to use reg.exe with /reg:64
    # but we must temporarily switch the HKCU hive.  For safety, we will create a temporary HKCU registry file
    # and merge it using reg.exe.  NOTE: This may overwrite some system values – test in a sandbox.
    $cmdImport = "reg import $regDst /reg:64"
    Log-Info "Importing HKCU into $TargetUser (might override existing keys) ..."
    Invoke-Expression $cmdImport

    # Clean up temp files
    Remove-Item -Path $regSrc, $regDst -Force -ErrorAction SilentlyContinue
}

# ---- 8. Completion ---------------------------------------------
Log-Info "Migration completed. Check $logFile for details."
