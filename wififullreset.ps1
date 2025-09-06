# Release the current IP address
ipconfig /release

# Flush the DNS client resolver cache
ipconfig /flushdns

# Renew the IP address
ipconfig /renew

# Reset the TCP/IP stack
netsh int ip reset

# Reset the Winsock catalog
netsh winsock reset

# Reset WinHTTP proxy settings
netsh winhttp reset proxy

# Optional: Restart the network adapter (for changes to take effect)
Restart-NetAdapter -Name "Ethernet"  # Or replace "Ethernet" with the correct adapter name
