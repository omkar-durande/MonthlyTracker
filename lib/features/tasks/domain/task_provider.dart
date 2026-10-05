import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_goals/core/services/supabase_service.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';
import 'package:monthly_goals/features/auth/domain/auth_provider.dart';

/// Repository for all task CRUD operations.
class TaskRepository {
  final _client = SupabaseService.client;
  static final List<TaskModel> _localTasks = [];

  Future<List<TaskModel>> fetchTasksForMonth(String month) async {
    final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';
    try {
      final data = await _client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .order('created_at');
      return (data as List).map((j) => TaskModel.fromJson(j)).toList();
    } catch (_) {
      return _localTasks.where((t) => t.month == month).toList();
    }
  }

  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final data = await _client
          .from('tasks')
          .insert(task.toJson()..remove('id'))
          .select()
          .single();
      return TaskModel.fromJson(data);
    } catch (_) {
      _localTasks.add(task);
      return task;
    }
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final now = DateTime.now();
    final json = task.toJson();
    json['updated_at'] = now.toIso8601String();
    if (task.status == TaskStatus.completed && task.completedAt == null) {
      json['completed_at'] = now.toIso8601String();
    }
    if (task.status != TaskStatus.completed) {
      json['completed_at'] = null;
    }
    try {
      final data = await _client
          .from('tasks')
          .update(json)
          .eq('id', task.id)
          .select()
          .single();
      return TaskModel.fromJson(data);
    } catch (_) {
      final index = _localTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _localTasks[index] = task;
      } else {
        _localTasks.add(task);
      }
      return task;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _client.from('tasks').delete().eq('id', taskId);
    } catch (_) {}
    _localTasks.removeWhere((t) => t.id == taskId);
  }

  Future<List<TaskModel>> fetchUnfinishedFromMonth(String month) async {
    final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';
    try {
      final data = await _client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .inFilter('status', ['pending', 'in_progress']);
      return (data as List).map((j) => TaskModel.fromJson(j)).toList();
    } catch (_) {
      return _localTasks
          .where((t) => t.month == month && t.status != TaskStatus.completed)
          .toList();
    }
  }

  Future<List<TaskModel>> fetchRecurringTasks() async {
    final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';
    try {
      final data = await _client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .eq('is_recurring', true);
      return (data as List).map((j) => TaskModel.fromJson(j)).toList();
    } catch (_) {
      return _localTasks.where((t) => t.isRecurring).toList();
    }
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  ref.watch(currentUserProvider); // re-create when auth changes
  return TaskRepository();
});

/// Currently selected month for task list.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Tasks for the selected month.
final tasksProvider =
    FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(taskRepositoryProvider);
  return repo.fetchTasksForMonth(
      '${month.year}-${month.month.toString().padLeft(2, '0')}');
});

/// Task filter options.
enum TaskFilter { all, pending, inProgress, completed }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

final taskSearchProvider = StateProvider<String>((ref) => '');

enum TaskSortOption { deadline, priority, createdAt }

final taskSortProvider =
    StateProvider<TaskSortOption>((ref) => TaskSortOption.deadline);

/// Filtered + sorted task list.
final filteredTasksProvider =
    Provider.autoDispose<AsyncValue<List<TaskModel>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final filter = ref.watch(taskFilterProvider);
  final search = ref.watch(taskSearchProvider);
  final sort = ref.watch(taskSortProvider);

  return tasksAsync.whenData((tasks) {
    var list = tasks;

    // Filter
    list = list.where((t) {
      switch (filter) {
        case TaskFilter.pending:
          return t.status == TaskStatus.pending;
        case TaskFilter.inProgress:
          return t.status == TaskStatus.inProgress;
        case TaskFilter.completed:
          return t.status == TaskStatus.completed;
        case TaskFilter.all:
          return true;
      }
    }).toList();

    // Search
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              (t.description?.toLowerCase().contains(q) ?? false) ||
              (t.category?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    // Sort
    list.sort((a, b) {
      switch (sort) {
        case TaskSortOption.deadline:
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        case TaskSortOption.priority:
          return b.priority.index.compareTo(a.priority.index);
        case TaskSortOption.createdAt:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return list;
  });
});

/// Today's top 3 high-priority tasks across all months.
final todaysFocusProvider =
    Provider.autoDispose<AsyncValue<List<TaskModel>>>((ref) {
  return ref.watch(tasksProvider).whenData((tasks) {
    final active = tasks
        .where((t) => t.status != TaskStatus.completed)
        .toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return active.take(3).toList();
  });
});
