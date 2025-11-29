@echo off
REM EcoVision AI - Automated Build Script
REM A VIREN Legacy Project by Aniket Mehra

echo.
echo ========================================
echo EcoVision AI - Build Script
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter SDK not found in PATH
    echo.
    echo Please install Flutter SDK from:
    echo https://flutter.dev/docs/get-started/install
    echo.
    echo After installation, add Flutter to your PATH and try again.
    pause
    exit /b 1
)

echo [INFO] Flutter SDK found
flutter --version
echo.

REM Step 1: Get dependencies
echo ========================================
echo Step 1: Installing Dependencies
echo ========================================
echo.
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to get dependencies
    pause
    exit /b 1
)
echo [SUCCESS] Dependencies installed
echo.

REM Step 2: Analyze code
echo ========================================
echo Step 2: Analyzing Code
echo ========================================
echo.
flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Code analysis found issues
    echo Continue anyway? (Y/N)
    set /p continue=
    if /i not "%continue%"=="Y" exit /b 1
)
echo [SUCCESS] Code analysis complete
echo.

REM Step 3: Check for keystore
echo ========================================
echo Step 3: Checking Build Configuration
echo ========================================
echo.

if not exist "android\key.properties" (
    echo [WARNING] android\key.properties not found
    echo.
    echo For RELEASE build, you need to:
    echo 1. Create keystore: scripts\setup_keystore.bat
    echo 2. Configure signing: copy android\key.properties.template android\key.properties
    echo 3. Edit android\key.properties with your passwords
    echo.
    echo Do you want to build DEBUG version instead? (Y/N)
    set /p debug=
    if /i "%debug%"=="Y" goto build_debug
    echo.
    echo Please set up keystore and signing, then run this script again.
    pause
    exit /b 1
)

if not exist "android\keystore\ecovisionai-release.jks" (
    echo [WARNING] Keystore file not found
    echo.
    echo Please create keystore first: scripts\setup_keystore.bat
    echo.
    echo Do you want to build DEBUG version instead? (Y/N)
    set /p debug=
    if /i "%debug%"=="Y" goto build_debug
    pause
    exit /b 1
)

echo [SUCCESS] Build configuration found
echo.

REM Step 4: Choose build type
echo ========================================
echo Step 4: Choose Build Type
echo ========================================
echo.
echo 1. Debug APK (for testing)
echo 2. Release APK (for distribution)
echo 3. Release App Bundle (for Play Store)
echo 4. Split APKs by architecture (smaller size)
echo.
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto build_debug
if "%choice%"=="2" goto build_release
if "%choice%"=="3" goto build_bundle
if "%choice%"=="4" goto build_split

echo [ERROR] Invalid choice
pause
exit /b 1

:build_debug
echo.
echo ========================================
echo Building Debug APK
echo ========================================
echo.
flutter build apk --debug
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
echo.
echo [SUCCESS] Debug APK built successfully!
echo.
echo Location: build\app\outputs\flutter-apk\app-debug.apk
echo.
echo To install on device: flutter install --debug
echo Or: adb install build\app\outputs\flutter-apk\app-debug.apk
goto end

:build_release
echo.
echo ========================================
echo Building Release APK
echo ========================================
echo.
flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
echo.
echo [SUCCESS] Release APK built successfully!
echo.
echo Location: build\app\outputs\flutter-apk\app-release.apk
echo.
echo APK is ready for distribution!
goto end

:build_bundle
echo.
echo ========================================
echo Building App Bundle
echo ========================================
echo.
flutter build appbundle --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
echo.
echo [SUCCESS] App Bundle built successfully!
echo.
echo Location: build\app\outputs\bundle\release\app-release.aab
echo.
echo Upload this file to Google Play Console
goto end

:build_split
echo.
echo ========================================
echo Building Split APKs
echo ========================================
echo.
flutter build apk --release --split-per-abi
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
echo.
echo [SUCCESS] Split APKs built successfully!
echo.
echo Location: build\app\outputs\flutter-apk\
echo   - app-armeabi-v7a-release.apk (32-bit ARM)
echo   - app-arm64-v8a-release.apk (64-bit ARM)
echo   - app-x86_64-release.apk (64-bit Intel)
echo.
echo Each APK is optimized for specific architecture
goto end

:end
echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Test the APK on a device
echo 2. Verify all features work correctly
echo 3. Check performance and battery usage
echo 4. Review DEPLOYMENT_CHECKLIST.md before release
echo.
pause
