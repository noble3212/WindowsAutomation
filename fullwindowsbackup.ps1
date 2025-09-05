# Define the backup destination
$backupDestination = "D:\WindowsBackup"
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$backupFolder = "$backupDestination\Backup_$timestamp"

# Create the backup destination folder if it doesn't exist
New-Item -ItemType Directory -Force -Path $backupFolder

# Run the wbadmin tool to create a full system image backup
Write-Host "Starting system image backup..."
Start-Process -NoNewWindow -Wait -FilePath "wbadmin" -ArgumentList "start backup -backupTarget:$backupFolder -include:C: -allCritical -quiet"

Write-Host "System image backup completed successfully and saved to $backupFolder"
#please note this is untested
