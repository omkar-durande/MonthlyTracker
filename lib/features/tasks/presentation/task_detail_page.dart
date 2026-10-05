import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/extensions/datetime_ext.dart';
import 'package:monthly_goals/shared/widgets/common_widgets.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';
import 'package:monthly_goals/features/tasks/domain/task_provider.dart';

class TaskDetailPage extends ConsumerWidget {
  final String taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(tasksProvider);

    return tasksAsync.when(
      data: (tasks) {
        final task = tasks.where((t) => t.id == taskId).firstOrNull;
        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task')),
            body: const Center(child: Text('Task not found')),
          );
        }

        final priorityColor = switch (task.priority) {
          TaskPriority.high => AppColors.priorityHigh,
          TaskPriority.medium => AppColors.priorityMedium,
          TaskPriority.low => AppColors.priorityLow,
        };

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [priorityColor.withValues(alpha: 0.8), AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => context.push('/tasks/$taskId/edit'),
                  ),
                ],
                title: Text(task.title,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Status + Priority row
                    Row(
                      children: [
                        _InfoChip(
                          label: task.status.label,
                          color: switch (task.status) {
                            TaskStatus.completed => AppColors.statusCompleted,
                            TaskStatus.inProgress => AppColors.statusInProgress,
                            TaskStatus.pending => AppColors.statusPending,
                          },
                          icon: switch (task.status) {
                            TaskStatus.completed => Icons.check_circle_rounded,
                            TaskStatus.inProgress =>
                              Icons.radio_button_checked_rounded,
                            TaskStatus.pending =>
                              Icons.radio_button_unchecked_rounded,
                          },
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          label: '${task.priority.label} Priority',
                          color: priorityColor,
                          icon: Icons.priority_high_rounded,
                        ),
                        if (task.isCarriedOver) ...[
                          const SizedBox(width: 8),
                          const _InfoChip(
                            label: '↩ Carried Over',
                            color: AppColors.info,
                            icon: Icons.redo_rounded,
                          ),
                        ],
                      ],
                    ).animate().fadeIn(delay: 50.ms),
                    const SizedBox(height: AppSizes.md),

                    // Description
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Description',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.primary)),
                              const SizedBox(height: 8),
                              Text(task.description!,
                                  style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: AppSizes.md),
                    ],

                    // Details card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Column(
                          children: [
                            if (task.deadline != null) ...[
                              _DetailRow(
                                icon: Icons.calendar_today_rounded,
                                label: 'Deadline',
                                value: task.deadline!.fullDateTime,
                                valueColor:
                                    task.isOverdue ? AppColors.error : null,
                              ),
                              const Divider(height: 24),
                            ],
                            if (task.category != null) ...[
                              _DetailRow(
                                icon: Icons.label_outline_rounded,
                                label: 'Category',
                                value: task.category!,
                              ),
                              const Divider(height: 24),
                            ],
                            _DetailRow(
                              icon: Icons.access_time_rounded,
                              label: 'Created',
                              value: task.createdAt.fullDateTime,
                            ),
                            if (task.completedAt != null) ...[
                              const Divider(height: 24),
                              _DetailRow(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'Completed',
                                value: task.completedAt!.fullDateTime,
                                valueColor: AppColors.success,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: AppSizes.lg),

                    // Status change buttons
                    _StatusButtons(task: task),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          Scaffold(appBar: AppBar(), body: const ShimmerList()),
      error: (e, _) => Scaffold(
          appBar: AppBar(), body: ErrorState(message: e.toString())),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _InfoChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall),
              Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: valueColor, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusButtons extends ConsumerWidget {
  final TaskModel task;
  const _StatusButtons({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: TaskStatus.values.where((s) => s != task.status).map((s) {
        final color = switch (s) {
          TaskStatus.completed => AppColors.statusCompleted,
          TaskStatus.inProgress => AppColors.statusInProgress,
          TaskStatus.pending => AppColors.statusPending,
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref
                  .read(taskRepositoryProvider)
                  .updateTask(task.copyWith(status: s));
              ref.invalidate(tasksProvider);
              if (context.mounted) context.pop();
            },
            icon: Icon(Icons.check_circle_outline_rounded, color: color),
            label: Text('Mark as ${s.label}',
                style: TextStyle(color: color)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color.withValues(alpha: 0.5)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
