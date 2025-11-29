import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for OpenCVService singleton
final openCVServiceProvider = Provider<OpenCVService>((ref) {
  return OpenCVService._();
});

/// Service for handling basic image analysis without OpenCV
/// (Simplified version to avoid OpenCV C++ linking issues)
class OpenCVService {
  OpenCVService._();

  /// Analyze water test strip and extract color values from predefined regions
  /// This is a simplified version that extracts average colors from regions
  Future<Map<String, List<int>>> analyzeTestStrip(File image) async {
    try {
      // Read image bytes
      final imageBytes = await image.readAsBytes();
      
      // Decode image
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final imageData = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      
      if (imageData == null) {
        throw Exception('Failed to decode image');
      }
      
      final width = frame.image.width;
      final height = frame.image.height;
      final pixels = imageData.buffer.asUint8List();
      
      // Define predefined regions for different test parameters
      // These are example regions - in a real app, these would be calibrated
      final regions = {
        'pH': _Region(50, 100, 80, 40),
        'chlorine': _Region(150, 100, 80, 40),
        'hardness': _Region(250, 100, 80, 40),
        'alkalinity': _Region(350, 100, 80, 40),
      };
      
      final results = <String, List<int>>{};
      
      // Extract average color from each region
      for (final entry in regions.entries) {
        final parameterName = entry.key;
        final region = entry.value;
        
        // Ensure region is within image bounds
        if (region.x + region.width <= width && 
            region.y + region.height <= height) {
          final color = _extractRegionColor(pixels, width, height, region);
          results[parameterName] = color;
        } else {
          // If region is out of bounds, use a default color
          results[parameterName] = [128, 128, 128]; // Gray
        }
      }
      
      return results;
    } catch (e) {
      // Return default values if analysis fails
      return {
        'pH': [128, 128, 128],
        'chlorine': [128, 128, 128],
        'hardness': [128, 128, 128],
        'alkalinity': [128, 128, 128],
      };
    }
  }
  
  /// Extract average RGB color from a region of the image
  List<int> _extractRegionColor(Uint8List pixels, int width, int height, _Region region) {
    int totalR = 0;
    int totalG = 0;
    int totalB = 0;
    int pixelCount = 0;
    
    // Sample pixels in the region
    for (int y = region.y; y < region.y + region.height; y++) {
      for (int x = region.x; x < region.x + region.width; x++) {
        final index = (y * width + x) * 4; // RGBA format
        
        if (index + 2 < pixels.length) {
          totalR += pixels[index];
          totalG += pixels[index + 1];
          totalB += pixels[index + 2];
          pixelCount++;
        }
      }
    }
    
    if (pixelCount == 0) {
      return [128, 128, 128]; // Default gray
    }
    
    // Calculate average
    final avgR = (totalR / pixelCount).round();
    final avgG = (totalG / pixelCount).round();
    final avgB = (totalB / pixelCount).round();
    
    return [avgR, avgG, avgB];
  }
}

/// Simple region class
class _Region {
  final int x;
  final int y;
  final int width;
  final int height;
  
  _Region(this.x, this.y, this.width, this.height);
}
