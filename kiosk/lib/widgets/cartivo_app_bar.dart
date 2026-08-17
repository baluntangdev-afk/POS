import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../gen/assets.gen.dart';
import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';
import '../theme/pos_design.dart';

/// Back + centered Cartivo logo app bar, used across the Cartivo merchant
/// sub-screens (Products, Orders, Transactions) to return to the hub.
class CartivoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CartivoAppBar({super.key, this.onBack, this.trailing});

  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final logoHeight = r.value<double>(kiosk: 36, tablet: 32, phone: 26);

    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
        boxShadow: POSShadow.headerBottom,
      ),
      padding: EdgeInsets.symmetric(horizontal: r.hPagePadding),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(child: Assets.images.cartivoLogo.image(height: logoHeight, fit: BoxFit.contain)),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onBack ?? () { if (context.canPop()) context.pop(); },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorSet.primary,
                side: const BorderSide(color: ColorSet.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.full)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (trailing != null) Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    );
  }
}
