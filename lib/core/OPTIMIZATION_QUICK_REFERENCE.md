# Performance Optimization Quick Reference

## Key Components

### 1. ResourceManager
**Purpose:** Centralized temporary file and resource management

**Usage:**
```dart
final resourceManager = ref.watch(resourceManagerProvider);

// Track a file
resourceManager.trackFile(filePath);

// Create temp file
final path = await resourceManager.createTempFilePath('prefix', 'ext');

// Cleanup
await resourceManager.cleanupFile(filePath);
await resourceManager.cleanupAllFiles();
```

### 2. PerformanceMonitor
**Purpose:** Track FPS and performance metrics (debug only)

**Usage:**
```dart
// Start monitoring
PerformanceMonitor.instance.startMonitoring();

// Get metrics
final report = PerformanceMonitor.instance.getReport();
print('FPS: ${report.averageFps}');

// Log report
PerformanceMonitor.instance.logReport();

// Stop
PerformanceMonitor.instance.stopMonitoring();
```

### 3. StatePersistence
**Purpose:** Persist app state across sessions

**Usage:**
```dart
// Save navigation
await StatePersistence.instance.saveNavigationIndex(index);

// Load navigation
final index = await StatePersistence.instance.loadNavigationIndex();

// Save/load settings
await StatePersistence.instance.saveSetting('key', value);
final value = await StatePersistence.instance.loadSetting<T>('key');
```

## Optimization Checklist

### For New Features
- [ ] Use StateNotifier for state management
- [ ] Integrate ResourceManager for temp files
- [ ] Implement proper dispose methods
- [ ] Use const constructors where possible
- [ ] Add error handling with cleanup
- [ ] Test with PerformanceMonitor

### For AI Operations
- [ ] Use buffer reuse in preprocessing
- [ ] Implement timeout handling
- [ ] Clean up temp files after inference
- [ ] Dispose OpenCV matrices properly
- [ ] Handle errors with resource cleanup

### For UI Components
- [ ] Use IndexedStack for navigation
- [ ] Cache expensive widgets
- [ ] Minimize setState calls
- [ ] Use const constructors
- [ ] Implement proper lifecycle management

## Common Patterns

### Pattern 1: Capture and Analyze with Cleanup
```dart
String? imagePath;
try {
  final XFile imageFile = await cameraController.takePicture();
  imagePath = imageFile.path;
  resourceManager.trackFile(imagePath);
  
  final results = await service.analyze(File(imagePath));
  
  await resourceManager.cleanupFile(imagePath);
} catch (e) {
  if (imagePath != null) {
    await resourceManager.cleanupFile(imagePath);
  }
  rethrow;
}
```

### Pattern 2: OpenCV with Proper Disposal
```dart
cv.Mat? mat;
try {
  mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
  // Process mat
  return result;
} finally {
  mat?.dispose();
}
```

### Pattern 3: State Persistence
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    _saveState();
  }
}
```

## Performance Targets

| Metric | Target | How to Achieve |
|--------|--------|----------------|
| 60 FPS | Always | Use IndexedStack, const widgets |
| < 1s Navigation | Always | IndexedStack, cached screens |
| < 3s Image Inference | Always | Buffer reuse, optimized preprocessing |
| < 5s Audio Inference | Always | Buffer reuse, optimized preprocessing |
| 0 Memory Leaks | Always | Proper disposal, ResourceManager |

## Troubleshooting

### Issue: Frame Drops
**Solution:** Check PerformanceMonitor, verify const constructors, profile with DevTools

### Issue: Memory Growth
**Solution:** Check ResourceManager cleanup, verify OpenCV disposal, profile memory

### Issue: Slow Inference
**Solution:** Verify buffer reuse, check model loading, test on different devices

### Issue: State Not Persisting
**Solution:** Verify StatePersistence calls, check lifecycle observers

## Best Practices

1. **Always dispose resources** in finally blocks
2. **Use ResourceManager** for all temporary files
3. **Implement proper error handling** with cleanup
4. **Test performance** in debug mode with PerformanceMonitor
5. **Profile regularly** using Flutter DevTools
6. **Cache expensive operations** when possible
7. **Use const constructors** everywhere possible
8. **Minimize setState calls** with granular state updates
