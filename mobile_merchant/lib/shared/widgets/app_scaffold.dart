import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Every screen is wrapped in this. Keeps padding, background, and app-bar
/// treatment consistent.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.all(16),
    this.safeArea = true,
    super.key,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: body);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: safeArea ? SafeArea(child: content) : content,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
