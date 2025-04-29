@echo off
setlocal enabledelayedexpansion

:: Set default path to adb from Android Studio
set ADB_PATH=%USERPROFILE%\AppData\Local\Android\Sdk\platform-tools\adb.exe

:: Check if adb.exe exists
if not exist "%ADB_PATH%" (
    echo [ERROR] ADB not found at default location:
    echo %ADB_PATH%
    echo Please install Android Studio or update the ADB path in this script.
    pause
    exit /b
)

:: Check for connected devices
echo Checking for connected device...
"%ADB_PATH%" devices >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] ADB failed to run.
    pause
    exit /b
)

:: Extract the first connected device's serial number
set DEVICE=
for /f "skip=1 tokens=1,2" %%i in ('"%ADB_PATH%" devices') do (
    if "%%j"=="device" (
        set DEVICE=%%i
    )
)

:: Validate that a proper device was found
if "!DEVICE!"=="" (
    echo [ERROR] No valid device found.
    pause
    exit /b
)

echo Device found: !DEVICE!

:: Check if Shizuku is already running
echo Checking if Shizuku is already authorized...
"%ADB_PATH%" shell ps | findstr /i "moe.shizuku.privileged.api" >nul 2>&1

if %errorlevel% equ 0 (
    echo Shizuku is already authorized on !DEVICE!.
) else (
    echo Shizuku is not authorized. Authorizing now...

    :: Optional: Restart Shizuku to ensure clean launch
    "%ADB_PATH%" shell am force-stop moe.shizuku.privileged.api >nul 2>&1

    :: Capture the output of the start script
    "%ADB_PATH%" shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh > temp_shizuku_output.txt

    :: Check for success output explicitly
    findstr /i "shizuku_starter exit with 0" temp_shizuku_output.txt >nul
    if %errorlevel% equ 0 (
        echo Shizuku started successfully!
    ) else (
        echo [WARNING] Script executed, but couldn't verify success from output.
        echo Here's what the script returned:
        type temp_shizuku_output.txt
    )

    :: Cleanup
    del temp_shizuku_output.txt >nul 2>&1
)
echo Check in the app to see if it worked
pause
exit /b