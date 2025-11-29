import 'package:flutter/material.dart';

class EcoTask {
  final String id;
  final String title;
  final String description;
  final String category;
  final int points;
  final String impact;
  final String difficulty;
  final String icon;
  final bool isCompleted;
  final DateTime? completedAt;

  EcoTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.points,
    required this.impact,
    required this.difficulty,
    required this.icon,
    this.isCompleted = false,
    this.completedAt,
  });

  /// Creates an EcoTask from JSON data
  factory EcoTask.fromJson(Map<String, dynamic> json) {
    return EcoTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      points: json['points'] as int,
      impact: json['impact'] as String,
      difficulty: json['difficulty'] as String,
      icon: json['icon'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// Converts the EcoTask to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'points': points,
      'impact': impact,
      'difficulty': difficulty,
      'icon': icon,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Creates a copy of this EcoTask with optionally updated values
  EcoTask copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? points,
    String? impact,
    String? difficulty,
    String? icon,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return EcoTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      points: points ?? this.points,
      impact: impact ?? this.impact,
      difficulty: difficulty ?? this.difficulty,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Get difficulty color
  Color get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'hard':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  String toString() {
    return 'EcoTask(id: $id, title: $title, category: $category, points: $points, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EcoTask && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
