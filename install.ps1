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
echo "> Enabling WSL feature..."

dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

$ProgressPreference = 'SilentlyContinue'

echo "> Downloading rootfs..."

Invoke-WebRequest -uri https://meow.plus/physics-data/wsl.tar.zip -OutFile C:\wsl.tar.zip

echo "> Importing rootfs..."

Expand-Archive -Path C:\wsl.tar.zip -DestinationPath C:\wsl.tar
del C:\wsl.tar.zip

wsl.exe --import physics-data-wsl C:\physics-data-wsl C:\wsl.tar --version 2
del C:\wsl.tar

echo "> Installation completed. Please use Windows Terminal to access WSL distro"
echo "> Alternatively, run 'wsl.exe -d physics-data-wsl'"
