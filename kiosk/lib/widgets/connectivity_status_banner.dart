import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/connectivity/connectivity_status_provider.dart';
import '../features/orders/entities/orders_feed_state.dart';
import '../features/orders/state/orders_feed_notifier.dart';
import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';
import '../theme/pos_design.dart';

/// App-wide status banner combining device-level internet reachability with
/// the orders live-feed socket state. Offline takes priority over whatever
/// the socket enum currently reports, since a dropped interface eventually
/// surfaces as `reconnecting`/`disconnected` too but with a less specific
/// message.
class ConnectivityStatusBanner extends ConsumerWidget {
  const ConnectivityStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).value ?? false;
    final connection =
        ref.watch(ordersFeedNotifierProvider.select((s) => s.value?.connection)) ??
        OrdersFeedConnection.connecting;

    final (label, color) = switch ((isOnline, connection)) {
      (false, _) => ('No internet connection', ColorSet.danger),
      (true, OrdersFeedConnection.connected) => (null, null),
      (true, OrdersFeedConnection.connecting) => ('Connecting…', ColorSet.warning),
      (true, OrdersFeedConnection.reconnecting) => ('Reconnecting…', ColorSet.warning),
      (true, OrdersFeedConnection.disconnected) => ('Not connected', POSColors.textTertiary),
    };

    if (label == null || color == null) return const SizedBox.shrink();

    final r = context.responsive;
    // Wrapped in its own Material — unlike every other piece of UI in this
    // app, this banner sits directly in app.dart's MaterialApp.router
    // builder, above/outside any Scaffold, so it has no Material ancestor
    // of its own to paint text against.
    return Material(
      color: Colors.white,
      child: Container(
        width: double.infinity,
        color: color.withValues(alpha: 0.1),
        padding: EdgeInsets.symmetric(
          horizontal: r.value<double>(kiosk: 24, tablet: 16, phone: 12),
          vertical: r.value<double>(kiosk: 10, tablet: 8, phone: 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
