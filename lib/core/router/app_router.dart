import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monthly_goals/features/auth/domain/auth_provider.dart';
import 'package:monthly_goals/features/auth/presentation/login_page.dart';
import 'package:monthly_goals/features/auth/presentation/signup_page.dart';
import 'package:monthly_goals/features/auth/presentation/forgot_password_page.dart';
import 'package:monthly_goals/features/home/presentation/home_page.dart';
import 'package:monthly_goals/features/tasks/presentation/tasks_page.dart';
import 'package:monthly_goals/features/tasks/presentation/add_edit_task_page.dart';
import 'package:monthly_goals/features/tasks/presentation/task_detail_page.dart';
import 'package:monthly_goals/features/goals/presentation/goals_page.dart';
import 'package:monthly_goals/features/goals/presentation/add_edit_goal_page.dart';
import 'package:monthly_goals/features/goals/presentation/goal_detail_page.dart';
import 'package:monthly_goals/features/reports/presentation/reports_page.dart';
import 'package:monthly_goals/features/reports/presentation/report_detail_page.dart';
import 'package:monthly_goals/features/profile/presentation/profile_page.dart';
import 'package:monthly_goals/shared/widgets/scaffold_with_nav.dart';

// Route path constants
class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/:id';
  static const String addTask = '/tasks/add';
  static const String editTask = '/tasks/:id/edit';
  static const String goals = '/goals';
  static const String goalDetail = '/goals/:id';
  static const String addGoal = '/goals/add';
  static const String editGoal = '/goals/:id/edit';
  static const String reports = '/reports';
  static const String reportDetail = '/reports/:month';
  static const String profile = '/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.uri.path == AppRoutes.login ||
          state.uri.path == AppRoutes.signup ||
          state.uri.path == AppRoutes.forgotPassword;

      if (!isAuthenticated && !isAuthRoute) return AppRoutes.login;
      if (isAuthenticated && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (c, s) => _fadeTransition(s, const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (c, s) => _fadeTransition(s, const SignupPage()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (c, s) => _fadeTransition(s, const ForgotPasswordPage()),
      ),

      // Main shell with bottom nav / rail
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (c, s) => _slideTransition(s, const HomePage()),
          ),
          GoRoute(
            path: AppRoutes.tasks,
            pageBuilder: (c, s) => _slideTransition(s, const TasksPage()),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (c, s) =>
                    _slideUpTransition(s, const AddEditTaskPage()),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (c, s) => _slideTransition(
                    s, TaskDetailPage(taskId: s.pathParameters['id']!)),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (c, s) => _slideUpTransition(
                        s,
                        AddEditTaskPage(
                            taskId: s.pathParameters['id'])),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.goals,
            pageBuilder: (c, s) => _slideTransition(s, const GoalsPage()),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (c, s) =>
                    _slideUpTransition(s, const AddEditGoalPage()),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (c, s) => _slideTransition(
                    s, GoalDetailPage(goalId: s.pathParameters['id']!)),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (c, s) => _slideUpTransition(
                        s,
                        AddEditGoalPage(
                            goalId: s.pathParameters['id'])),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (c, s) => _slideTransition(s, const ReportsPage()),
            routes: [
              GoRoute(
                path: ':month',
                pageBuilder: (c, s) => _slideTransition(
                    s,
                    ReportDetailPage(
                        month: s.pathParameters['month']!)),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (c, s) => _slideTransition(s, const ProfilePage()),
          ),
        ],
      ),
    ],
  );
});

// Custom page transitions
CustomTransitionPage _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, anim, _, c) =>
        FadeTransition(opacity: anim, child: c),
    transitionDuration: const Duration(milliseconds: 300),
  );
}

CustomTransitionPage _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, anim, _, c) {
      final tween = Tween(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOut));
      return FadeTransition(
        opacity: anim,
        child: SlideTransition(position: anim.drive(tween), child: c),
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
  );
}

CustomTransitionPage _slideUpTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, anim, _, c) {
      final tween = Tween(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOut));
      return FadeTransition(
        opacity: anim,
        child: SlideTransition(position: anim.drive(tween), child: c),
      );
    },
    transitionDuration: const Duration(milliseconds: 320),
  );
}
