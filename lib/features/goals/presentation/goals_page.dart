import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/constants/app_strings.dart';
import 'package:monthly_goals/shared/widgets/common_widgets.dart';
import 'package:monthly_goals/features/goals/domain/goal_model.dart';
import 'package:monthly_goals/features/goals/domain/goal_provider.dart';
import 'package:monthly_goals/features/goals/presentation/widgets/goal_card.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(filteredGoalsProvider);
    final filter = ref.watch(goalFilterProvider);
    final selectedMonth = ref.watch(selectedGoalMonthProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            padding: EdgeInsets.fromLTRB(
              AppSizes.md,
              MediaQuery.of(context).padding.top + 12,
              AppSizes.md,
              AppSizes.md,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Goals',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Month nav
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white),
                      onPressed: () {
                        ref.read(selectedGoalMonthProvider.notifier).state =
                            DateTime(selectedMonth.year,
                                selectedMonth.month - 1);
                      },
                    ),
                    Text(
                      '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                      onPressed: () {
                        ref.read(selectedGoalMonthProvider.notifier).state =
                            DateTime(selectedMonth.year,
                                selectedMonth.month + 1);
                      },
                    ),
                  ],
                ),
                // Summary row
                goalsAsync.when(
                  data: (goals) => _GoalSummaryRow(goals: goals),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ).animate().fadeIn(),

          // Filter chips
          _GoalFilterChips(filter: filter),

          // Goal list
          Expanded(
            child: goalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return EmptyState(
                    icon: Icons.flag_outlined,
                    title: AppStrings.noGoals,
                    subtitle: AppStrings.noGoalsSub,
                    action: ElevatedButton.icon(
                      onPressed: () => context.push('/goals/add'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(AppStrings.addGoal),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(goalsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.md, AppSizes.sm, AppSizes.md, 100),
                    itemCount: goals.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.sm),
                    itemBuilder: (ctx, i) =>
                        GoalCard(goal: goals[i], index: i),
                  ),
                );
              },
              loading: () => const ShimmerList(count: 4, itemHeight: 120),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(goalsProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_goal_fab',
        onPressed: () => context.push('/goals/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addGoal),
      ).animate().scale(delay: 300.ms),
    );
  }
}

class _GoalSummaryRow extends StatelessWidget {
  final List<GoalModel> goals;
  const _GoalSummaryRow({required this.goals});

  @override
  Widget build(BuildContext context) {
    final active = goals.where((g) => g.status == GoalStatus.active).length;
    final achieved =
        goals.where((g) => g.status == GoalStatus.achieved).length;
    final missed = goals.where((g) => g.status == GoalStatus.missed).length;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _SmallStat(label: 'Active', value: '$active',
              color: AppColors.primaryLight),
          _SmallStat(label: 'Achieved', value: '$achieved',
              color: AppColors.success),
          _SmallStat(label: 'Missed', value: '$missed',
              color: AppColors.error),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SmallStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
        ],
      ),
    );
  }
}

class _GoalFilterChips extends ConsumerWidget {
  final GoalFilter filter;
  const _GoalFilterChips({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
          AppSizes.md, AppSizes.sm, AppSizes.md, 0),
      child: Row(
        children: GoalFilter.values.map((f) {
          final label = switch (f) {
            GoalFilter.all => 'All',
            GoalFilter.active => 'Active',
            GoalFilter.achieved => 'Achieved',
            GoalFilter.missed => 'Missed',
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: filter == f,
              onSelected: (_) =>
                  ref.read(goalFilterProvider.notifier).state = f,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
            ),
          );
        }).toList(),
      ),
    );
  }
}
