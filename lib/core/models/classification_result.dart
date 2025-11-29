class ClassificationResult {
  final String label;
  final double confidence;
  final DateTime timestamp;

  ClassificationResult({
    required this.label,
    required this.confidence,
    required this.timestamp,
  });

  /// Creates a ClassificationResult from JSON data
  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Converts the ClassificationResult to JSON format
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a copy of this ClassificationResult with optionally updated values
  ClassificationResult copyWith({
    String? label,
    double? confidence,
    DateTime? timestamp,
  }) {
    return ClassificationResult(
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'ClassificationResult(label: $label, confidence: $confidence, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassificationResult &&
        other.label == label &&
        other.confidence == confidence &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return label.hashCode ^ confidence.hashCode ^ timestamp.hashCode;
  }
}