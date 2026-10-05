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
import 'package:monthly_goals/features/tasks/domain/task_provider.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';
import 'package:monthly_goals/core/extensions/datetime_ext.dart';

class GoalDetailPage extends ConsumerStatefulWidget {
  final String goalId;
  const GoalDetailPage({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends ConsumerState<GoalDetailPage> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(goalsProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return goalsAsync.when(
      data: (goals) {
        final goal = goals.where((g) => g.id == widget.goalId).firstOrNull;
        if (goal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Goal')),
            body: const Center(child: Text('Goal not found')),
          );
        }

        final color = AppColors.fromHex(goal.color);
        final linkedTasks = tasksAsync.valueOrNull
                ?.where((t) => t.goalId == widget.goalId)
                .toList() ??
            [];
        final completedTasks =
            linkedTasks.where((t) => t.status == TaskStatus.completed).length;

        // Show confetti if achieved
        if (goal.status == GoalStatus.achieved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_confetti.state == ConfettiControllerState.stopped) {
              _confetti.play();
            }
          });
        }

        return Scaffold(
          body: Stack(
            alignment: Alignment.topCenter,
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.8), color],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(goal.emoji,
                                  style: const TextStyle(fontSize: 56)),
                              const SizedBox(height: 8),
                              Text(goal.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                        onPressed: () =>
                            context.push('/goals/${widget.goalId}/edit'),
                      ),
                    ],
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Progress section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    ProgressRing(
                                      progress: goal.progress,
                                      size: 80,
                                      strokeWidth: 8,
                                      color: color,
                                      center: Text(
                                        '${goal.progressPercent}%',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: color),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Progress',
                                              style: theme.textTheme.titleMedium),
                                          const SizedBox(height: 4),
                                          if (goal.isMeasurable)
                                            Text(
                                              '${goal.currentValue.toStringAsFixed(0)} / ${goal.targetValue!.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w800,
                                                  color: color),
                                            )
                                          else
                                            Text(
                                              '$completedTasks / ${linkedTasks.length} tasks',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: color),
                                            ),
                                          if (goal.habitStreak > 0) ...[
                                            const SizedBox(height: 4),
                                            Row(children: [
                                              const Icon(
                                                  Icons.local_fire_department_rounded,
                                                  size: 14,
                                                  color: AppColors.warning),
                                              const SizedBox(width: 4),
                                              Text('${goal.habitStreak}-day streak',
                                                  style:
                                                      const TextStyle(
                                                          fontSize: 12,
                                                          color: AppColors.warning,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                            ]),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Measurable progress slider
                                if (goal.isMeasurable) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Slider(
                                          value: goal.currentValue
                                              .clamp(0, goal.targetValue!),
                                          max: goal.targetValue!,
                                          activeColor: color,
                                          onChanged: (v) => _updateProgress(v, goal),
                                        ),
                                      ),
                                      Text(
                                          '+1',
                                          style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.w600)),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_rounded,
                                            color: color),
                                        onPressed: () => _incrementProgress(goal),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 50.ms),
                        const SizedBox(height: AppSizes.md),

                        // Goal info
                        if (goal.description != null) ...[
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
                                  Text(goal.description!),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 100.ms),
                          const SizedBox(height: AppSizes.md),
                        ],

                        // Linked tasks
                        Text('Linked Tasks (${linkedTasks.length})',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (linkedTasks.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.md),
                              child: Text('No tasks linked to this goal.',
                                  style: theme.textTheme.bodyMedium),
                            ),
                          )
                        else
                          ...linkedTasks.asMap().entries.map((e) {
                            final t = e.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  t.status == TaskStatus.completed
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: t.status == TaskStatus.completed
                                      ? AppColors.success
                                      : AppColors.statusPending,
                                ),
                                title: Text(t.title,
                                    style: TextStyle(
                                        decoration:
                                            t.status == TaskStatus.completed
                                                ? TextDecoration.lineThrough
                                                : null)),
                                subtitle: t.deadline != null
                                    ? Text(t.deadline!.compactLabel)
                                    : null,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppSizes.radiusMd)),
                                tileColor: theme.colorScheme.surface,
                               ).animate(delay: (e.key * 50).ms).fadeIn(),
                            );
                          }),

                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),

              // Confetti
              ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppColors.primary, AppColors.secondary,
                  AppColors.success, AppColors.accent,
                ],
              ),
            ],
          ),
        );
      },
      loading: () =>
          Scaffold(appBar: AppBar(), body: const ShimmerList()),
      error: (e, _) =>
          Scaffold(appBar: AppBar(), body: ErrorState(message: e.toString())),
    );
  }

  Future<void> _updateProgress(double value, GoalModel goal) async {
    final repo = ref.read(goalRepositoryProvider);
    await repo.updateGoal(goal.copyWith(
      currentValue: value,
      status: value >= goal.targetValue! ? GoalStatus.achieved : goal.status,
    ));
    ref.invalidate(goalsProvider);
  }

  Future<void> _incrementProgress(GoalModel goal) async {
    final newValue = (goal.currentValue + 1).clamp(0.0, goal.targetValue!).toDouble();
    await _updateProgress(newValue, goal);
    if (newValue >= goal.targetValue! && mounted) {
      _confetti.play();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Goal Achieved! Congratulations!')),
      );
    }
  }
}
