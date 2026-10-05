import 'package:equatable/equatable.dart';

/// Goal status.
enum GoalStatus { active, achieved, missed }

extension GoalStatusExt on GoalStatus {
  String get label {
    switch (this) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.achieved:
        return 'Achieved';
      case GoalStatus.missed:
        return 'Missed';
    }
  }

  String get dbValue {
    switch (this) {
      case GoalStatus.active:
        return 'active';
      case GoalStatus.achieved:
        return 'achieved';
      case GoalStatus.missed:
        return 'missed';
    }
  }

  static GoalStatus fromString(String s) {
    switch (s) {
      case 'achieved':
        return GoalStatus.achieved;
      case 'missed':
        return GoalStatus.missed;
      default:
        return GoalStatus.active;
    }
  }
}

/// Core goal model.
class GoalModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String emoji;
  final String color; // hex string
  final double? targetValue;
  final double currentValue;
  final DateTime? deadline;
  final GoalStatus status;
  final String month; // 'YYYY-MM'
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed: linked tasks progress (set externally)
  final int linkedTasksTotal;
  final int linkedTasksCompleted;
  final int habitStreak;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.emoji = '🎯',
    this.color = '#6366F1',
    this.targetValue,
    this.currentValue = 0,
    this.deadline,
    this.status = GoalStatus.active,
    required this.month,
    this.isRecurring = false,
    required this.createdAt,
    required this.updatedAt,
    this.linkedTasksTotal = 0,
    this.linkedTasksCompleted = 0,
    this.habitStreak = 0,
  });

  /// Progress 0.0–1.0 based on tasks OR measurable value.
  double get progress {
    if (targetValue != null && targetValue! > 0) {
      return (currentValue / targetValue!).clamp(0.0, 1.0);
    }
    if (linkedTasksTotal > 0) {
      return (linkedTasksCompleted / linkedTasksTotal).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  int get progressPercent => (progress * 100).round();

  bool get isMeasurable => targetValue != null && targetValue! > 0;

  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? emoji,
    String? color,
    double? targetValue,
    double? currentValue,
    DateTime? deadline,
    GoalStatus? status,
    String? month,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? linkedTasksTotal,
    int? linkedTasksCompleted,
    int? habitStreak,
    bool clearTargetValue = false,
    bool clearDeadline = false,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      targetValue: clearTargetValue ? null : (targetValue ?? this.targetValue),
      currentValue: currentValue ?? this.currentValue,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      status: status ?? this.status,
      month: month ?? this.month,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedTasksTotal: linkedTasksTotal ?? this.linkedTasksTotal,
      linkedTasksCompleted:
          linkedTasksCompleted ?? this.linkedTasksCompleted,
      habitStreak: habitStreak ?? this.habitStreak,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'emoji': emoji,
      'color': color,
      'target_value': targetValue,
      'current_value': currentValue,
      'deadline': deadline?.toIso8601String(),
      'status': status.dbValue,
      'month': month,
      'is_recurring': isRecurring,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      emoji: json['emoji'] as String? ?? '🎯',
      color: json['color'] as String? ?? '#6366F1',
      targetValue: (json['target_value'] as num?)?.toDouble(),
      currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      status: GoalStatusExt.fromString(json['status'] as String? ?? 'active'),
      month: json['month'] as String,
      isRecurring: json['is_recurring'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id, userId, title, description, emoji, color,
        targetValue, currentValue, deadline, status, month,
        isRecurring, createdAt, updatedAt,
        linkedTasksTotal, linkedTasksCompleted, habitStreak,
      ];
}
