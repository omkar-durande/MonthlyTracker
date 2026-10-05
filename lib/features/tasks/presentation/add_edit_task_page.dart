import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/constants/app_strings.dart';
import 'package:monthly_goals/core/extensions/datetime_ext.dart';
import 'package:monthly_goals/core/services/notification_service.dart';
import 'package:monthly_goals/core/services/supabase_service.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';
import 'package:monthly_goals/features/tasks/domain/task_provider.dart';
import 'package:monthly_goals/features/goals/domain/goal_provider.dart';

class AddEditTaskPage extends ConsumerStatefulWidget {
  final String? taskId;
  const AddEditTaskPage({super.key, this.taskId});

  @override
  ConsumerState<AddEditTaskPage> createState() => _AddEditTaskPageState();
}

class _AddEditTaskPageState extends ConsumerState<AddEditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.pending;
  DateTime? _deadline;
  TimeOfDay? _deadlineTime;
  String? _linkedGoalId;
  bool _isRecurring = false;
  bool _loading = false;
  TaskModel? _existingTask;

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTask());
    }
  }

  Future<void> _loadTask() async {
    final tasks = ref.read(tasksProvider).valueOrNull;
    final task = tasks?.firstWhere(
      (t) => t.id == widget.taskId,
      orElse: () => tasks.first,
    );
    if (task != null && task.id == widget.taskId) {
      setState(() {
        _existingTask = task;
        _titleCtrl.text = task.title;
        _descCtrl.text = task.description ?? '';
        _categoryCtrl.text = task.category ?? '';
        _priority = task.priority;
        _status = task.status;
        _deadline = task.deadline;
        _deadlineTime = task.deadline != null
            ? TimeOfDay.fromDateTime(task.deadline!)
            : null;
        _linkedGoalId = task.goalId;
        _isRecurring = task.isRecurring;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  DateTime? get _fullDeadline {
    if (_deadline == null) return null;
    if (_deadlineTime != null) {
      return DateTime(
        _deadline!.year,
        _deadline!.month,
        _deadline!.day,
        _deadlineTime!.hour,
        _deadlineTime!.minute,
      );
    }
    return DateTime(_deadline!.year, _deadline!.month, _deadline!.day, 23, 59);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final repo = ref.read(taskRepositoryProvider);
      final selectedMonth = ref.read(selectedMonthProvider);
      final monthKey =
          '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}';
      final userId = SupabaseService.currentUserId ?? 'demo-user-id-12345';
      final now = DateTime.now();

      if (_existingTask != null) {
        // Update
        final updated = _existingTask!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          deadline: _fullDeadline,
          priority: _priority,
          status: _status,
          category: _categoryCtrl.text.trim().isEmpty
              ? null
              : _categoryCtrl.text.trim(),
          goalId: _linkedGoalId,
          isRecurring: _isRecurring,
          updatedAt: now,
          clearDeadline: _fullDeadline == null,
        );
        await repo.updateTask(updated);
        if (_fullDeadline != null) {
          await NotificationService.scheduleTaskReminders(
            taskId: updated.id,
            taskTitle: updated.title,
            deadline: _fullDeadline!,
          );
        }
      } else {
        // Create
        final task = TaskModel(
          id: const Uuid().v4(),
          userId: userId,
          goalId: _linkedGoalId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          deadline: _fullDeadline,
          priority: _priority,
          status: _status,
          category: _categoryCtrl.text.trim().isEmpty
              ? null
              : _categoryCtrl.text.trim(),
          month: monthKey,
          isRecurring: _isRecurring,
          createdAt: now,
          updatedAt: now,
        );
        final created = await repo.createTask(task);
        if (_fullDeadline != null) {
          await NotificationService.scheduleTaskReminders(
            taskId: created.id,
            taskTitle: created.title,
            deadline: _fullDeadline!,
          );
        }
      }

      ref.invalidate(tasksProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    final isEdit = widget.taskId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? AppStrings.editTask : AppStrings.addTask),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _submit, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.taskTitle,
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Title is required'
                  : null,
            ).animate().fadeIn(delay: 50.ms),
            const SizedBox(height: AppSizes.md),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.taskDescription,
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: AppSizes.md),

            // Deadline
            const _SectionLabel(label: AppStrings.deadline),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(_deadline == null
                        ? 'Set Date'
                        : _deadline!.fullDate),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _deadline != null
                          ? AppColors.primary
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deadline != null ? _pickTime : null,
                    icon: const Icon(Icons.access_time_rounded, size: 18),
                    label: Text(_deadlineTime == null
                        ? 'Set Time'
                        : _deadlineTime!.format(context)),
                  ),
                ),
                if (_deadline != null)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () =>
                        setState(() { _deadline = null; _deadlineTime = null; }),
                  ),
              ],
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: AppSizes.md),

            // Priority
            const _SectionLabel(label: AppStrings.priority),
            _PrioritySelector(
              value: _priority,
              onChanged: (v) => setState(() => _priority = v),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: AppSizes.md),

            // Status
            const _SectionLabel(label: AppStrings.status),
            _StatusSelector(
              value: _status,
              onChanged: (v) => setState(() => _status = v),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: AppSizes.md),

            // Category
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.category,
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: AppSizes.md),

            // Linked goal
            const _SectionLabel(label: AppStrings.linkedGoal),
            goalsAsync.when(
              data: (goals) {
                final validValue = goals.any((g) => g.id == _linkedGoalId)
                    ? _linkedGoalId
                    : null;
                return DropdownButtonFormField<String?>(
                  value: validValue,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('None')),
                    ...goals.map((g) => DropdownMenuItem<String?>(
                          value: g.id,
                          child: Text(
                            '${g.emoji}  ${g.title}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (v) => setState(() => _linkedGoalId = v),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: AppSizes.md),

            // Recurring toggle
            SwitchListTile(
              title: const Text(AppStrings.recurring),
              subtitle: const Text('Carried over each month automatically'),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(isEdit ? 'Update Task' : 'Create Task'),
            ).animate().fadeIn(delay: 450.ms),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _deadlineTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _deadlineTime = picked);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;

  const _PrioritySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskPriority.values.map((p) {
        final color = switch (p) {
          TaskPriority.low => AppColors.priorityLow,
          TaskPriority.medium => AppColors.priorityMedium,
          TaskPriority.high => AppColors.priorityHigh,
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: value == p
                      ? color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: value == p ? color : color.withValues(alpha: 0.3),
                    width: value == p ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.circle, color: color, size: 14),
                    const SizedBox(height: 4),
                    Text(p.label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: value == p
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: color)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final TaskStatus value;
  final ValueChanged<TaskStatus> onChanged;

  const _StatusSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskStatus.values.map((s) {
        final color = switch (s) {
          TaskStatus.pending => AppColors.statusPending,
          TaskStatus.inProgress => AppColors.statusInProgress,
          TaskStatus.completed => AppColors.statusCompleted,
        };
        final selected = value == s;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(s),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: selected ? color : color.withValues(alpha: 0.3),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  s.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
