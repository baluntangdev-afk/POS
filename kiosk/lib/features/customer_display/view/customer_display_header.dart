import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../theme/pos_design.dart';

/// Persistent brand strip shown at the top of every customer-display state.
/// [storeName]/[storeLogoUrl] are expected to come from the periodically
/// refreshed catalog so a store rename shows up here without needing an
/// active order.
class CustomerDisplayHeader extends StatelessWidget {
  const CustomerDisplayHeader({super.key, required this.storeName, this.storeLogoUrl});

  final String storeName;
  final String? storeLogoUrl;

  @override
  Widget build(BuildContext context) {
    final displayName = storeName.isEmpty ? 'POS Kiosk' : storeName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: POSSpacing.lg, vertical: POSSpacing.md),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E1D9))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(gradient: POSGradient.primary, borderRadius: BorderRadius.circular(POSRadius.sm)),
            clipBehavior: Clip.antiAlias,
            child: storeLogoUrl != null
                ? CachedNetworkImage(
                    imageUrl: storeLogoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _Initial(displayName: displayName),
                  )
                : _Initial(displayName: displayName),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ColorSet.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        displayName[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
      ),
    );
  }
}
