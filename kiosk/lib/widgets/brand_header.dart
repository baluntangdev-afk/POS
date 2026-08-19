import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../gen/assets.gen.dart';
import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';
import '../theme/pos_design.dart';

/// App bar with an outlined Back button and the centered Cartivo logo,
/// matching the header used on the New Order screen.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.onBackPressed});

  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final backButtonHeight = r.value<double>(kiosk: 52, tablet: 44, phone: 38);

    return Container(
      height: r.value<double>(kiosk: 68, tablet: 60, phone: 52),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
        boxShadow: POSShadow.headerBottom,
      ),
      padding: EdgeInsets.symmetric(horizontal: r.value<double>(kiosk: 24, tablet: 16, phone: 12)),
      child: Row(
        children: [
          SizedBox(
            height: backButtonHeight,
            child: OutlinedButton.icon(
              onPressed: onBackPressed ?? () { if (context.canPop()) context.pop(); },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorSet.primary,
                side: const BorderSide(color: ColorSet.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Spacer(),
          Assets.images.cartivoLogo.image(height: r.value<double>(kiosk: 36, tablet: 28, phone: 22)),
          const Spacer(),
          SizedBox(width: r.value<double>(kiosk: 110, tablet: 90, phone: 76)),
        ],
      ),
    );
  }
}
