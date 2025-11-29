import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';

/// Reusable dialog for permission requests and error handling
class PermissionDialog extends StatelessWidget {
  final PermissionResult permissionResult;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const PermissionDialog({
    super.key,
    required this.permissionResult,
    this.onRetry,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getTitle()),
      content: Text(permissionResult.getMessage()),
      actions: _buildActions(context),
    );
  }

  String _getTitle() {
    if (permissionResult.isGranted) {
      return 'Permission Granted';
    } else if (permissionResult.isPermanentlyDenied) {
      return 'Permission Required';
    } else if (permissionResult.isRestricted) {
      return 'Access Restricted';
    } else if (permissionResult.hasError) {
      return 'Error';
    } else {
      return 'Permission Denied';
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    // Cancel button (always available except when granted)
    if (!permissionResult.isGranted) {
      actions.add(
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
          child: const Text('Cancel'),
        ),
      );
    }

    // Settings button for permanently denied permissions
    if (permissionResult.isPermanentlyDenied) {
      actions.add(
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      );
    }

    // Retry button for denied (but not permanently) permissions
    if (permissionResult.isDenied && !permissionResult.isPermanentlyDenied) {
      actions.add(
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRetry?.call();
          },
          child: const Text('Retry'),
        ),
      );
    }

    // OK button for granted or restricted
    if (permissionResult.isGranted || permissionResult.isRestricted) {
      actions.add(
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      );
    }

    return actions;
  }

  /// Show permission dialog
  static Future<void> show(
    BuildContext context,
    PermissionResult permissionResult, {
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDialog(
        permissionResult: permissionResult,
        onRetry: onRetry,
        onCancel: onCancel,
      ),
    );
  }
}

/// Widget to display when a feature is unavailable due to missing permissions
class PermissionDeniedWidget extends StatelessWidget {
  final String featureName;
  final String permissionName;
  final String rationale;
  final VoidCallback onRequestPermission;

  const PermissionDeniedWidget({
    super.key,
    required this.featureName,
    required this.permissionName,
    required this.rationale,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '$featureName Unavailable',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              rationale,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRequestPermission,
              icon: const Icon(Icons.security),
              label: Text('Grant $permissionName Permission'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display when hardware is unavailable
class HardwareUnavailableWidget extends StatelessWidget {
  final String featureName;
  final String hardwareName;
  final String message;

  const HardwareUnavailableWidget({
    super.key,
    required this.featureName,
    required this.hardwareName,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hardware,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '$featureName Unavailable',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This device does not have a compatible $hardwareName.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
