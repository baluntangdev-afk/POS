import 'package:flutter/material.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
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
              return Column(
                children: [
                  _BrandPanel(height: 130, isLandscape: false),
                  Expanded(
                    child: Container(
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
            return Column(
              children: [
                _BrandPanel(height: 110, isLandscape: false),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: LoginView(isSmallHeight: isSmallHeight),
                  ),
                ),
              ],
            );
          }

          final panelWidth = context.responsive.value<double>(kiosk: 420, tablet: 340, phone: 260);
          return Row(
            children: [
              _BrandPanel(width: panelWidth, isLandscape: true),
              Expanded(
                child: Container(
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

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({
    this.height,
    this.width,
    required this.isLandscape,
  });

  final double? height;
  final double? width;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final logoHeight = r.value<double>(kiosk: 52, tablet: 44, phone: 38);

    Widget content;
    if (isLandscape) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Assets.images.png.onboardingLogo.image(
                height: 48,
                fit: BoxFit.contain,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'POS Kiosk',
            style: TextStyle(
              color: Colors.white,
              fontSize: r.value<double>(kiosk: 28, tablet: 22, phone: 18),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Point of Sale System',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: r.value<double>(kiosk: 14, tablet: 12, phone: 11),
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 60),
          _StatusBadge(),
        ],
      );
    } else {
      content = SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Assets.images.png.onboardingLogo.image(
              height: logoHeight,
              fit: BoxFit.contain,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              'POS Kiosk',
              style: TextStyle(
                color: Colors.white,
                fontSize: r.value<double>(kiosk: 22, tablet: 18, phone: 16),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: height,
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B7A8C), Color(0xFF156070)],
        ),
      ),
      padding: EdgeInsets.all(isLandscape ? 32.0 : 24.0),
      child: content,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(POSRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ColorSet.success,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: ColorSet.success.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'System Online',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
