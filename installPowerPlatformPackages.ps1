Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2102613" -OutFile Setup.Microsoft.PowerAutomate.exe
.\Setup.Microsoft.PowerAutomate.exe -Silent -Install -ACCEPTEULA

Invoke-WebRequest "https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe" -OutFile PBIDesktopSetup_x64.exe
.\PBIDesktopSetup_x64.exe -silent -norestart ACCEPT_EULA=1

Install-PackageProvider -Name NuGet -Force
Install-Module PSWindowsUpdate -Confirm:$False -Force
Import-Module PSWindowsUpdate
Install-WindowsUpdate -AcceptAll -AutoReboot
