# Elevation
param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (Test-Admin)) {
    if ($elevated) {
        # tried to elevate, did not work, aborting
        echo "Failed to run with elevated privilege. Please install WSL manually."
    }
    else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

$ErrorActionPreference = "Stop"

if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
    echo "> Only x86_64 system is supported."
    pause
    exit 1
}

$wininfo = Get-ComputerInfo

$winversion = [int]$wininfo.OsBuildNumber

if ($winversion -lt 14393) {
    echo "> Your system is too old. Please update to a newer Windows 10/11."
    pause
    exit 1
}

$wslversion = 1
if ($winversion -ge 18362) {
    if ($wininfo.HyperVRequirementVirtualizationFirmwareEnabled) {
        $wslversion = 2
    }
    else {
        echo "> Your system supports WSL2, but VT is not enabled. Continue with WSL1."
        pause
    }
}

if (Get-Command "wsl.exe" -ErrorAction SilentlyContinue) {
    $ProgressPreference = 'SilentlyContinue'

    echo "> Downloading rootfs..."

    Invoke-WebRequest -uri https://meow.plus/physics-data/wsl.tar.zip -OutFile C:\wsl.tar.zip

    echo "> Importing rootfs..."

    Expand-Archive -Path C:\wsl.tar.zip -DestinationPath C:\physics-data-wsl
    del C:\wsl.tar.zip

    wsl.exe --import physics-data-wsl C:\physics-data-wsl C:\physics-data-wsl\rootfs.tar --version $wslversion
    del C:\physics-data-wsl\rootfs.tar

    echo "> Installation completed. Please use Windows Terminal to access WSL distro"
    echo "> Alternatively, run 'wsl.exe -d physics-data-wsl'"
}
else {
    echo "> wsl.exe not found. Enabling WSL feature..."

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

    echo "> WSL enabled. Please restart computer manually, and execute this script again."
}

pause
