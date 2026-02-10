@echo off
echo ========================================
echo COMPLETE GRADLE FIX FOR ECOVISION AI
echo ========================================
echo.

echo Step 1: Stopping all Java/Gradle processes...
taskkill /F /IM java.exe 2>nul
taskkill /F /IM gradle.exe 2>nul
taskkill /F /IM studio64.exe 2>nul
timeout /t 2 >nul

echo Step 2: Cleaning Flutter build cache...
call flutter clean
if errorlevel 1 (
    echo Warning: Flutter clean failed
)

echo Step 3: Removing local Android Gradle cache...
if exist "android\.gradle" (
    rd /s /q "android\.gradle"
    echo Removed android\.gradle
)

echo Step 4: Removing global Gradle cache (this may take a moment)...
if exist "%USERPROFILE%\.gradle\caches" (
    rd /s /q "%USERPROFILE%\.gradle\caches"
    echo Removed global Gradle cache
)

echo Step 5: Removing Gradle daemon...
if exist "%USERPROFILE%\.gradle\daemon" (
    rd /s /q "%USERPROFILE%\.gradle\daemon"
    echo Removed Gradle daemon
)

echo Step 6: Getting Flutter dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Flutter pub get failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo GRADLE CACHE CLEANED SUCCESSFULLY!
echo ========================================
echo.
echo Now building APK with fresh Gradle cache...
echo This will take 3-5 minutes on first build...
echo.

call flutter build apk --release

if errorlevel 1 (
    echo.
    echo ========================================
    echo BUILD FAILED!
    echo ========================================
    echo.
    echo Please try these steps:
    echo 1. Close Android Studio completely
    echo 2. Restart your computer
    echo 3. Run this script again
    echo.
    pause
    exit /b 1
) else (
    echo.
    echo ========================================
    echo BUILD SUCCESSFUL!
    echo ========================================
    echo.
    echo APK Location: build\app\outputs\flutter-apk\app-release.apk
    echo.
    
    if exist "build\app\outputs\flutter-apk\app-release.apk" (
        copy "build\app\outputs\flutter-apk\app-release.apk" "build\app\outputs\flutter-apk\EcoVision-AI-v1.2-BirdNET.apk"
        echo Copied to: EcoVision-AI-v1.2-BirdNET.apk
        echo.
        dir "build\app\outputs\flutter-apk\*.apk" | findstr /i ".apk"
    )
)

echo.
pause
