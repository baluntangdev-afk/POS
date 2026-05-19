import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';

class OnboardingContents extends StatefulWidget {
  const OnboardingContents({super.key, required this.isSmallHeight});

  final bool isSmallHeight;

  @override
  State<OnboardingContents> createState() => _OnboardingContentsState();
}

class _OnboardingContentsState extends State<OnboardingContents>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveValue.of(context);
    final isKiosk = responsive.value<bool>(kiosk: true, tablet: false, phone: false);
    final isTablet = responsive.value<bool>(kiosk: false, tablet: true, phone: false);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: ColorSet.gradientBg,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Padding(
                padding: responsive.value<EdgeInsets>(
                  phone: const EdgeInsets.symmetric(horizontal: 30.0),
                  tablet: const EdgeInsets.symmetric(horizontal: 60.0),
                  kiosk: const EdgeInsets.symmetric(horizontal: 100.0),
                ),
                child: Assets.images.png.onboardingLogo.image(
                  color: Colors.white,
                  width: responsive.value<double>(phone: 260, tablet: 400, kiosk: 600),
                  height: responsive.value<double>(phone: 80, tablet: 120, kiosk: 160),
                  fit: BoxFit.contain,
                ),
              ),
              Gap(
                responsive.value<double>(
                  phone: widget.isSmallHeight ? 20 : 30,
                  tablet: widget.isSmallHeight ? 30 : 50,
                  kiosk: widget.isSmallHeight ? 40 : 60,
                ),
              ),
              // Headline
              Text(
                'Welcome to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: responsive.value<double>(phone: 24, tablet: 40, kiosk: 60),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              Gap(
                responsive.value<double>(
                  phone: widget.isSmallHeight ? 40 : 60,
                  tablet: widget.isSmallHeight ? 60 : 80,
                  kiosk: widget.isSmallHeight ? 80 : 120,
                ),
              ),
              // Pulsing "Touch To Start" button
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: isKiosk ? 480 : 0.0,
                  ),
                  margin: isTablet
                      ? const EdgeInsets.symmetric(horizontal: 48)
                      : EdgeInsets.zero,
                  child: isTablet
                      ? SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: _TouchToStartContent(
                            fontSize: 22,
                            isTablet: true,
                          ),
                        )
                      : SizedBox(
                          width: isKiosk ? 480 : 300,
                          height: isKiosk ? 80 : 56,
                          child: _TouchToStartContent(
                            fontSize: isKiosk ? 28 : 18,
                            isTablet: false,
                          ),
                        ),
                ),
              ),
            ],
          ),
          // Bottom info strip
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.value<double>(phone: 16, tablet: 24, kiosk: 32),
                vertical: responsive.value<double>(phone: 10, tablet: 12, kiosk: 16),
              ),
              color: Colors.black.withValues(alpha: 0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'POS Kiosk System',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: responsive.value<double>(phone: 11, tablet: 13, kiosk: 15),
                    ),
                  ),
                  Text(
                    _getDateString(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: responsive.value<double>(phone: 11, tablet: 13, kiosk: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDateString() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

class _TouchToStartContent extends StatelessWidget {
  const _TouchToStartContent({required this.fontSize, required this.isTablet});

  final double fontSize;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Touch To Start',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColorSet.primary,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
