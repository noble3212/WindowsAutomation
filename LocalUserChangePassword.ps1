# Change password for a user
Set-LocalUser -Name "UserName" -Password (ConvertTo-SecureString "NewPassword123" -AsPlainText -Force)
Write-Host "Password changed for UserName."
