@echo off
echo Building EcoVision AI...
echo.

REM Clean previous build
flutter clean

REM Get dependencies
flutter pub get

REM Build release APK
flutter build apk --release

REM Create output directory
if not exist "output" mkdir output

REM Copy APK to output folder and root
copy "build\app\outputs\flutter-apk\app-release.apk" "output\ecovision-ai-v1.0.apk"
copy "build\app\outputs\flutter-apk\app-release.apk" "ecovision-ai-v1.0.apk"

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo APK Location 1: ecovision-ai-v1.0.apk
echo APK Location 2: output\ecovision-ai-v1.0.apk
echo.
echo Install command:
echo adb install ecovision-ai-v1.0.apk
echo ========================================
pause
