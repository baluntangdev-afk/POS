import 'package:flutter/material.dart';

import '../../../navigation/router.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';
import 'onboarding_contents.dart';

/// Onboarding / attract screen.
///
/// Delegates all visual content to [OnboardingContents] (which owns the
/// gradient background). This screen is responsible only for the scaffold
/// layer (status bar config, safe area, platform selection).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAndroid = context.breakpoint.isAndroid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallHeight = constraints.maxHeight <= 500;
        final body = OnboardingContents(
          isSmallHeight: isSmallHeight,
          onTap: () => const LoginRoute().go(context),
        );

        if (isAndroid) {
          // Transparent status bar with light icons — gradient is full-bleed.
          return AndroidScaffold(
            statusBarIconBrightness: Brightness.light,
            extendBodyBehindAppBar: true,
            body: body,
          );
        }

        return WindowsScaffold(body: body);
      },
    );
  }
}
