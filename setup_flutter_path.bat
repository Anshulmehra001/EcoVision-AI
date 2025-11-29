@echo off
REM Setup Flutter PATH for D: drive installation
REM Run this AFTER extracting Flutter to D:\flutter

echo ========================================
echo Flutter PATH Setup for D: Drive
echo ========================================
echo.

REM Check if Flutter exists on D: drive
if not exist "D:\flutter\bin\flutter.bat" (
    echo [ERROR] Flutter not found at D:\flutter
    echo.
    echo Please:
    echo 1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows
    echo 2. Extract the ZIP to D:\ (so you have D:\flutter\bin\flutter.bat)
    echo 3. Run this script again
    echo.
    pause
    exit /b 1
)

echo [SUCCESS] Flutter found at D:\flutter
echo.

REM Add to PATH for current session
set PATH=%PATH%;D:\flutter\bin
echo [INFO] Added D:\flutter\bin to PATH for this session
echo.

REM Add to user PATH permanently
echo [INFO] Adding to permanent PATH...
setx PATH "%PATH%;D:\flutter\bin"

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo IMPORTANT: Close this window and open a NEW PowerShell window
echo.
echo Then verify installation:
echo   flutter --version
echo.
echo Then build your APK:
echo   cd "D:\EcoVision mobile"
echo   flutter pub get
echo   flutter build apk --debug
echo.
pause
