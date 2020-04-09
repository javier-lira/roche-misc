Expand-Archive -LiteralPath OpenSSH-Win64.zip -DestinationPath "C:\Program Files"
Rename-Item "C:\Program Files\OpenSSH-Win64" "C:\Program Files\OpenSSH"
powershell.exe -ExecutionPolicy Bypass -File "C:\Program Files\OpenSSH\install-sshd.ps1"
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
Set-Service sshd -StartupType Automatic
New-Item –Path "HKLM:\SOFTWARE" –Name OpenSSH
Set-Itemproperty -path 'HKLM:\SOFTWARE\OpenSSH' -Name 'DefaultShell' -value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
net start sshd
