import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../cartivo_auth/state/cartivo_auth_state_notifier.dart';

/// Dashboard header for the Cartivo merchant hub — mirrors the in-store
/// `_MenuHeader` (logo, live time/date, account pill, sign out).
class CartivoDashboardHeader extends HookConsumerWidget {
  const CartivoDashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(cartivoAuthStateProvider).value;
    final r = context.responsive;
    final headerHeight = r.value<double>(kiosk: 72, tablet: 64, phone: 58);
    final logoHeight = r.value<double>(kiosk: 40, tablet: 32, phone: 26);
    final avatarSize = r.value<double>(kiosk: 44, tablet: 38, phone: 32);
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);
    final dateStr = DateFormat('EEE, MMM d').format(now);
    final name = auth?.displayName ?? 'Merchant';

    Future<void> signOut() async {
      await ref.read(cartivoAuthStateProvider.notifier).logout();
      if (context.mounted) const CartivoLoginRoute().go(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showDateTime = width >= 860;
        final iconOnly = width < 580;

        return Container(
          height: headerHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
            boxShadow: POSShadow.headerBottom,
          ),
          padding: EdgeInsets.symmetric(horizontal: r.hPagePadding),
          child: Row(
            children: [
              Assets.images.cartivoLogo.image(height: logoHeight, fit: BoxFit.contain),
              if (showDateTime) ...[
                SizedBox(width: r.value<double>(kiosk: 24, tablet: 16, phone: 12)),
                Container(width: 1, height: 28, color: POSColors.borderDefault),
                SizedBox(width: r.value<double>(kiosk: 24, tablet: 16, phone: 12)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                        fontWeight: FontWeight.w700,
                        color: POSColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                        color: POSColors.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              if (iconOnly) ...[
                _Avatar(
                  name: name,
                  size: avatarSize,
                  fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                ),
                SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                IconButton(
                  onPressed: signOut,
                  icon: Icon(Icons.logout_rounded, size: r.value<double>(kiosk: 20, tablet: 18, phone: 16)),
                  color: ColorSet.danger,
                  tooltip: 'Sign Out',
                  style: IconButton.styleFrom(
                    backgroundColor: ColorSet.danger.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
                  ),
                ),
              ] else ...[
                Container(
                  height: r.value<double>(kiosk: 48, tablet: 42, phone: 36),
                  constraints: BoxConstraints(
                    maxWidth: r.value<double>(kiosk: 220, tablet: 200, phone: 180),
                  ),
                  margin: EdgeInsets.symmetric(
                    horizontal: r.value<double>(kiosk: 16, tablet: 12, phone: 10),
                    vertical: r.value<double>(kiosk: 8, tablet: 6, phone: 5),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.value<double>(kiosk: 16, tablet: 12, phone: 10),
                  ),
                  decoration: BoxDecoration(
                    color: POSColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(POSRadius.full),
                    border: Border.all(color: POSColors.borderDefault),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Avatar(name: name, size: avatarSize * 0.8, fontSize: r.value<double>(kiosk: 13, tablet: 11, phone: 10)),
                      SizedBox(width: r.value<double>(kiosk: 10, tablet: 8, phone: 6)),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 14, tablet: 12, phone: 11),
                                fontWeight: FontWeight.w600,
                                color: POSColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Merchant',
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 11, tablet: 10, phone: 9),
                                color: ColorSet.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                SizedBox(
                  height: r.value<double>(kiosk: 48, tablet: 42, phone: 36),
                  child: OutlinedButton.icon(
                    onPressed: signOut,
                    icon: Icon(Icons.logout_rounded, size: r.value<double>(kiosk: 16, tablet: 14, phone: 13)),
                    label: Text('Sign Out', style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 12, phone: 11))),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorSet.danger,
                      side: BorderSide(color: ColorSet.danger.withValues(alpha: 0.5), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
                      padding: EdgeInsets.symmetric(horizontal: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size, required this.fontSize});

  final String name;
  final double size;
  final double fontSize;

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: POSGradient.primary),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
