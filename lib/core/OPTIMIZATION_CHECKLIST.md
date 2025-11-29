# Performance Optimization Checklist

Quick reference for maintaining optimal performance in EcoVision AI.

## When Creating New Widgets

- [ ] Use `const` constructors for static widgets
- [ ] Wrap expensive widgets in `RepaintBoundary`
- [ ] Use `select` for Riverpod state watching
- [ ] Avoid rebuilding entire widget trees
- [ ] Keep widget build methods simple and fast

## When Working with AI Models

- [ ] Use buffer pool for preprocessing
- [ ] Return buffers to pool after use
- [ ] Implement proper timeout handling
- [ ] Clean up temporary files immediately
- [ ] Handle errors gracefully

## When Managing Resources

- [ ] Track temporary files with ResourceManager
- [ ] Clean up files after use
- [ ] Dispose controllers in dispose() method
- [ ] Handle app lifecycle events
- [ ] Implement proper error cleanup

## When Adding Navigation

- [ ] Use IndexedStack for tab navigation
- [ ] Persist navigation state
- [ ] Add haptic feedback
- [ ] Keep transitions under 250ms
- [ ] Maintain state across navigation

## When Handling Permissions

- [ ] Use centralized PermissionService
- [ ] Show clear permission rationale
- [ ] Handle denial gracefully
- [ ] Provide retry mechanism
- [ ] Check hardware availability

## Performance Targets

✅ **60 FPS** - All UI transitions
✅ **<5 seconds** - Model initialization
✅ **<3 seconds** - Image inference
✅ **<5 seconds** - Audio inference
✅ **<1 second** - Navigation transitions
✅ **<100 MB** - Temporary file storage
✅ **<5%** - Dropped frame percentage

## Common Issues

### Issue: Low FPS
**Solution:** Add RepaintBoundary, use const constructors, check for excessive rebuilds

### Issue: High Memory
**Solution:** Return buffers to pool, clean up temp files, dispose resources properly

### Issue: Slow Inference
**Solution:** Verify model loaded, check buffer availability, monitor timeouts

### Issue: Resource Leaks
**Solution:** Implement dispose methods, track resources, handle lifecycle events

## Quick Commands

```dart
// Monitor performance (debug only)
PerformanceMonitor.instance.startMonitoring();
PerformanceMonitor.instance.logReport();

// Check buffer pool
final stats = InferenceBufferPool.instance.getStatistics();

// Check cache size
final size = await resourceManager.getCacheSize();

// Clean up resources
await resourceManager.cleanupAllFiles();
```

## Code Examples

### Optimized Widget
```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use select for selective rebuilds
    final isLoading = ref.watch(
      myProvider.select((state) => state.isLoading)
    );
    
    return RepaintBoundary(
      child: const MyExpensiveWidget(),
    );
  }
}
```

### Buffer Usage
```dart
Future<void> processImage(File image) async {
  Uint8List? buffer;
  try {
    final bytes = await image.readAsBytes();
    buffer = InferenceBufferPool.instance.getBuffer(bytes.length);
    buffer.setAll(0, bytes);
    
    // Use buffer...
    
  } finally {
    if (buffer != null) {
      InferenceBufferPool.instance.returnBuffer(buffer);
    }
  }
}
```

### Resource Cleanup
```dart
@override
void dispose() {
  // Dispose controllers
  _controller?.dispose();
  
  // Clean up files
  if (_tempFile != null) {
    resourceManager.cleanupFile(_tempFile!);
  }
  
  super.dispose();
}
```

## Remember

🎯 **Performance is a feature** - Users notice lag and jank
🔧 **Optimize early** - Easier to maintain than fix later
📊 **Monitor regularly** - Use debug tools to catch issues
🧹 **Clean up always** - Resources don't clean themselves
⚡ **Test on real devices** - Emulators don't show real performance
