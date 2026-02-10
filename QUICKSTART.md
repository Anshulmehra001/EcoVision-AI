# EcoVision AI - Quick Start Guide

Get up and running with EcoVision AI in 5 minutes!

## 📥 Installation (2 minutes)

### Option 1: Install Pre-built APK (Recommended)
1. Download `EcoVision-AI-v1.2-ImprovedAI.apk` (77MB)
2. On your Android device:
   - Go to Settings → Security
   - Enable "Install from unknown sources"
3. Open the APK file
4. Tap "Install"
5. Done! 🎉

### Option 2: Build from Source
```bash
# Clone repository
git clone <repository-url>
cd ecovisionai

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 🚀 First Launch (1 minute)

1. Open EcoVision AI
2. Grant permissions when prompted:
   - ✅ Camera (for water quality)
   - ✅ Microphone (for bird recognition)
   - ✅ Storage (for audio upload)
3. You'll see 3 main features on home screen

## 💧 Test Water Quality (1 minute)

1. Tap **"Aqua Lens"**
2. Dip test strip in water
3. Wait for colors to develop (30-60 seconds)
4. Hold test strip in front of camera
5. Tap **"Capture & Analyze"**
6. View results! 📊

**Pro Tips:**
- Use natural daylight
- Hold strip flat and centered
- Avoid shadows

## 🐦 Identify Birds (1 minute)

### Record Live
1. Tap **"Biodiversity Ear"**
2. Tap **"Start Recording"**
3. Wait 10 seconds (auto-stops)
4. View top 5 bird matches! 🐦

### Upload Audio
1. Tap **"Upload Audio File"**
2. Select WAV file from device
3. Wait for analysis
4. View results!

**Pro Tips:**
- Record in quiet environment
- Morning hours are best
- Get close to bird (safely!)

## 🌱 Track Eco Actions

1. Tap **"Eco Action Hub"**
2. Browse environmental tasks
3. Tap task to see details
4. Complete tasks and track progress! 🌍

## ❓ Troubleshooting

### "No test strip detected"
- ✅ Ensure test strip is clearly visible
- ✅ Use better lighting
- ✅ Hold strip flat and centered

### "No bird detected"
- ✅ Record in quieter environment
- ✅ Get closer to bird
- ✅ Try recording for full 10 seconds
- ✅ Ensure bird is actually vocalizing

### Camera/Microphone not working
- ✅ Check app permissions in Android settings
- ✅ Restart the app
- ✅ Restart your device

### App crashes
- ✅ Clear app cache
- ✅ Reinstall the app
- ✅ Check Android version (requires API 21+)

## 📊 Understanding Results

### Water Quality
- **pH**: 0-14 scale (7 is neutral)
- **Chlorine**: ppm (parts per million)
- **Hardness**: mg/L (milligrams per liter)
- **Alkalinity**: mg/L

### Bird Recognition
- Shows top 5 matches
- Confidence percentage (40%+ shown)
- Higher % = more confident match

## 🎯 Best Practices

### For Accurate Water Testing
1. Follow test strip instructions
2. Wait for full color development
3. Use consistent lighting
4. Test multiple times for verification

### For Accurate Bird ID
1. Record in morning (6-10 AM)
2. Minimize background noise
3. Record multiple calls
4. Compare with online bird calls

## 🔄 Updates

Check for updates regularly:
- New bird species
- Improved accuracy
- Bug fixes
- New features

## 📞 Need Help?

- Check README.md for detailed info
- Check CHANGELOG.md for version history
- Open issue on GitHub
- Read full documentation

## 🎉 You're Ready!

Start exploring and contributing to environmental conservation! 🌍🌿

---

**Quick Links:**
- [Full Documentation](README.md)
- [Changelog](CHANGELOG.md)
- [Contributing Guide](CONTRIBUTING.md)
- [License](LICENSE)
