import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProgress {
  final int totalPoints;
  final List<String> completedTaskIds;
  final Map<String, int> categoryProgress;
  final DateTime lastUpdated;

  UserProgress({
    required this.totalPoints,
    required this.completedTaskIds,
    required this.categoryProgress,
    required this.lastUpdated,
  });

  factory UserProgress.initial() {
    return UserProgress(
      totalPoints: 0,
      completedTaskIds: [],
      categoryProgress: {},
      lastUpdated: DateTime.now(),
    );
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalPoints: json['totalPoints'] as int,
      completedTaskIds: List<String>.from(json['completedTaskIds'] as List),
      categoryProgress: Map<String, int>.from(json['categoryProgress'] as Map),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPoints': totalPoints,
      'completedTaskIds': completedTaskIds,
      'categoryProgress': categoryProgress,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  static Future<UserProgress> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('user_progress');
      if (jsonString == null) return UserProgress.initial();
      return UserProgress.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return UserProgress.initial();
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_progress', jsonEncode(toJson()));
    } catch (e) {
      // Ignore save errors
    }
  }

  UserProgress addPoints(int points) {
    return copyWith(
      totalPoints: totalPoints + points,
      lastUpdated: DateTime.now(),
    );
  }

  UserProgress completeTask(String taskId, int points, {String? category}) {
    if (completedTaskIds.contains(taskId)) return this;
    
    final newCompletedIds = [...completedTaskIds, taskId];
    final newCategoryProgress = Map<String, int>.from(categoryProgress);
    
    if (category != null) {
      newCategoryProgress[category] = (newCategoryProgress[category] ?? 0) + 1;
    }
    
    return copyWith(
      totalPoints: totalPoints + points,
      completedTaskIds: newCompletedIds,
      categoryProgress: newCategoryProgress,
      lastUpdated: DateTime.now(),
    );
  }

  bool isTaskCompleted(String taskId) => completedTaskIds.contains(taskId);

  UserProgress copyWith({
    int? totalPoints,
    List<String>? completedTaskIds,
    Map<String, int>? categoryProgress,
    DateTime? lastUpdated,
  }) {
    return UserProgress(
      totalPoints: totalPoints ?? this.totalPoints,
      completedTaskIds: completedTaskIds ?? this.completedTaskIds,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
