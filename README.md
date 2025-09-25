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
# Windows user migration
This will automate the moving of windows profile to another user incase of profile corruption
how to use 
Make the script executable
.\MigrateProfile.ps1 -SourceUser alice -TargetUser bob -ExportRegistry
# windows user migration with robocopy 
Parallel Copy
Start-Job is used to fire off a robocopy job for every folder that needs to be mirrored. The jobs run concurrently on all available CPU cores.
UI Front‑End
A WinForms dialog asks the operator for Source and Target usernames (profile folder names) and lets the user pick whether to export the registry.
Backup First
Before anything is overwritten, the script creates a snapshot of the target profile in C:\Users\<Target>\ProfileBackup‑<timestamp>. The snapshot is made with robocopy /MIR.
Audit Report
After all jobs finish, the script parses the individual robocopy logs, pulls the numbers of Copied, Skipped, and Errors, and writes a single “audit” file in the same log directory. The audit file can be opened in Excel or a text editor.
# How It Works
 
UI – Show-MigrationForm builds the form and returns a hash with Source, Target and ExportReg.

Logging – Log-Info writes to both the console and the central log file.

Parallel Copy – Copy-Parallel builds a robocopy command with /LOG+:<LogFile> and starts it inside a background job.

Snapshot – A dedicated robocopy job mirrors the target profile to ProfileBackup‑<stamp>.

Jobs – All core folders, AppData subfolders, and UWP packages are queued as separate jobs.

Wait & Audit – Wait-Job blocks until all jobs finish, then the script counts Copied/Skipped/Errors from each log line, writes an audit CSV, and notifies you.

3. Running the Script
Open PowerShell as Administrator (Start‑Menu → PowerShell → Run as Administrator).
Navigate to the folder where you saved the script, e.g.:

cd C:\Scripts
.\ProfileMigration.ps1
