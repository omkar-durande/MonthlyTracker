import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/utils/efficiency_calculator.dart';
import 'package:monthly_goals/shared/widgets/common_widgets.dart';
import 'package:monthly_goals/features/reports/domain/report_provider.dart';
import 'package:monthly_goals/features/reports/domain/monthly_report_model.dart';

class ReportDetailPage extends ConsumerWidget {
  final String month;
  const ReportDetailPage({super.key, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportForMonthProvider(month));

    return Scaffold(
      body: reportAsync.when(
        data: (report) {
          if (report == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Report')),
              body: const Center(child: Text('Report not found')),
            );
          }
          return _ReportBody(report: report);
        },
        loading: () =>
            Scaffold(appBar: AppBar(), body: const ShimmerList()),
        error: (e, _) =>
            Scaffold(appBar: AppBar(), body: ErrorState(message: e.toString())),
      ),
    );
  }
}

class _ReportBody extends StatefulWidget {
  final MonthlyReportModel report;
  const _ReportBody({required this.report});

  @override
  State<_ReportBody> createState() => _ReportBodyState();
}

class _ReportBodyState extends State<_ReportBody> {
  final _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = widget.report;
    final grade = EfficiencyCalculator.grade(report.efficiency);
    final gradeColor = _gradeColor(report.efficiency);
    final insight = report.summaryJson['insight'] as String? ?? '';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.headerGradient),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    _formatMonth(report.month),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    grade,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: () => _shareReport(),
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(AppSizes.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              RepaintBoundary(
                key: _repaintKey,
                child: Column(
                  children: [
                    // Main efficiency card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _BigStat(
                                  label: 'Efficiency',
                                  value: '${report.efficiency.round()}%',
                                  color: gradeColor,
                                  icon: Icons.speed_rounded,
                                ),
                                _BigStat(
                                  label: 'On-Time',
                                  value: '${(report.summaryJson['on_time_rate'] as num? ?? 0).round()}%',
                                  color: AppColors.info,
                                  icon: Icons.timer_rounded,
                                ),
                                _BigStat(
                                  label: 'Completed',
                                  value: '${report.completed}/${report.total}',
                                  color: AppColors.success,
                                  icon: Icons.check_circle_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.md),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: report.efficiency / 100,
                                minHeight: 12,
                                backgroundColor: gradeColor.withValues(alpha: 0.15),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(gradeColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 50.ms),
                    const SizedBox(height: AppSizes.md),

                    // Counts row
                    Row(children: [
                      Expanded(
                          child: _CountCard(
                              label: 'Completed', value: report.completed,
                              color: AppColors.success)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _CountCard(
                              label: 'Pending', value: report.pending,
                              color: AppColors.statusPending)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _CountCard(
                              label: 'Overdue', value: report.overdue,
                              color: AppColors.error)),
                    ]).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: AppSizes.md),

                    // Goals
                    Row(children: [
                      Expanded(
                          child: _CountCard(
                              label: 'Goals Achieved',
                              value: report.goalsAchieved,
                              color: AppColors.success)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _CountCard(
                              label: 'Goals Missed',
                              value: report.goalsMissed,
                              color: AppColors.error)),
                    ]).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: AppSizes.md),

                    // Completion donut
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Task Breakdown',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: AppSizes.md),
                            SizedBox(
                              height: 180,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: PieChart(
                                      PieChartData(
                                        sections: [
                                          PieChartSectionData(
                                            value: report.completed.toDouble(),
                                            color: AppColors.success,
                                            title:
                                                '${report.completed}',
                                            titleStyle: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700),
                                            radius: 60,
                                          ),
                                          PieChartSectionData(
                                            value: report.pending.toDouble(),
                                            color: AppColors.statusPending,
                                            title: '${report.pending}',
                                            titleStyle: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700),
                                            radius: 60,
                                          ),
                                          if (report.overdue > 0)
                                            PieChartSectionData(
                                              value: report.overdue.toDouble(),
                                              color: AppColors.error,
                                              title: '${report.overdue}',
                                              titleStyle: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700),
                                              radius: 60,
                                            ),
                                        ],
                                        centerSpaceRadius: 40,
                                        sectionsSpace: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _Legend(
                                          color: AppColors.success,
                                          label: 'Completed'),
                                      SizedBox(height: 8),
                                      _Legend(
                                          color: AppColors.statusPending,
                                          label: 'Pending'),
                                      SizedBox(height: 8),
                                      _Legend(
                                          color: AppColors.error,
                                          label: 'Overdue'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: AppSizes.md),

                    // Weekly bar chart
                    if (report.weeklyCompletions.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Weekly Completions',
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: AppSizes.md),
                              SizedBox(
                                height: 160,
                                child: BarChart(
                                  BarChartData(
                                    alignment:
                                        BarChartAlignment.spaceAround,
                                    barGroups: _buildBarGroups(
                                        report.weeklyCompletions),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 28,
                                              getTitlesWidget: (v, _) =>
                                                  Text('${v.toInt()}',
                                                      style: const TextStyle(
                                                          fontSize: 10)))),
                                      bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (v, _) {
                                                final labels = [
                                                  'W1', 'W2', 'W3', 'W4', 'W5'
                                                ];
                                                final idx = v.toInt();
                                                return idx < labels.length
                                                    ? Text(labels[idx],
                                                        style: const TextStyle(
                                                            fontSize: 10))
                                                    : const SizedBox.shrink();
                                              })),
                                      topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                              showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                              showTitles: false)),
                                    ),
                                    gridData: const FlGridData(
                                        drawVerticalLine: false),
                                    borderData: FlBorderData(show: false),
                                    barTouchData:
                                        BarTouchData(enabled: true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: AppSizes.md),
                    ],

                    // Daily line chart
                    if (report.dailyCompletions.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Daily Productivity',
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: AppSizes.md),
                              SizedBox(
                                height: 160,
                                child: LineChart(
                                  LineChartData(
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _buildLineSpots(
                                            report.dailyCompletions),
                                        isCurved: true,
                                        color: AppColors.primary,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ],
                                    titlesData: const FlTitlesData(
                                      topTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                              showTitles: false)),
                                      rightTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                              showTitles: false)),
                                    ),
                                    gridData: FlGridData(
                                      drawVerticalLine: false,
                                      horizontalInterval: 1,
                                      getDrawingHorizontalLine: (v) =>
                                          FlLine(
                                              color: Colors.grey
                                                  .withValues(alpha: 0.15),
                                              strokeWidth: 1),
                                    ),
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: AppSizes.md),
                    ],

                    // Highlights
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Highlights',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: AppSizes.sm),
                            if (report.bestDay.isNotEmpty)
                              _HighlightRow(
                                  icon: Icons.star_rounded,
                                  label: 'Best Day',
                                  value: report.bestDay,
                                  color: AppColors.secondary),
                            if (report.mostProductiveCategory.isNotEmpty)
                              _HighlightRow(
                                  icon: Icons.label_rounded,
                                  label: 'Top Category',
                                  value: report.mostProductiveCategory,
                                  color: AppColors.primary),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms),

                    // Insight
                    if (insight.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.md),
                      GlassCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (b) =>
                                  AppColors.primaryGradient.createShader(b),
                              child: const Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(insight,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontStyle: FontStyle.italic)),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, int> data) {
    final keys = ['W1', 'W2', 'W3', 'W4', 'W5'];
    return keys.asMap().entries.map((e) {
      final v = data[e.value] ?? 0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: v.toDouble(),
            color: AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  List<FlSpot> _buildLineSpots(Map<String, int> data) {
    final sorted = data.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
    return sorted
        .map((e) => FlSpot(int.parse(e.key).toDouble(), e.value.toDouble()))
        .toList();
  }

  Color _gradeColor(double e) {
    if (e >= 90) return AppColors.success;
    if (e >= 70) return AppColors.primary;
    if (e >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _formatMonth(String key) {
    try {
      return DateFormat('MMMM yyyy').format(DateTime.parse('$key-01'));
    } catch (_) {
      return key;
    }
  }

  Future<void> _shareReport() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final xFile = XFile.fromData(bytes,
          mimeType: 'image/png', name: 'monthly_report.png');
      await Share.shareXFiles([xFile],
          text: 'My Monthly Goals Report 📊');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e')),
        );
      }
    }
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _BigStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _CountCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSizes.sm, horizontal: AppSizes.sm),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HighlightRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text('$label: ',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
