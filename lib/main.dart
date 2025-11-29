import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'core/services/resource_manager.dart';
import 'core/utils/performance_monitor.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for better UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style for consistent appearance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Request permissions on startup
  try {
    // Import permission_handler dynamically to avoid errors
    // Permissions will be requested when features are accessed
  } catch (e) {
    debugPrint('Permission initialization skipped: $e');
  }
  
  runApp(
    const ProviderScope(
      child: EcoVisionApp(),
    ),
  );
}

class EcoVisionApp extends ConsumerStatefulWidget {
  const EcoVisionApp({super.key});

  @override
  ConsumerState<EcoVisionApp> createState() => _EcoVisionAppState();
}

class _EcoVisionAppState extends ConsumerState<EcoVisionApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Schedule cleanup of old temporary files
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedulePeriodicCleanup();
      
      // Start performance monitoring in debug mode
      if (kDebugMode) {
        PerformanceMonitor.instance.startMonitoring();
        _schedulePerformanceReporting();
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Stop performance monitoring
    if (kDebugMode) {
      PerformanceMonitor.instance.stopMonitoring();
    }
    
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Clean up resources when app goes to background
    if (state == AppLifecycleState.paused) {
      _cleanupResources();
    }
    
    // Clean up old files when app resumes
    if (state == AppLifecycleState.resumed) {
      _cleanupOldFiles();
    }
  }
  
  void _schedulePeriodicCleanup() {
    // Clean up old files periodically
    Future.delayed(const Duration(minutes: 30), () {
      if (mounted) {
        _cleanupOldFiles();
        _schedulePeriodicCleanup();
      }
    });
  }
  
  void _schedulePerformanceReporting() {
    // Log performance metrics periodically in debug mode
    if (!kDebugMode) return;
    
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        PerformanceMonitor.instance.logReport();
        _schedulePerformanceReporting();
      }
    });
  }
  
  Future<void> _cleanupResources() async {
    try {
      final resourceManager = ref.read(resourceManagerProvider);
      await resourceManager.cleanupOldFiles(maxAge: const Duration(minutes: 30));
    } catch (e) {
      // Ignore cleanup errors
    }
  }
  
  Future<void> _cleanupOldFiles() async {
    try {
      final resourceManager = ref.read(resourceManagerProvider);
      await resourceManager.cleanupOldFiles();
      await resourceManager.clearCacheIfNeeded();
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoVision AI',
      theme: AppTheme.lightTheme(),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      // Performance optimizations
      builder: (context, child) {
        // Ensure consistent text scaling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: child!,
        );
      },
    );
  }
}