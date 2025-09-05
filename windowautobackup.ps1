# Backup important files from C: to D:
$source = "C:\Users\YourUser\Documents"
$destination = "D:\Backup\Documents"
Copy-Item -Path $source -Destination $destination -Recurse -Force
Write-Host "Backup complete."
