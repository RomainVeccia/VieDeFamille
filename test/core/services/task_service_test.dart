import 'package:flutter_test/flutter_test.dart';
import 'package:vie_de_famille/core/models/family_task.dart';
import 'package:vie_de_famille/core/services/task_service.dart';

void main() {
  group('TaskService', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    /// Helper to create a task with sensible defaults
    FamilyTask makeTask({
      String id = 'task-1',
      String? assignedTo,
      TaskRecurrence recurrence = TaskRecurrence.none,
      DateTime? dueDate,
      bool completed = false,
      DateTime? completedAt,
      DateTime? createdAt,
    }) {
      return FamilyTask(
        id: id,
        title: 'Task $id',
        assignedTo: assignedTo,
        createdBy: 'creator',
        recurrence: recurrence,
        dueDate: dueDate,
        completed: completed,
        completedAt: completedAt,
        createdAt: createdAt ?? now,
      );
    }

    group('todayTasks', () {
      test('should include daily recurring tasks', () {
        final tasks = [
          makeTask(id: 'daily', recurrence: TaskRecurrence.daily),
          makeTask(id: 'weekly', recurrence: TaskRecurrence.weekly,
              createdAt: now.subtract(const Duration(days: 3))),
        ];

        final result = TaskService.todayTasks(tasks);

        expect(result.any((t) => t.id == 'daily'), isTrue);
      });

      test('should include tasks due today', () {
        final tasks = [
          makeTask(id: 'due-today', dueDate: today),
          makeTask(id: 'due-tomorrow',
              dueDate: today.add(const Duration(days: 1))),
        ];

        final result = TaskService.todayTasks(tasks);

        expect(result.any((t) => t.id == 'due-today'), isTrue);
        expect(result.any((t) => t.id == 'due-tomorrow'), isFalse);
      });

      test('should include tasks created today with no due date', () {
        final tasks = [
          makeTask(id: 'created-today', createdAt: now),
          makeTask(id: 'created-yesterday',
              createdAt: now.subtract(const Duration(days: 1))),
        ];

        final result = TaskService.todayTasks(tasks);

        expect(result.any((t) => t.id == 'created-today'), isTrue);
        expect(result.any((t) => t.id == 'created-yesterday'), isFalse);
      });

      test('should filter by memberId when specified', () {
        final tasks = [
          makeTask(id: 't1', assignedTo: 'alice',
              recurrence: TaskRecurrence.daily),
          makeTask(id: 't2', assignedTo: 'bob',
              recurrence: TaskRecurrence.daily),
          makeTask(id: 't3', recurrence: TaskRecurrence.daily),
        ];

        final result = TaskService.todayTasks(tasks, memberId: 'alice');

        expect(result.length, equals(1));
        expect(result.first.id, equals('t1'));
      });

      test('should return empty list when no tasks match', () {
        final tasks = [
          makeTask(id: 'old',
              createdAt: now.subtract(const Duration(days: 10))),
        ];

        final result = TaskService.todayTasks(tasks);

        expect(result, isEmpty);
      });
    });

    group('pending', () {
      test('should return only uncompleted tasks', () {
        final tasks = [
          makeTask(id: 'pending', completed: false),
          makeTask(id: 'done', completed: true, completedAt: now),
        ];

        final result = TaskService.pending(tasks);

        expect(result.length, equals(1));
        expect(result.first.id, equals('pending'));
      });

      test('should return empty list when all tasks are completed', () {
        final tasks = [
          makeTask(id: 'done1', completed: true, completedAt: now),
          makeTask(id: 'done2', completed: true, completedAt: now),
        ];

        final result = TaskService.pending(tasks);

        expect(result, isEmpty);
      });
    });

    group('completedToday', () {
      test('should return tasks completed today', () {
        final tasks = [
          makeTask(id: 'done-today', completed: true, completedAt: now),
          makeTask(id: 'done-yesterday', completed: true,
              completedAt: now.subtract(const Duration(days: 1))),
          makeTask(id: 'not-done'),
        ];

        final result = TaskService.completedToday(tasks);

        expect(result.length, equals(1));
        expect(result.first.id, equals('done-today'));
      });

      test('should return empty when no tasks completed today', () {
        final tasks = [
          makeTask(id: 'not-done'),
          makeTask(id: 'done-yesterday', completed: true,
              completedAt: now.subtract(const Duration(days: 1))),
        ];

        final result = TaskService.completedToday(tasks);

        expect(result, isEmpty);
      });

      test('should ignore completed tasks without completedAt', () {
        final tasks = [
          makeTask(id: 'no-timestamp', completed: true),
        ];

        final result = TaskService.completedToday(tasks);

        expect(result, isEmpty);
      });
    });

    group('todayCompletionRate', () {
      test('should return 0.0 when no tasks today', () {
        final tasks = <FamilyTask>[
          makeTask(id: 'old',
              createdAt: now.subtract(const Duration(days: 10))),
        ];

        final rate = TaskService.todayCompletionRate(tasks);

        expect(rate, equals(0.0));
      });

      test('should return 1.0 when all today tasks are completed', () {
        final tasks = [
          makeTask(id: 't1', recurrence: TaskRecurrence.daily,
              completed: true, completedAt: now),
          makeTask(id: 't2', recurrence: TaskRecurrence.daily,
              completed: true, completedAt: now),
        ];

        final rate = TaskService.todayCompletionRate(tasks);

        expect(rate, equals(1.0));
      });

      test('should return 0.5 when half of today tasks are completed', () {
        final tasks = [
          makeTask(id: 't1', recurrence: TaskRecurrence.daily,
              completed: true, completedAt: now),
          makeTask(id: 't2', recurrence: TaskRecurrence.daily),
        ];

        final rate = TaskService.todayCompletionRate(tasks);

        expect(rate, equals(0.5));
      });
    });

    group('forMember', () {
      test('should return tasks assigned to a specific member', () {
        final tasks = [
          makeTask(id: 't1', assignedTo: 'alice'),
          makeTask(id: 't2', assignedTo: 'bob'),
          makeTask(id: 't3', assignedTo: 'alice'),
          makeTask(id: 't4'), // unassigned
        ];

        final result = TaskService.forMember(tasks, 'alice');

        expect(result.length, equals(2));
        expect(result.every((t) => t.assignedTo == 'alice'), isTrue);
      });

      test('should return empty list when no tasks for member', () {
        final tasks = [
          makeTask(id: 't1', assignedTo: 'bob'),
        ];

        final result = TaskService.forMember(tasks, 'alice');

        expect(result, isEmpty);
      });
    });
  });
}
