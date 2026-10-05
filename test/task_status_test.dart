import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';

TaskModel _makeTask({
  required String id,
  TaskStatus status = TaskStatus.pending,
  DateTime? deadline,
  DateTime? completedAt,
  String month = '2026-10',
  String? carriedFrom,
}) {
  final now = DateTime.now();
  return TaskModel(
    id: id,
    userId: 'user1',
    title: 'Task $id',
    status: status,
    priority: TaskPriority.medium,
    month: month,
    deadline: deadline,
    completedAt: completedAt,
    carriedFrom: carriedFrom,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('TaskModel status logic', () {
    test('pending task is not overdue without deadline', () {
      final task = _makeTask(id: '1');
      expect(task.isOverdue, false);
    });

    test('task with past deadline and pending status is overdue', () {
      final task = _makeTask(
        id: '2',
        deadline: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(task.isOverdue, true);
    });

    test('completed task is not overdue even with past deadline', () {
      final task = _makeTask(
        id: '3',
        status: TaskStatus.completed,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now(),
      );
      expect(task.isOverdue, false);
    });

    test('task with future deadline is not overdue', () {
      final task = _makeTask(
        id: '4',
        deadline: DateTime.now().add(const Duration(days: 3)),
      );
      expect(task.isOverdue, false);
    });

    test('isDueToday returns true for same-day deadline', () {
      final now = DateTime.now();
      final task = _makeTask(
        id: '5',
        deadline: DateTime(now.year, now.month, now.day, 23, 59),
      );
      expect(task.isDueToday, true);
    });

    test('isCompletedOnTime true when completed before deadline', () {
      final deadline = DateTime.now().add(const Duration(hours: 2));
      final task = _makeTask(
        id: '6',
        status: TaskStatus.completed,
        deadline: deadline,
        completedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      expect(task.isCompletedOnTime, true);
    });

    test('isCompletedOnTime false when completed after deadline', () {
      final deadline = DateTime.now().subtract(const Duration(hours: 1));
      final task = _makeTask(
        id: '7',
        status: TaskStatus.completed,
        deadline: deadline,
        completedAt: DateTime.now(),
      );
      expect(task.isCompletedOnTime, false);
    });

    test('isCarriedOver true when carriedFrom is set', () {
      final task = _makeTask(id: '8', carriedFrom: 'original-task-id');
      expect(task.isCarriedOver, true);
    });

    test('copyWith preserves fields not changed', () {
      final task = _makeTask(id: '9', status: TaskStatus.pending);
      final updated = task.copyWith(status: TaskStatus.completed);
      expect(updated.id, '9');
      expect(updated.status, TaskStatus.completed);
      expect(updated.title, task.title);
    });
  });

  group('Carry-over logic', () {
    test('carried task has carriedFrom field pointing to original', () {
      const originalId = 'original-001';
      final original = _makeTask(
        id: originalId,
        status: TaskStatus.pending,
        month: '2026-09',
      );
      final carried = original.copyWith(
        id: 'new-001',
        month: '2026-10',
        status: TaskStatus.pending,
        carriedFrom: original.id,
      );

      expect(carried.carriedFrom, originalId);
      expect(carried.month, '2026-10');
      expect(carried.isCarriedOver, true);
    });

    test('carried task status resets to pending', () {
      final original = _makeTask(
        id: 'orig',
        status: TaskStatus.inProgress,
        month: '2026-09',
      );
      final carried = original.copyWith(
        status: TaskStatus.pending,
        month: '2026-10',
        carriedFrom: original.id,
      );
      expect(carried.status, TaskStatus.pending);
    });
  });
}
