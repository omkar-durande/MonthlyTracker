import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/constants/app_strings.dart';
import 'package:monthly_goals/shared/widgets/common_widgets.dart';
import 'package:monthly_goals/core/utils/efficiency_calculator.dart';
import 'package:monthly_goals/features/reports/domain/report_provider.dart';
import 'package:monthly_goals/features/reports/domain/monthly_report_model.dart';
import 'package:monthly_goals/features/tasks/domain/task_provider.dart';
import 'package:monthly_goals/features/goals/domain/goal_provider.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allReports = ref.watch(allReportsProvider);
    final now = DateTime.now();
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.headerGradient),
              padding: EdgeInsets.fromLTRB(
                AppSizes.md,
                MediaQuery.of(context).padding.top + 12,
                AppSizes.md,
                AppSizes.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reports',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Track your monthly efficiency',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _GenerateReportButton(
                      currentMonthKey: currentMonthKey),
                ],
              ),
            ).animate().fadeIn(),
          ),

          // Report history
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.md),
            sliver: allReports.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.bar_chart_outlined,
                      title: AppStrings.noReports,
                      subtitle: AppStrings.noReportsSub,
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: reports.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.sm),
                  itemBuilder: (ctx, i) =>
                      _ReportHistoryCard(report: reports[i], index: i),
                );
              },
              loading: () => const SliverToBoxAdapter(
                  child: ShimmerList(count: 3, itemHeight: 100)),
              error: (e, _) => SliverToBoxAdapter(
                  child: ErrorState(message: e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateReportButton extends ConsumerWidget {
  final String currentMonthKey;
  const _GenerateReportButton({required this.currentMonthKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _generate(context, ref),
      icon: const Icon(Icons.auto_awesome_rounded),
      label: const Text('Generate This Month\'s Report'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    final tasks = ref.read(tasksProvider).valueOrNull ?? [];
    final goals = ref.read(goalsProvider).valueOrNull ?? [];

    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks this month to generate a report.')),
      );
      return;
    }

    try {
      await ref.read(reportRepositoryProvider).generateAndSave(
            tasks: tasks,
            goals: goals,
            month: currentMonthKey,
          );
      ref.invalidate(allReportsProvider);
      if (context.mounted) {
        context.push('/reports/$currentMonthKey');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _ReportHistoryCard extends StatelessWidget {
  final MonthlyReportModel report;
  final int index;
  const _ReportHistoryCard({required this.report, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grade = EfficiencyCalculator.grade(report.efficiency);
    final gradeColor = _gradeColor(report.efficiency);

    return Card(
      child: InkWell(
        onTap: () => context.push('/reports/${report.month}'),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              // Donut mini
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: report.efficiency,
                            color: gradeColor,
                            radius: 10,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: 100 - report.efficiency,
                            color: gradeColor.withValues(alpha: 0.15),
                            radius: 10,
                            showTitle: false,
                          ),
                        ],
                        centerSpaceRadius: 18,
                        sectionsSpace: 0,
                      ),
                    ),
                    Text('${report.efficiency.round()}%',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: gradeColor)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_formatMonth(report.month),
                            style: theme.textTheme.titleMedium),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: gradeColor.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(grade,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: gradeColor,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.completed}/${report.total} tasks · '
                      '${report.goalsAchieved} goals achieved',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 60).ms).fadeIn().slideX(begin: 0.05);
  }

  String _formatMonth(String key) {
    try {
      final d = DateTime.parse('$key-01');
      return DateFormat('MMMM yyyy').format(d);
    } catch (_) {
      return key;
    }
  }

  Color _gradeColor(double e) {
    if (e >= 90) return AppColors.success;
    if (e >= 70) return AppColors.primary;
    if (e >= 50) return AppColors.warning;
    return AppColors.error;
  }
}
