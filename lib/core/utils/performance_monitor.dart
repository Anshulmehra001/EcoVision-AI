import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

/// Performance monitoring utility for tracking frame rates and performance metrics
class PerformanceMonitor {
  PerformanceMonitor._();
  
  static final PerformanceMonitor instance = PerformanceMonitor._();
  
  bool _isMonitoring = false;
  final List<Duration> _frameDurations = [];
  int _droppedFrames = 0;
  DateTime? _lastFrameTime;
  
  // Target frame time for 60fps (16.67ms)
  static const Duration targetFrameTime = Duration(microseconds: 16667);
  
  /// Start monitoring frame performance
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _frameDurations.clear();
    _droppedFrames = 0;
    _lastFrameTime = DateTime.now();
    
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
  }
  
  /// Stop monitoring frame performance
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
  }
  
  /// Callback for frame timing data
  void _onFrameTiming(List<FrameTiming> timings) {
    if (!_isMonitoring) return;
    
    for (final timing in timings) {
      final frameDuration = timing.totalSpan;
      _frameDurations.add(frameDuration);
      
      // Check if frame was dropped (took longer than target)
      if (frameDuration > targetFrameTime) {
        _droppedFrames++;
      }
      
      // Keep only last 120 frames (2 seconds at 60fps)
      if (_frameDurations.length > 120) {
        _frameDurations.removeAt(0);
      }
    }
  }
  
  /// Get current average FPS
  double get averageFps {
    if (_frameDurations.isEmpty) return 0.0;
    
    final totalMicroseconds = _frameDurations
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b);
    
    final averageMicroseconds = totalMicroseconds / _frameDurations.length;
    
    return 1000000.0 / averageMicroseconds;
  }
  
  /// Get percentage of dropped frames
  double get droppedFramePercentage {
    if (_frameDurations.isEmpty) return 0.0;
    return (_droppedFrames / _frameDurations.length) * 100;
  }
  
  /// Check if performance is meeting 60fps target
  bool get isMeetingTarget {
    return averageFps >= 55.0 && droppedFramePercentage < 5.0;
  }
  
  /// Get performance report
  PerformanceReport getReport() {
    return PerformanceReport(
      averageFps: averageFps,
      droppedFrames: _droppedFrames,
      totalFrames: _frameDurations.length,
      droppedFramePercentage: droppedFramePercentage,
      isMeetingTarget: isMeetingTarget,
    );
  }
  
  /// Reset monitoring data
  void reset() {
    _frameDurations.clear();
    _droppedFrames = 0;
    _lastFrameTime = null;
  }
  
  /// Log performance report (debug mode only)
  void logReport() {
    if (!kDebugMode) return;
    
    final report = getReport();
    debugPrint('=== Performance Report ===');
    debugPrint('Average FPS: ${report.averageFps.toStringAsFixed(2)}');
    debugPrint('Dropped Frames: ${report.droppedFrames}/${report.totalFrames}');
    debugPrint('Dropped Frame %: ${report.droppedFramePercentage.toStringAsFixed(2)}%');
    debugPrint('Meeting Target: ${report.isMeetingTarget ? "YES" : "NO"}');
    debugPrint('========================');
  }
}

/// Performance report data class
class PerformanceReport {
  final double averageFps;
  final int droppedFrames;
  final int totalFrames;
  final double droppedFramePercentage;
  final bool isMeetingTarget;
  
  const PerformanceReport({
    required this.averageFps,
    required this.droppedFrames,
    required this.totalFrames,
    required this.droppedFramePercentage,
    required this.isMeetingTarget,
  });
  
  @override
  String toString() {
    return 'PerformanceReport(fps: ${averageFps.toStringAsFixed(2)}, '
           'dropped: $droppedFrames/$totalFrames, '
           'target: ${isMeetingTarget ? "met" : "not met"})';
  }
}
