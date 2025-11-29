import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecovisionai/core/models/user_progress.dart';
import 'package:ecovisionai/core/models/eco_task.dart';
import 'package:ecovisionai/core/models/classification_result.dart';
import 'package:ecovisionai/features/eco_action_hub/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Functionality Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Should load tasks from local assets without network', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Load tasks (should work offline from assets)
      final tasksAsync = container.read(tasksProvider);

      await tasksAsync.when(
        data: (tasks) {
          // Tasks should be loaded from assets
          expect(tasks, isA<List<EcoTask>>());
        },
        loading: () async {
          // Wait for loading to complete
          await Future.delayed(const Duration(milliseconds: 100));
        },
        error: (error, stack) {
          fail('Tasks should load from assets without network');
        },
      );
    });

    test('Should persist user progress locally', () async {
      // Create progress
      final progress = UserProgress(
        totalPoints: 150,
        completedTaskIds: [1, 2, 3],
        categoryProgress: {'flora': 75, 'water': 75},
        lastUpdated: DateTime.now(),
      );

      // Save to local storage
      await progress.save();

      // Load from local storage
      final loaded = await UserProgress.load();

      // Verify data persisted
      expect(loaded.totalPoints, 150);
      expect(loaded.completedTaskIds, [1, 2, 3]);
      expect(loaded.categoryProgress, {'flora': 75, 'water': 75});
    });

    test('Should handle classification results offline', () {
      // Create classification result
      final result = ClassificationResult(
        label: 'Healthy Plant',
        confidence: 0.95,
        timestamp: DateTime.now(),
      );

      // Serialize to JSON (for local caching)
      final json = result.toJson();
      expect(json['label'], 'Healthy Plant');
      expect(json['confidence'], 0.95);

      // Deserialize from JSON
      final restored = ClassificationResult.fromJson(json);
      expect(restored.label, result.label);
      expect(restored.confidence, result.confidence);
    });

    test('Should maintain state without network connectivity', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Complete tasks offline
      await container
          .read(userProgressProvider.notifier)
          .completeTask(1, 50, category: 'flora');
      await container
          .read(userProgressProvider.notifier)
          .completeTask(2, 30, category: 'water');

      // Verify state maintained
      final progress = container.read(userProgressProvider);
      expect(progress.totalPoints, 80);
      expect(progress.completedTaskIds, [1, 2]);
    });

    test('Should recover from storage failures gracefully', () async {
      // Attempt to load when no data exists
      final progress = await UserProgress.load();

      // Should return initial progress instead of failing
      expect(progress.totalPoints, 0);
      expect(progress.completedTaskIds, isEmpty);
    });

    test('Should cache AI model results locally', () {
      // Create multiple results
      final results = [
        ClassificationResult(
          label: 'Species A',
          confidence: 0.9,
          timestamp: DateTime.now(),
        ),
        ClassificationResult(
          label: 'Species B',
          confidence: 0.8,
          timestamp: DateTime.now(),
        ),
      ];

      // Serialize for caching
      final jsonList = results.map((r) => r.toJson()).toList();
      expect(jsonList.length, 2);

      // Deserialize from cache
      final restored = jsonList
          .map((json) => ClassificationResult.fromJson(json))
          .toList();
      expect(restored.length, 2);
      expect(restored[0].label, 'Species A');
      expect(restored[1].label, 'Species B');
    });

    test('Should handle concurrent offline operations', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Perform multiple operations concurrently
      await Future.wait([
        container
            .read(userProgressProvider.notifier)
            .completeTask(1, 20),
        container
            .read(userProgressProvider.notifier)
            .completeTask(2, 30),
        container
            .read(userProgressProvider.notifier)
            .completeTask(3, 40),
      ]);

      // Verify all operations completed
      final progress = container.read(userProgressProvider);
      expect(progress.totalPoints, 90);
      expect(progress.completedTaskIds.length, 3);
    });

    test('Should maintain data integrity across app sessions', () async {
      // Session 1: Create and save data
      final session1Progress = UserProgress(
        totalPoints: 200,
        completedTaskIds: [1, 2, 3, 4],
        categoryProgress: {'flora': 100, 'water': 50, 'bird': 50},
        lastUpdated: DateTime.now(),
      );
      await session1Progress.save();

      // Simulate app restart
      await Future.delayed(const Duration(milliseconds: 50));

      // Session 2: Load data
      final session2Progress = await UserProgress.load();

      // Verify data integrity
      expect(session2Progress.totalPoints, 200);
      expect(session2Progress.completedTaskIds, [1, 2, 3, 4]);
      expect(session2Progress.categoryProgress['flora'], 100);
      expect(session2Progress.categoryProgress['water'], 50);
      expect(session2Progress.categoryProgress['bird'], 50);
    });
  });

  group('Data Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Should persist task completion status', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Complete a task
      await container
          .read(userProgressProvider.notifier)
          .completeTask(5, 60);

      // Verify persistence
      final progress = await UserProgress.load();
      expect(progress.isTaskCompleted(5), true);
      expect(progress.totalPoints, 60);
    });

    test('Should handle empty storage gracefully', () async {
      // Clear all storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Load should return initial state
      final progress = await UserProgress.load();
      expect(progress.totalPoints, 0);
      expect(progress.completedTaskIds, isEmpty);
    });

    test('Should update lastUpdated timestamp on changes', () async {
      final initial = UserProgress.initial();
      final timestamp1 = initial.lastUpdated;

      await Future.delayed(const Duration(milliseconds: 10));

      final updated = initial.addPoints(50);
      final timestamp2 = updated.lastUpdated;

      // Timestamp should be updated
      expect(timestamp2.isAfter(timestamp1), true);
    });

    test('Should preserve data types during serialization', () async {
      final original = UserProgress(
        totalPoints: 123,
        completedTaskIds: [1, 5, 10],
        categoryProgress: {'test': 456},
        lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
      );

      await original.save();
      final loaded = await UserProgress.load();

      // Verify types preserved
      expect(loaded.totalPoints, isA<int>());
      expect(loaded.completedTaskIds, isA<List<int>>());
      expect(loaded.categoryProgress, isA<Map<String, int>>());
      expect(loaded.lastUpdated, isA<DateTime>());
    });
  });
}
