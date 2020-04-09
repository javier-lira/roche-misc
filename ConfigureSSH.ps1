Expand-Archive -LiteralPath OpenSSH-Win64.zip -DestinationPath "C:\Program Files"
Rename-Item "C:\Program Files\OpenSSH-Win64" "C:\Program Files\OpenSSH"
powershell.exe -ExecutionPolicy Bypass -File "C:\Program Files\OpenSSH\install-sshd.ps1"
Set-Service sshd -StartupType Automatic
Set-Itemproperty -path 'HKLM:\SOFTWARE\OpenSSH' -Name 'DefaultShell' -value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
net start sshd
