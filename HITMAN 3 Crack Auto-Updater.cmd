@echo off
rem ===================
rem boilerplate
rem ===================
set "PathExt=.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC"

set "SysPath=%SystemRoot%\System32"
set "Path=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)

set "ComSpec=%SysPath%\cmd.exe"
set "PSModulePath=%ProgramFiles%\WindowsPowerShell\Modules;%SysPath%\WindowsPowerShell\v1.0\Modules"

>nul fltmc || (
echo Right click on this script and run it as administrator.
pause
exit
)

rem ===================
rem config
rem ===================

set "ZIP_URL=https://github.com/thecatontheceiling/autoupdate/releases/latest/download/Release.zip"
set "TEMP_DIR=C:\TempAutoUpdater"
set "DEFAULT_DIR=C:\Program Files (x86)\Steam\steamapps\common\HITMAN 3"

rem ===================
rem determine install directory
rem ===================
set "INSTALL_DIR="

call :CheckFileExists "%DEFAULT_DIR%\steamclient64.dll"
if %ERRORLEVEL%==0 (
    set "INSTALL_DIR=%DEFAULT_DIR%"
) ELSE (
    echo.
    echo Custom game install directory detected.
    set /p "USER_DIR=Please enter the path where you installed the game: "
    set "USER_DIR=%USER_DIR:~0,-1%"
    call :CheckFileExists "%USER_DIR%\steamclient64.dll"
    if %ERRORLEVEL$==0 (
        set "INSTALL_DIR=%USER_DIR%"
    ) else (
        echo.
        echo Error: The directory you specified either doesn't contain the game or you currently do not have the the crack installed. If so, please follow the install guide instead of using this script.
        echo You can find the guide here: https://rentry.co/hitman3piracy
        pause
        exit /b 1
    )
)

echo.
echo Installation directory found: "%INSTALL_DIR%"
cd /d "%INSTALL_DIR%" || (
    echo Error: Failed to change directory to "%INSTALL_DIR%".
    pause
    exit /b 1
)

rem ===================
rem backup user saves
rem ===================

echo.
echo Backing up user data...

set "TIMESTAMP=%DATE:/=-%_%TIME::=-%"
set "BACKUP_DIR=%INSTALL_DIR%\backup_%TIMESTAMP%"
mkdir "%BACKUP_DIR%" || (
    echo Error: Failed to create backup directory "%BACKUP_DIR%".
    pause
    exit /B 1
)

call :BackupFolder "Peacock\userdata"
call :BackupFolder "Peacock\contractSessions"

call :BackupFolder "steam_saves"

echo User data backed up successfully to "%BACKUP_DIR%".

rem ===================
rem download and extract update
rem ===================

echo.
echo Downloading the latest update...

if exist "%TEMP_DIR%" (
    echo Clearing existing temporary directory...
    rd /s /q "%TEMP_DIR%" || (
        echo Error: Failed to remove existing temporary directory "%TEMP_DIR%".
        pause
        exit /b 1
    )
)
mkdir "%TEMP_DIR%" || (
    echo Error: Failed to create temporary directory "%TEMP_DIR%".
    pause
    exit /b 1
)

echo Downloading update from "%ZIP_URL%"...
powershell -Command "try { Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%TEMP_DIR%\update.zip' -ErrorAction Stop } catch { Write-Error $_.Exception.Message; exit 1 }"
if ERRORLEVEL 1 (
    echo Error: Failed to download the update.
    pause
    exit /b 1
)

echo Extracting the update...
PowerShell -Command "try { Expand-Archive -Path '%TEMP_DIR%\update.zip' -DestinationPath '%TEMP_DIR%\extracted' -Force -ErrorAction Stop } catch { Write-Error $_.Exception.Message; exit 1 }"
if ERRORLEVEL 1 (
    echo Error: Failed to extract the update.
    pause
    exit /b 1
)

Update downloaded and extracted successfully.

rem ===================
rem update files
rem ===================

echo.
echo Updating the crack...

set "ITEMS=Peacock steam_saves ColdClientLoader.ini HITMAN 3 Launcher.cmd Launcher.exe steamclient.dll steamclient_loader_x64.exe steamclient64.dll"

for %%I in (%ITEMS%) do (
    call :ReplaceFiles "%%I"
)

echo Files replaced successfully.

rem ===================
rem restore user data
rem ===================

echo.
echo Restoring user data...

call :RestoreFolder "Peacock\userdata"
call :RestoreFolder "Peacock\contractSessions"

call :RestoreFolder "steam_saves"

echo User data restored successfully.

rem ===================
rem cleanup temp files
rem ===================

echo.
echo Cleaning up temporary files...
rd /s /q "%TEMP_DIR%" || (
    echo Warning: Failed to remove temporary directory "%TEMP_DIR%".
)

echo Temporary files cleaned up.


echo.
echo Update completed successfully! Make sure the game files themselves are updated using steam, after that you can play the game as normal.
echo You can keep using this script everytime I release a new update for the crack.
pause
exit /b 0

rem ===================
rem check existence of file helper func
rem ===================
:CheckFileExists
    if exist "%~1" exit /b 0
    exit /b 1
rem ============================

rem folder backup helper func
:BackupFolder
    if exist "%INSTALL_DIR%\%~1" (
        robocopy "%INSTALL_DIR%\%~1" "%BACKUP_DIR%\%~1" /e /copyall /R:3 /W:5
        if ERRORLEVEL 8 (
            echo Error: Failed to backup folder "%~1".
            pause
            exit /b 1
        )
    ) else (
        echo Warning: Folder "%~1" does not exist and will be skipped.
    )
    exit /B 0
rem ============================

rem ===================
rem replace files helper func
rem ===================
:ReplaceFiles
    if exist "%TEMP_DIR%\extracted\%~1" (
        copy /y "%TEMP_DIR%\extracted\%~1" "%INSTALL_DIR%\%~1"
        if ERRORLEVEL 8 (
            echo Error: Failed to replace "%~1".
            pause
            exit /b 1
        )
    ) else (
        echo Warning: Update folder "%~1" does not exist in the update package and will be skipped.
    )
    exit /b 0
rem ============================

rem ===================
rem restore folder helper func
rem ===================
:RestoreFolder
    if exist "%BACKUP_DIR%\%~1" (
        robocopy "%BACKUP_DIR%\%~1" "%INSTALL_DIR%\%~1" /e /copyall /R:3 /W:5
        if ERRORLEVEL 8 (
            echo Error: Failed to restore folder "%~1".
            pause
            exit /b 1
        )
    ) else (
        echo Warning: Backup folder "%~1" does not exist and cannot be restored.
    )
    exit /b 0
rem ============================