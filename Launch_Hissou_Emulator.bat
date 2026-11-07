@echo off
title Hissou Launcher
echo ========================================================
echo               HISSOU APP LAUNCHER
echo ========================================================
echo.
echo [1/2] Opening Android Emulator window (Pixel_API_34)...
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd Pixel_API_34

echo Waiting for emulator to connect...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" wait-for-device

echo.
echo [2/2] Running Flutter App with Hot Reload...
cd /d "%~dp0"
flutter run -d emulator-5554
pause
