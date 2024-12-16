REM Run the installer silently with full options
set InstallerName=%1
set InstallSrcPath=%2
set InstallTargetPath=%3
set InstallTargetPathLog=%1.log


echo Installing package name %InstallerName%...
"%InstallSrcPath%" /S /D=%InstallTargetPath% /verbose > "%InstallTargetPathLog%" 2>&1

REM Display the log file content
echo ============================================================
type "%InstallTargetPathLog%"
echo ============================================================