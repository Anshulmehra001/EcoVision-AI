import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to check internet connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connection
  Future<bool> isOnline() async {
    try {
      // First check connectivity status
      var connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Verify actual internet access by pinging Google DNS
      try {
        final result = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 3),
        );
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    } catch (e) {
      debugPrint('[ConnectivityService] Error checking connectivity: $e');
      return false;
    }
  }

  /// Get connectivity status stream
  Stream<ConnectivityResult> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}
