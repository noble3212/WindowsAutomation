# Example: PowerShell script to automate file integrity and system health checks

# Run SFC scan
Write-Host "Running SFC scan..."
sfc /scannow

# Run DISM tool to fix Windows image
Write-Host "Running DISM tool..."
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth

# Check disk (optional, if you'd like to add this to your script)
Write-Host "Running Check Disk..."
chkdsk C: /f /r

# Check for Windows Update issues
Write-Host "Checking for Windows Update issues..."
Get-WindowsUpdateLog

# List all drivers and check their status
Write-Host "Listing all drivers..."
Get-WmiObject Win32_PnPSignedDriver | Select-Object DeviceName, DriverVersion, DriverDate | Format-Table -AutoSize

# Check Event Logs for recent errors
Write-Host "Checking recent event logs..."
Get-WinEvent -LogName System | Where-Object { $_.LevelDisplayName -eq "Error" } | Select-Object TimeCreated, Message | Format-Table -AutoSize

# Check system for disk usage (example check for possible storage issues)
Write-Host "Checking disk usage..."
Get-PSDrive -PSProvider FileSystem

