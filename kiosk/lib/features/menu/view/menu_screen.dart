import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../widgets/android_bottom_sheet.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/access.dart';
import '../state/access_notifier.dart';
import '../view/menu_grid.dart';
import '../view/user_details_widget.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessProvider.select((it) => it.value ?? Access.unknown()));
    final r = context.responsive;
    final isAndroid = context.breakpoint.isAndroid;

    if (isAndroid) {
      // Dark status-bar icons suit the #F3F1ED background.
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    }

    final scrollBody = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Gradient header ──────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: ColorSet.gradientBg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // On Android the status bar is transparent, so add top inset.
                if (isAndroid) const SafeArea(bottom: false, child: SizedBox.shrink()),
                Gap(r.spacingXl),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.hPagePadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: Assets.images.png.appBarLogo.image(
                          color: Colors.white,
                          width: r.scale(300),
                          height: r.scale(80),
                        ),
                      ),
                      if (isAndroid)
                        // Avatar chip — tapping opens account bottom sheet.
                        _AndroidAvatarChip(
                          access: access,
                          onTap: () => _showAccountSheet(context, access),
                        ),
                    ],
                  ),
                ),
                if (!isAndroid) UserDetailsWidget(access: access),
                Gap(r.spacingMd),
              ],
            ),
          ),
          // ── Menu grid ────────────────────────────────────────────────────
          Container(
            color: ColorSet.background,
            padding: EdgeInsets.all(r.spacingMd),
            child: MenuGrid(role: access.role),
          ),
        ],
      ),
    );

    if (isAndroid) {
      return AndroidScaffold(
        backgroundColor: ColorSet.background,
        bottomNavigationBar: _AndroidBottomNav(access: access),
        body: scrollBody,
      );
    }

    return WindowsScaffold(body: scrollBody);
  }

  void _showAccountSheet(BuildContext context, Access access) {
    showAndroidBottomSheet<void>(
      context: context,
      maxHeightRatio: 0.45,
      builder: (ctx) => _AccountBottomSheet(access: access),
    );
  }
}

// ─── Android avatar chip in header ────────────────────────────────────────────

class _AndroidAvatarChip extends StatelessWidget {
  const _AndroidAvatarChip({required this.access, required this.onTap});

  final Access access;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: ColorSet.userDetails,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                access.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Account bottom sheet ─────────────────────────────────────────────────────

class _AccountBottomSheet extends StatelessWidget {
  const _AccountBottomSheet({required this.access});

  final Access access;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: ColorSet.userDetails,
            child: Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            access.fullName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            access.role.title,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            access.employeeId,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorSet.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout', style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.of(context).pop();
                const OnboardingRoute().go(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Android Material bottom navigation bar ───────────────────────────────────

class _AndroidBottomNav extends StatelessWidget {
  const _AndroidBottomNav({required this.access});

  final Access access;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: ColorSet.primary.withValues(alpha: 0.12),
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            break; // already on home
          case 1:
            const SalesRoute().push<void>(context);
          case 2:
            const TransactionsRoute().push<void>(context);
          case 3:
            const SalesReportRoute().push<void>(context);
          case 4:
            // Account sheet is accessible from header avatar chip too.
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'Sales'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
      ],
    );
  }
}
