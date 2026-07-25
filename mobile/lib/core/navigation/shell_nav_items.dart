import 'package:flutter/material.dart';

class ShellNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const ShellNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

const shellNavItems = [
  ShellNavItem(
    label: 'Order',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
  ),
  ShellNavItem(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),
  ShellNavItem(
    label: 'Inventory',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view,
  ),
  ShellNavItem(
    label: 'Users',
    icon: Icons.people_outlined,
    selectedIcon: Icons.people,
  ),
  ShellNavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];
