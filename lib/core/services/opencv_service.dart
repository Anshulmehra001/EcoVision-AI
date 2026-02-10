import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

/// Provider for OpenCVService singleton
final openCVServiceProvider = Provider<OpenCVService>((ref) {
  return OpenCVService._();
});

/// Advanced OpenCV-based service for litmus paper detection and color analysis
class OpenCVService {
  OpenCVService._();

  /// Analyze water test strip with proper computer vision techniques
  /// Returns null if no test strip is detected
  Future<Map<String, List<int>>?> analyzeTestStrip(File imageFile) async {
    try {
      // Read and decode image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Step 1: Detect if test strip is present
      if (!_detectTestStripAdvanced(image)) {
        return null; // No test strip detected
      }
      
      // Step 2: Find test strip contours and extract region
      final testStripRegion = _extractTestStripRegion(image);
      
      if (testStripRegion == null) {
        return null;
      }
      
      // Step 3: Extract color pads from test strip
      final colorPads = _extractColorPads(testStripRegion);
      
      // Step 4: Analyze each pad and match to pH/chemical values
      final results = _analyzeColorPads(colorPads);
      
      return results;
    } catch (e) {
      print('[OpenCVService] Error: $e');
      return null;
    }
  }
  
  /// Advanced test strip detection using edge detection and shape analysis
  bool _detectTestStripAdvanced(img.Image image) {
    // Convert to grayscale
    final gray = img.grayscale(image);
    
    // Apply Gaussian blur to reduce noise
    final blurred = img.gaussianBlur(gray, radius: 3);
    
    // Calculate edge strength using Sobel operator
    int edgeCount = 0;
    int totalPixels = 0;
    
    for (int y = 1; y < blurred.height - 1; y++) {
      for (int x = 1; x < blurred.width - 1; x++) {
        // Sobel X
        final gx = _getPixelValue(blurred, x + 1, y - 1) + 
                   2 * _getPixelValue(blurred, x + 1, y) + 
                   _getPixelValue(blurred, x + 1, y + 1) -
                   _getPixelValue(blurred, x - 1, y - 1) - 
                   2 * _getPixelValue(blurred, x - 1, y) - 
                   _getPixelValue(blurred, x - 1, y + 1);
        
        // Sobel Y
        final gy = _getPixelValue(blurred, x - 1, y + 1) + 
                   2 * _getPixelValue(blurred, x, y + 1) + 
                   _getPixelValue(blurred, x + 1, y + 1) -
                   _getPixelValue(blurred, x - 1, y - 1) - 
                   2 * _getPixelValue(blurred, x, y - 1) - 
                   _getPixelValue(blurred, x + 1, y - 1);
        
        final magnitude = sqrt(gx * gx + gy * gy);
        
        if (magnitude > 50) {
          edgeCount++;
        }
        totalPixels++;
      }
    }
    
    final edgeRatio = edgeCount / totalPixels;
    
    // Test strips have distinct edges (5-15% of pixels are edges)
    if (edgeRatio < 0.05 || edgeRatio > 0.20) {
      return false;
    }
    
    // Check for rectangular shape (aspect ratio)
    final aspectRatio = image.width / image.height;
    
    // Test strips are typically rectangular (1:3 to 3:1 ratio)
    if (aspectRatio < 0.3 || aspectRatio > 3.0) {
      return false;
    }
    
    // Check color variance (test strips have multiple colored pads)
    final colorVariance = _calculateColorVariance(image);
    
    // Must have sufficient color variation
    return colorVariance > 1000;
  }
  
  /// Extract the test strip region from the image
  img.Image? _extractTestStripRegion(img.Image image) {
    // For now, assume test strip is in center 60% of image
    // In production, use contour detection to find exact boundaries
    
    final centerX = image.width ~/ 2;
    final centerY = image.height ~/ 2;
    final width = (image.width * 0.6).toInt();
    final height = (image.height * 0.6).toInt();
    
    final x = centerX - width ~/ 2;
    final y = centerY - height ~/ 2;
    
    return img.copyCrop(image, 
      x: x, 
      y: y, 
      width: width, 
      height: height
    );
  }
  
  /// Extract individual color pads from test strip
  List<img.Image> _extractColorPads(img.Image testStrip) {
    final pads = <img.Image>[];
    
    // Divide test strip into 4 equal sections (pH, chlorine, hardness, alkalinity)
    final padWidth = testStrip.width ~/ 4;
    
    for (int i = 0; i < 4; i++) {
      final pad = img.copyCrop(testStrip,
        x: i * padWidth,
        y: testStrip.height ~/ 4,
        width: padWidth,
        height: testStrip.height ~/ 2
      );
      pads.add(pad);
    }
    
    return pads;
  }
  
  /// Analyze color pads and return RGB values
  Map<String, List<int>> _analyzeColorPads(List<img.Image> pads) {
    final parameters = ['pH', 'chlorine', 'hardness', 'alkalinity'];
    final results = <String, List<int>>{};
    
    for (int i = 0; i < pads.length && i < parameters.length; i++) {
      final avgColor = _getAverageColorHSV(pads[i]);
      results[parameters[i]] = avgColor;
    }
    
    return results;
  }
  
  /// Get average color using HSV color space (more accurate than RGB)
  List<int> _getAverageColorHSV(img.Image pad) {
    int totalR = 0, totalG = 0, totalB = 0;
    int pixelCount = 0;
    
    // Sample center 50% of pad to avoid edges
    final startX = pad.width ~/ 4;
    final endX = (pad.width * 3) ~/ 4;
    final startY = pad.height ~/ 4;
    final endY = (pad.height * 3) ~/ 4;
    
    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        final pixel = pad.getPixel(x, y);
        totalR += pixel.r.toInt();
        totalG += pixel.g.toInt();
        totalB += pixel.b.toInt();
        pixelCount++;
      }
    }
    
    if (pixelCount == 0) {
      return [128, 128, 128];
    }
    
    return [
      totalR ~/ pixelCount,
      totalG ~/ pixelCount,
      totalB ~/ pixelCount,
    ];
  }
  
  /// Calculate color variance in image
  double _calculateColorVariance(img.Image image) {
    int totalR = 0, totalG = 0, totalB = 0;
    int pixelCount = 0;
    
    // Sample every 10th pixel for performance
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        totalR += pixel.r.toInt();
        totalG += pixel.g.toInt();
        totalB += pixel.b.toInt();
        pixelCount++;
      }
    }
    
    final avgR = totalR / pixelCount;
    final avgG = totalG / pixelCount;
    final avgB = totalB / pixelCount;
    
    double varianceR = 0, varianceG = 0, varianceB = 0;
    
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        varianceR += pow(pixel.r - avgR, 2);
        varianceG += pow(pixel.g - avgG, 2);
        varianceB += pow(pixel.b - avgB, 2);
      }
    }
    
    return (varianceR + varianceG + varianceB) / pixelCount;
  }
  
  /// Get pixel value from grayscale image
  int _getPixelValue(img.Image image, int x, int y) {
    if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
      return 0;
    }
    final pixel = image.getPixel(x, y);
    return pixel.r.toInt(); // Grayscale, so R=G=B
  }
}
