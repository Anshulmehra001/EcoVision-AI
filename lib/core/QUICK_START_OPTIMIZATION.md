# Quick Start: Performance Optimization

## For New Developers

This guide helps you understand and maintain the performance optimizations in EcoVision AI.

## Key Concepts

### 1. RepaintBoundary
Isolates widget repaints to improve performance.

**When to use:**
- Around camera previews
- Around loading indicators
- Around expensive custom paint widgets
- Around animated widgets

**Example:**
```dart
RepaintBoundary(
  child: CameraPreview(controller),
)
```

### 2. Buffer Pooling
Reuses memory buffers to reduce allocations.

**When to use:**
- AI inference preprocessing
- Image/audio data processing
- Any repeated memory allocation

**Example:**
```dart
final buffer = InferenceBufferPool.instance.getBuffer(size);
try {
  // Use buffer
  buffer.setAll(0, data);
} finally {
  InferenceBufferPool.instance.returnBuffer(buffer);
}
```

### 3. Selective State Watching
Only rebuild widgets when specific data changes.

**When to use:**
- Any Riverpod state watching
- When only part of state is needed

**Example:**
```dart
// Bad - rebuilds on any state change
final state = ref.watch(myProvider);

// Good - rebuilds only when isLoading changes
final isLoading = ref.watch(
  myProvider.select((state) => state.isLoading)
);
```

### 4. Resource Cleanup
Automatically clean up temporary files and resources.

**When to use:**
- After capturing images/audio
- In dispose methods
- On errors

**Example:**
```dart
// Track file
resourceManager.trackFile(imagePath);

// Clean up after use
await resourceManager.cleanupFile(imagePath);
```

## Common Patterns

### Pattern 1: Optimized Widget
```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key}); // const constructor
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selective watching
    final isLoading = ref.watch(
      myProvider.select((s) => s.isLoading)
    );
    
    return RepaintBoundary( // Isolate repaints
      child: isLoading
        ? const CircularProgressIndicator() // const widget
        : const MyContent(),
    );
  }
}
```

### Pattern 2: AI Inference with Buffer Pool
```dart
Future<void> runInference(File file) async {
  Uint8List? buffer;
  String? tempPath;
  
  try {
    // Read data
    final bytes = await file.readAsBytes();
    
    // Get buffer from pool
    buffer = InferenceBufferPool.instance.getBuffer(bytes.length);
    buffer.setAll(0, bytes);
    
    // Run inference
    final results = await model.run(buffer);
    
    // Process results
    // ...
    
  } catch (e) {
    // Handle error
  } finally {
    // Always clean up
    if (buffer != null) {
      InferenceBufferPool.instance.returnBuffer(buffer);
    }
    if (tempPath != null) {
      await resourceManager.cleanupFile(tempPath);
    }
  }
}
```

### Pattern 3: Resource Management
```dart
class MyFeatureNotifier extends StateNotifier<MyState> {
  final ResourceManager _resourceManager;
  
  Future<void> captureAndProcess() async {
    String? filePath;
    
    try {
      // Capture
      filePath = await capture();
      _resourceManager.trackFile(filePath);
      
      // Process
      await process(filePath);
      
    } catch (e) {
      // Handle error
    } finally {
      // Clean up
      if (filePath != null) {
        await _resourceManager.cleanupFile(filePath);
      }
    }
  }
  
  @override
  void dispose() {
    // Clean up resources
    _controller?.dispose();
    super.dispose();
  }
}
```

## Performance Checklist

Before committing code, verify:

- [ ] Used `const` constructors where possible
- [ ] Added `RepaintBoundary` around expensive widgets
- [ ] Used selective state watching with `select`
- [ ] Returned buffers to pool after use
- [ ] Cleaned up temporary files
- [ ] Implemented proper `dispose` methods
- [ ] Handled errors with cleanup
- [ ] Tested on real device

## Monitoring Performance

### Debug Mode
```dart
// Performance monitoring runs automatically
// Check logs for reports every 30 seconds

// Manual check:
final report = PerformanceMonitor.instance.getReport();
print('FPS: ${report.averageFps}');
print('Dropped: ${report.droppedFramePercentage}%');
```

### Buffer Pool Stats
```dart
final stats = InferenceBufferPool.instance.getStatistics();
print('Total memory: ${stats['total_memory_bytes']} bytes');
print('Buffer count: ${stats['total_buffer_count']}');
```

### Cache Size
```dart
final size = await resourceManager.getCacheSize();
print('Cache size: ${size / (1024 * 1024)} MB');
```

## Troubleshooting

### Problem: Low FPS
1. Check for missing `RepaintBoundary`
2. Look for excessive rebuilds
3. Use selective state watching
4. Profile with Flutter DevTools

### Problem: High Memory
1. Check buffer pool is being used
2. Verify files are being cleaned up
3. Check for resource leaks
4. Monitor GC in DevTools

### Problem: Slow Inference
1. Verify models are loaded
2. Check buffer pool availability
3. Monitor timeout occurrences
4. Test on real device

## Best Practices

✅ **Always** use const constructors for static widgets
✅ **Always** return buffers to pool
✅ **Always** clean up temporary files
✅ **Always** dispose resources
✅ **Always** use selective state watching

❌ **Never** allocate buffers without pool
❌ **Never** forget to clean up files
❌ **Never** block UI thread
❌ **Never** ignore dispose methods
❌ **Never** watch entire state when only part is needed

## Resources

- **Full Guide:** `lib/core/PERFORMANCE_OPTIMIZATION_GUIDE.md`
- **Checklist:** `lib/core/OPTIMIZATION_CHECKLIST.md`
- **Implementation:** `TASK_14_IMPLEMENTATION_SUMMARY.md`

## Questions?

Check the comprehensive guides or review existing code for examples.
