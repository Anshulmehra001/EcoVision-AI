@echo off
echo ========================================
echo ECOVISION AI - BUILD APK
echo ========================================
echo.

REM Set Java path
set JAVA_HOME=D:\jdk-17.0.13+11
set PATH=%JAVA_HOME%\bin;D:\flutter\flutter_windows_3.38.3-stable\flutter\bin;%PATH%

REM Set Gradle options to fix SSL issues
set GRADLE_OPTS=-Djavax.net.ssl.trustStoreType=Windows-ROOT

echo Checking Java...
java -version
if errorlevel 1 (
    echo ERROR: Java not found!
    echo Please install Java JDK 17 to D:\jdk-17.0.13+11
    pause
    exit /b 1
)

echo.
echo Checking Flutter...
flutter --version
if errorlevel 1 (
    echo ERROR: Flutter not found!
    echo Please install Flutter to D:\flutter\flutter_windows_3.38.3-stable\flutter
    pause
    exit /b 1
)

echo.
echo Cleaning previous build...
flutter clean

echo.
echo Getting dependencies...
flutter pub get

echo.
echo Building APK (this takes 3-5 minutes)...
flutter build apk --release

if errorlevel 1 (
    echo.
    echo ========================================
    echo BUILD FAILED!
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo BUILD SUCCESSFUL!
echo ========================================
echo.

REM Copy and rename APK
copy "build\app\outputs\flutter-apk\app-release.apk" "build\app\outputs\flutter-apk\EcoVision-AI-v1.2.apk"

echo APK Location: build\app\outputs\flutter-apk\
echo.
dir "build\app\outputs\flutter-apk\*.apk" | findstr /i ".apk"

echo.
echo ========================================
echo DONE! Install the APK on your device.
echo ========================================
pause
