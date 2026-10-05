import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/constants/app_strings.dart';
import 'package:monthly_goals/shared/widgets/common_widgets.dart';
import 'package:monthly_goals/features/tasks/domain/task_provider.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';
import 'package:monthly_goals/features/tasks/presentation/widgets/task_card.dart';
import 'package:monthly_goals/features/tasks/presentation/widgets/month_selector.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  bool _showCalendar = false;
  DateTime? _selectedCalendarDay;

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final filter = ref.watch(taskFilterProvider);
    final filteredAsync = ref.watch(filteredTasksProvider);

    return Scaffold(
      body: Column(
        children: [
          // Gradient header with month selector
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
                    Expanded(
                      child: MonthSelector(
                        selectedMonth: selectedMonth,
                        onChanged: (m) {
                          ref.read(selectedMonthProvider.notifier).state = m;
                          _selectedCalendarDay = null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showCalendar
                            ? Icons.calendar_today_rounded
                            : Icons.calendar_month_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _showCalendar = !_showCalendar),
                    ),
                    PopupMenuButton<TaskSortOption>(
                      icon: const Icon(Icons.sort_rounded, color: Colors.white),
                      onSelected: (v) =>
                          ref.read(taskSortProvider.notifier).state = v,
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: TaskSortOption.deadline,
                            child: Text('Sort by Deadline')),
                        const PopupMenuItem(
                            value: TaskSortOption.priority,
                            child: Text('Sort by Priority')),
                        const PopupMenuItem(
                            value: TaskSortOption.createdAt,
                            child: Text('Sort by Created')),
                      ],
                    ),
                  ],
                ),
                // Search bar
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tasks…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) =>
                      ref.read(taskSearchProvider.notifier).state = v,
                ),
              ],
            ),
          ),

          // Calendar view
          if (_showCalendar)
            _CalendarSection(
              selectedMonth: selectedMonth,
              tasks: filteredAsync.valueOrNull ?? [],
              selectedDay: _selectedCalendarDay,
              onDaySelected: (d) => setState(() => _selectedCalendarDay = d),
            ),

          // Filter chips
          _FilterChips(filter: filter),

          // Task list
          Expanded(
            child: filteredAsync.when(
              data: (tasks) {
                final displayTasks = _selectedCalendarDay != null
                    ? tasks
                        .where((t) =>
                            t.deadline != null &&
                            isSameDay(t.deadline!, _selectedCalendarDay!))
                        .toList()
                    : tasks;

                if (displayTasks.isEmpty) {
                  return EmptyState(
                    icon: Icons.check_box_outlined,
                    title: AppStrings.noTasks,
                    subtitle: AppStrings.noTasksSub,
                    action: ElevatedButton.icon(
                      onPressed: () => context.push('/tasks/add'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(AppStrings.addTask),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.md, AppSizes.sm, AppSizes.md, 100),
                  itemCount: displayTasks.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.sm),
                  itemBuilder: (ctx, i) => TaskCard(
                    task: displayTasks[i],
                    index: i,
                    onStatusChanged: (s) =>
                        _updateStatus(displayTasks[i], s, ref),
                    onDelete: () => _delete(displayTasks[i], ref, ctx),
                  ),
                );
              },
              loading: () => const ShimmerList(count: 5),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(tasksProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_task_fab',
        onPressed: () => context.push('/tasks/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addTask),
      ).animate().scale(delay: 300.ms),
    );
  }

  Future<void> _updateStatus(
      TaskModel task, TaskStatus status, WidgetRef ref) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.updateTask(task.copyWith(status: status));
    ref.invalidate(tasksProvider);
  }

  Future<void> _delete(
      TaskModel task, WidgetRef ref, BuildContext ctx) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.deleteTask(task.id);
    ref.invalidate(tasksProvider);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.taskDeleted),
          action: SnackBarAction(
            label: AppStrings.undo,
            onPressed: () async {
              await repo.createTask(task);
              ref.invalidate(tasksProvider);
            },
          ),
        ),
      );
    }
  }
}

class _CalendarSection extends StatelessWidget {
  final DateTime selectedMonth;
  final List<TaskModel> tasks;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarSection({
    required this.selectedMonth,
    required this.tasks,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TableCalendar(
      firstDay: DateTime(selectedMonth.year, selectedMonth.month, 1),
      lastDay: DateTime(selectedMonth.year, selectedMonth.month + 1, 0),
      focusedDay: selectedDay ?? selectedMonth,
      selectedDayPredicate: (d) =>
          selectedDay != null && isSameDay(d, selectedDay!),
      onDaySelected: (sel, _) => onDaySelected(sel),
      calendarFormat: CalendarFormat.month,
      headerVisible: false,
      eventLoader: (day) => tasks
          .where((t) => t.deadline != null && isSameDay(t.deadline!, day))
          .toList(),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
        ),
        weekendTextStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  final TaskFilter filter;
  const _FilterChips({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, 0),
      child: Row(
        children: TaskFilter.values.map((f) {
          final label = switch (f) {
            TaskFilter.all => 'All',
            TaskFilter.pending => 'Pending',
            TaskFilter.inProgress => 'In Progress',
            TaskFilter.completed => 'Completed',
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: filter == f,
              onSelected: (_) =>
                  ref.read(taskFilterProvider.notifier).state = f,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
            ),
          );
        }).toList(),
      ),
    );
  }
}
