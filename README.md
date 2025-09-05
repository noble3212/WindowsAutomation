# WindowsAutomation
These are some scripts to automate windows file check, event viewer mointoring. And back up a certain file location to another among anything else
Note with windows backup- it directs a certain folder to another location on a drive. Please note this will not backup windows- unless i make fullwindowsbackup script- which i will
# Windows auto check
It will check windows and scan for corruption. This will scan disks- please note this doesnt do disk optimization you only need to on HDDS
# Please note windows full backup is untested
it is different from windowsautobackup or windows file back up- Windows file backup will backup mainfiles like apps and downloads- You will not be able to restore windows from this
# Event Viewer watching ps1
Supposed to log directly to C drive- System autologs works a bit better for this-
# CVE scanner
Please note this can't seem to find CVES yet. This just acts as a proof of concept.
and badmalwarescanner is suppost to detect if there is any suspious activity. But, it will mainly sus yourself out. As it detects if there is a CMD window open among other things
# System mointor 
It has issues accurately descripting tasks- It assumes when an application uses more than 1 core. It's at 500%. Task manager is better
# Bot net scanner
This will scan for applications with few too many DNS queries- This is normal but if something other than microsoft comes up itll tell you
