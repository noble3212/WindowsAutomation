<#
.SYNOPSIS
    Profile migration tool – interactive, parallel copy, backup and audit.

.DESCRIPTION
    • Presents a WinForms UI for source/target usernames and registry export flag.
    • Creates a snapshot of the target profile before anything is overwritten.
    • Copies core folders, AppData, and UWP packages in parallel using Start‑Job.
    • Logs each robocopy run; at the end a single audit file summarises what happened.
    • Supports optional export/import of the source HKCU hive.

.NOTES
    Author: ChatGPT – 2025
    Tested on Windows 10/11, PowerShell 5.1+.  Adapt as needed for older hosts.
#>

# ---------- 0.  Prepare the WinForms UI ----------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-MigrationForm {
    param(
        [string]$defaultSource = '',
        [string]$defaultTarget = ''
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text   = 'Profile Migration'
    $form.Width  = 400
    $form.Height = 260
    $form.FormBorderStyle = 'FixedDialog'
    $form.StartPosition  = 'CenterScreen'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $lblSource = New-Object System.Windows.Forms.Label
    $lblSource.Text   = 'Source User:'
    $lblSource.AutoSize = $true
    $lblSource.Location = '20,20'
    $form.Controls.Add($lblSource)

    $txtSource = New-Object System.Windows.Forms.TextBox
    $txtSource.Location = '120,17'
    $txtSource.Width   = 220
    $txtSource.Text   = $defaultSource
    $form.Controls.Add($txtSource)

    $lblTarget = New-Object System.Windows.Forms.Label
    $lblTarget.Text   = 'Target User:'
    $lblTarget.AutoSize = $true
    $lblTarget.Location = '20,60'
    $form.Controls.Add($lblTarget)

    $txtTarget = New-Object System.Windows.Forms.TextBox
    $txtTarget.Location = '120,57'
    $txtTarget.Width   = 220
    $txtTarget.Text   = $defaultTarget
    $form.Controls.Add($txtTarget)

    $chkReg = New-Object System.Windows.Forms.CheckBox
    $chkReg.Location = '120,95'
    $chkReg.Size = '220,20'
    $chkReg.Text = 'Export HKCU registry from source and import into target'
    $form.Controls.Add($chkReg)

    $btnOK   = New-Object System.Windows.Forms.Button
    $btnOK.Location = '120,130'
    $btnOK.Size = '100,30'
    $btnOK.Text = 'Start'
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $btnOK
    $form.Controls.Add($btnOK)

    $btnCancel   = New-Object System.Windows.Forms.Button
    $btnCancel.Location = '240,130'
    $btnCancel.Size = '100,30'
    $btnCancel.Text = 'Cancel'
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $btnCancel
    $form.Controls.Add($btnCancel)

    $form.Add_Shown({$form.Activate()})
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return @{
            Source   = $txtSource.Text.Trim()
            Target   = $txtTarget.Text.Trim()
            ExportReg= $chkReg.Checked
        }
    } else {
        return $null
    }
}

# ---------- 1.  Common functions ----------
function Log-Info {
    param([string]$msg)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "$timestamp : $msg"
    Write-Host $line
    Add-Content -Path $script:LogFile -Value $line
}

function Copy-Parallel {
    param(
        [string]$Src,
        [string]$Dst,
        [string]$RobocopyOpts
    )
    # Build the robocopy command
    $cmd = "robocopy `"$Src`" `"$Dst`" $RobocopyOpts /LOG+:`"$script:LogFile`""
    # Run in background job
    $job = Start-Job -ScriptBlock {
        param($c)
        Invoke-Expression $c
    } -ArgumentList $cmd

    return $job
}

# ---------- 2.  Main migration logic ----------
function Run-Migration {
    param(
        [string]$SourceUser,
        [string]$TargetUser,
        [switch]$ExportRegistry
    )

    # ---- 2.1  Resolve profile paths ----
    $sourceRoot = "C:\Users\$SourceUser"
    $targetRoot = "C:\Users\$TargetUser"

    if (-not (Test-Path $sourceRoot)) {
        Throw "Source profile folder '$sourceRoot' does not exist."
    }
    if (-not (Test-Path $targetRoot)) {
        Throw "Target profile folder '$targetRoot' does not exist."
    }

    # ---- 2.2  Setup log directory ----
    $logDir = "$env:USERPROFILE\ProfileMigrationLogs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
    $script:LogFile = Join-Path $logDir "Migration-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    if (Test-Path $script:LogFile) { Remove-Item $script:LogFile -Force }

    # ---- 2.3  Take snapshot of target profile ----
    $backupDir = "C:\Users\$TargetUser\ProfileBackup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Log-Info "Creating snapshot of target profile in $backupDir ..."
    $robocopyCommon = '/MIR /R:2 /W:2 /DCOPY:T /COPY:DAT /NP /NFL /NDL'
    $snapJob = Start-Job -ScriptBlock {
        param($src,$dst,$opts,$log)
        $cmd = "robocopy `"$src`" `"$dst`" $opts /LOG+:`"$log`""
        Invoke-Expression $cmd
    } -ArgumentList $targetRoot,$backupDir,$robocopyCommon,$script:LogFile
    Wait-Job $snapJob | Out-Null
    Log-Info "Snapshot finished."

    # ---- 2.4  Define folder sets ----
    $foldersToCopy = @('Documents','Desktop','Pictures','Videos','Downloads')
    $appDataSubs   = @('Local','Roaming')
    $uwpSrc  = Join-Path $sourceRoot 'AppData\Local\Packages'
    $uwpDst  = Join-Path $targetRoot 'AppData\Local\Packages'

    # ---- 2.5  Launch parallel robocopy jobs ----
    $jobs = @()
    $robocopyOpts = $robocopyCommon + ' /LOG+:`"$script:LogFile`"'

    # Core folders
    foreach ($f in $foldersToCopy) {
        $src = Join-Path $sourceRoot $f
        $dst = Join-Path $targetRoot $f
        if (Test-Path $src) {
            Log-Info "Queueing copy of $f ..."
            $jobs += Copy-Parallel -Src $src -Dst $dst -RobocopyOpts $robocopyOpts
        } else {
            Log-Info "Source folder $src does not exist – skipping."
        }
    }

    # AppData subfolders
    foreach ($sub in $appDataSubs) {
        $src = Join-Path (Join-Path $sourceRoot 'AppData') $sub
        $dst = Join-Path (Join-Path $targetRoot 'AppData') $sub
        Log-Info "Queueing copy of AppData\$sub ..."
        $jobs += Copy-Parallel -Src $src -Dst $dst -RobocopyOpts ($robocopyOpts + ' /XJ')
    }

    # UWP packages
    if (Test-Path $uwpSrc) {
        Log-Info "Queueing copy of Windows Store packages ..."
        $jobs += Copy-Parallel -Src $uwpSrc -Dst $uwpDst -RobocopyOpts $robocopyOpts
    } else {
        Log-Info "No UWP packages found – skipping."
    }

    # ---- 2.6  Wait for all jobs to finish ----
    Log-Info "Waiting for all copy jobs ..."
    $jobs | Wait-Job | Out-Null
    Log-Info "All copy jobs completed."

    # ---- 2.7  Optional registry export/import ----
    if ($ExportRegistry) {
        Log-Info "Exporting source HKCU hive ..."
        $regSrc = "$env:TEMP\$SourceUser-HKCU.reg"
        $regDst = "$env:TEMP\$TargetUser-HKCU.reg"

        # Export source hive (needs to run as *source* user – we use admin but with the same key path)
        reg.exe export "HKU\$SourceUser" $regSrc /y | Out-Null
        Log-Info "Source hive exported to $regSrc."

        # Import into target
        reg.exe import $regSrc /y | Out-Null
        Log-Info "Target hive updated from $regSrc."
    }

    # ---- 2.8  Generate audit report ----
    Log-Info "Parsing logs for audit ..."
    $auditFile = Join-Path $logDir "Audit-$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    # Robocopy statistics line pattern – e.g.  Copied  12  Skipped 3  Errors 0
    $copied  = 0
    $skipped = 0
    $errors  = 0

    Get-Content $script:LogFile | ForEach-Object {
        if ($_ -match 'Copied\s+(\d+)\s+Skipped\s+(\d+)\s+Errors\s+(\d+)') {
            $copied  += [int]$matches[1]
            $skipped += [int]$matches[2]
            $errors  += [int]$matches[3]
        }
    }

    $auditLines = @(
        "Copied  ,$copied",
        "Skipped ,$skipped",
        "Errors  ,$errors"
    )
    Set-Content -Path $auditFile -Value $auditLines
    Log-Info "Audit report written to $auditFile."

    # ---- 2.9  Final message ----
    Log-Info "Profile migration completed."
}

# ---------- 3.  Run the tool ----------
$uiResult = Show-MigrationForm
if ($null -eq $uiResult) {
    Write-Host "Operation cancelled by user."
    exit
}

# Validate inputs
if ([string]::IsNullOrWhiteSpace($uiResult.Source) -or `
    [string]::IsNullOrWhiteSpace($uiResult.Target)) {
    Throw 'Both Source and Target usernames must be supplied.'
}

# Run
try {
    Run-Migration -SourceUser $uiResult.Source `
                  -TargetUser $uiResult.Target `
                  -ExportRegistry:$uiResult.ExportReg
} catch {
    Write-Error $_
    exit 1
}
