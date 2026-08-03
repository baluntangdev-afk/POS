import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../utils/breakpoints.dart';
import 'shell_nav_items.dart';

class AdaptiveShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdaptiveShell({super.key, required this.navigationShell});

  void _onTap(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (Breakpoints.isTablet(constraints.maxWidth)) {
          return _TabletShell(
            navigationShell: navigationShell,
            onTap: _onTap,
          );
        }
        return _PhoneShell(
          navigationShell: navigationShell,
          onTap: _onTap,
        );
      },
    );
  }
}

class _TabletShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTap;

  const _TabletShell({required this.navigationShell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.surface,
            selectedIndex: current,
            onDestinationSelected: onTap,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.point_of_sale, color: AppColors.primary, size: 32),
            ),
            destinations: shellNavItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _PhoneShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTap;

  const _PhoneShell({required this.navigationShell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: onTap,
        destinations: shellNavItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
