import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/constants/app_strings.dart';
import 'package:monthly_goals/core/router/app_router.dart';
import 'package:monthly_goals/core/services/supabase_service.dart';
import 'package:monthly_goals/features/auth/domain/auth_provider.dart';
import 'package:monthly_goals/features/tasks/domain/task_provider.dart';
import 'package:monthly_goals/features/goals/domain/goal_provider.dart';
import 'package:monthly_goals/features/tasks/domain/task_model.dart';
import 'package:monthly_goals/shared/providers/theme_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = SupabaseService.currentUser;
    final tasksAsync = ref.watch(tasksProvider);
    final goalsAsync = ref.watch(goalsProvider);

    final fullName = (user?.userMetadata?['full_name'] as String?) ??
        user?.email ??
        'User';
    final email = user?.email ?? '';
    final initials = fullName.isNotEmpty
        ? fullName.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
        : '?';

    final totalTasks = tasksAsync.valueOrNull?.length ?? 0;
    final completedTasks = tasksAsync.valueOrNull
            ?.where((t) => t.status == TaskStatus.completed)
            .length ??
        0;
    final activeGoals = goalsAsync.valueOrNull?.length ?? 0;

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
                AppSizes.xl,
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ).animate().scale(delay: 100.ms),
                  const SizedBox(height: 12),
                  Text(fullName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(email,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14)),
                ],
              ),
            ).animate().fadeIn(),
          ),

          // Stats
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    _ProfileStat(
                        label: 'Tasks Done',
                        value: '$completedTasks/$totalTasks'),
                    const SizedBox(width: 8),
                    _ProfileStat(
                        label: 'Goals Set',
                        value: '$activeGoals'),
                  ],
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: AppSizes.lg),

                // Settings section
                Text('Settings',
                    style: theme.textTheme.titleMedium).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 8),

                Card(
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        subtitle: 'Deadline reminders',
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 56),
                      _ThemeTile(),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: Icons.info_outline_rounded,
                        label: 'About MonthlyGoals',
                        subtitle: 'Version 1.0.0',
                        onTap: () {},
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: AppSizes.md),

                // Sign out
                OutlinedButton.icon(
                  onPressed: () => _signOut(context, ref),
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.error),
                  label: const Text(AppStrings.logout,
                      style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProfileTile(
      {required this.icon,
      required this.label,
      this.subtitle,
      this.trailing,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

// Theme toggle tile
class _ThemeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: AppColors.primary),
      title: const Text('Theme'),
      subtitle: Text(isDark ? 'Dark' : 'Light'),
      trailing: Switch(
        value: isDark,
        onChanged: (_) {
          ref.read(themeModeProvider.notifier).state =
              isDark ? ThemeMode.light : ThemeMode.dark;
        },
      ),
    );
  }
}
