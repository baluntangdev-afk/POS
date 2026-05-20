import 'package:flutter/material.dart';

import '../../../navigation/router.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';
import 'onboarding_contents.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAndroid = context.breakpoint.isAndroid;

    if (isAndroid) {
      return AndroidScaffold(
        statusBarIconBrightness: Brightness.light,
        extendBodyBehindAppBar: true,
        body: GestureDetector(
          onTap: () => const LoginRoute().go(context),
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallHeight = constraints.maxHeight <= 500;
                return SizedBox.expand(
                  child: OnboardingContents(isSmallHeight: isSmallHeight),
                );
              },
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => const LoginRoute().go(context),
      child: WindowsScaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallHeight = constraints.maxHeight <= 500;
            return SizedBox.expand(
              child: OnboardingContents(isSmallHeight: isSmallHeight),
            );
          },
        ),
      ),
    );
  }
}
