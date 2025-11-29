import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/eco_task.dart';
import '../../core/models/user_progress.dart';

final tasksProvider = FutureProvider<List<EcoTask>>((ref) async {
  try {
    final jsonString = await rootBundle.loadString('assets/data/eco_tasks.json');
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    final tasksList = jsonData['tasks'] as List<dynamic>;
    return tasksList.map((taskJson) => EcoTask.fromJson(taskJson as Map<String, dynamic>)).toList();
  } catch (e) {
    return [];
  }
});

final userProgressProvider = StateNotifierProvider<UserProgressNotifier, UserProgress>((ref) {
  return UserProgressNotifier();
});

class UserProgressNotifier extends StateNotifier<UserProgress> {
  UserProgressNotifier() : super(UserProgress.initial()) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await UserProgress.load();
    state = progress;
  }

  Future<void> addPoints(int points) async {
    state = state.addPoints(points);
    await state.save();
  }

  Future<void> completeTask(String taskId, int points, {String? category}) async {
    if (!state.isTaskCompleted(taskId)) {
      state = state.completeTask(taskId, points, category: category);
      await state.save();
    }
  }

  bool isTaskCompleted(String taskId) => state.isTaskCompleted(taskId);

  Future<void> reset() async {
    state = UserProgress.initial();
    await state.save();
  }
}

final tasksWithStatusProvider = Provider<AsyncValue<List<EcoTask>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final userProgress = ref.watch(userProgressProvider);
  
  return tasksAsync.when(
    data: (tasks) {
      final tasksWithStatus = tasks.map((task) {
        return task.copyWith(
          isCompleted: userProgress.isTaskCompleted(task.id),
        );
      }).toList();
      return AsyncValue.data(tasksWithStatus);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
