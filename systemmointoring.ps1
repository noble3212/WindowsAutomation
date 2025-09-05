# Define refresh interval in seconds
$refreshInterval = 1

# Function to display CPU usage per core and overall CPU usage
function Get-CPUUsage {
    $cpuUsage = Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty LoadPercentage
    $cpuCount = (Get-WmiObject -Class Win32_Processor).Count
    $cpuUsageText = "CPU Usage (per core):"
    
    $totalCpuUsage = 0
    $cpuUsageText += "`n"
    for ($i = 0; $i -lt $cpuCount; $i++) {
        $cpuUsageText += "Core $($i + 1): $($cpuUsage[$i])%`n"
        $totalCpuUsage += $cpuUsage[$i]
    }

    # Calculate the total CPU usage as the average across all cores
    $totalCpuUsage = [math]::round($totalCpuUsage / $cpuCount, 2)
    $cpuUsageText += "`nTotal CPU Usage: $totalCpuUsage%"
    
    return $cpuUsageText
}

# Function to display RAM usage (in GB)
function Get-RAMUsage {
    $ram = Get-WmiObject -Class Win32_OperatingSystem
    $totalMemory = [math]::round($ram.TotalVisibleMemorySize / 1KB / 1024, 2)   # Convert to GB (in Kilobytes)
    $freeMemory = [math]::round($ram.FreePhysicalMemory / 1KB / 1024, 2)         # Convert to GB (in Kilobytes)
    $usedMemory = $totalMemory - $freeMemory
    $memoryUsagePercent = [math]::round(($usedMemory / $totalMemory) * 100, 2)

    return "RAM Usage: $usedMemory GB / $totalMemory GB ($memoryUsagePercent%)"
}

# Function to display disk usage and health
function Get-DiskUsage {
    $disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }   # Only local disks

    $diskInfo = ""
    foreach ($disk in $disks) {
        $diskSize = [math]::round($disk.Size / 1GB, 2)    # Size in GB
        $diskFree = [math]::round($disk.FreeSpace / 1GB, 2) # Free space in GB
        $diskUsed = $diskSize - $diskFree
        $diskUsagePercent = [math]::round(($diskUsed / $diskSize) * 100, 2)
        $diskInfo += "Drive $($disk.DeviceID): $diskUsed GB / $diskSize GB ($diskUsagePercent%) - Free: $diskFree GB`n"
        
        # Get disk health info (Temperature, Status, etc.)
        $diskHealth = Get-WmiObject -Class Win32_PhysicalMedia | Where-Object { $_.Tag -eq $disk.DeviceID }
        $diskHealthStatus = if ($diskHealth) { $diskHealth.HealthStatus } else { "Unknown" }
        $diskInfo += "Health Status: $diskHealthStatus`n"
    }
    return $diskInfo
}

# Function to display GPU usage
function Get-GPUUsage {
    $gpuInfo = Get-WmiObject -Class Win32_VideoController
    $gpuUsage = ""
    foreach ($gpu in $gpuInfo) {
        $gpuUsage += "GPU: $($gpu.Name) - GPU Load: N/A (No direct query available via WMI)`n"
        $gpuUsage += "GPU Memory: $([math]::round($gpu.AdapterRAM / 1MB, 2)) MB`n"
    }
    return $gpuUsage
}

# Function to display Network usage (Send/Receive bytes)
function Get-NetworkUsage {
    $networkInfo = Get-WmiObject -Class Win32_NetworkAdapterStatistics | Where-Object { $_.Name -notlike "*Virtual*" }
    $networkStats = ""

    foreach ($network in $networkInfo) {
        $networkStats += "Network: $($network.Name)`n"
        $networkStats += "Sent: $([math]::round($network.BytesSent / 1MB, 2)) MB | Received: $([math]::round($network.BytesReceived / 1MB, 2)) MB`n"
    }
    
    return $networkStats
}

# Function to display process CPU and RAM usage
function Get-ProcessUsage {
    $processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
    $processInfo = "Top 5 Processes by CPU Usage:`n"
    
    foreach ($proc in $processes) {
        $cpuUsage = [math]::round($proc.CPU, 2)
        $ramUsage = [math]::round($proc.WorkingSet / 1MB, 2)
        $processInfo += "$($proc.Name) - CPU: $cpuUsage% | RAM: $ramUsage MB`n"
    }
    return $processInfo
}

# Function to display system monitoring in a loop
function Monitor-System {
    Clear-Host
    Write-Host "Real-time System Monitoring - CPU, RAM, Disk, GPU, Network, and Processes"
    Write-Host "------------------------------------------------------"
    
    while ($true) {
        # Get the real-time system data
        $cpuUsage = Get-CPUUsage
        $ramUsage = Get-RAMUsage
        $diskUsage = Get-DiskUsage
        $gpuUsage = Get-GPUUsage
        $networkUsage = Get-NetworkUsage
        $processUsage = Get-ProcessUsage
        
        # Display the information
        Write-Host "`n$cpuUsage"
        Write-Host "`n$ramUsage"
        Write-Host "`n$diskUsage"
        Write-Host "`n$gpuUsage"
        Write-Host "`n$networkUsage"
        Write-Host "`n$processUsage"
        
        # Sleep for a refresh interval
        Start-Sleep -Seconds $refreshInterval
    }
}

# Start monitoring the system
Monitor-System

