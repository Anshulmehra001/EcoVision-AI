@echo off
REM Script to find Java installation and keytool

echo Searching for Java installation...
echo.

REM Check if JAVA_HOME is set
if defined JAVA_HOME (
    echo JAVA_HOME is set to: %JAVA_HOME%
    if exist "%JAVA_HOME%\bin\keytool.exe" (
        echo Found keytool at: %JAVA_HOME%\bin\keytool.exe
        echo.
        echo You can use this command:
        echo "%JAVA_HOME%\bin\keytool.exe" -genkey -v -keystore android/keystore/ecovisionai-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ecovisionai-release -storepass ecovision2025 -keypass ecovision2025 -dname "CN=EcoVision AI, OU=VIREN Legacy, O=VIREN Legacy, L=Unknown, S=Unknown, C=US"
        exit /b 0
    )
)

REM Search common Java installation locations
if exist "C:\Program Files\Java" (
    echo Checking: C:\Program Files\Java
    for /d %%D in ("C:\Program Files\Java\*") do (
        if exist "%%D\bin\keytool.exe" (
            echo Found keytool at: %%D\bin\keytool.exe
            echo.
            echo You can use this command:
            echo "%%D\bin\keytool.exe" -genkey -v -keystore android/keystore/ecovisionai-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ecovisionai-release -storepass ecovision2025 -keypass ecovision2025 -dname "CN=EcoVision AI, OU=VIREN Legacy, O=VIREN Legacy, L=Unknown, S=Unknown, C=US"
            exit /b 0
        )
    )
)

if exist "C:\Program Files (x86)\Java" (
    echo Checking: C:\Program Files (x86)\Java
    for /d %%D in ("C:\Program Files (x86)\Java\*") do (
        if exist "%%D\bin\keytool.exe" (
            echo Found keytool at: %%D\bin\keytool.exe
            echo.
            echo You can use this command:
            echo "%%D\bin\keytool.exe" -genkey -v -keystore android/keystore/ecovisionai-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ecovisionai-release -storepass ecovision2025 -keypass ecovision2025 -dname "CN=EcoVision AI, OU=VIREN Legacy, O=VIREN Legacy, L=Unknown, S=Unknown, C=US"
            exit /b 0
        )
    )
)

if exist "C:\Program Files\Android\Android Studio\jbr" (
    echo Checking: C:\Program Files\Android\Android Studio\jbr
    if exist "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" (
        echo Found keytool at: C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe
        echo.
        echo You can use this command:
        echo "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore android/keystore/ecovisionai-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ecovisionai-release -storepass ecovision2025 -keypass ecovision2025 -dname "CN=EcoVision AI, OU=VIREN Legacy, O=VIREN Legacy, L=Unknown, S=Unknown, C=US"
        exit /b 0
    )
)

echo.
echo Java/keytool not found in common locations.
echo Please install Java JDK or Android Studio.
echo.
echo If you have Android Studio installed, keytool is usually at:
echo C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe
exit /b 1
