import 'package:flutter_test/flutter_test.dart';
import 'package:ecovisionai/core/models/classification_result.dart';

void main() {
  group('ClassificationResult Model Tests', () {
    test('should create ClassificationResult with required fields', () {
      final timestamp = DateTime.now();
      final result = ClassificationResult(
        label: 'Healthy Plant',
        confidence: 0.95,
        timestamp: timestamp,
      );

      expect(result.label, 'Healthy Plant');
      expect(result.confidence, 0.95);
      expect(result.timestamp, timestamp);
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final result = ClassificationResult(
        label: 'Bird Species A',
        confidence: 0.87,
        timestamp: timestamp,
      );

      final json = result.toJson();

      expect(json['label'], 'Bird Species A');
      expect(json['confidence'], 0.87);
      expect(json['timestamp'], timestamp.toIso8601String());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'label': 'Plant Disease',
        'confidence': 0.72,
        'timestamp': '2024-01-01T12:00:00.000',
      };

      final result = ClassificationResult.fromJson(json);

      expect(result.label, 'Plant Disease');
      expect(result.confidence, 0.72);
      expect(result.timestamp, DateTime(2024, 1, 1, 12, 0, 0));
    });

    test('should create copy with updated values', () {
      final original = ClassificationResult(
        label: 'Original',
        confidence: 0.5,
        timestamp: DateTime(2024, 1, 1),
      );

      final copy = original.copyWith(
        label: 'Updated',
        confidence: 0.9,
      );

      expect(copy.label, 'Updated');
      expect(copy.confidence, 0.9);
      expect(copy.timestamp, original.timestamp);
    });

    test('should compare equality correctly', () {
      final timestamp = DateTime(2024, 1, 1);
      final result1 = ClassificationResult(
        label: 'Test',
        confidence: 0.8,
        timestamp: timestamp,
      );
      final result2 = ClassificationResult(
        label: 'Test',
        confidence: 0.8,
        timestamp: timestamp,
      );
      final result3 = ClassificationResult(
        label: 'Different',
        confidence: 0.8,
        timestamp: timestamp,
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });
  });
}
