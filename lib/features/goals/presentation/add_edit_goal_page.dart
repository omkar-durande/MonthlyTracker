import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/constants/app_strings.dart';
import 'package:monthly_goals/core/services/supabase_service.dart';
import 'package:monthly_goals/features/goals/domain/goal_model.dart';
import 'package:monthly_goals/features/goals/domain/goal_provider.dart';

class AddEditGoalPage extends ConsumerStatefulWidget {
  final String? goalId;
  const AddEditGoalPage({super.key, this.goalId});

  @override
  ConsumerState<AddEditGoalPage> createState() => _AddEditGoalPageState();
}

class _AddEditGoalPageState extends ConsumerState<AddEditGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();

  String _emoji = '🎯';
  String _color = '#6366F1';
  DateTime? _deadline;
  GoalStatus _status = GoalStatus.active;
  bool _hasMeasurable = false;
  bool _loading = false;
  GoalModel? _existingGoal;

  final _emojis = [
    '🎯', '🏋️', '📚', '💡', '🚀', '🎨', '💼', '🌱', '🧘', '🏃',
    '✍️', '🎵', '💰', '🏠', '❤️', '🤝', '🌍', '🔬', '🏆', '⭐',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.goalId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadGoal());
    }
  }

  Future<void> _loadGoal() async {
    final goals = ref.read(goalsProvider).valueOrNull;
    final goal = goals?.firstWhere(
      (g) => g.id == widget.goalId,
      orElse: () => goals.first,
    );
    if (goal != null && goal.id == widget.goalId) {
      setState(() {
        _existingGoal = goal;
        _titleCtrl.text = goal.title;
        _descCtrl.text = goal.description ?? '';
        _emoji = goal.emoji;
        _color = goal.color;
        _deadline = goal.deadline;
        _status = goal.status;
        _hasMeasurable = goal.isMeasurable;
        if (goal.targetValue != null) {
          _targetCtrl.text = goal.targetValue!.toStringAsFixed(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(goalRepositoryProvider);
      final selectedMonth = ref.read(selectedGoalMonthProvider);
      final monthKey =
          '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}';
      final now = DateTime.now();

      if (_existingGoal != null) {
        final updated = _existingGoal!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          emoji: _emoji,
          color: _color,
          targetValue: _hasMeasurable && _targetCtrl.text.isNotEmpty
              ? double.tryParse(_targetCtrl.text)
              : null,
          deadline: _deadline,
          status: _status,
          updatedAt: now,
          clearTargetValue: !_hasMeasurable,
          clearDeadline: _deadline == null,
        );
        await repo.updateGoal(updated);
      } else {
        final goal = GoalModel(
          id: const Uuid().v4(),
          userId: SupabaseService.currentUserId ?? 'demo-user-id-12345',
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          emoji: _emoji,
          color: _color,
          targetValue: _hasMeasurable && _targetCtrl.text.isNotEmpty
              ? double.tryParse(_targetCtrl.text)
              : null,
          deadline: _deadline,
          status: GoalStatus.active,
          month: monthKey,
          createdAt: now,
          updatedAt: now,
        );
        await repo.createGoal(goal);
      }
      ref.invalidate(goalsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = AppColors.fromHex(_color);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goalId != null
            ? AppStrings.editGoal
            : AppStrings.addGoal),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            // Preview card
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: selectedColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: selectedColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(_emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleCtrl.text.isEmpty
                              ? 'Goal Title'
                              : _titleCtrl.text,
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: selectedColor),
                        ),
                        if (_descCtrl.text.isNotEmpty)
                          Text(_descCtrl.text,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: AppSizes.md),

            // Emoji picker
            const _SectionLabel('Emoji'),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final e = _emojis[i];
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: e == _emoji
                            ? selectedColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: e == _emoji
                              ? selectedColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                          child: Text(e,
                              style: const TextStyle(fontSize: 22))),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 50.ms),
            const SizedBox(height: AppSizes.md),

            // Color picker
            const _SectionLabel('Color'),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppColors.goalColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = AppColors.goalColors[i];
                  final isSelected = _color == c;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.fromHex(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(
                                color: AppColors.fromHex(c).withValues(alpha: 0.5),
                                blurRadius: 8)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: AppSizes.md),

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.goalTitle,
                prefixIcon: Icon(Icons.title_rounded),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: AppSizes.md),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.goalDescription,
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: AppSizes.md),

            // Deadline
            const _SectionLabel('Deadline (optional)'),
            OutlinedButton.icon(
              onPressed: _pickDeadline,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(_deadline == null
                  ? 'Set Deadline'
                  : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: AppSizes.md),

            // Measurable goal
            SwitchListTile(
              title: const Text('Measurable Goal'),
              subtitle: const Text('E.g., "Read 10 books", "Workout 20 days"'),
              value: _hasMeasurable,
              onChanged: (v) => setState(() => _hasMeasurable = v),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            ).animate().fadeIn(delay: 300.ms),

            if (_hasMeasurable) ...[
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: AppStrings.targetValue,
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (v) {
                  if (_hasMeasurable && (v == null || v.isEmpty)) {
                    return 'Target value required for measurable goals';
                  }
                  return null;
                },
              ).animate().fadeIn(),
            ],

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(widget.goalId != null ? 'Update Goal' : 'Create Goal'),
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _deadline = picked);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

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
