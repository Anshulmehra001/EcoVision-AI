@echo off
REM Build release APK and copy to output folder automatically
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] Flutter not found in PATH. Install SDK to D:\flutter and run setup_flutter_path.bat
  exit /b 1
)
flutter pub get || exit /b 1
flutter build apk --release || exit /b 1
if not exist "output" mkdir output
copy /Y build\app\outputs\flutter-apk\app-release.apk output\EcoVisionAI-release.apk >nul
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] Failed to copy APK
  exit /b 1
)
echo [SUCCESS] APK copied to output\EcoVisionAI-release.apk
