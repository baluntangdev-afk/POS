import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../theme/pos_design.dart';
import '../entities/customer_display_catalog.dart';
import '../entities/customer_display_snapshot.dart';
import 'customer_display_header.dart';
import 'menu_showcase.dart';

class IdleCustomerView extends StatelessWidget {
  const IdleCustomerView({super.key, required this.snapshot, required this.catalog});

  final CustomerDisplayIdle snapshot;
  final CustomerDisplayCatalog? catalog;

  @override
  Widget build(BuildContext context) {
    // The catalog poll (every ~15s) is the source that actually reflects a
    // live store rename; the cart snapshot's store name is only a fallback
    // for the moment before the first catalog push arrives.
    final storeName = catalog?.storeName ?? snapshot.storeName;
    final storeLogoUrl = catalog?.storeLogoUrl ?? snapshot.storeLogo;

    return ColoredBox(
      color: ColorSet.background,
      child: Column(
        children: [
          CustomerDisplayHeader(storeName: storeName, storeLogoUrl: storeLogoUrl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: POSSpacing.lg, vertical: POSSpacing.sm),
            color: ColorSet.welcomeText,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'Welcome!',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Take a look at what’s on the menu while we get you set up',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: MenuShowcase(categories: catalog?.categories ?? const [], compact: false),
          ),
        ],
      ),
    );
  }
}
