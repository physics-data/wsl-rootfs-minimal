# Elevation
param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
        echo "Failed to run with elevated privilege. Please install WSL manually."
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

$ErrorActionPreference = "Stop"
echo "> Uninstalling..."

wsl.exe --shutdown
wsl.exe --unregister physics-data-wsl

Remove-Item -Recurse -Force C:\physics-data-wsl

echo "> Uninstallation completed."
