import 'package:flutter/material.dart';

import '../styles/color_set.dart';
import 'top_app_bar.dart';

/// Full-screen modal scaffold used for kiosk-form-factor overlays.
/// Wraps a [TopAppBar] header above [body] content inside a white surface.
class KioskModal extends StatelessWidget {
  const KioskModal({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.trailing,
    this.showBack = true,
  });

  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorSet.background,
      body: Column(
        children: [
          TopAppBar(
            title: title,
            onBackPressed: onBack,
            trailing: trailing,
            showBack: showBack,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
