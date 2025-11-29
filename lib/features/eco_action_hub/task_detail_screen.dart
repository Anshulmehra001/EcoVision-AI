import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/eco_task.dart';
import 'providers.dart';

class TaskDetailScreen extends ConsumerWidget {
  final EcoTask task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProgress = ref.watch(userProgressProvider);
    final isCompleted = userProgress.isTaskCompleted(task.id);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, theme, isCompleted),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(theme),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(theme),
                  const SizedBox(height: 16),
                  _buildImpactCard(theme),
                  const SizedBox(height: 24),
                  if (!isCompleted)
                    _buildCompleteButton(context, ref, theme)
                  else
                    _buildCompletedBadge(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [Colors.green, Colors.green[700]!]
              : [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.eco,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem(
              icon: Icons.stars,
              label: 'Points',
              value: '${task.points}',
              color: Colors.amber[700]!,
              theme: theme,
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey[300],
            ),
            _buildInfoItem(
              icon: Icons.signal_cellular_alt,
              label: 'Difficulty',
              value: task.difficulty,
              color: _getDifficultyColor(task.difficulty),
              theme: theme,
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey[300],
            ),
            _buildInfoItem(
              icon: Icons.category,
              label: 'Category',
              value: _shortenCategory(task.category),
              color: theme.colorScheme.primary,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCard(ThemeData theme) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Environmental Impact',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.impact,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: Colors.green[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context, WidgetRef ref, ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: () {
        ref.read(userProgressProvider.notifier).completeTask(
          task.id,
          task.points,
          category: task.category,
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Task completed! +${task.points} points'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      icon: const Icon(Icons.check_circle, size: 24),
      label: const Text('Mark as Complete'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }

  Widget _buildCompletedBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 32),
          const SizedBox(width: 12),
          Text(
            'Task Completed!',
            style: TextStyle(
              color: Colors.green[900],
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _shortenCategory(String category) {
    if (category.length > 12) {
      return '${category.substring(0, 10)}...';
    }
    return category;
  }
}
