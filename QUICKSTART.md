# Quick Start Guide

Get EcoVision AI running in 5 minutes!

## Prerequisites

- Flutter SDK 3.38.3+
- Android device or emulator

## Installation

```bash
# 1. Clone repository
git clone https://github.com/yourusername/ecovision-ai.git
cd ecovision-ai

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

## Build APK

```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

## Install on Device

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Features

- 🌿 **Flora Shield** - Plant disease detection
- 💧 **Aqua Lens** - Water quality analysis
- 🦜 **Biodiversity Ear** - Bird identification
- 🌍 **Eco Action Hub** - Task management

## Documentation

- **Full Documentation:** [README.md](README.md)
- **Getting Started:** [docs/development/getting-started.md](docs/development/getting-started.md)
- **Building:** [docs/deployment/building.md](docs/deployment/building.md)

## Troubleshooting

### Build fails?
```bash
flutter clean
flutter pub get
flutter run
```

### Device not detected?
```bash
adb devices
# Enable USB debugging on device
```

## Need Help?

- Check [docs/](docs/)
- Open an issue on GitHub
- Email: support@ecovisionai.com

---

**Ready to contribute?** See [CONTRIBUTING.md](CONTRIBUTING.md)
