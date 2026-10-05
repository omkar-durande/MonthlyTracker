import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/shared/widgets/common_widgets.dart';
import 'package:monthly_goals/features/goals/domain/goal_model.dart';
import 'package:monthly_goals/features/goals/domain/goal_provider.dart';

class GoalCard extends ConsumerStatefulWidget {
  final GoalModel goal;
  final int index;
  const GoalCard({super.key, required this.goal, required this.index});

  @override
  ConsumerState<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<GoalCard> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = widget.goal;
    final color = AppColors.fromHex(goal.color);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Card(
          child: InkWell(
            onTap: () => context.push('/goals/${goal.id}'),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Emoji
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(goal.emoji,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal.title,
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if (goal.description != null)
                              Text(goal.description!,
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // Status badge
                      _GoalStatusBadge(status: goal.status),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  goal.isMeasurable
                                      ? '${goal.currentValue.toStringAsFixed(0)} / ${goal.targetValue!.toStringAsFixed(0)}'
                                      : '${goal.linkedTasksCompleted} / ${goal.linkedTasksTotal} tasks',
                                  style: theme.textTheme.labelSmall,
                                ),
                                Text('${goal.progressPercent}%',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: color)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: goal.progress,
                                minHeight: 8,
                                backgroundColor: color.withValues(alpha: 0.12),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ProgressRing(
                        progress: goal.progress,
                        size: 52,
                        strokeWidth: 5,
                        color: color,
                        center: Text('${goal.progressPercent}%',
                            style: TextStyle(
                                fontSize: 9,
                                color: color,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // Bottom row: streak + check-in + actions
                  Row(
                    children: [
                      if (goal.habitStreak > 0) ...[
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text('${goal.habitStreak}d streak',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.warning)),
                        const SizedBox(width: 12),
                      ],
                      const Spacer(),
                      // Check-in button
                      TextButton.icon(
                        onPressed: () => _checkIn(context),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 16),
                        label: const Text('Check In'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      // Edit
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        onPressed: () =>
                            context.push('/goals/${goal.id}/edit'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      // Delete
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.error),
                        onPressed: () => _delete(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate(delay: (widget.index * 60).ms).fadeIn().slideY(begin: 0.05),

        // Confetti
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            AppColors.primary, AppColors.secondary, AppColors.success,
            AppColors.accent,
          ],
        ),
      ],
    );
  }

  Future<void> _checkIn(BuildContext context) async {
    final repo = ref.read(goalRepositoryProvider);
    final alreadyChecked = await repo.hasCheckedInToday(widget.goal.id);
    if (alreadyChecked) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already checked in today! 🔥')),
        );
      }
      return;
    }
    await repo.checkIn(widget.goal.id);
    ref.invalidate(goalsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked in! Keep the streak going 💪')),
      );
    }
    // If goal just achieved, show confetti
    if (widget.goal.progress >= 1.0) {
      _confetti.play();
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content:
            Text('Delete "${widget.goal.title}"? All linked data will remain.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(goalRepositoryProvider).deleteGoal(widget.goal.id);
      ref.invalidate(goalsProvider);
    }
  }
}

class _GoalStatusBadge extends StatelessWidget {
  final GoalStatus status;
  const _GoalStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      GoalStatus.active => (AppColors.primary, Icons.radio_button_checked_rounded),
      GoalStatus.achieved => (AppColors.success, Icons.check_circle_rounded),
      GoalStatus.missed => (AppColors.error, Icons.cancel_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
