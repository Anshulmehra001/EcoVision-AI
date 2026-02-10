# EcoVision AI - Technical Documentation

Complete technical documentation for developers.

## 📋 Table of Contents

1. [Architecture](#architecture)
2. [Core Services](#core-services)
3. [Features](#features)
4. [Data Models](#data-models)
5. [State Management](#state-management)
6. [Testing](#testing)
7. [Build & Deployment](#build--deployment)

---

## Architecture

### Project Structure
```
lib/
├── core/                    # Core functionality
│   ├── models/             # Data models
│   ├── services/           # Business logic services
│   ├── theme/              # App theming
│   ├── utils/              # Utility functions
│   └── widgets/            # Reusable widgets
├── features/               # Feature modules
│   ├── aqua_lens/         # Water quality detection
│   ├── biodiversity_ear/  # Bird voice recognition
│   ├── eco_action_hub/    # Environmental tasks
│   └── splash/            # Splash screen
└── main.dart              # App entry point
```

### Design Patterns
- **Provider Pattern**: Riverpod for state management
- **Service Pattern**: Separate business logic from UI
- **Repository Pattern**: Data access abstraction
- **Factory Pattern**: Model creation

---

## Core Services

### 1. OpenCV Service (`opencv_service.dart`)

**Purpose**: Water test strip analysis using computer vision

**Key Methods**:
```dart
Future<Map<String, List<int>>?> analyzeTestStrip(File imageFile)
```

**Algorithm**:
1. **Test Strip Detection**
   - Convert to grayscale
   - Apply Gaussian blur (radius: 3)
   - Sobel edge detection
   - Calculate edge ratio (5-15% for valid strips)
   - Check aspect ratio (0.3-3.0)
   - Measure color variance (>1000)

2. **Region Extraction**
   - Crop center 60% of image
   - Focus on test strip area

3. **Color Pad Extraction**
   - Divide into 4 equal sections
   - Each section = one chemical parameter

4. **Color Analysis**
   - Sample center 50% of each pad
   - Convert RGB to HSV
   - Calculate average color
   - Return RGB values

**Returns**: `Map<String, List<int>>` or `null` if no strip detected

### 2. TFLite Service (`tflite_service.dart`)

**Purpose**: Bird voice recognition using audio analysis

**Key Methods**:
```dart
Future<BirdIdentificationResult> runBirdInference(String audioPath)
```

**Algorithm**:
1. **Feature Extraction**
   - Average amplitude (loudness)
   - Maximum amplitude (peak)
   - Zero-crossing rate (frequency)
   - Energy (power)
   - Spectral centroid (brightness)
   - Spectral rolloff (frequency distribution)

2. **Pattern Matching**
   - Compare features against 442+ species
   - Score each species (0.3-0.75)
   - Apply feature-based scoring:
     - High-frequency birds: +0.25
     - Low-frequency birds: +0.25
     - Loud birds: +0.2
     - Medium songbirds: +0.2

3. **Confidence Filtering**
   - Threshold: 40%
   - Return top 5 matches
   - Show "No detection" if below threshold

**Returns**: `BirdIdentificationResult` with confidence scores

### 3. Permission Service (`permission_service.dart`)

**Purpose**: Centralized permission handling

**Key Methods**:
```dart
Future<PermissionResult> requestCameraPermission()
Future<PermissionResult> requestMicrophonePermission()
Future<PermissionResult> requestStoragePermission()
```

**Features**:
- Unified permission API
- Error handling
- User-friendly messages
- Permission status tracking

### 4. Resource Manager (`resource_manager.dart`)

**Purpose**: Temporary file management

**Key Methods**:
```dart
Future<String> createTempFilePath(String prefix, String extension)
void trackFile(String path)
Future<void> cleanupFile(String path)
```

**Features**:
- Automatic cleanup
- File tracking
- Error handling

---

## Features

### Aqua Lens (Water Quality)

**Files**:
- `lib/features/aqua_lens/screen.dart` - UI
- `lib/features/aqua_lens/provider.dart` - State management

**State**:
```dart
class AquaLensState {
  bool isInitialized;
  bool isCapturing;
  bool isAnalyzing;
  Map<String, List<int>> colorResults;
  String? error;
  CameraController? cameraController;
  bool hasPermission;
}
```

**Flow**:
1. Initialize camera
2. Request permissions
3. Show camera preview
4. Capture image on button press
5. Analyze with OpenCV
6. Display results or error

### Biodiversity Ear (Bird Recognition)

**Files**:
- `lib/features/biodiversity_ear/screen.dart` - UI
- `lib/features/biodiversity_ear/provider.dart` - State management

**State**:
```dart
class BiodiversityEarState {
  bool isInitialized;
  bool isRecording;
  bool isAnalyzing;
  List<ClassificationResult> results;
  String? error;
  bool hasPermission;
  int recordingDuration;
  String? currentRecordingPath;
}
```

**Flow**:
1. Initialize recorder
2. Request permissions
3. Record audio (10 seconds) OR upload file
4. Analyze with audio processing
5. Display top 5 results or "No detection"

### Eco Action Hub

**Files**:
- `lib/features/eco_action_hub/screen.dart` - Task list UI
- `lib/features/eco_action_hub/task_detail_screen.dart` - Task details
- `lib/features/eco_action_hub/providers.dart` - State management

**Features**:
- Load tasks from JSON
- Filter by category
- Track completion
- Persist progress

---

## Data Models

### ClassificationResult
```dart
class ClassificationResult {
  final String label;
  final double confidence;
  final DateTime timestamp;
}
```

### EcoTask
```dart
class EcoTask {
  final String id;
  final String title;
  final String description;
  final String category;
  final int points;
  final String difficulty;
}
```

### UserProgress
```dart
class UserProgress {
  final Set<String> completedTasks;
  final int totalPoints;
  final DateTime lastUpdated;
}
```

---

## State Management

### Riverpod Providers

**Service Providers** (Singleton):
```dart
final openCVServiceProvider = Provider<OpenCVService>((ref) => OpenCVService._());
final tfliteServiceProvider = Provider<TFLiteService>((ref) => TFLiteService._());
final permissionServiceProvider = Provider<PermissionService>((ref) => PermissionService());
final resourceManagerProvider = Provider<ResourceManager>((ref) => ResourceManager());
```

**State Notifier Providers**:
```dart
final aquaLensProvider = StateNotifierProvider<AquaLensNotifier, AquaLensState>(...);
final biodiversityEarProvider = StateNotifierProvider<BiodiversityEarNotifier, BiodiversityEarState>(...);
final ecoTasksProvider = StateNotifierProvider<EcoTasksNotifier, EcoTasksState>(...);
```

---

## Testing

### Unit Tests
Location: `test/unit/`

**Models**:
- `classification_result_test.dart`
- `eco_task_test.dart`
- `user_progress_test.dart`

**Services**:
- `permission_service_test.dart`

### Integration Tests
Location: `test/integration/`

**Tests**:
- `navigation_test.dart` - Navigation flow
- `eco_action_hub_test.dart` - Task management
- `offline_functionality_test.dart` - Offline mode

### Running Tests
```bash
# All tests
flutter test

# Specific test
flutter test test/unit/models/classification_result_test.dart

# With coverage
flutter test --coverage
```

---

## Build & Deployment

### Development Build
```bash
flutter run
```

### Release Build
```bash
# Clean
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build Script
Use `build_apk.bat` for automated building:
```bash
build_apk.bat
```

### Requirements
- Flutter SDK 3.38.3+
- Dart 3.10.1+
- Java JDK 17
- Android SDK (API 21+)

### Signing (Production)
1. Create keystore:
```bash
keytool -genkey -v -keystore ecovision.keystore -alias ecovision -keyalg RSA -keysize 2048 -validity 10000
```

2. Configure `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=ecovision
storeFile=<path-to-keystore>
```

3. Build signed APK:
```bash
flutter build apk --release
```

---

## Performance Optimization

### Image Processing
- Use appropriate image resolution
- Implement caching
- Async processing
- Memory management

### Audio Processing
- Stream processing for large files
- Buffer management
- Cleanup temporary files

### State Management
- Selective rebuilds
- Memoization
- Lazy loading

---

## Troubleshooting

### Build Issues
**Gradle SSL errors**:
- Solution: Use `gradle.properties` with SSL trust store config

**Java not found**:
- Solution: Set `JAVA_HOME` environment variable

**Flutter not found**:
- Solution: Add Flutter to PATH

### Runtime Issues
**Camera not working**:
- Check permissions
- Verify camera availability
- Check Android version

**Audio recording fails**:
- Check microphone permission
- Verify audio hardware
- Check storage space

---

## API Reference

### OpenCVService
```dart
class OpenCVService {
  Future<Map<String, List<int>>?> analyzeTestStrip(File imageFile);
}
```

### TFLiteService
```dart
class TFLiteService {
  Future<void> init();
  Future<BirdIdentificationResult> runBirdInference(String audioPath);
  void dispose();
}
```

### PermissionService
```dart
class PermissionService {
  Future<PermissionResult> requestCameraPermission();
  Future<PermissionResult> requestMicrophonePermission();
  Future<PermissionResult> requestStoragePermission();
}
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) file.

---

**Last Updated**: January 2026  
**Version**: 1.2.0
