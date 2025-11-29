@echo off
REM EcoVision AI - Keystore Setup Script (Windows)
REM This script helps create a keystore for signing Android release builds

echo ==========================================
echo EcoVision AI - Keystore Setup
echo ==========================================
echo.

REM Check if keytool is available
where keytool >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: keytool not found. Please install Java JDK and add it to PATH.
    pause
    exit /b 1
)

REM Create keystore directory if it doesn't exist
if not exist "android\keystore" mkdir "android\keystore"

REM Check if keystore already exists
if exist "android\keystore\ecovisionai-release.jks" (
    echo Warning: Keystore already exists at android\keystore\ecovisionai-release.jks
    set /p OVERWRITE="Do you want to create a new one? This will overwrite the existing keystore. (y/N): "
    if /i not "%OVERWRITE%"=="y" (
        echo Aborted. Existing keystore preserved.
        pause
        exit /b 0
    )
)

echo Creating Android keystore for EcoVision AI...
echo.
echo You will be prompted to enter:
echo   1. Keystore password (remember this!)
echo   2. Key password (remember this!)
echo   3. Your name and organization details
echo.
echo IMPORTANT: Store these passwords securely!
echo.

REM Generate keystore
keytool -genkey -v -keystore android\keystore\ecovisionai-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ecovisionai-release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo Keystore created successfully!
    echo ==========================================
    echo.
    echo Next steps:
    echo 1. Copy android\key.properties.template to android\key.properties
    echo 2. Edit android\key.properties with your keystore passwords
    echo 3. NEVER commit key.properties or the keystore to version control
    echo 4. Keep a secure backup of your keystore file
    echo.
    echo To verify your keystore:
    echo   keytool -list -v -keystore android\keystore\ecovisionai-release.jks
    echo.
) else (
    echo.
    echo Error: Failed to create keystore
    pause
    exit /b 1
)

pause
