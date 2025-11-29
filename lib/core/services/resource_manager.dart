import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Provider for ResourceManager singleton
final resourceManagerProvider = Provider<ResourceManager>((ref) {
  return ResourceManager._();
});

/// Service for managing temporary files and resource cleanup
class ResourceManager {
  ResourceManager._();

  final Set<String> _trackedFiles = {};
  final Set<String> _trackedDirectories = {};
  
  /// Track a temporary file for cleanup
  void trackFile(String path) {
    _trackedFiles.add(path);
  }
  
  /// Track a temporary directory for cleanup
  void trackDirectory(String path) {
    _trackedDirectories.add(path);
  }
  
  /// Remove a file from tracking (e.g., when manually deleted)
  void untrackFile(String path) {
    _trackedFiles.remove(path);
  }
  
  /// Clean up a specific file
  Future<void> cleanupFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      _trackedFiles.remove(path);
    } catch (e) {
      // Ignore cleanup errors
    }
  }
  
  /// Clean up all tracked temporary files
  Future<void> cleanupAllFiles() async {
    final filesToClean = List<String>.from(_trackedFiles);
    
    for (final path in filesToClean) {
      await cleanupFile(path);
    }
  }
  
  /// Clean up old temporary files (older than specified duration)
  Future<void> cleanupOldFiles({Duration maxAge = const Duration(hours: 1)}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      
      // List all files in temp directory
      final entities = tempDir.listSync(recursive: true);
      
      for (final entity in entities) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            final age = now.difference(stat.modified);
            
            if (age > maxAge) {
              await entity.delete();
              _trackedFiles.remove(entity.path);
            }
          } catch (e) {
            // Ignore errors for individual files
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
  
  /// Get temporary directory path
  Future<String> getTempDirectory() async {
    final tempDir = await getTemporaryDirectory();
    return tempDir.path;
  }
  
  /// Create a unique temporary file path
  Future<String> createTempFilePath(String prefix, String extension) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${tempDir.path}/${prefix}_$timestamp.$extension';
    trackFile(path);
    return path;
  }
  
  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      
      final entities = tempDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            totalSize += stat.size;
          } catch (e) {
            // Ignore errors for individual files
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  /// Clear all cache if size exceeds limit
  Future<void> clearCacheIfNeeded({int maxSizeBytes = 100 * 1024 * 1024}) async {
    final cacheSize = await getCacheSize();
    
    if (cacheSize > maxSizeBytes) {
      await cleanupAllFiles();
      
      // Also clean up temp directory
      try {
        final tempDir = await getTemporaryDirectory();
        final entities = tempDir.listSync(recursive: true);
        
        for (final entity in entities) {
          if (entity is File) {
            try {
              await entity.delete();
            } catch (e) {
              // Ignore errors
            }
          }
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }
  
  /// Dispose and cleanup all resources
  Future<void> dispose() async {
    await cleanupAllFiles();
    _trackedFiles.clear();
    _trackedDirectories.clear();
  }
}
