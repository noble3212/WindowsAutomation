# Monitor event logs for errors
$events = Get-WinEvent -LogName System | Where-Object { $_.LevelDisplayName -eq "Error" }
if ($events.Count -gt 0) {
    Write-Host "Errors detected in event logs."
}
