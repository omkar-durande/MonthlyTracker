import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:monthly_goals/core/services/supabase_service.dart';
import 'package:monthly_goals/core/utils/efficiency_calculator.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';
import 'package:monthly_goals/features/goals/domain/goal_model.dart';
import 'package:monthly_goals/features/auth/domain/auth_provider.dart';
import 'package:monthly_goals/features/reports/domain/monthly_report_model.dart';

class ReportRepository {
  final _client = SupabaseService.client;
  static final List<MonthlyReportModel> _localReports = [];

  Future<MonthlyReportModel?> fetchReport(String month) async {
    final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';
    try {
      final data = await _client
          .from('monthly_reports')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .maybeSingle();
      if (data == null) return null;
      return MonthlyReportModel.fromJson(data);
    } catch (_) {
      return _localReports.firstWhereOrNull((r) => r.month == month);
    }
  }

  Future<List<MonthlyReportModel>> fetchAllReports() async {
    final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';
    try {
      final data = await _client
          .from('monthly_reports')
          .select()
          .eq('user_id', userId)
          .order('month', ascending: false);
      return (data as List).map((j) => MonthlyReportModel.fromJson(j)).toList();
    } catch (_) {
      return _localReports;
    }
  }

  Future<MonthlyReportModel> generateAndSave({
    required List<TaskModel> tasks,
    required List<GoalModel> goals,
    required String month,
  }) async {
    final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';
    final total = tasks.length;
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final onTime =
        tasks.where((t) => t.isCompletedOnTime).length;
    final overdue =
        tasks.where((t) => t.isOverdue).length;
    final completedLate = completed - onTime;

    final efficiency = EfficiencyCalculator.overallEfficiency(total, completed);
    final onTimeRate = EfficiencyCalculator.onTimeRate(completed, onTime);

    final goalsAchieved =
        goals.where((g) => g.status == GoalStatus.achieved).length;
    final goalsMissed =
        goals.where((g) => g.status == GoalStatus.missed).length;

    // Best day: day with most completions
    final completedTasks =
        tasks.where((t) => t.completedAt != null).toList();
    final dayGroups = groupBy<TaskModel, String>(completedTasks,
        (t) => DateFormat('yyyy-MM-dd').format(t.completedAt!));
    String bestDay = '';
    int bestCount = 0;
    dayGroups.forEach((day, ts) {
      if (ts.length > bestCount) {
        bestCount = ts.length;
        bestDay = day;
      }
    });
    if (bestDay.isNotEmpty) {
      bestDay = DateFormat('EEE, MMM d').format(DateTime.parse(bestDay));
    }

    // Most productive category
    final categoryGroups = groupBy<TaskModel, String>(
        completedTasks, (t) => t.category ?? 'Uncategorized');
    String bestCat = '';
    int bestCatCount = 0;
    categoryGroups.forEach((cat, ts) {
      if (ts.length > bestCatCount) {
        bestCatCount = ts.length;
        bestCat = cat;
      }
    });

    // Weekly completions
    final weeklyCompletions = <String, int>{};
    for (var t in completedTasks) {
      final d = t.completedAt!;
      final weekNum = ((d.day - 1) ~/ 7) + 1;
      final key = 'W$weekNum';
      weeklyCompletions[key] = (weeklyCompletions[key] ?? 0) + 1;
    }

    // Daily completions
    final dailyCompletions = <String, int>{};
    for (var t in completedTasks) {
      final key = DateFormat('d').format(t.completedAt!);
      dailyCompletions[key] = (dailyCompletions[key] ?? 0) + 1;
    }

    final insight = EfficiencyCalculator.insight(
      efficiency: efficiency,
      onTime: onTimeRate,
      streakDays: 0,
      bestCategory: bestCat,
    );

    final summaryJson = {
      'overdue': overdue,
      'completed_late': completedLate,
      'on_time_rate': onTimeRate,
      'goals_achieved': goalsAchieved,
      'goals_missed': goalsMissed,
      'best_day': bestDay,
      'most_productive_category': bestCat,
      'longest_streak': 0,
      'insight': insight,
      'weekly_completions': weeklyCompletions,
      'daily_completions': dailyCompletions,
    };

    final payload = {
      'user_id': userId,
      'month': month,
      'total': total,
      'completed': completed,
      'on_time': onTime,
      'efficiency': efficiency,
      'summary_json': summaryJson,
    };

    final reportModel = MonthlyReportModel(
      id: 'report-$month',
      userId: userId,
      month: month,
      total: total,
      completed: completed,
      onTime: onTime,
      overdue: overdue,
      completedLate: completedLate,
      efficiency: efficiency,
      onTimeRate: onTimeRate,
      goalsAchieved: goalsAchieved,
      goalsMissed: goalsMissed,
      bestDay: bestDay,
      mostProductiveCategory: bestCat,
      longestStreak: 0,
      summaryJson: summaryJson,
      createdAt: DateTime.now(),
      weeklyCompletions: weeklyCompletions,
      dailyCompletions: dailyCompletions,
    );

    try {
      final data = await _client
          .from('monthly_reports')
          .upsert(payload, onConflict: 'user_id,month')
          .select()
          .single();
      return MonthlyReportModel.fromJson(data);
    } catch (_) {
      _localReports.removeWhere((r) => r.month == month);
      _localReports.add(reportModel);
      return reportModel;
    }
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  ref.watch(currentUserProvider);
  return ReportRepository();
});

final allReportsProvider =
    FutureProvider.autoDispose<List<MonthlyReportModel>>((ref) async {
  return ref.watch(reportRepositoryProvider).fetchAllReports();
});

final reportForMonthProvider =
    FutureProvider.autoDispose.family<MonthlyReportModel?, String>(
        (ref, month) async {
  return ref.watch(reportRepositoryProvider).fetchReport(month);
});
