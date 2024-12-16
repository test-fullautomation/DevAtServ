REM Run the installer silently with full options
set InstallerName=%1
set InstallTargetPath=%2

echo Installing package name %InstallerName%...
"%InstallerName%" /D=%InstallTargetPath%