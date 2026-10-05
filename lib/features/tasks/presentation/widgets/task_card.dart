import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/extensions/datetime_ext.dart';
import 'package:monthly_goals/shared/widgets/common_widgets.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final int index;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.onStatusChanged,
    required this.onDelete,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.completed:
        return AppColors.statusCompleted;
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.pending:
        return AppColors.statusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 28),
      ),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/tasks/${task.id}'),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority accent bar
                Container(
                  width: 4,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _priorityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                decoration: task.status == TaskStatus.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (task.isCarriedOver)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('↩ Carried',
                                  style: TextStyle(
                                      fontSize: 10, color: AppColors.info)),
                            ),
                        ],
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(task.description!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Status chip
                          GestureDetector(
                            onTap: () => _cycleStatus(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusFull),
                                border: Border.all(
                                    color: _statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_statusIcon, color: _statusColor, size: 12),
                                  const SizedBox(width: 4),
                                  Text(task.status.label,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: _statusColor,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Deadline
                          if (task.deadline != null) ...[
                            if (task.isOverdue)
                              PriorityBadge(
                                  label: '⚠️ ${task.deadline!.countdownLabel()}',
                                  color: AppColors.error)
                            else if (task.isDueToday)
                              const PriorityBadge(
                                  label: '📅 Today',
                                  color: AppColors.warning)
                            else if (task.isDueSoon)
                              PriorityBadge(
                                  label: '⏰ ${task.deadline!.countdownLabel()}',
                                  color: AppColors.info)
                            else
                              Text(task.deadline!.compactLabel,
                                  style: theme.textTheme.labelSmall),
                          ],
                        ],
                      ),
                      if (task.category != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.label_outline_rounded,
                                size: 12, color: AppColors.statusPending),
                            const SizedBox(width: 4),
                            Text(task.category!,
                                style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Quick actions
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => context.push('/tasks/${task.id}/edit'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05);
  }

  IconData get _statusIcon {
    switch (task.status) {
      case TaskStatus.completed:
        return Icons.check_circle_rounded;
      case TaskStatus.inProgress:
        return Icons.radio_button_checked_rounded;
      case TaskStatus.pending:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  void _cycleStatus(BuildContext context) {
    final next = switch (task.status) {
      TaskStatus.pending => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.completed,
      TaskStatus.completed => TaskStatus.pending,
    };
    onStatusChanged(next);
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Delete "${task.title}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
