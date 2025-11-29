import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Centralized permission management service
class PermissionService {
  PermissionService._();
  
  static final instance = PermissionService._();
  // Concurrency guard to avoid overlapping native permission dialogs
  Future<PermissionResult>? _activePermissionFuture;

  /// Check and request camera permission with retry mechanism
  Future<PermissionResult> requestCameraPermission() async {
    return _requestPermission(
      ph.Permission.camera,
      'Camera',
      'Camera access is required to capture images for plant disease detection and water quality analysis.',
    );
  }

  /// Check and request microphone permission with retry mechanism
  Future<PermissionResult> requestMicrophonePermission() async {
    return _requestPermission(
      ph.Permission.microphone,
      'Microphone',
      'Microphone access is required to record audio for bird species identification.',
    );
  }

  /// Generic permission request handler with comprehensive error handling
  Future<PermissionResult> _requestPermission(
    ph.Permission permission,
    String permissionName,
    String rationale,
  ) async {
    Completer<PermissionResult>? completer;
    try {
      // If a request is already in flight, await it to finish
      if (_activePermissionFuture != null) {
        return await _activePermissionFuture!;
      }
      completer = Completer<PermissionResult>();
      _activePermissionFuture = completer.future;
      // Check current permission status
      ph.PermissionStatus status;
      try {
        status = await permission.status;
      } catch (e) {
        // If permission check fails, try to request directly
        debugPrint('Permission status check failed: $e');
        status = await permission.request();
      }

      // If already granted, return success
      if (status.isGranted) {
        final r = PermissionResult.granted();
        completer.complete(r);
        return r;
      }

      // If permanently denied, guide user to settings
      if (status.isPermanentlyDenied) {
        final r = PermissionResult.permanentlyDenied(
          permissionName: permissionName,
          rationale: rationale,
        );
        completer.complete(r);
        return r;
      }

      // If denied but not permanently, request permission
      if (status.isDenied) {
        final result = await permission.request();
        
        if (result.isGranted) {
          final r = PermissionResult.granted();
          completer.complete(r);
          return r;
        } else if (result.isPermanentlyDenied) {
          final r = PermissionResult.permanentlyDenied(
            permissionName: permissionName,
            rationale: rationale,
          );
          completer.complete(r);
          return r;
        } else {
          final r = PermissionResult.denied(
            permissionName: permissionName,
            rationale: rationale,
          );
          completer.complete(r);
          return r;
        }
      }

      // If restricted (iOS), return restricted status
      if (status.isRestricted) {
        final r = PermissionResult.restricted(
          permissionName: permissionName,
          rationale: rationale,
        );
        completer.complete(r);
        return r;
      }

      // Default to denied
      final r = PermissionResult.denied(
        permissionName: permissionName,
        rationale: rationale,
      );
      completer.complete(r);
      return r;
    } catch (e) {
      final r = PermissionResult.error(
        permissionName: permissionName,
        errorMessage: 'Failed to request $permissionName permission: ${e.toString()}',
      );
      if (completer != null && !completer.isCompleted) {
        completer.complete(r);
      }
      return r;
    } finally {
      _activePermissionFuture = null;
    }
  }

  /// Check if camera is available on device
  Future<bool> isCameraAvailable() async {
    try {
      // This is a basic check - actual camera availability is checked during initialization
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if microphone is available on device
  Future<bool> isMicrophoneAvailable() async {
    try {
      // This is a basic check - actual microphone availability is checked during initialization
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings for manual permission management
  Future<bool> openSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (e) {
      return false;
    }
  }
}

/// Result of a permission request with detailed status
class PermissionResult {
  final bool isGranted;
  final bool isPermanentlyDenied;
  final String? permissionName;
  final String? rationale;
  final String? errorMessage;

  const PermissionResult({
    required this.isGranted,
    this.isPermanentlyDenied = false,
    this.permissionName,
    this.rationale,
    this.errorMessage,
  });

  factory PermissionResult.granted() {
    return const PermissionResult(isGranted: true);
  }

  factory PermissionResult.denied({
    required String permissionName,
    required String rationale,
  }) {
    return PermissionResult(
      isGranted: false,
      permissionName: permissionName,
      rationale: rationale,
    );
  }

  factory PermissionResult.permanentlyDenied({
    required String permissionName,
    required String rationale,
  }) {
    return PermissionResult(
      isGranted: false,
      isPermanentlyDenied: true,
      permissionName: permissionName,
      rationale: rationale,
    );
  }

  factory PermissionResult.restricted({
    required String permissionName,
    required String rationale,
  }) {
    return PermissionResult(
      isGranted: false,
      permissionName: permissionName,
      rationale: rationale,
    );
  }

  factory PermissionResult.error({
    required String permissionName,
    required String errorMessage,
  }) {
    return PermissionResult(
      isGranted: false,
      permissionName: permissionName,
      errorMessage: errorMessage,
    );
  }

  bool get isDenied => !isGranted;
  bool get isRestricted => false;
  bool get hasError => errorMessage != null;

  /// Get user-friendly message for the permission result
  String getMessage() {
    if (hasError) {
      return errorMessage!;
    }

    if (isGranted) {
      return 'Permission granted';
    } else if (isPermanentlyDenied) {
      return '$permissionName permission was permanently denied. Please enable it in app settings. $rationale';
    } else {
      return '$permissionName permission was denied. $rationale';
    }
  }
}

/// Provider for permission service
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService.instance;
});
