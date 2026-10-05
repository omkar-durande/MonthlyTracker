import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/constants/app_strings.dart';
import 'package:monthly_goals/core/router/app_router.dart';
import 'package:monthly_goals/features/tasks/domain/task_provider.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';
import 'package:monthly_goals/features/goals/domain/goal_provider.dart';
import 'package:monthly_goals/features/goals/domain/goal_model.dart';
import 'package:monthly_goals/shared/widgets/common_widgets.dart';
import 'package:monthly_goals/core/extensions/datetime_ext.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _quote() {
    final day = DateTime.now().day;
    return AppStrings.quotes[day % AppStrings.quotes.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final todaysFocus = ref.watch(todaysFocusProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final greeting = _greeting();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tasksProvider);
          ref.invalidate(goalsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _HomeHeader(greeting: greeting, quote: _quote(), now: now),
            ),

            // Stats row
            SliverToBoxAdapter(
              child: _StatsRow(
                todaysFocus: todaysFocus,
                goalsAsync: goalsAsync,
              ),
            ),

            // Today's Focus
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, AppSizes.md, AppSizes.md, 0),
                child: Row(
                  children: [
                    Text("Today's Focus",
                        style: theme.textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.tasks),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              sliver: todaysFocus.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _FocusEmptyCard(),
                    );
                  }
                  return SliverList.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.sm),
                    itemBuilder: (ctx, i) =>
                        _FocusTaskCard(task: tasks[i], index: i),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                    child: ShimmerCard(height: 80)),
                error: (e, _) =>
                    SliverToBoxAdapter(child: ErrorState(message: e.toString())),
              ),
            ),

            // Active Goals
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, AppSizes.lg, AppSizes.md, 0),
                child: Row(
                  children: [
                    Text('Active Goals', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.goals),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.xl),
              sliver: goalsAsync.when(
                data: (goals) {
                  final active = goals
                      .where((g) => g.status == GoalStatus.active)
                      .take(3)
                      .toList();
                  if (active.isEmpty) {
                    return SliverToBoxAdapter(child: _GoalEmptyCard());
                  }
                  return SliverList.separated(
                    itemCount: active.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.sm),
                    itemBuilder: (ctx, i) =>
                        _GoalProgressCard(goal: active[i], index: i),
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: ShimmerCard(height: 80)),
                error: (e, _) =>
                    SliverToBoxAdapter(child: ErrorState(message: e.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤';
    return 'Good evening 🌙';
  }
}

class _HomeHeader extends StatelessWidget {
  final String greeting;
  final String quote;
  final DateTime now;

  const _HomeHeader(
      {required this.greeting, required this.quote, required this.now});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        MediaQuery.of(context).padding.top + AppSizes.md,
        AppSizes.md,
        AppSizes.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting,
              style: const TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(DateFormat('EEEE, MMMM d').format(now),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 15)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    quote,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }
}

class _StatsRow extends ConsumerWidget {
  final AsyncValue<List<TaskModel>> todaysFocus;
  final AsyncValue<List<GoalModel>> goalsAsync;

  const _StatsRow({required this.todaysFocus, required this.goalsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final totalTasks = tasksAsync.valueOrNull?.length ?? 0;
    final completedTasks = tasksAsync.valueOrNull
            ?.where((t) => t.status == TaskStatus.completed)
            .length ??
        0;
    final activeGoals = goalsAsync.valueOrNull
            ?.where((g) => g.status == GoalStatus.active)
            .length ??
        0;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Tasks This Month',
              value: '$completedTasks/$totalTasks',
              icon: Icons.task_alt_rounded,
              color: AppColors.primary,
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: _StatCard(
              label: 'Active Goals',
              value: '$activeGoals',
              icon: Icons.flag_rounded,
              color: AppColors.secondary,
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _FocusTaskCard extends StatelessWidget {
  final TaskModel task;
  final int index;
  const _FocusTaskCard({required this.task, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = _priorityColor(task.priority);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (task.deadline != null)
                    Text(task.deadline!.countdownLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: task.isOverdue ? AppColors.error : null,
                        )),
                ],
              ),
            ),
            PriorityBadge(
                label: task.priority.label, color: priorityColor),
          ],
        ),
      ),
    ).animate(delay: (index * 80).ms).fadeIn().slideX(begin: 0.05);
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }
}

class _GoalProgressCard extends StatelessWidget {
  final GoalModel goal;
  final int index;
  const _GoalProgressCard({required this.goal, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.fromHex(goal.color);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Text(goal.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: goal.progress,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text('${goal.progressPercent}% complete',
                      style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ProgressRing(
              progress: goal.progress,
              size: 48,
              strokeWidth: 5,
              color: color,
              center: Text('${goal.progressPercent}%',
                  style: TextStyle(
                      fontSize: 10, color: color, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 80).ms).fadeIn().slideX(begin: 0.05);
  }
}

class _FocusEmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 32),
            const SizedBox(width: 12),
            Text("You're all caught up! 🎉",
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _GoalEmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined,
                color: AppColors.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text('No active goals. Set one to get started!',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
