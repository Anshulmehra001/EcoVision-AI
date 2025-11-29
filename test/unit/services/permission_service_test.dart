import 'package:flutter_test/flutter_test.dart';
import 'package:ecovisionai/core/services/permission_service.dart';

void main() {
  group('PermissionResult Tests', () {
    test('should create granted result', () {
      final result = PermissionResult.granted();

      expect(result.isGranted, true);
      expect(result.isDenied, false);
      expect(result.isPermanentlyDenied, false);
      expect(result.hasError, false);
    });

    test('should create denied result with message', () {
      final result = PermissionResult.denied(
        permissionName: 'Camera',
        rationale: 'Camera is needed for plant detection',
      );

      expect(result.isDenied, true);
      expect(result.isGranted, false);
      expect(result.permissionName, 'Camera');
      expect(result.rationale, 'Camera is needed for plant detection');
    });

    test('should create permanently denied result', () {
      final result = PermissionResult.permanentlyDenied(
        permissionName: 'Microphone',
        rationale: 'Microphone is needed for audio recording',
      );

      expect(result.isPermanentlyDenied, true);
      expect(result.isGranted, false);
      expect(result.permissionName, 'Microphone');
    });

    test('should create restricted result', () {
      final result = PermissionResult.restricted(
        permissionName: 'Camera',
        rationale: 'Camera access is restricted',
      );

      expect(result.isRestricted, true);
      expect(result.isGranted, false);
    });

    test('should create error result', () {
      final result = PermissionResult.error(
        permissionName: 'Camera',
        errorMessage: 'Failed to request permission',
      );

      expect(result.hasError, true);
      expect(result.errorMessage, 'Failed to request permission');
    });

    test('should provide user-friendly message for granted', () {
      final result = PermissionResult.granted();
      expect(result.getMessage(), 'Permission granted');
    });

    test('should provide user-friendly message for denied', () {
      final result = PermissionResult.denied(
        permissionName: 'Camera',
        rationale: 'Needed for photos',
      );
      expect(result.getMessage(), contains('Camera permission was denied'));
      expect(result.getMessage(), contains('Needed for photos'));
    });

    test('should provide user-friendly message for permanently denied', () {
      final result = PermissionResult.permanentlyDenied(
        permissionName: 'Microphone',
        rationale: 'Needed for audio',
      );
      expect(result.getMessage(), contains('permanently denied'));
      expect(result.getMessage(), contains('app settings'));
    });

    test('should provide error message when has error', () {
      final result = PermissionResult.error(
        permissionName: 'Camera',
        errorMessage: 'Custom error',
      );
      expect(result.getMessage(), 'Custom error');
    });
  });

  group('PermissionService Tests', () {
    test('should return singleton instance', () {
      final instance1 = PermissionService.instance;
      final instance2 = PermissionService.instance;

      expect(instance1, same(instance2));
    });

    test('should check camera availability', () async {
      final service = PermissionService.instance;
      final isAvailable = await service.isCameraAvailable();

      expect(isAvailable, isA<bool>());
    });

    test('should check microphone availability', () async {
      final service = PermissionService.instance;
      final isAvailable = await service.isMicrophoneAvailable();

      expect(isAvailable, isA<bool>());
    });
  });
}
