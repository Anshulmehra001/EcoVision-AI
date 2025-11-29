# Performance Optimization Guide

This document describes the performance optimizations implemented in EcoVision AI to ensure smooth 60fps operation and efficient resource usage.

## Overview

The application implements multiple layers of optimization to meet the 60fps target and ensure responsive user experience:

1. **Widget Optimization** - Efficient widget rebuilding
2. **Memory Management** - Buffer pooling and resource cleanup
3. **State Management** - Selective rebuilds with Riverpod
4. **Resource Cleanup** - Automatic cleanup of temporary files
5. **Performance Monitoring** - Real-time FPS tracking

## 1. Widget Optimization

### RepaintBoundary Usage

`RepaintBoundary` widgets are strategically placed to isolate expensive repaints:

```dart
// Camera preview is isolated to prevent unnecessary repaints
RepaintBoundary(
  child: CameraPreview(controller),
)

// Loading indicators are isolated
RepaintBoundary(
  child: CircularProgressIndicator(),
)
```

**Benefits:**
- Prevents cascade repaints when only part of the UI changes
- Improves frame rate during animations
- Reduces GPU workload

### Const Constructors

Widgets that don't change use `const` constructors to enable compile-time optimization:

```dart
const SizedBox(height: 16)
const Text('Static text')
const Icon(Icons.camera)
```

**Benefits:**
- Widgets are created once and reused
- Reduces memory allocations
- Faster widget tree building

### IndexedStack for Navigation

The main scaffold uses `IndexedStack` for instant tab switching:

```dart
IndexedStack(
  index: _currentIndex,
  children: _screens,
)
```

**Benefits:**
- All screens remain in memory (state preservation)
- Instant switching without rebuild
- Smooth 60fps transitions

## 2. Memory Management

### Buffer Pooling

The `InferenceBufferPool` reuses memory buffers for AI inference:

```dart
// Get buffer from pool
final buffer = InferenceBufferPool.instance.getBuffer(size);

// Use buffer for inference
// ...

// Return to pool for reuse
InferenceBufferPool.instance.returnBuffer(buffer);
```

**Benefits:**
- Reduces memory allocations
- Decreases garbage collection pressure
- Improves inference performance

**Configuration:**
- Maximum 3 buffers per size
- Automatic cleanup when pool is full
- Buffers are zeroed before reuse

### Resource Manager

Automatic cleanup of temporary files:

```dart
// Track file for cleanup
resourceManager.trackFile(imagePath);

// Cleanup after use
await resourceManager.cleanupFile(imagePath);

// Periodic cleanup of old files
await resourceManager.cleanupOldFiles(maxAge: Duration(hours: 1));
```

**Benefits:**
- Prevents storage bloat
- Automatic cleanup on app lifecycle events
- Configurable cleanup policies

## 3. State Management Optimization

### Selective Rebuilds

Riverpod's `select` feature prevents unnecessary rebuilds:

```dart
// Only rebuild when isAnalyzing changes
final isAnalyzing = ref.watch(
  floraShieldProvider.select((state) => state.isAnalyzing)
);
```

**Available Selectors:**
- `floraShieldIsInitializedProvider`
- `floraShieldIsCapturingProvider`
- `floraShieldIsAnalyzingProvider`
- `floraShieldResultsProvider`
- `floraShieldErrorProvider`
- Similar selectors for other features

**Benefits:**
- Widgets only rebuild when their specific data changes
- Reduces unnecessary widget tree traversals
- Improves overall responsiveness

### State Persistence

Navigation state is persisted across app restarts:

```dart
// Save navigation state
await StatePersistence.instance.saveNavigationIndex(index);

// Restore on app start
final savedIndex = await StatePersistence.instance.loadNavigationIndex();
```

**Benefits:**
- Better user experience
- Faster app resume
- Maintains user context

## 4. Resource Cleanup

### Automatic Cleanup Triggers

Resources are cleaned up automatically:

1. **App Lifecycle Events:**
   - `AppLifecycleState.paused` - Clean up active resources
   - `AppLifecycleState.resumed` - Clean up old files

2. **Periodic Cleanup:**
   - Every 30 minutes during app usage
   - Removes files older than 1 hour

3. **Manual Cleanup:**
   - After AI inference completion
   - On error conditions
   - On feature disposal

### Camera and Audio Resources

Proper disposal of hardware resources:

```dart
@override
void dispose() {
  // Dispose camera controller
  state.cameraController?.dispose();
  
  // Dispose audio recorder
  _recorder.dispose();
  
  // Clean up temporary files
  resourceManager.cleanupFile(recordingPath);
  
  super.dispose();
}
```

## 5. Performance Monitoring

### Real-time FPS Tracking

The `PerformanceMonitor` tracks frame performance in debug mode:

```dart
// Start monitoring
PerformanceMonitor.instance.startMonitoring();

// Get current metrics
final report = PerformanceMonitor.instance.getReport();
print('Average FPS: ${report.averageFps}');
print('Dropped frames: ${report.droppedFramePercentage}%');

// Check if meeting 60fps target
if (report.isMeetingTarget) {
  print('Performance target met!');
}
```

**Metrics Tracked:**
- Average FPS
- Dropped frame count
- Dropped frame percentage
- Target achievement (55+ fps, <5% dropped)

**Reporting:**
- Automatic logging every 30 seconds (debug mode only)
- No performance impact in release builds

## 6. AI Inference Optimization

### Model Loading

Models are loaded once at startup and kept in memory:

```dart
// Initialize within 5 seconds (Requirement 8.1)
await tfliteService.init().timeout(Duration(seconds: 5));
```

**Optimizations:**
- Parallel model loading (flora + bird)
- Tensor pre-allocation
- 2 threads per model for optimal performance

### Inference Timeouts

Strict timeouts prevent UI blocking:

- Image inference: 3 seconds (Requirement 1.2)
- Audio inference: 5 seconds (Requirement 2.3)

### Preprocessing Optimization

Buffer reuse during preprocessing:

```dart
// Get buffer from pool
final buffer = _bufferPool.getBuffer(imageBytes.length);

// Preprocess in-place
buffer.setAll(0, imageBytes);

// Return after inference
_bufferPool.returnBuffer(buffer);
```

## 7. Animation Performance

### Smooth Transitions

All animations target 60fps:

```dart
// Navigation animation
NavigationBar(
  animationDuration: Duration(milliseconds: 250),
)

// Haptic feedback for better UX
HapticFeedback.lightImpact();
```

### Loading Indicators

Optimized progress indicators:

```dart
// Isolated with RepaintBoundary
RepaintBoundary(
  child: CircularProgressIndicator(
    strokeWidth: 6,
    value: progress,
  ),
)
```

## 8. Best Practices

### Do's

✅ Use `const` constructors whenever possible
✅ Wrap expensive widgets in `RepaintBoundary`
✅ Use selective state watching with `select`
✅ Clean up resources in `dispose` methods
✅ Return buffers to pool after use
✅ Use `IndexedStack` for tab navigation
✅ Implement proper error handling
✅ Monitor performance in debug mode

### Don'ts

❌ Don't rebuild entire widget trees unnecessarily
❌ Don't keep large files in temporary storage
❌ Don't allocate new buffers for every inference
❌ Don't block the UI thread with long operations
❌ Don't forget to dispose controllers and resources
❌ Don't use `setState` when Riverpod can be used
❌ Don't ignore memory warnings

## 9. Performance Targets

### Frame Rate
- **Target:** 60 FPS
- **Acceptable:** 55+ FPS
- **Dropped Frames:** <5%

### AI Inference
- **Model Loading:** <5 seconds
- **Image Inference:** <3 seconds
- **Audio Inference:** <5 seconds

### Memory
- **Buffer Pool:** <100 MB
- **Temporary Files:** <100 MB
- **Cleanup Frequency:** Every 30 minutes

### Navigation
- **Tab Switch:** <1 second (Requirement 7.3)
- **Screen Transition:** <250ms
- **State Restoration:** <500ms

## 10. Troubleshooting

### Low FPS

1. Check performance monitor logs
2. Look for excessive rebuilds
3. Verify `RepaintBoundary` placement
4. Check for memory leaks

### High Memory Usage

1. Check buffer pool statistics
2. Verify resource cleanup
3. Check temporary file count
4. Monitor GC frequency

### Slow Inference

1. Verify model is loaded
2. Check buffer pool availability
3. Monitor timeout occurrences
4. Check device capabilities

## 11. Monitoring Commands

### Debug Mode

```dart
// Get performance report
final report = PerformanceMonitor.instance.getReport();

// Get buffer pool stats
final stats = InferenceBufferPool.instance.getStatistics();

// Get cache size
final cacheSize = await resourceManager.getCacheSize();
```

### Release Mode

Performance monitoring is automatically disabled in release builds to avoid overhead.

## 12. Future Optimizations

Potential areas for further optimization:

1. **Image Preprocessing:** Implement native preprocessing for faster inference
2. **Model Quantization:** Use INT8 quantized models for faster inference
3. **Batch Processing:** Process multiple inferences in parallel
4. **Caching:** Cache recent inference results
5. **Progressive Loading:** Load models on-demand instead of at startup

## Conclusion

These optimizations ensure EcoVision AI meets all performance requirements:

- ✅ 60fps UI transitions (Requirement 7.3, 7.4)
- ✅ Fast AI inference (Requirements 8.5, 1.5, 2.5, 3.5)
- ✅ Efficient memory usage
- ✅ Proper resource cleanup
- ✅ Smooth user experience

All optimizations are implemented with minimal code complexity and maximum maintainability.
