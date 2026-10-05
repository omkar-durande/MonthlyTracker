import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/constants/app_strings.dart';
import 'package:monthly_goals/core/extensions/datetime_ext.dart';
import 'package:monthly_goals/core/services/supabase_service.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';
import 'package:monthly_goals/features/tasks/domain/task_provider.dart';

/// Bottom sheet for the carry-over flow when the user opens a new month.
class CarryOverSheet extends ConsumerStatefulWidget {
  final String previousMonth;
  final String currentMonth;

  const CarryOverSheet({
    super.key,
    required this.previousMonth,
    required this.currentMonth,
  });

  @override
  ConsumerState<CarryOverSheet> createState() => _CarryOverSheetState();
}

class _CarryOverSheetState extends ConsumerState<CarryOverSheet> {
  List<TaskModel> _tasks = [];
  final Set<String> _selected = {};
  final Map<String, DateTime?> _newDeadlines = {};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(taskRepositoryProvider);
    final tasks =
        await repo.fetchUnfinishedFromMonth(widget.previousMonth);
    setState(() {
      _tasks = tasks;
      _selected.addAll(tasks.map((t) => t.id));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) {
        return Column(
          children: [
            // Handle
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.carryOverTitle,
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'You have ${_tasks.length} unfinished tasks from ${widget.previousMonth}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  if (!_loading) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setState(
                              () => _selected.addAll(_tasks.map((t) => t.id))),
                          child: const Text(AppStrings.selectAll),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selected.clear()),
                          child: const Text(AppStrings.selectNone),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const Divider(),

            // Task list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _tasks.isEmpty
                      ? Center(
                          child: Text(
                            'No unfinished tasks from last month 🎉',
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          controller: scroll,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md),
                          itemCount: _tasks.length,
                          itemBuilder: (_, i) =>
                              _CarryOverTaskRow(
                            task: _tasks[i],
                            isSelected: _selected.contains(_tasks[i].id),
                            newDeadline: _newDeadlines[_tasks[i].id],
                            onToggle: (v) {
                              setState(() {
                                if (v) {
                                  _selected.add(_tasks[i].id);
                                } else {
                                  _selected.remove(_tasks[i].id);
                                }
                              });
                            },
                            onDeadlineChanged: (d) {
                              setState(
                                  () => _newDeadlines[_tasks[i].id] = d);
                            },
                          ),
                        ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: ElevatedButton(
                  onPressed: _selected.isEmpty || _submitting
                      ? null
                      : _addToThisMonth,
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          'Add ${_selected.length} task(s) to ${widget.currentMonth}'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToThisMonth() async {
    setState(() => _submitting = true);
    final repo = ref.read(taskRepositoryProvider);
    final now = DateTime.now();
    final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';

    for (final task in _tasks.where((t) => _selected.contains(t.id))) {
      final newDeadline = _newDeadlines[task.id] ?? task.deadline;
      final carried = TaskModel(
        id: const Uuid().v4(),
        userId: userId,
        goalId: task.goalId,
        title: task.title,
        description: task.description,
        deadline: newDeadline,
        priority: task.priority,
        status: TaskStatus.pending,
        category: task.category,
        month: widget.currentMonth,
        carriedFrom: task.id,
        isRecurring: task.isRecurring,
        createdAt: now,
        updatedAt: now,
      );
      await repo.createTask(carried);
    }

    ref.invalidate(tasksProvider);
    if (mounted) Navigator.pop(context, true);
  }
}

class _CarryOverTaskRow extends StatelessWidget {
  final TaskModel task;
  final bool isSelected;
  final DateTime? newDeadline;
  final ValueChanged<bool> onToggle;
  final ValueChanged<DateTime?> onDeadlineChanged;

  const _CarryOverTaskRow({
    required this.task,
    required this.isSelected,
    required this.newDeadline,
    required this.onToggle,
    required this.onDeadlineChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysOverdue = task.deadline != null
        ? DateTime.now().difference(task.deadline!).inDays
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (v) => onToggle(v ?? false),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  if (task.deadline != null)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'Original: ${task.deadline!.compactLabel}${daysOverdue > 0 ? ' ($daysOverdue days overdue)' : ''}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.error),
                        ),
                      ],
                    ),
                  if (newDeadline != null)
                    Row(
                      children: [
                        const Icon(Icons.update_rounded,
                            size: 12, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text('New: ${newDeadline!.compactLabel}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.success)),
                      ],
                    ),
                  if (isSelected)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => onDeadlineChanged(null),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Keep old',
                              style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _pickNewDeadline(context),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Set new date',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickNewDeadline(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) onDeadlineChanged(picked);
  }
}
