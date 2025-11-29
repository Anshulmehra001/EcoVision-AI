import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/opencv_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/resource_manager.dart';

/// State class for Aqua Lens feature
class AquaLensState {
  final bool isInitialized;
  final bool isCapturing;
  final bool isAnalyzing;
  final Map<String, List<int>> colorResults;
  final String? error;
  final CameraController? cameraController;
  final bool hasPermission;

  const AquaLensState({
    this.isInitialized = false,
    this.isCapturing = false,
    this.isAnalyzing = false,
    this.colorResults = const {},
    this.error,
    this.cameraController,
    this.hasPermission = false,
  });

  AquaLensState copyWith({
    bool? isInitialized,
    bool? isCapturing,
    bool? isAnalyzing,
    Map<String, List<int>>? colorResults,
    String? error,
    CameraController? cameraController,
    bool? hasPermission,
  }) {
    return AquaLensState(
      isInitialized: isInitialized ?? this.isInitialized,
      isCapturing: isCapturing ?? this.isCapturing,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      colorResults: colorResults ?? this.colorResults,
      error: error ?? this.error,
      cameraController: cameraController ?? this.cameraController,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

/// Provider for Aqua Lens state management
class AquaLensNotifier extends StateNotifier<AquaLensState> {
  AquaLensNotifier(
    this._openCVService, 
    this._permissionService,
    this._resourceManager,
  ) : super(const AquaLensState());

  final OpenCVService _openCVService;
  final PermissionService _permissionService;
  final ResourceManager _resourceManager;
  List<CameraDescription>? _cameras;

  /// Idempotent initialization; separates permission and hardware setup.
  Future<PermissionResult> initialize() async {
    if (state.isInitialized && state.hasPermission) {
      return PermissionResult.granted();
    }
    final permissionResult = await _permissionService.requestCameraPermission();
    if (!permissionResult.isGranted) {
      state = state.copyWith(error: permissionResult.getMessage(), hasPermission: false);
      return permissionResult;
    }
    if (!state.isInitialized) {
      final cameraInitResult = await _initializeCamera();
      return cameraInitResult.isGranted ? permissionResult : cameraInitResult;
    }
    return permissionResult;
  }

  /// Request permission only; initializes hardware if needed and granted.
  Future<PermissionResult> requestPermission() async {
    final permissionResult = await _permissionService.requestCameraPermission();
    if (permissionResult.isGranted) {
      state = state.copyWith(hasPermission: true);
      if (!state.isInitialized) {
        await _initializeCamera();
      }
    } else {
      state = state.copyWith(hasPermission: false, error: permissionResult.getMessage());
    }
    return permissionResult;
  }

  Future<PermissionResult> _initializeCamera() async {
    try {
      try {
        _cameras = await availableCameras();
      } catch (e) {
        state = state.copyWith(error: 'Failed to access camera hardware: ${e.toString()}', hasPermission: true);
        return PermissionResult.error(permissionName: 'Camera', errorMessage: 'Camera hardware is not available on this device');
      }
      if (_cameras == null || _cameras!.isEmpty) {
        state = state.copyWith(error: 'No cameras available on this device', hasPermission: true);
        return PermissionResult.error(permissionName: 'Camera', errorMessage: 'No cameras found on this device');
      }
      final backCamera = _cameras!.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back, orElse: () => _cameras!.first);
      final controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
      try {
        await controller.initialize();
      } catch (e) {
        state = state.copyWith(error: 'Failed to initialize camera: ${e.toString()}', isInitialized: false, hasPermission: true);
        return PermissionResult.error(permissionName: 'Camera', errorMessage: 'Camera initialization failed. Please try again.');
      }
      state = state.copyWith(isInitialized: true, cameraController: controller, hasPermission: true, error: null);
      return PermissionResult.granted();
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize camera: ${e.toString()}', isInitialized: false);
      return PermissionResult.error(permissionName: 'Camera', errorMessage: 'Unexpected error during initialization: ${e.toString()}');
    }
  }

  /// Capture image and run water test strip analysis
  Future<void> captureAndAnalyze() async {
    if (!state.isInitialized || state.cameraController == null) {
      state = state.copyWith(error: 'Camera not initialized');
      return;
    }

    String? imagePath;
    try {
      state = state.copyWith(isCapturing: true, error: null);

      // Capture image
      final XFile imageFile = await state.cameraController!.takePicture();
      imagePath = imageFile.path;
      
      // Track file for cleanup
      _resourceManager.trackFile(imagePath);
      
      state = state.copyWith(isCapturing: false, isAnalyzing: true);

      // Run OpenCV color analysis
      final results = await _openCVService.analyzeTestStrip(File(imagePath));

      state = state.copyWith(
        isAnalyzing: false,
        colorResults: results,
      );

      // Clean up temporary file immediately after analysis
      await _resourceManager.cleanupFile(imagePath);
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        isAnalyzing: false,
        error: 'Analysis failed: ${e.toString()}',
      );
      // Clean up on error
      if (imagePath != null) {
        await _resourceManager.cleanupFile(imagePath);
      }
    }
  }

  /// Analyze an existing image file (uploaded test strip)
  Future<void> analyzeExisting(File imageFile) async {
    String? imagePath;
    try {
      state = state.copyWith(isCapturing: true, error: null);
      imagePath = imageFile.path;
      _resourceManager.trackFile(imagePath);
      state = state.copyWith(isCapturing: false, isAnalyzing: true);
      final results = await _openCVService.analyzeTestStrip(imageFile);
      state = state.copyWith(isAnalyzing: false, colorResults: results);
      await _resourceManager.cleanupFile(imagePath);
    } catch (e) {
      state = state.copyWith(isCapturing: false, isAnalyzing: false, error: 'Analysis failed: ${e.toString()}');
      if (imagePath != null) {
        await _resourceManager.cleanupFile(imagePath);
      }
    }
  }

  /// Clear current results
  void clearResults() {
    state = state.copyWith(colorResults: {});
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  // (Replaced by new requestPermission above)

  @override
  void dispose() {
    state.cameraController?.dispose();
    super.dispose();
  }
}

/// Provider for Aqua Lens functionality
final aquaLensProvider = StateNotifierProvider<AquaLensNotifier, AquaLensState>((ref) {
  final openCVService = ref.watch(openCVServiceProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final resourceManager = ref.watch(resourceManagerProvider);
  return AquaLensNotifier(openCVService, permissionService, resourceManager);
});
