# Android Build Configuration Reference

## Overview

This document describes the Android build configuration for EcoVision AI.

## Build Configuration Summary

### SDK Versions
- **Minimum SDK**: API 21 (Android 5.0 Lollipop)
- **Target SDK**: API 34 (Android 14)
- **Compile SDK**: API 34

### Application Details
- **Package Name**: com.virenlegacy.ecovisionai
- **Version**: Defined in pubspec.yaml
- **Application ID**: com.virenlegacy.ecovisionai

## Build Types

### Debug Build
- **Minification**: Disabled
- **Resource Shrinking**: Disabled
- **Signing**: Debug keystore (auto-generated)
- **Use Case**: Development and testing

### Release Build
- **Minification**: Enabled (R8)
- **Resource Shrinking**: Enabled
- **ProGuard**: Enabled with custom rules
- **Signing**: Release keystore (must be configured)
- **Use Case**: Production deployment

## ProGuard Configuration

ProGuard rules are defined in `android/app/proguard-rules.pro` and include:

- Flutter framework preservation
- TensorFlow Lite model protection
- OpenCV library protection
- Plugin preservation (camera, audio, permissions)
- JSON serialization support
- Native method preservation
- Debug information retention for stack traces

## Signing Configuration

### Setup Required

1. Create keystore using `scripts/setup_keystore.bat` (Windows) or `scripts/setup_keystore.sh` (Linux/Mac)
2. Copy `key.properties.template` to `key.properties`
3. Fill in keystore details in `key.properties`

### Key Properties Format

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=ecovisionai-release
storeFile=../keystore/ecovisionai-release.jks
```

### Security Notes

- Never commit `key.properties` to version control
- Never commit keystore files (*.jks, *.keystore) to version control
- Keep secure backups of keystore files
- Store passwords in a password manager

## Build Optimizations

### Gradle Optimizations
- Parallel builds enabled
- Build caching enabled
- Configure on demand enabled
- Increased heap size (2GB)

### Android Optimizations
- R8 full mode enabled
- Build cache enabled
- MultiDex enabled for large apps
- ABI filters for optimized builds

### Supported ABIs
- armeabi-v7a (32-bit ARM)
- arm64-v8a (64-bit ARM)
- x86_64 (64-bit Intel)

## Package Optimizations

### Excluded Files
- Duplicate META-INF files
- License files
- Notice files
- Kotlin module files

### Asset Optimization
- Models compressed in assets
- Icons generated at multiple densities
- Resources automatically optimized

## Build Commands

### Standard Release Build
```bash
flutter build apk --release
```

### App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### Split APKs by Architecture
```bash
flutter build apk --release --split-per-abi
```

### Analyze Build Size
```bash
flutter build apk --release --analyze-size
```

## Troubleshooting

### Build Fails with Signing Error
- Verify `key.properties` exists and has correct values
- Check keystore file path is correct
- Verify keystore passwords are correct

### ProGuard Breaks App
- Check `proguard-rules.pro` for missing keep rules
- Test with `--no-shrink` flag to isolate issue
- Add keep rules for classes accessed via reflection

### Out of Memory During Build
- Increase heap size in `gradle.properties`
- Close other applications
- Use `--no-daemon` flag

### Large APK Size
- Use `--split-per-abi` for architecture-specific builds
- Remove unused dependencies
- Compress assets
- Use vector graphics instead of raster images

## File Structure

```
android/
├── app/
│   ├── build.gradle              # Main build configuration
│   ├── proguard-rules.pro        # ProGuard rules
│   └── src/main/
│       └── AndroidManifest.xml   # App manifest with permissions
├── build.gradle                  # Project-level build config
├── gradle.properties             # Gradle optimization settings
├── key.properties.template       # Template for signing config
├── key.properties                # Actual signing config (gitignored)
└── keystore/
    ├── README.md                 # Keystore setup instructions
    ├── .gitkeep                  # Keep directory in git
    └── ecovisionai-release.jks   # Release keystore (gitignored)
```

## Version Management

Version is managed in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

- Increment BUILD_NUMBER for each release
- Update MAJOR.MINOR.PATCH following semantic versioning

## Dependencies

Key dependencies affecting build:
- flutter_riverpod: State management
- tflite_flutter: AI model inference
- camera: Camera functionality
- opencv_dart: Computer vision
- record: Audio recording
- permission_handler: Runtime permissions

## Performance Targets

- App launch: < 5 seconds
- Model loading: < 5 seconds
- Image inference: < 3 seconds
- Audio inference: < 5 seconds
- UI frame rate: 60 fps

## Release Checklist

Before building release:
- [ ] Update version in pubspec.yaml
- [ ] Test all features in debug mode
- [ ] Configure keystore and key.properties
- [ ] Verify ProGuard rules are complete
- [ ] Test release build on physical device
- [ ] Check APK size is reasonable
- [ ] Verify all features work in release mode

## Additional Resources

- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
- [Android Build Configuration](https://developer.android.com/studio/build)
- [ProGuard Documentation](https://www.guardsquare.com/manual/home)
- [R8 Optimization](https://developer.android.com/studio/build/shrink-code)
