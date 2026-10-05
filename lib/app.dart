import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_goals/core/router/app_router.dart';
import 'package:monthly_goals/core/theme/app_theme.dart';
import 'package:monthly_goals/shared/providers/theme_provider.dart';

class MonthlyGoalsApp extends ConsumerWidget {
  const MonthlyGoalsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'MonthlyGoals',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
