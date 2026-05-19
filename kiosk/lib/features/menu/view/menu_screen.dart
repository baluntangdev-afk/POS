import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/access.dart';
import '../state/access_notifier.dart';
import '../view/menu_grid.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessProvider.select((it) => it.value ?? Access.unknown()));
    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: Column(
        children: [
          _MenuHeader(access: access),
          Expanded(child: MenuGrid(role: access.role)),
        ],
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.access});

  final Access access;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final headerHeight = responsive.value<double>(kiosk: 76, tablet: 64, phone: 56);
    final logoWidth = responsive.value<double>(kiosk: 180, tablet: 140, phone: 110);
    final logoHeight = responsive.value<double>(kiosk: 48, tablet: 36, phone: 28);
    final avatarSize = responsive.value<double>(kiosk: 44, tablet: 36, phone: 30);

    return Container(
      height: headerHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value<double>(kiosk: 32, tablet: 24, phone: 16),
      ),
      child: Row(
        children: [
          // App logo
          Assets.images.png.appBarLogo.image(
            width: logoWidth,
            height: logoHeight,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          // User name + role
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                access.fullName,
                style: TextStyle(
                  fontSize: responsive.value<double>(kiosk: 16, tablet: 14, phone: 12),
                  fontWeight: FontWeight.w600,
                  color: ColorSet.dark,
                ),
              ),
              Text(
                access.role.title,
                style: TextStyle(
                  fontSize: responsive.value<double>(kiosk: 13, tablet: 12, phone: 11),
                  color: ColorSet.dark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          SizedBox(width: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8)),
          // Avatar circle
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: ColorSet.gradientBg),
            ),
            child: Center(
              child: Text(
                _initials(access.fullName),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: responsive.value<double>(kiosk: 16, tablet: 14, phone: 12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: responsive.value<double>(kiosk: 16, tablet: 12, phone: 10)),
          // Logout button
          SizedBox(
            height: responsive.value<double>(kiosk: 56, tablet: 48, phone: 40),
            child: OutlinedButton.icon(
              onPressed: () => const OnboardingRoute().go(context),
              icon: Icon(
                Icons.logout,
                size: responsive.value<double>(kiosk: 18, tablet: 16, phone: 14),
              ),
              label: Text(
                'Logout',
                style: TextStyle(
                  fontSize: responsive.value<double>(kiosk: 15, tablet: 13, phone: 12),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorSet.danger,
                side: const BorderSide(color: ColorSet.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
