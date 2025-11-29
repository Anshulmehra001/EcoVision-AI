import 'package:flutter_test/flutter_test.dart';
import 'package:ecovisionai/core/models/user_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProgress Model Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should create initial UserProgress with default values', () {
      final progress = UserProgress.initial();

      expect(progress.totalPoints, 0);
      expect(progress.completedTaskIds, isEmpty);
      expect(progress.categoryProgress, isEmpty);
      expect(progress.lastUpdated, isA<DateTime>());
    });

    test('should add points correctly', () {
      final progress = UserProgress.initial();
      final updated = progress.addPoints(50);

      expect(updated.totalPoints, 50);
      expect(updated.completedTaskIds, progress.completedTaskIds);
    });

    test('should complete task and add points', () {
      final progress = UserProgress.initial();
      final updated = progress.completeTask(1, 30);

      expect(updated.totalPoints, 30);
      expect(updated.completedTaskIds, contains(1));
    });

    test('should not duplicate completed task IDs', () {
      final progress = UserProgress.initial();
      final updated1 = progress.completeTask(1, 30);
      final updated2 = updated1.completeTask(1, 30);

      expect(updated2.completedTaskIds.length, 1);
      expect(updated2.totalPoints, 60);
    });

    test('should track category progress', () {
      final progress = UserProgress.initial();
      final updated = progress.completeTask(1, 30, category: 'flora');

      expect(updated.getCategoryProgress('flora'), 30);
      expect(updated.getCategoryProgress('water'), 0);
    });

    test('should check if task is completed', () {
      final progress = UserProgress.initial();
      final updated = progress.completeTask(1, 30);

      expect(updated.isTaskCompleted(1), true);
      expect(updated.isTaskCompleted(2), false);
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final progress = UserProgress(
        totalPoints: 100,
        completedTaskIds: [1, 2, 3],
        categoryProgress: {'flora': 50, 'water': 50},
        lastUpdated: timestamp,
      );

      final json = progress.toJson();

      expect(json['totalPoints'], 100);
      expect(json['completedTaskIds'], [1, 2, 3]);
      expect(json['categoryProgress'], {'flora': 50, 'water': 50});
      expect(json['lastUpdated'], timestamp.toIso8601String());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'totalPoints': 150,
        'completedTaskIds': [1, 2, 3, 4],
        'categoryProgress': {'flora': 75, 'bird': 75},
        'lastUpdated': '2024-01-01T12:00:00.000',
      };

      final progress = UserProgress.fromJson(json);

      expect(progress.totalPoints, 150);
      expect(progress.completedTaskIds, [1, 2, 3, 4]);
      expect(progress.categoryProgress, {'flora': 75, 'bird': 75});
      expect(progress.lastUpdated, DateTime(2024, 1, 1, 12, 0, 0));
    });

    test('should save and load from SharedPreferences', () async {
      final progress = UserProgress(
        totalPoints: 200,
        completedTaskIds: [1, 2],
        categoryProgress: {'test': 100},
        lastUpdated: DateTime.now(),
      );

      await progress.save();
      final loaded = await UserProgress.load();

      expect(loaded.totalPoints, 200);
      expect(loaded.completedTaskIds, [1, 2]);
      expect(loaded.categoryProgress, {'test': 100});
    });

    test('should return initial progress if load fails', () async {
      final loaded = await UserProgress.load();

      expect(loaded.totalPoints, 0);
      expect(loaded.completedTaskIds, isEmpty);
    });

    test('should create copy with updated values', () {
      final original = UserProgress.initial();
      final copy = original.copyWith(
        totalPoints: 100,
        completedTaskIds: [1, 2],
      );

      expect(copy.totalPoints, 100);
      expect(copy.completedTaskIds, [1, 2]);
      expect(copy.categoryProgress, original.categoryProgress);
    });
  });
}
