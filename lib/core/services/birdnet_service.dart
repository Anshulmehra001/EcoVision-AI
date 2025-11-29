import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/classification_result.dart';

/// BirdNET Cloud API service for high-accuracy bird identification
class BirdNetService {
  static const String apiUrl = 'https://api.birdnet.cornell.edu/analyze';
  static const Duration timeout = Duration(seconds: 30);

  /// Identify bird from audio file using BirdNET API
  Future<List<ClassificationResult>> identifyBird(
    String audioPath, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      debugPrint('[BirdNetService] Analyzing audio with BirdNET API...');

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioPath),
      );

      // Add optional location parameters for better accuracy
      if (latitude != null && longitude != null) {
        request.fields['lat'] = latitude.toString();
        request.fields['lon'] = longitude.toString();
      }

      // Add week of year for seasonal filtering
      var now = DateTime.now();
      var weekOfYear = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).ceil();
      request.fields['week'] = weekOfYear.toString();

      // Send request with timeout
      var streamedResponse = await request.send().timeout(timeout);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        var results = _parseResults(jsonData);
        
        debugPrint('[BirdNetService] ✓ Received ${results.length} results from BirdNET');
        return results;
      } else {
        throw Exception('BirdNET API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[BirdNetService] ✗ Error: $e');
      rethrow;
    }
  }

  /// Parse BirdNET API response
  List<ClassificationResult> _parseResults(Map<String, dynamic> json) {
    var results = <ClassificationResult>[];

    if (json.containsKey('results')) {
      var resultsList = json['results'] as List;
      
      for (var item in resultsList) {
        results.add(ClassificationResult(
          label: item['species'] ?? item['common_name'] ?? 'Unknown',
          confidence: (item['confidence'] ?? 0.0).toDouble(),
          timestamp: DateTime.now(),
        ));
      }
    }

    // Sort by confidence
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return results.take(5).toList();
  }

  /// Check if BirdNET API is available
  Future<bool> isAvailable() async {
    try {
      var response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200 || response.statusCode == 405; // 405 = Method not allowed (but server is up)
    } catch (e) {
      return false;
    }
  }
}
