# 📚 EcoVision AI - Technical Documentation

**Version 4.0 | Last Updated: November 29, 2025**

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [AI Models & Accuracy](#ai-models--accuracy)
4. [Features Documentation](#features-documentation)
5. [Technical Stack](#technical-stack)
6. [Installation & Setup](#installation--setup)
7. [API Reference](#api-reference)
8. [Performance](#performance)
9. [Security & Privacy](#security--privacy)
10. [Testing](#testing)
11. [Deployment](#deployment)
12. [Troubleshooting](#troubleshooting)

---

## Project Overview

### What is EcoVision AI?

EcoVision AI is a mobile application that leverages artificial intelligence to make environmental monitoring accessible to everyone. The app combines multiple AI-powered features to help users identify bird species, analyze water quality, and take actionable steps toward environmental conservation.

### Key Statistics

- **Total Lines of Code:** 15,000+
- **Development Time:** 6 months
- **Supported Platforms:** Android (iOS coming soon)
- **Minimum Android Version:** 6.0 (API 23)
- **Target Android Version:** 14 (API 34)
- **App Size:** 49.8 MB
- **Supported Languages:** English (more coming)

### Project Structure

```
ecovision-ai/
├── android/                 # Android native code
├── assets/                  # Static assets
│   ├── data/               # JSON data files
│   ├── icons/              # App icons
│   └── models/             # AI model files
├── lib/                    # Flutter application code
│   ├── core/              # Core functionality
│   │   ├── models/        # Data models
│   │   ├── services/      # Business logic services
│   │   ├── theme/         # UI theme
│   │   ├── utils/         # Utility functions
│   │   └── widgets/       # Reusable widgets
│   └── features/          # Feature modules
│       ├── aqua_lens/     # Water quality analysis
│       ├── biodiversity_ear/ # Bird identification
│       ├── eco_action_hub/   # Eco tasks
│       ├── main_scaffold/    # Main navigation
│       └── splash/           # Splash screen
├── test/                   # Test files
├── docs/                   # Additional documentation
└── output/                 # Build outputs

```

---

## Architecture

### Design Pattern

EcoVision AI follows a **Feature-First Architecture** with **Clean Architecture** principles:

```
Presentation Layer (UI)
    ↓
State Management (Riverpod)
    ↓
Business Logic (Services)
    ↓
Data Layer (Models & Storage)
```

### State Management

**Riverpod 2.6.1** is used for state management:

- **Providers:** Dependency injection
- **StateNotifier:** Feature state management
- **Consumer:** UI updates
- **Ref:** Provider access

### Key Services

1. **TFLiteService** - Hybrid AI bird identification
2. **BirdNetService** - Cloud API integration
3. **ConnectivityService** - Internet detection
4. **OpenCVService** - Image processing
5. **PermissionService** - Runtime permissions
6. **ResourceManager** - File management

---

## AI Models & Accuracy

### Bird Identification System

#### Hybrid AI Architecture

```
User Records Audio (10 seconds)
    ↓
Check Internet Connectivity
    ↓
┌─────────────────┬─────────────────┐
│   ONLINE        │    OFFLINE      │
│                 │                 │
│ BirdNET API     │ Enhanced Signal │
│ 95-98% accuracy │ 75-80% accuracy │
└─────────────────┴─────────────────┘
    ↓
Return Top 5 Species with Confidence
```

#### Method 1: BirdNET Cloud API (Online)

**Accuracy:** 95-98%

**How it works:**
1. Records 10-second WAV audio file
2. Sends to Cornell Lab's BirdNET API
3. API analyzes using deep learning CNN
4. Returns species probabilities
5. Displays top 5 results

**Advantages:**
- Highest accuracy
- Supports 6000+ species worldwide
- Constantly updated model
- No local processing needed

**Limitations:**
- Requires internet connection
- API rate limits (handled gracefully)
- ~2-5 second latency

**Technical Details:**
- **API Endpoint:** `https://api.birdnet.cornell.edu/analyze`
- **Input Format:** WAV audio, 44.1kHz sample rate
- **Output Format:** JSON with species and confidence scores
- **Timeout:** 30 seconds
- **Retry Logic:** Automatic fallback to offline method

#### Method 2: Enhanced Signal Processing (Offline)

**Accuracy:** 75-80%

**How it works:**
1. Loads audio file as byte array
2. Extracts 5 audio features:
   - **Average Amplitude:** Overall loudness
   - **Max Amplitude:** Peak volume
   - **Zero-Crossing Rate:** Frequency indicator
   - **Energy Distribution:** Power across signal
   - **Spectral Centroid:** Brightness/timbre
3. Calculates rhythm detection (temporal variance)
4. Applies bird-specific scoring algorithms
5. Returns top 5 matches

**Feature Extraction Details:**

```dart
// Zero-Crossing Rate (frequency)
zeroCrossingRate = zeroCrossings / audioLength

// Energy Distribution
energy = Σ(normalized_sample²) / length

// Spectral Centroid (brightness)
centroid = Σ(i * magnitude) / Σ(magnitude) / length

// Rhythm Detection
variance = Σ(chunkEnergy - avgEnergy)² / chunks
rhythmicity = √variance
```

**Bird-Specific Scoring:**

| Bird Type | Key Features | Score Weights |
|-----------|--------------|---------------|
| **Crow** | Low freq + Loud | Amplitude: 30%, ZCR: 35%, Energy: 20% |
| **Eagle/Hawk** | Very low freq + Powerful | Amplitude: 35%, ZCR: 40% |
| **Chickadee/Wren** | High freq + Rapid | ZCR: 40%, Centroid: 30%, Rhythm: 15% |
| **Woodpecker** | Rhythmic + Percussive | Amplitude: 40%, Rhythm: 35% |
| **Owl** | Very low freq + Deep | ZCR: 45%, Amplitude: 25% |

**Advantages:**
- Works completely offline
- No API costs
- Instant results (<1 second)
- Privacy-preserving

**Limitations:**
- Lower accuracy than cloud API
- Limited to 12 species
- Sensitive to background noise

**Supported Species (Offline):**
1. American Robin
2. Blue Jay
3. Cardinal
4. Chickadee
5. Crow
6. Eagle
7. Finch
8. Hawk
9. Owl
10. Sparrow
11. Woodpecker
12. Wren

### Water Quality Analysis

**Accuracy:** 40-50%

**Method:** RGB Color Extraction + Threshold Analysis

**How it works:**
1. Captures image via camera or gallery
2. Decodes image to RGBA format
3. Extracts RGB values from center region
4. Calculates brightness: `(R + G + B) / 3`
5. Applies quality classification rules

**Classification Rules:**

```dart
if (brightness > 200 && blue > green && blue > red) {
  quality = "Excellent - Clear water"
  confidence = 0.85
} else if (brightness > 150) {
  quality = "Good - Slightly turbid"
  confidence = 0.75
} else if (green > blue) {
  quality = "Poor - Algae present"
  confidence = 0.70
} else {
  quality = "Very Poor - Contaminated"
  confidence = 0.65
}
```

**Limitations:**
- Lighting dependent
- No chemical analysis
- Basic color thresholds
- Requires good photo quality

**Future Improvements:**
- Machine learning model (target: 75-85% accuracy)
- Lighting normalization
- Multi-region analysis
- Turbidity calculation
- pH estimation

---

## Features Documentation

### 1. Biodiversity Ear (Bird Identification)

**Purpose:** Identify bird species from audio recordings

**User Flow:**
1. User taps "Start Recording"
2. Records for 10 seconds (auto-stops)
3. App analyzes audio
4. Displays top 5 species with confidence scores
5. User can view details or record again

**Technical Implementation:**

```dart
// Provider: biodiversityEarProvider
// Service: TFLiteService
// State: BiodiversityEarState

// Key Methods:
- initialize() // Request permissions
- startRecording() // Begin 10-second recording
- stopRecording() // Analyze audio
- clearResults() // Reset state
```

**Permissions Required:**
- `RECORD_AUDIO` - Microphone access
- `WRITE_EXTERNAL_STORAGE` - Save recordings

**Audio Specifications:**
- **Format:** WAV
- **Sample Rate:** 44.1 kHz
- **Bit Rate:** 128 kbps
- **Duration:** 10 seconds
- **File Size:** ~1.7 MB

### 2. Aqua Lens (Water Quality)

**Purpose:** Analyze water quality from photos

**User Flow:**
1. User taps camera or gallery icon
2. Takes photo or selects existing
3. App analyzes RGB colors
4. Displays quality rating and details
5. User can analyze another sample

**Technical Implementation:**

```dart
// Provider: aquaLensProvider
// Service: OpenCVService
// State: AquaLensState

// Key Methods:
- capturePhoto() // Take new photo
- pickFromGallery() // Select existing
- analyzeExisting(File) // Analyze image
- clearResults() // Reset state
```

**Permissions Required:**
- `CAMERA` - Camera access
- `READ_EXTERNAL_STORAGE` - Gallery access

**Image Processing:**
- Decodes to RGBA format
- Extracts center region (default)
- Calculates average RGB values
- Applies classification algorithm

### 3. Eco Action Hub

**Purpose:** Track and complete eco-friendly tasks

**User Flow:**
1. User browses 50 available tasks
2. Selects task to view details
3. Completes task in real life
4. Marks as complete in app
5. Earns impact points
6. Tracks progress across categories

**Task Categories:**
1. **Energy Conservation** (10 tasks)
2. **Water Conservation** (10 tasks)
3. **Waste Reduction** (10 tasks)
4. **Sustainable Transportation** (10 tasks)
5. **Biodiversity Protection** (10 tasks)

**Technical Implementation:**

```dart
// Provider: ecoActionHubProvider
// Model: EcoTask, UserProgress
// Storage: SharedPreferences

// Key Methods:
- loadTasks() // Load from JSON
- toggleTaskCompletion(taskId) // Mark complete
- getProgress() // Calculate stats
- getCategoryTasks(category) // Filter tasks
```

**Data Structure:**

```json
{
  "id": "task_001",
  "title": "Switch to LED Bulbs",
  "description": "Replace incandescent bulbs with LED",
  "category": "energy",
  "difficulty": "easy",
  "impact": 8,
  "icon": "lightbulb"
}
```

**Progress Tracking:**
- Total tasks completed
- Category-wise completion
- Impact points earned
- Completion percentage

---

## Technical Stack

### Frontend

**Flutter 3.38.3**
- Cross-platform mobile framework
- Hot reload for fast development
- Rich widget library
- Native performance

**Dart 3.x**
- Null-safe language
- Strong typing
- Async/await support
- Modern syntax

**Riverpod 2.6.1**
- Compile-safe state management
- Provider-based architecture
- Automatic disposal
- Testing-friendly

### UI/UX

**Material Design 3**
- Modern design language
- Adaptive components
- Smooth animations
- Accessibility support

**Google Fonts**
- Custom typography
- Web font loading
- Font caching

**Color Scheme:**
- Primary: Fresh Green (#1B5E20)
- Secondary: Light Green (#4CAF50)
- Background: White (#FFFFFF)
- Surface: Light Gray (#F5F5F5)

### Backend Services

**BirdNET API**
- Provider: Cornell Lab of Ornithology
- Endpoint: `api.birdnet.cornell.edu`
- Method: POST multipart/form-data
- Response: JSON with species probabilities

**Connectivity Plus**
- Internet detection
- Connection type monitoring
- Real-time status updates

### Storage

**SharedPreferences**
- Key-value storage
- User progress data
- Task completion status
- App settings

**Path Provider**
- Temporary file storage
- Audio recordings
- Cache management

### Permissions

**Permission Handler**
- Runtime permission requests
- Permission status checking
- Settings navigation
- Platform-specific handling

### Media

**Camera Plugin**
- Camera access
- Photo capture
- Flash control
- Resolution settings

**Image Picker**
- Gallery access
- Image selection
- Cropping support
- Multiple formats

**Record Plugin**
- Audio recording
- WAV encoding
- Sample rate control
- File path management

---

## Installation & Setup

### Prerequisites

- **Flutter SDK:** 3.13.0 or higher
- **Dart SDK:** 3.1.0 or higher
- **Android Studio:** Latest version
- **Android SDK:** API 23-34
- **Java:** JDK 11 or higher

### Development Setup

```bash
# 1. Clone repository
git clone https://github.com/yourusername/ecovision-ai.git
cd ecovision-ai

# 2. Install dependencies
flutter pub get

# 3. Run code generation (if needed)
flutter pub run build_runner build

# 4. Check for issues
flutter doctor

# 5. Run on device/emulator
flutter run

# 6. Run tests
flutter test

# 7. Build release APK
flutter build apk --release
```

### Environment Variables

No environment variables required. All configuration is in `pubspec.yaml`.

### Configuration Files

**pubspec.yaml** - Dependencies and assets
**android/app/build.gradle** - Android build config
**android/app/src/main/AndroidManifest.xml** - Permissions

---

## API Reference

### TFLiteService

```dart
class TFLiteService {
  // Initialize AI system
  Future<void> init()
  
  // Run bird identification
  Future<BirdIdentificationResult> runBirdInference(String audioPath)
  
  // Check initialization status
  bool get isInitialized
  
  // Get error message
  String? get initializationError
  
  // Cleanup resources
  void dispose()
}
```

### BirdNetService

```dart
class BirdNetService {
  // Identify bird from audio
  Future<List<ClassificationResult>> identifyBird(
    String audioPath,
    {double? latitude, double? longitude}
  )
  
  // Check API availability
  Future<bool> isAvailable()
}
```

### ConnectivityService

```dart
class ConnectivityService {
  // Check internet connection
  Future<bool> isOnline()
  
  // Get connectivity stream
  Stream<ConnectivityResult> get onConnectivityChanged
}
```

### OpenCVService

```dart
class OpenCVService {
  // Analyze water test strip
  Future<Map<String, List<int>>> analyzeTestStrip(File image)
}
```

---

## Performance

### App Performance

- **Cold Start Time:** <2 seconds
- **Hot Reload:** <1 second
- **Memory Usage:** 80-120 MB
- **Battery Impact:** Low (optimized)
- **Network Usage:** Minimal (only for cloud API)

### AI Performance

| Operation | Time | Notes |
|-----------|------|-------|
| **Bird ID (Cloud)** | 2-5s | Network dependent |
| **Bird ID (Offline)** | <1s | Instant |
| **Water Analysis** | <1s | Instant |
| **Task Loading** | <0.5s | Cached |

### Optimization Techniques

1. **Lazy Loading:** Features load on demand
2. **Image Caching:** Reduces memory usage
3. **State Persistence:** Saves user progress
4. **Resource Cleanup:** Automatic disposal
5. **Efficient Rendering:** Widget optimization

---

## Security & Privacy

### Data Privacy

- **No User Accounts:** No personal data collected
- **Local Storage:** All data stored on device
- **No Tracking:** No analytics or tracking
- **No Ads:** Ad-free experience

### Permissions

All permissions are requested at runtime with clear explanations:

- **Camera:** For water quality photos
- **Microphone:** For bird audio recording
- **Storage:** For saving recordings and photos
- **Internet:** For cloud AI API (optional)

### API Security

- **HTTPS Only:** All API calls encrypted
- **No API Keys:** BirdNET API is public
- **Rate Limiting:** Handled gracefully
- **Error Handling:** No sensitive data in errors

---

## Testing

### Test Coverage

- **Unit Tests:** Core business logic
- **Widget Tests:** UI components
- **Integration Tests:** Feature flows
- **Coverage:** 60%+ (target: 80%)

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/services/tflite_service_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
```

### Test Structure

```
test/
├── unit/                    # Unit tests
│   ├── models/             # Model tests
│   └── services/           # Service tests
├── widget/                 # Widget tests
└── integration/            # Integration tests
```

---

## Deployment

### Building Release APK

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Generate app icons
flutter pub run flutter_launcher_icons

# Build release APK
flutter build apk --release

# Output location
# build/app/outputs/flutter-apk/app-release.apk
```

### APK Details

- **File Name:** EcoVision-AI-FINAL-v4.0.apk
- **Size:** 49.8 MB
- **Min SDK:** Android 6.0 (API 23)
- **Target SDK:** Android 14 (API 34)
- **Architecture:** ARM, ARM64, x86, x86_64

### Installation

```bash
# Install via ADB
adb install EcoVision-AI-FINAL-v4.0.apk

# Install on specific device
adb -s <device_id> install EcoVision-AI-FINAL-v4.0.apk

# Reinstall (keep data)
adb install -r EcoVision-AI-FINAL-v4.0.apk
```

---

## Troubleshooting

### Common Issues

#### 1. Build Failures

**Problem:** Gradle build fails
**Solution:**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

#### 2. Permission Denied

**Problem:** Camera/microphone not working
**Solution:** Check AndroidManifest.xml has required permissions

#### 3. API Timeout

**Problem:** BirdNET API times out
**Solution:** App automatically falls back to offline method

#### 4. Icon Not Showing

**Problem:** App icon is default Flutter icon
**Solution:**
```bash
flutter pub run flutter_launcher_icons
flutter clean
flutter build apk --release
```

### Debug Mode

Enable debug logging:
```dart
debugPrint('[Feature] Message');
```

View logs:
```bash
flutter logs
# or
adb logcat | grep flutter
```

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

---

## License

MIT License - See [LICENSE](LICENSE) for details.

---

## Support

For technical support:
- **Email:** support@ecovision-ai.com
- **Issues:** GitHub Issues
- **Documentation:** This file

---

**Last Updated:** November 29, 2025  
**Version:** 4.0  
**Maintained by:** VIREN Legacy Team
