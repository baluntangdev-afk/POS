import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';

/// Full-bleed onboarding / attract screen.
///
/// Renders a gradient background, brand logo, hero headline, an animated
/// "Tap to Begin" CTA, and a bottom info strip with store name + live clock.
///
/// Three form-factor variants (per spec Section 4 §1):
///   [K] 480 px-wide pill CTA, 80 px height, 56 px+ hero text.
///   [W] Full-width CTA (max 400 px), 72 px height, 48 px hero text.
///   [A] Same as W with SafeArea for status bar, transparent light-icon status
///       bar, bottom strip above navigation inset.
///
/// [isSmallHeight] is forwarded from the parent so the layout can collapse
/// vertical spacing when the window is short.
///
/// [onTap] is called when the user presses "Tap to Begin". Wire it to
/// `const LoginRoute().go(context)` in the parent screen.
///
/// [storeName] appears in the bottom info strip.
class OnboardingContents extends HookWidget {
  const OnboardingContents({
    super.key,
    required this.isSmallHeight,
    this.onTap,
    this.storeName = 'POS System',
  });

  final bool isSmallHeight;
  final VoidCallback? onTap;
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final bp = context.breakpoint;

    // ─── Breathing animation on the CTA button ───────────────────────────────
    final animCtrl = useAnimationController(
      duration: const Duration(milliseconds: 1600),
    );
    final breathScale = useAnimation(
      Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: animCtrl, curve: Curves.easeInOut),
      ),
    );
    useEffect(() {
      animCtrl.repeat(reverse: true);
      return animCtrl.stop;
    }, const []);

    // ─── Android: transparent status bar with light icons ────────────────────
    useEffect(() {
      if (bp.isAndroid) {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        );
      }
      return null;
    }, const []);

    // ─── Sizing ──────────────────────────────────────────────────────────────
    final heroSize = r.value<double>(kiosk: 56, tablet: 48, phone: 36);
    final logoW = r.value<double>(kiosk: 600, tablet: 400, phone: 280);
    final logoH = r.value<double>(kiosk: 160, tablet: 110, phone: 76);
    final ctaH = r.value<double>(kiosk: 80, tablet: 72, phone: 64);
    final stripFontSize = r.value<double>(kiosk: 20, tablet: 18, phone: 16);
    final bottomInset =
        bp.isAndroid ? MediaQuery.of(context).viewPadding.bottom : 0.0;

    // ─── CTA button with breathing scale ─────────────────────────────────────
    Widget buildCta() {
      Widget pill = GestureDetector(
        onTap: onTap,
        child: Container(
          height: ctaH,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ctaH / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Tap to Begin',
              style: TextStyle(
                color: ColorSet.primary,
                fontSize: r.fontLabel,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );

      pill = Transform.scale(scale: breathScale, child: pill);

      if (bp.isKiosk) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 480),
          child: pill,
        );
      }

      // Tablet / Android: full-width within 24 dp horizontal padding.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: pill,
      );
    }

    // ─── Bottom strip: store name + live clock ───────────────────────────────
    Widget buildBottomStrip() {
      final textStyle = TextStyle(
        color: Colors.white.withValues(alpha: 0.75),
        fontSize: stripFontSize,
        fontWeight: FontWeight.w500,
      );
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(storeName, style: textStyle),
            StreamBuilder<int>(
              stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
              builder: (context, _) => Text(
                DateFormat('MMM d, yyyy  h:mm a').format(DateTime.now()),
                style: textStyle,
              ),
            ),
          ],
        ),
      );
    }

    // ─── Root layout ─────────────────────────────────────────────────────────
    // The gradient fills the full screen (extends behind Android status bar).
    // SafeArea(bottom: false) shifts the main column below the status bar while
    // the bottom strip handles its own inset manually.
    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: ColorSet.gradientBg,
          ),
        ),
        child: Stack(
          children: [
            // Main content — centred, safe-area aware at the top.
            Positioned.fill(
              bottom: 60 + bottomInset,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Assets.images.png.onboardingLogo.image(
                      color: Colors.white,
                      width: logoW,
                      height: logoH,
                      fit: BoxFit.contain,
                    ),
                    Gap(isSmallHeight ? 24 : r.spacingXl),
                    // Hero headline
                    Text(
                      'Welcome',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: heroSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Gap(isSmallHeight ? 20 : r.spacingLg),
                    // Breathing CTA
                    buildCta(),
                  ],
                ),
              ),
            ),
            // Bottom info strip — pinned to the bottom edge.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: buildBottomStrip(),
            ),
          ],
        ),
      ),
    );
  }
}
