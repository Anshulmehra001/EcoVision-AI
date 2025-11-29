import 'package:flutter_test/flutter_test.dart';
import 'package:ecovisionai/core/models/eco_task.dart';

void main() {
  group('EcoTask Model Tests', () {
    test('should create EcoTask with all required fields', () {
      final task = EcoTask(
        id: 1,
        title: 'Plant a Tree',
        description: 'Help the environment',
        instructions: 'Find a suitable location',
        points: 50,
        trigger: 'plant_disease',
        isCompleted: false,
      );

      expect(task.id, 1);
      expect(task.title, 'Plant a Tree');
      expect(task.description, 'Help the environment');
      expect(task.instructions, 'Find a suitable location');
      expect(task.points, 50);
      expect(task.trigger, 'plant_disease');
      expect(task.isCompleted, false);
    });

    test('should default isCompleted to false', () {
      final task = EcoTask(
        id: 1,
        title: 'Test Task',
        description: 'Test',
        instructions: 'Test',
        points: 10,
        trigger: 'test',
      );

      expect(task.isCompleted, false);
    });

    test('should serialize to JSON correctly', () {
      final task = EcoTask(
        id: 2,
        title: 'Clean Water',
        description: 'Test water quality',
        instructions: 'Use test strips',
        points: 30,
        trigger: 'water_quality',
        isCompleted: true,
      );

      final json = task.toJson();

      expect(json['id'], 2);
      expect(json['title'], 'Clean Water');
      expect(json['description'], 'Test water quality');
      expect(json['instructions'], 'Use test strips');
      expect(json['points'], 30);
      expect(json['trigger'], 'water_quality');
      expect(json['isCompleted'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 3,
        'title': 'Bird Watching',
        'description': 'Identify species',
        'instructions': 'Record audio',
        'points': 40,
        'trigger': 'bird_species',
        'isCompleted': false,
      };

      final task = EcoTask.fromJson(json);

      expect(task.id, 3);
      expect(task.title, 'Bird Watching');
      expect(task.description, 'Identify species');
      expect(task.instructions, 'Record audio');
      expect(task.points, 40);
      expect(task.trigger, 'bird_species');
      expect(task.isCompleted, false);
    });

    test('should create copy with updated values', () {
      final original = EcoTask(
        id: 1,
        title: 'Original',
        description: 'Original desc',
        instructions: 'Original inst',
        points: 10,
        trigger: 'original',
        isCompleted: false,
      );

      final copy = original.copyWith(
        title: 'Updated',
        isCompleted: true,
      );

      expect(copy.title, 'Updated');
      expect(copy.isCompleted, true);
      expect(copy.id, original.id);
      expect(copy.description, original.description);
    });

    test('should compare equality correctly', () {
      final task1 = EcoTask(
        id: 1,
        title: 'Test',
        description: 'Test',
        instructions: 'Test',
        points: 10,
        trigger: 'test',
      );
      final task2 = EcoTask(
        id: 1,
        title: 'Test',
        description: 'Test',
        instructions: 'Test',
        points: 10,
        trigger: 'test',
      );
      final task3 = EcoTask(
        id: 2,
        title: 'Different',
        description: 'Test',
        instructions: 'Test',
        points: 10,
        trigger: 'test',
      );

      expect(task1, equals(task2));
      expect(task1, isNot(equals(task3)));
    });
  });
}
