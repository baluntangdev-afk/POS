import 'package:flutter/material.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/responsive/responsive_value.dart';
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Assets.images.onboardingBg.image(
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      scale: context.responsive.value<double>(phone: 3.0, tablet: 2.5, kiosk: 2.0),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.85),
                          Colors.white.withValues(alpha: 0.75),
                          Colors.white.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  OnboardingContents(isSmallHeight: isSmallHeight),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
