import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:monthly_goals/core/constants/app_colors.dart';
import 'package:monthly_goals/core/constants/app_sizes.dart';
import 'package:monthly_goals/core/router/app_router.dart';

class ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNav({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: AppRoutes.home),
    (icon: Icons.check_box_outlined, activeIcon: Icons.check_box_rounded, label: 'Tasks', path: AppRoutes.tasks),
    (icon: Icons.flag_outlined, activeIcon: Icons.flag_rounded, label: 'Goals', path: AppRoutes.goals),
    (icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Reports', path: AppRoutes.reports),
    (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', path: AppRoutes.profile),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= AppSizes.navRailBreakpoint;
    final currentIndex = _currentIndex(context);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (i) => context.go(_tabs[i].path),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ShaderMask(
                  shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                  child: const Icon(Icons.track_changes_rounded, size: 32, color: Colors.white),
                ),
              ),
              destinations: _tabs.map((t) => NavigationRailDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon, color: AppColors.primary),
                label: Text(t.label),
              )).toList(),
              useIndicator: true,
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs.map((t) => NavigationDestination(
          icon: Icon(t.icon),
          selectedIcon: Icon(t.activeIcon, color: AppColors.primary),
          label: t.label,
        )).toList(),
      ),
    );
  }
}
