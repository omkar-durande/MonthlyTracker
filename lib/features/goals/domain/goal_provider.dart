import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_goals/core/services/supabase_service.dart';
import 'package:monthly_goals/features/goals/domain/goal_model.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';
import 'package:monthly_goals/features/auth/domain/auth_provider.dart';
import 'package:monthly_goals/features/tasks/domain/task_provider.dart';

class GoalRepository {
  final _client = SupabaseService.client;
  static final List<GoalModel> _localGoals = [];
  static final Map<String, List<DateTime>> _localCheckins = {};

  Future<List<GoalModel>> fetchGoalsForMonth(String month) async {
    final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';
    try {
      final data = await _client
          .from('goals')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .order('created_at');
      return (data as List).map((j) => GoalModel.fromJson(j)).toList();
    } catch (_) {
      return _localGoals.where((g) => g.month == month).toList();
    }
  }

  Future<GoalModel> createGoal(GoalModel goal) async {
    try {
      final data = await _client
          .from('goals')
          .insert(goal.toJson()..remove('id'))
          .select()
          .single();
      return GoalModel.fromJson(data);
    } catch (_) {
      _localGoals.add(goal);
      return goal;
    }
  }

  Future<GoalModel> updateGoal(GoalModel goal) async {
    final json = goal.toJson();
    json['updated_at'] = DateTime.now().toIso8601String();
    try {
      final data = await _client
          .from('goals')
          .update(json)
          .eq('id', goal.id)
          .select()
          .single();
      return GoalModel.fromJson(data);
    } catch (_) {
      final index = _localGoals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _localGoals[index] = goal;
      } else {
        _localGoals.add(goal);
      }
      return goal;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _client.from('goals').delete().eq('id', goalId);
    } catch (_) {}
    _localGoals.removeWhere((g) => g.id == goalId);
  }

  /// Check in for today and return updated streak.
  Future<int> checkIn(String goalId) async {
    final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      await _client.from('habit_checkins').upsert({
        'user_id': userId,
        'goal_id': goalId,
        'date': dateStr,
      });
      return await _calculateStreak(goalId, userId);
    } catch (_) {
      final list = _localCheckins.putIfAbsent(goalId, () => []);
      if (!list.any((d) => d.year == today.year && d.month == today.month && d.day == today.day)) {
        list.add(today);
      }
      return list.length;
    }
  }

  Future<bool> hasCheckedInToday(String goalId) async {
    final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      final data = await _client
          .from('habit_checkins')
          .select()
          .eq('user_id', userId)
          .eq('goal_id', goalId)
          .eq('date', dateStr);
      return (data as List).isNotEmpty;
    } catch (_) {
      final list = _localCheckins[goalId] ?? [];
      return list.any((d) => d.year == today.year && d.month == today.month && d.day == today.day);
    }
  }

  Future<List<DateTime>> fetchCheckIns(String goalId) async {
    final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';
    try {
      final data = await _client
          .from('habit_checkins')
          .select('date')
          .eq('user_id', userId)
          .eq('goal_id', goalId);
      return (data as List)
          .map((j) => DateTime.parse(j['date'] as String))
          .toList();
    } catch (_) {
      return _localCheckins[goalId] ?? [];
    }
  }

  Future<int> _calculateStreak(String goalId, String userId) async {
    try {
      final data = await _client
          .from('habit_checkins')
          .select('date')
          .eq('user_id', userId)
          .eq('goal_id', goalId)
          .order('date', ascending: false);
      final dates = (data as List)
          .map((j) => DateTime.parse(j['date'] as String))
          .toList();
      if (dates.isEmpty) return 0;
      int streak = 1;
      for (int i = 0; i < dates.length - 1; i++) {
        final diff = dates[i].difference(dates[i + 1]).inDays;
        if (diff == 1) {
          streak++;
        } else {
          break;
        }
      }
      return streak;
    } catch (_) {
      return (_localCheckins[goalId] ?? []).length;
    }
  }
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  ref.watch(currentUserProvider);
  return GoalRepository();
});

final selectedGoalMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final goalsProvider =
    FutureProvider.autoDispose<List<GoalModel>>((ref) async {
  final month = ref.watch(selectedGoalMonthProvider);
  final repo = ref.watch(goalRepositoryProvider);
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  final monthKey =
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  final goals = await repo.fetchGoalsForMonth(monthKey);

  // Enrich with linked task counts and streaks
  return Future.wait(goals.map((g) async {
    final linked = tasks.where((t) => t.goalId == g.id).toList();
    final streak = await repo._calculateStreak(
        g.id, SupabaseService.currentUserId ?? '');
    return g.copyWith(
      linkedTasksTotal: linked.length,
      linkedTasksCompleted:
          linked.where((t) => t.status == TaskStatus.completed).length,
      habitStreak: streak,
    );
  }));
});

enum GoalFilter { all, active, achieved, missed }

final goalFilterProvider =
    StateProvider<GoalFilter>((ref) => GoalFilter.all);

final filteredGoalsProvider =
    Provider.autoDispose<AsyncValue<List<GoalModel>>>((ref) {
  final goalsAsync = ref.watch(goalsProvider);
  final filter = ref.watch(goalFilterProvider);
  return goalsAsync.whenData((goals) {
    switch (filter) {
      case GoalFilter.active:
        return goals.where((g) => g.status == GoalStatus.active).toList();
      case GoalFilter.achieved:
        return goals.where((g) => g.status == GoalStatus.achieved).toList();
      case GoalFilter.missed:
        return goals.where((g) => g.status == GoalStatus.missed).toList();
      case GoalFilter.all:
        return goals;
    }
  });
});
