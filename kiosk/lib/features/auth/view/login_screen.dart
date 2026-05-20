import 'package:flutter/material.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';
import 'login_view.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAndroid = context.breakpoint.isAndroid;

    if (isAndroid) {
      return AndroidScaffold(
        statusBarIconBrightness: Brightness.light,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallHeight = constraints.maxHeight <= 500;
              final bottomPad = MediaQuery.of(context).viewPadding.bottom;
              // Android always uses the portrait (top-banner + card) layout.
              return Column(
                children: [
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: ColorSet.gradientBg,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: Assets.images.png.onboardingLogo.image(
                          color: Colors.white,
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomPad),
                        child: LoginView(isSmallHeight: isSmallHeight),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return WindowsScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallHeight = constraints.maxHeight <= 500;
          final isPortrait = constraints.maxHeight > constraints.maxWidth;

          if (isPortrait) {
            // Windows tablet portrait: top gradient banner + white card below
            return Column(
              children: [
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: ColorSet.gradientBg,
                    ),
                  ),
                  child: Center(
                    child: Assets.images.png.onboardingLogo.image(
                      color: Colors.white,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: Colors.white,
                    child: LoginView(isSmallHeight: isSmallHeight),
                  ),
                ),
              ],
            );
          }

          // Kiosk / Windows tablet landscape: left gradient panel + right white card
          final panelWidth = context.responsive.value<double>(kiosk: 400, tablet: 320, phone: 240);
          return Row(
            children: [
              Container(
                width: panelWidth,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: ColorSet.gradientBg,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Assets.images.png.onboardingLogo.image(
                      color: Colors.white,
                      width: panelWidth * 0.75,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Point of Sale',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: context.responsive.value<double>(
                          kiosk: 20,
                          tablet: 16,
                          phone: 14,
                        ),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: Colors.white,
                  child: LoginView(isSmallHeight: isSmallHeight),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
