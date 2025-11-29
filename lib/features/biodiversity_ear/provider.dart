import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/models/classification_result.dart';
import '../../core/services/tflite_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/resource_manager.dart';

/// State class for Biodiversity Ear feature
class BiodiversityEarState {
  final bool isInitialized;
  final bool isRecording;
  final bool isAnalyzing;
  final List<ClassificationResult> results;
  final String? error;
  final bool hasPermission;
  final int recordingDuration; // in seconds
  final String? currentRecordingPath;

  const BiodiversityEarState({
    this.isInitialized = false,
    this.isRecording = false,
    this.isAnalyzing = false,
    this.results = const [],
    this.error,
    this.hasPermission = false,
    this.recordingDuration = 0,
    this.currentRecordingPath,
  });

  BiodiversityEarState copyWith({
    bool? isInitialized,
    bool? isRecording,
    bool? isAnalyzing,
    List<ClassificationResult>? results,
    String? error,
    bool? hasPermission,
    int? recordingDuration,
    String? currentRecordingPath,
  }) {
    return BiodiversityEarState(
      isInitialized: isInitialized ?? this.isInitialized,
      isRecording: isRecording ?? this.isRecording,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      results: results ?? this.results,
      error: error ?? this.error,
      hasPermission: hasPermission ?? this.hasPermission,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      currentRecordingPath: currentRecordingPath ?? this.currentRecordingPath,
    );
  }
}

/// Provider for Biodiversity Ear state management
class BiodiversityEarNotifier extends StateNotifier<BiodiversityEarState> {
  BiodiversityEarNotifier(
    this._tfliteService, 
    this._permissionService,
    this._resourceManager,
  ) : super(const BiodiversityEarState());

  final TFLiteService _tfliteService;
  final PermissionService _permissionService;
  final ResourceManager _resourceManager;
  final AudioRecorder _recorder = AudioRecorder();

  /// Initialize recorder and check permissions
  Future<PermissionResult> initialize() async {
    try {
      // Request microphone permission using centralized service
      final permissionResult = await _permissionService.requestMicrophonePermission();
      
      if (!permissionResult.isGranted) {
        state = state.copyWith(
          error: permissionResult.getMessage(),
          hasPermission: false,
        );
        return permissionResult;
      }

      // Check if recorder hardware is available
      try {
        final isAvailable = await _recorder.hasPermission();
        if (!isAvailable) {
          state = state.copyWith(
            error: 'Audio recording is not available on this device',
            hasPermission: false,
          );
          return PermissionResult.error(
            permissionName: 'Microphone',
            errorMessage: 'Microphone hardware is not available on this device',
          );
        }
      } catch (e) {
        state = state.copyWith(
          error: 'Failed to access microphone hardware: ${e.toString()}',
          hasPermission: true,
        );
        return PermissionResult.error(
          permissionName: 'Microphone',
          errorMessage: 'Microphone hardware check failed',
        );
      }

      state = state.copyWith(
        isInitialized: true,
        hasPermission: true,
        error: null,
      );

      return permissionResult;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize audio recorder: ${e.toString()}',
        isInitialized: false,
      );
      return PermissionResult.error(
        permissionName: 'Microphone',
        errorMessage: 'Unexpected error during initialization: ${e.toString()}',
      );
    }
  }

  /// Start 10-second audio recording
  Future<void> startRecording() async {
    if (!state.isInitialized || !state.hasPermission) {
      state = state.copyWith(error: 'Audio recorder not initialized or permission denied');
      return;
    }

    try {
      // Create unique temporary file path
      final recordingPath = await _resourceManager.createTempFilePath('bird_recording', 'wav');

      // Configure recording settings
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        bitRate: 128000,
      );

      // Start recording
      await _recorder.start(config, path: recordingPath);

      state = state.copyWith(
        isRecording: true,
        recordingDuration: 0,
        currentRecordingPath: recordingPath,
        error: null,
      );

      // Start timer for 10 seconds
      _startRecordingTimer();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start recording: ${e.toString()}',
        isRecording: false,
      );
    }
  }

  /// Stop recording and analyze audio
  Future<void> stopRecording() async {
    if (!state.isRecording) return;

    String? recordingPath;
    try {
      // Stop recording
      recordingPath = await _recorder.stop();
      
      state = state.copyWith(
        isRecording: false,
        isAnalyzing: true,
        recordingDuration: 0,
      );

      if (recordingPath != null) {
        // Run AI inference on the recorded audio with timeout handling
        final result = await _tfliteService.runBirdInference(recordingPath);
        
        // Log which method was used
        print('[BiodiversityEar] Used: ${result.method} (${(result.accuracy * 100).toStringAsFixed(0)}% accuracy)');

        state = state.copyWith(
          isAnalyzing: false,
          results: result.results,
          currentRecordingPath: recordingPath,
        );

        // Clean up temporary file after a short delay
        Future.delayed(const Duration(seconds: 30), () {
          _resourceManager.cleanupFile(recordingPath!);
        });
      } else {
        state = state.copyWith(
          isAnalyzing: false,
          error: 'Recording failed - no audio file created',
        );
      }
    } on InferenceTimeoutException catch (e) {
      state = state.copyWith(
        isRecording: false,
        isAnalyzing: false,
        error: 'Analysis timed out. Please try recording in a quieter environment.',
      );
      // Clean up on error
      if (recordingPath != null) {
        await _resourceManager.cleanupFile(recordingPath);
      }
    } on ModelInitializationException catch (e) {
      state = state.copyWith(
        isRecording: false,
        isAnalyzing: false,
        error: 'AI model not available. ${e.message}',
      );
      // Clean up on error
      if (recordingPath != null) {
        await _resourceManager.cleanupFile(recordingPath);
      }
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        isAnalyzing: false,
        error: 'Analysis failed: ${e.toString()}',
      );
      // Clean up on error
      if (recordingPath != null) {
        await _resourceManager.cleanupFile(recordingPath);
      }
    }
  }

  /// Start recording timer (10 seconds)
  void _startRecordingTimer() {
    const duration = Duration(seconds: 1);
    
    void tick() {
      if (!state.isRecording) return;
      
      final newDuration = state.recordingDuration + 1;
      
      if (newDuration >= 10) {
        // Auto-stop after 10 seconds
        stopRecording();
      } else {
        state = state.copyWith(recordingDuration: newDuration);
        Future.delayed(duration, tick);
      }
    }
    
    Future.delayed(duration, tick);
  }



  /// Clear current results
  void clearResults() {
    state = state.copyWith(results: []);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Request microphone permission with retry mechanism
  Future<PermissionResult> requestPermission() async {
    return await initialize();
  }

  /// Get the detected species for task navigation
  String? get detectedSpecies {
    if (state.results.isNotEmpty) {
      return state.results.first.label;
    }
    return null;
  }

  /// Get recording progress (0.0 to 1.0)
  double get recordingProgress {
    return state.recordingDuration / 10.0;
  }

  @override
  void dispose() {
    _recorder.dispose();
    // Clean up current recording if exists
    if (state.currentRecordingPath != null) {
      _resourceManager.cleanupFile(state.currentRecordingPath!);
    }
    super.dispose();
  }
}

/// Provider for Biodiversity Ear functionality
final biodiversityEarProvider = StateNotifierProvider<BiodiversityEarNotifier, BiodiversityEarState>((ref) {
  final tfliteService = ref.watch(tfliteServiceProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final resourceManager = ref.watch(resourceManagerProvider);
  return BiodiversityEarNotifier(tfliteService, permissionService, resourceManager);
});