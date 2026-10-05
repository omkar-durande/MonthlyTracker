import 'package:equatable/equatable.dart';

/// Task priorities.
enum TaskPriority { low, medium, high }

/// Task statuses.
enum TaskStatus { pending, inProgress, completed }

extension TaskPriorityExt on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  String get dbValue {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
    }
  }

  static TaskPriority fromString(String s) {
    switch (s) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
}

extension TaskStatusExt on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  String get dbValue {
    switch (this) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  static TaskStatus fromString(String s) {
    switch (s) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }
}

/// Core task model.
class TaskModel extends Equatable {
  final String id;
  final String userId;
  final String? goalId;
  final String title;
  final String? description;
  final DateTime? deadline;
  final TaskPriority priority;
  final TaskStatus status;
  final String? category;
  final String month; // 'YYYY-MM'
  final String? carriedFrom;
  final bool isRecurring;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.userId,
    this.goalId,
    required this.title,
    this.description,
    this.deadline,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.category,
    required this.month,
    this.carriedFrom,
    this.isRecurring = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue =>
      deadline != null &&
      deadline!.isBefore(DateTime.now()) &&
      status != TaskStatus.completed;

  bool get isDueToday {
    if (deadline == null) return false;
    final now = DateTime.now();
    return deadline!.year == now.year &&
        deadline!.month == now.month &&
        deadline!.day == now.day;
  }

  bool get isDueSoon {
    if (deadline == null) return false;
    final hours = deadline!.difference(DateTime.now()).inHours;
    return hours >= 0 && hours <= 48;
  }

  bool get isCompletedOnTime =>
      status == TaskStatus.completed &&
      completedAt != null &&
      deadline != null &&
      completedAt!.isBefore(deadline!);

  bool get isCarriedOver => carriedFrom != null;

  TaskModel copyWith({
    String? id,
    String? userId,
    String? goalId,
    String? title,
    String? description,
    DateTime? deadline,
    TaskPriority? priority,
    TaskStatus? status,
    String? category,
    String? month,
    String? carriedFrom,
    bool? isRecurring,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearGoalId = false,
    bool clearDeadline = false,
    bool clearCompletedAt = false,
    bool clearCarriedFrom = false,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalId: clearGoalId ? null : (goalId ?? this.goalId),
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      month: month ?? this.month,
      carriedFrom:
          clearCarriedFrom ? null : (carriedFrom ?? this.carriedFrom),
      isRecurring: isRecurring ?? this.isRecurring,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal_id': goalId,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'priority': priority.dbValue,
      'status': status.dbValue,
      'category': category,
      'month': month,
      'carried_from': carriedFrom,
      'is_recurring': isRecurring,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalId: json['goal_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      priority: TaskPriorityExt.fromString(json['priority'] as String? ?? 'medium'),
      status: TaskStatusExt.fromString(json['status'] as String? ?? 'pending'),
      category: json['category'] as String?,
      month: json['month'] as String,
      carriedFrom: json['carried_from'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id, userId, goalId, title, description, deadline,
        priority, status, category, month, carriedFrom,
        isRecurring, completedAt, createdAt, updatedAt,
      ];
}
