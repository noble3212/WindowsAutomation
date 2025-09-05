# Define the backup folder for system information and logs
$backupFolder = "C:\BackupLogs"
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$backupDestination = "$backupFolder\SystemReport_$timestamp"

# Create the backup destination folder if it doesn't exist
New-Item -ItemType Directory -Force -Path $backupDestination

# Generate System Information Report (like systeminfo)
$systemInfoFile = "$backupDestination\SystemInfo.txt"
systeminfo > $systemInfoFile
Write-Host "System information report saved to $systemInfoFile"

# Collect Windows Event Logs
$eventLogs = @("Application", "System", "Security")

foreach ($log in $eventLogs) {
    $eventLogFile = "$backupDestination\$log-EventLog.txt"
    
    # Collect the last 1000 events from each log (you can adjust the number)
    Get-WinEvent -LogName $log -MaxEvents 1000 | Select-Object TimeCreated, LevelDisplayName, Message | Format-Table -AutoSize > $eventLogFile
    Write-Host "$log event log saved to $eventLogFile"
}

Write-Host "Full system logs and information report generated and saved to $backupDestination"
