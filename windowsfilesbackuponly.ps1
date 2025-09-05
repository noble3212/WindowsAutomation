# Define source and destination paths
$sourcePath = "C:\"
$backupPath = "D:\WindowsBackup"
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$backupDestination = "$backupPath\Backup_$timestamp"

# Create backup destination folder
New-Item -ItemType Directory -Force -Path $backupDestination

# List of important directories to back up
$directoriesToBackup = @(
    "C:\Users",         # User data (Documents, Pictures, etc.)
    "C:\Windows",       # System files (careful with permissions)
    "C:\ProgramData",   # Program data (application settings, etc.)
    "C:\Program Files", # Installed programs
    "C:\Program Files (x86)", # 32-bit installed programs
    "C:\Users\Public"   # Public folders (shared files)
)

# Loop through each directory and copy it to backup location
foreach ($directory in $directoriesToBackup) {
    if (Test-Path $directory) {
        $destination = "$backupDestination\$($directory.Substring(3).Replace("\", "_"))"
        Write-Host "Backing up $directory to $destination..."
        try {
            # Copy the directory recursively, preserve permissions
            Copy-Item -Path $directory -Destination $destination -Recurse -Force -Verbose
            Write-Host "$directory backed up successfully."
        } catch {
            Write-Host "Error backing up $directory: $_"
        }
    } else {
        Write-Host "$directory not found, skipping."
    }
}

# Optionally back up the registry (this will back up the SYSTEM and SOFTWARE hives)
$regBackupPath = "$backupDestination\RegistryBackup"
New-Item -ItemType Directory -Force -Path $regBackupPath
Write-Host "Backing up system registry..."
reg export HKLM\SYSTEM "$regBackupPath\SYSTEM.reg" /y
reg export HKLM\SOFTWARE "$regBackupPath\SOFTWARE.reg" /y

Write-Host "Registry backed up successfully."

# Optionally, you can back up the entire drive using a method like robocopy, but be cautious:
# robocopy C:\ $backupDestination /MIR /COPYALL /R:3 /W:5

Write-Host "Backup process completed. All files are saved in $backupDestination."
