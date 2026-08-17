import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/secure_storage/sources/cartivo_auth_storage.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/resposive_wrap_container.dart';
import 'cartivo_dashboard_header.dart';
import 'cartivo_dashboard_tile_card.dart';

final _cartivoStoredDocProvider = StreamProvider((ref) {
  return ref.watch(cartivoAuthStorageProvider).stored;
});

/// Cartivo merchant hub — landing screen shown right after Cartivo login.
/// Also demonstrates the session-expiry contract: [CartivoTokenInterceptor]
/// clears the stored session on a 401, which this screen observes to route
/// back to login.
class CartivoHomeScreen extends HookConsumerWidget {
  const CartivoHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(_cartivoStoredDocProvider, (previous, next) {
      final wasSignedIn = previous?.value != null;
      final isSignedOut = next.value == null;
      if (wasSignedIn && isSignedOut) {
        const CartivoLoginRoute().go(context);
      }
    });

    return Scaffold(
      backgroundColor: POSColors.surfaceSubtle,
      body: Column(
        children: [
          const CartivoDashboardHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final rowItems = width > 900 ? 3 : width > 600 ? 2 : 1;
                  final padding = width > 900 ? 32.0 : width > 600 ? 24.0 : 16.0;
                  final spacing = width > 900 ? 20.0 : 16.0;

                  return Padding(
                    padding: EdgeInsets.all(padding),
                    child: ResponsiveWrapContainer(
                      equalWidth: true,
                      rowItems: rowItems,
                      spacing: spacing,
                      items: [
                        CartivoDashboardTileCard(
                          label: 'Products',
                          icon: Icons.inventory_2_outlined,
                          accentColor: const Color(0xFFE67E22),
                          onTap: () => const CartivoProductsRoute().push<void>(context),
                        ),
                        CartivoDashboardTileCard(
                          label: 'Orders',
                          icon: Icons.receipt_long_outlined,
                          accentColor: const Color(0xFF4A90D9),
                          onTap: () => const CartivoOrdersRoute().push<void>(context),
                        ),
                        CartivoDashboardTileCard(
                          label: 'Transactions',
                          icon: Icons.payments_outlined,
                          accentColor: ColorSet.success,
                          onTap: () => const CartivoTransactionsRoute().push<void>(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
