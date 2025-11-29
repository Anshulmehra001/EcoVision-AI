import 'dart:typed_data';

/// Buffer pool for reusing memory allocations during AI inference
/// This reduces GC pressure and improves performance
class InferenceBufferPool {
  InferenceBufferPool._();
  
  static final InferenceBufferPool instance = InferenceBufferPool._();
  
  // Pools for different buffer sizes
  final Map<int, List<Uint8List>> _bufferPools = {};
  
  // Maximum number of buffers to keep per size
  static const int maxBuffersPerSize = 3;
  
  /// Get a buffer of the specified size from the pool or create a new one
  Uint8List getBuffer(int size) {
    final pool = _bufferPools[size];
    
    if (pool != null && pool.isNotEmpty) {
      // Reuse existing buffer
      return pool.removeLast();
    }
    
    // Create new buffer
    return Uint8List(size);
  }
  
  /// Return a buffer to the pool for reuse
  void returnBuffer(Uint8List buffer) {
    final size = buffer.length;
    
    // Initialize pool for this size if it doesn't exist
    _bufferPools[size] ??= [];
    
    final pool = _bufferPools[size]!;
    
    // Only keep up to maxBuffersPerSize buffers per size
    if (pool.length < maxBuffersPerSize) {
      // Clear the buffer before returning to pool
      buffer.fillRange(0, buffer.length, 0);
      pool.add(buffer);
    }
    // If pool is full, let the buffer be garbage collected
  }
  
  /// Clear all buffers from the pool
  void clearAll() {
    _bufferPools.clear();
  }
  
  /// Clear buffers of a specific size
  void clearSize(int size) {
    _bufferPools.remove(size);
  }
  
  /// Get total memory used by pooled buffers
  int getTotalMemoryUsage() {
    int total = 0;
    for (final entry in _bufferPools.entries) {
      final size = entry.key;
      final count = entry.value.length;
      total += size * count;
    }
    return total;
  }
  
  /// Get statistics about the buffer pool
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};
    
    for (final entry in _bufferPools.entries) {
      final size = entry.key;
      final count = entry.value.length;
      stats['size_$size'] = {
        'count': count,
        'total_bytes': size * count,
      };
    }
    
    stats['total_memory_bytes'] = getTotalMemoryUsage();
    stats['total_buffer_count'] = _bufferPools.values.fold<int>(
      0,
      (sum, pool) => sum + pool.length,
    );
    
    return stats;
  }
}
