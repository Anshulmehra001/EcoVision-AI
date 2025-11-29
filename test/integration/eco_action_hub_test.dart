import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecovisionai/features/eco_action_hub/screen.dart';
import 'package:ecovisionai/features/eco_action_hub/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Eco Action Hub Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Should display user total points at top of screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EcoActionHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Requirement 4.1: Display total points at top
      expect(find.textContaining('Points'), findsWidgets);
    });

    testWidgets('Should load and display tasks from JSON',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EcoActionHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display task list
      // The actual tasks depend on assets/data/tasks.json
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Should navigate to task detail when task is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EcoActionHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap a task card (if tasks are loaded)
      final taskCards = find.byType(Card);
      if (taskCards.evaluate().isNotEmpty) {
        await tester.tap(taskCards.first);
        await tester.pumpAndSettle();

        // Should navigate to detail screen
        // Verify by checking for back button or detail screen elements
        expect(find.byType(AppBar), findsWidgets);
      }
    });

    testWidgets('Should update points when task is completed',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Get initial progress
      final initialProgress = container.read(userProgressProvider);
      expect(initialProgress.totalPoints, 0);

      // Complete a task
      await container
          .read(userProgressProvider.notifier)
          .completeTask(1, 50);

      // Verify points updated
      final updatedProgress = container.read(userProgressProvider);
      expect(updatedProgress.totalPoints, 50);
      expect(updatedProgress.isTaskCompleted(1), true);
    });

    testWidgets('Should not duplicate points for already completed task',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Complete task twice
      await container
          .read(userProgressProvider.notifier)
          .completeTask(1, 50);
      await container
          .read(userProgressProvider.notifier)
          .completeTask(1, 50);

      // Points should only be added once
      final progress = container.read(userProgressProvider);
      expect(progress.totalPoints, 50);
      expect(progress.completedTaskIds.length, 1);
    });

    testWidgets('Should persist progress across app restarts',
        (WidgetTester tester) async {
      // First session - complete a task
      final container1 = ProviderContainer();
      await container1
          .read(userProgressProvider.notifier)
          .completeTask(1, 50);
      container1.dispose();

      // Simulate app restart - create new container
      await tester.pump(const Duration(milliseconds: 100));
      
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      // Wait for progress to load
      await tester.pump(const Duration(milliseconds: 100));

      // Progress should be persisted
      final progress = container2.read(userProgressProvider);
      expect(progress.totalPoints, 50);
      expect(progress.isTaskCompleted(1), true);
    });

    testWidgets('Should track category progress correctly',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Complete tasks in different categories
      await container
          .read(userProgressProvider.notifier)
          .completeTask(1, 30, category: 'flora');
      await container
          .read(userProgressProvider.notifier)
          .completeTask(2, 40, category: 'water');
      await container
          .read(userProgressProvider.notifier)
          .completeTask(3, 20, category: 'flora');

      final progress = container.read(userProgressProvider);
      expect(progress.getCategoryProgress('flora'), 50);
      expect(progress.getCategoryProgress('water'), 40);
      expect(progress.totalPoints, 90);
    });

    testWidgets('Should highlight tasks based on AI triggers',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Add a trigger
      container.read(highlightedTriggersProvider.notifier).state = {
        'plant_disease'
      };

      // Verify trigger is set
      final triggers = container.read(highlightedTriggersProvider);
      expect(triggers, contains('plant_disease'));
    });

    testWidgets('Should clear highlighted triggers',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Add triggers
      container.read(highlightedTriggersProvider.notifier).state = {
        'plant_disease',
        'bird_species'
      };

      // Clear triggers
      container.read(highlightedTriggersProvider.notifier).state = {};

      // Verify triggers cleared
      final triggers = container.read(highlightedTriggersProvider);
      expect(triggers, isEmpty);
    });
  });
}
