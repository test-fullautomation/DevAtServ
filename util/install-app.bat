REM Run the installer silently with full options
set InstallerName=%1
set InstallTargetPath=%2
set InstallTargetPathLog=%2.log


echo Installing package name %InstallerName%...
"%InstallerName%" /S /D=%InstallTargetPath% /verbose > "%InstallTargetPathLog%" 2>&1

REM Display the log file content
echo ============================================================
type "%InstallTargetPathLog%"
echo ============================================================