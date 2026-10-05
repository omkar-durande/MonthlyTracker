import 'package:equatable/equatable.dart';

/// Stored monthly report snapshot.
class MonthlyReportModel extends Equatable {
  final String id;
  final String userId;
  final String month; // 'YYYY-MM'
  final int total;
  final int completed;
  final int onTime;
  final int overdue;
  final int completedLate;
  final double efficiency;
  final double onTimeRate;
  final int goalsAchieved;
  final int goalsMissed;
  final String bestDay;
  final String mostProductiveCategory;
  final int longestStreak;
  final Map<String, dynamic> summaryJson;
  final DateTime createdAt;

  // Week-by-week bar data (keys: 'W1','W2','W3','W4','W5')
  final Map<String, int> weeklyCompletions;

  // Daily completions for line chart
  final Map<String, int> dailyCompletions;

  const MonthlyReportModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.total,
    required this.completed,
    required this.onTime,
    required this.overdue,
    required this.completedLate,
    required this.efficiency,
    required this.onTimeRate,
    required this.goalsAchieved,
    required this.goalsMissed,
    required this.bestDay,
    required this.mostProductiveCategory,
    required this.longestStreak,
    required this.summaryJson,
    required this.createdAt,
    this.weeklyCompletions = const {},
    this.dailyCompletions = const {},
  });

  int get pending => total - completed;

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary_json'] as Map<String, dynamic>? ?? {};
    return MonthlyReportModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      month: json['month'] as String,
      total: json['total'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      onTime: json['on_time'] as int? ?? 0,
      overdue: summary['overdue'] as int? ?? 0,
      completedLate: summary['completed_late'] as int? ?? 0,
      efficiency: (json['efficiency'] as num?)?.toDouble() ?? 0,
      onTimeRate: (summary['on_time_rate'] as num?)?.toDouble() ?? 0,
      goalsAchieved: summary['goals_achieved'] as int? ?? 0,
      goalsMissed: summary['goals_missed'] as int? ?? 0,
      bestDay: summary['best_day'] as String? ?? '',
      mostProductiveCategory:
          summary['most_productive_category'] as String? ?? '',
      longestStreak: summary['longest_streak'] as int? ?? 0,
      summaryJson: summary,
      createdAt: DateTime.parse(json['created_at'] as String),
      weeklyCompletions:
          (summary['weekly_completions'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v as int)),
      dailyCompletions:
          (summary['daily_completions'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v as int)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'month': month,
      'total': total,
      'completed': completed,
      'on_time': onTime,
      'efficiency': efficiency,
      'summary_json': {
        ...summaryJson,
        'overdue': overdue,
        'completed_late': completedLate,
        'on_time_rate': onTimeRate,
        'goals_achieved': goalsAchieved,
        'goals_missed': goalsMissed,
        'best_day': bestDay,
        'most_productive_category': mostProductiveCategory,
        'longest_streak': longestStreak,
        'weekly_completions': weeklyCompletions,
        'daily_completions': dailyCompletions,
      },
    };
  }

  @override
  List<Object?> get props => [id, userId, month, total, completed, efficiency];
}
