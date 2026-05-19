import 'package:flutter/material.dart';

import '../../../navigation/router.dart';
import '../../../widgets/windows_scaffold.dart';
import 'onboarding_contents.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
