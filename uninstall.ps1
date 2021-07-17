echo "> Uninstalling..."

wsl.exe --shutdown
wsl.exe --unregister physics-data

del C:\physics-data-wsl

echo "> Uninstallation completed."
