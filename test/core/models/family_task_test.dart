import 'package:flutter_test/flutter_test.dart';
import 'package:vie_de_famille/core/models/family_task.dart';

void main() {
  group('FamilyTask', () {
    late FamilyTask task;

    setUp(() {
      task = FamilyTask(
        id: 'task-1',
        title: 'Nourrir les poules',
        description: 'Matin et soir',
        assignedTo: 'member-1',
        createdBy: 'member-2',
        priority: TaskPriority.high,
        recurrence: TaskRecurrence.daily,
        category: TaskCategory.poules,
        dueDate: DateTime(2026, 4, 3),
        pointsValue: 15,
        createdAt: DateTime(2026, 4, 1),
      );
    });

    group('complete', () {
      test('should mark task as completed with completedAt timestamp', () {
        final completed = task.complete();

        expect(completed.completed, isTrue);
        expect(completed.completedAt, isNotNull);
        expect(completed.id, equals(task.id));
        expect(completed.title, equals(task.title));
        expect(completed.pointsValue, equals(task.pointsValue));
      });

      test('should preserve all other fields when completing', () {
        final completed = task.complete();

        expect(completed.description, equals(task.description));
        expect(completed.assignedTo, equals(task.assignedTo));
        expect(completed.createdBy, equals(task.createdBy));
        expect(completed.priority, equals(task.priority));
        expect(completed.recurrence, equals(task.recurrence));
        expect(completed.category, equals(task.category));
        expect(completed.dueDate, equals(task.dueDate));
        expect(completed.createdAt, equals(task.createdAt));
      });
    });

    group('uncomplete', () {
      test('should reset completed status and clear completedAt', () {
        final completed = task.complete();
        final uncompleted = completed.uncomplete();

        expect(uncompleted.completed, isFalse);
        expect(uncompleted.completedAt, isNull);
      });

      test('should preserve all other fields when uncompleting', () {
        final completed = task.complete();
        final uncompleted = completed.uncomplete();

        expect(uncompleted.id, equals(task.id));
        expect(uncompleted.title, equals(task.title));
        expect(uncompleted.assignedTo, equals(task.assignedTo));
        expect(uncompleted.pointsValue, equals(task.pointsValue));
        expect(uncompleted.priority, equals(task.priority));
        expect(uncompleted.recurrence, equals(task.recurrence));
      });
    });

    group('isOverdue', () {
      test('should return true when dueDate is in the past and not completed',
          () {
        final overdue = FamilyTask(
          id: 'task-overdue',
          title: 'Old task',
          createdBy: 'member-1',
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        );

        expect(overdue.isOverdue, isTrue);
      });

      test('should return false when task is completed even if past due', () {
        final completedPastDue = FamilyTask(
          id: 'task-done',
          title: 'Done task',
          createdBy: 'member-1',
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          completed: true,
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        );

        expect(completedPastDue.isOverdue, isFalse);
      });

      test('should return false when dueDate is in the future', () {
        final futureTask = FamilyTask(
          id: 'task-future',
          title: 'Future task',
          createdBy: 'member-1',
          dueDate: DateTime.now().add(const Duration(days: 5)),
          createdAt: DateTime.now(),
        );

        expect(futureTask.isOverdue, isFalse);
      });

      test('should return false when dueDate is null', () {
        final noDue = FamilyTask(
          id: 'task-nodue',
          title: 'No due date',
          createdBy: 'member-1',
          createdAt: DateTime.now(),
        );

        expect(noDue.isOverdue, isFalse);
      });
    });

    group('isDueToday', () {
      test('should return true when dueDate is today', () {
        final now = DateTime.now();
        final todayTask = FamilyTask(
          id: 'task-today',
          title: 'Today task',
          createdBy: 'member-1',
          dueDate: DateTime(now.year, now.month, now.day, 15, 30),
          createdAt: now,
        );

        expect(todayTask.isDueToday, isTrue);
      });

      test('should return false when dueDate is tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowTask = FamilyTask(
          id: 'task-tomorrow',
          title: 'Tomorrow task',
          createdBy: 'member-1',
          dueDate: tomorrow,
          createdAt: DateTime.now(),
        );

        expect(tomorrowTask.isDueToday, isFalse);
      });

      test('should return false when dueDate is null', () {
        final noDue = FamilyTask(
          id: 'task-nodue',
          title: 'No due date',
          createdBy: 'member-1',
          createdAt: DateTime.now(),
        );

        expect(noDue.isDueToday, isFalse);
      });
    });

    group('copyWith', () {
      test('should update specified fields only', () {
        final updated = task.copyWith(
          title: 'New title',
          pointsValue: 50,
        );

        expect(updated.title, equals('New title'));
        expect(updated.pointsValue, equals(50));
        expect(updated.id, equals(task.id));
        expect(updated.description, equals(task.description));
        expect(updated.assignedTo, equals(task.assignedTo));
      });
    });

    group('JSON serialization', () {
      test('should roundtrip through toJson and fromJson', () {
        final json = task.toJson();
        final restored = FamilyTask.fromJson(json);

        expect(restored.id, equals(task.id));
        expect(restored.title, equals(task.title));
        expect(restored.description, equals(task.description));
        expect(restored.assignedTo, equals(task.assignedTo));
        expect(restored.createdBy, equals(task.createdBy));
        expect(restored.priority, equals(task.priority));
        expect(restored.recurrence, equals(task.recurrence));
        expect(restored.category, equals(task.category));
        expect(restored.dueDate, equals(task.dueDate));
        expect(restored.completed, equals(task.completed));
        expect(restored.pointsValue, equals(task.pointsValue));
        expect(restored.createdAt, equals(task.createdAt));
      });

      test('should handle null optional fields in JSON', () {
        final minimal = FamilyTask(
          id: 'min-task',
          title: 'Minimal',
          createdBy: 'member-1',
          createdAt: DateTime(2026, 1, 1),
        );

        final json = minimal.toJson();
        final restored = FamilyTask.fromJson(json);

        expect(restored.description, isNull);
        expect(restored.assignedTo, isNull);
        expect(restored.dueDate, isNull);
        expect(restored.completedAt, isNull);
        expect(restored.completed, isFalse);
        expect(restored.pointsValue, equals(10)); // default
      });

      test('should serialize enums as index values', () {
        final json = task.toJson();

        expect(json['priority'], equals(TaskPriority.high.index));
        expect(json['recurrence'], equals(TaskRecurrence.daily.index));
        expect(json['category'], equals(TaskCategory.poules.index));
      });
    });

    group('create factory', () {
      test('should generate a UUID and set createdAt to now', () {
        final created = FamilyTask.create(
          title: 'Test task',
          createdBy: 'member-1',
          pointsValue: 20,
        );

        expect(created.id, isNotEmpty);
        expect(created.id.length, greaterThan(10)); // UUID format
        expect(created.title, equals('Test task'));
        expect(created.createdBy, equals('member-1'));
        expect(created.pointsValue, equals(20));
        expect(created.completed, isFalse);
        expect(created.createdAt.difference(DateTime.now()).inSeconds.abs(),
            lessThan(2));
      });

      test('should apply default values when not specified', () {
        final created = FamilyTask.create(
          title: 'Default task',
          createdBy: 'member-1',
        );

        expect(created.priority, equals(TaskPriority.medium));
        expect(created.recurrence, equals(TaskRecurrence.none));
        expect(created.category, equals(TaskCategory.general));
        expect(created.pointsValue, equals(10));
      });
    });
  });
}
