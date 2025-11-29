# Keystore Setup Instructions

This directory should contain your Android keystore file for signing release builds.

## Creating a Keystore

Run the following command to create a new keystore:

```bash
keytool -genkey -v -keystore ecovisionai-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ecovisionai-release
```

You will be prompted to enter:
- Keystore password (remember this!)
- Key password (remember this!)
- Your name and organization details

## Setting Up key.properties

1. Copy `key.properties.template` to `key.properties` in the android directory:
   ```bash
   cp key.properties.template key.properties
   ```

2. Edit `key.properties` and fill in your actual values:
   - `storePassword`: The keystore password you created
   - `keyPassword`: The key password you created
   - `keyAlias`: ecovisionai-release (or your chosen alias)
   - `storeFile`: Path to your keystore file (relative to android/app)

## Security Notes

- **NEVER** commit `key.properties` or your keystore file to version control
- Keep backups of your keystore in a secure location
- If you lose your keystore, you cannot update your app on the Play Store
- Store passwords securely (consider using a password manager)

## .gitignore

Make sure these files are in your .gitignore:
```
android/key.properties
android/keystore/*.jks
android/keystore/*.keystore
```

## Building a Release APK

Once your keystore is set up, build a release APK with:

```bash
flutter build apk --release
```

Or build an App Bundle for Play Store:

```bash
flutter build appbundle --release
```
