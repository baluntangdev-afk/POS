import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'config/feature_flags.dart';
import 'core/connectivity/connectivity_status_provider.dart';
import 'core/transaction_sync/sales_sync_signal.dart';
import 'features/auth/state/login_state_notifier.dart';
import 'features/orders/entities/order_event.dart';
import 'features/orders/entities/orders_feed_state.dart';
import 'features/orders/state/device_token_status_provider.dart';
import 'features/orders/state/merchant_device_notifier.dart';
import 'features/orders/state/orders_feed_notifier.dart';
import 'features/orders/state/webhook_auth_status_provider.dart';
import 'features/transaction_sync/state/transaction_sync_progress_notifier.dart';
import 'features/transaction_sync/state/transaction_sync_ticker_provider.dart';
import 'navigation/router.dart';
import 'styles/color_set.dart';
import 'styles/fallback_theme.dart';
import 'widgets/connectivity_status_banner.dart';
import 'widgets/global_unfocus_on_tap_outside.dart';
import 'widgets/onscreen_keyboard/onscreen_keyboard_scope.dart';

/// Lets non-widget code (and app.dart itself) show a SnackBar without being
/// tied to whichever screen's Scaffold is currently on screen.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class App extends ConsumerWidget {
  const App({super.key, required this.container});

  final ProviderContainer container;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Boots the session-scoped orders live feed (kept alive via ref.keepAlive
    // in the notifier); it connects/disconnects itself as loginStateProvider
    // changes, independent of which screen is on screen.
    ref.watch(ordersFeedNotifierProvider);
    ref.listen(ordersFeedNotifierProvider, _onOrdersFeedStateChange);
    ref.listen(ordersFeedNotifierProvider, _onNewOrderCreated);
    ref.listen(loginStateProvider, (previous, next) {
      final wasLoggedIn = previous?.value != null;
      if (wasLoggedIn || next.value == null) return;
      if (!kSkipDeviceRegistration) {
        unawaited(ref.read(merchantDeviceNotifierProvider.notifier).refreshStatus());
      }
      unawaited(ref.read(transactionSyncProgressProvider.notifier).drainPending());
    });
    ref.listen(webhookAuthStatusProvider, (previous, next) {
      if (next != null && next != previous) _showAuthToast(next.message);
    });
    ref.listen(deviceTokenStatusProvider, (previous, next) {
      if (next != null && next != previous) _showAuthToast(next.message);
    });
    // Back online → push anything that piled up, jittered so a fleet of
    // kiosks regaining the network together doesn't stampede the service.
    ref.listen(isOnlineProvider, (previous, next) {
      final wasOnline = previous?.value;
      final isOnline = next.value ?? false;
      // Only a real offline → online edge (not the first emission) triggers.
      if ((wasOnline ?? true) || !isOnline) return;
      unawaited(_drainPendingSyncJittered(ref));
    });
    ref.listen(salesSyncTriggerProvider, (previous, next) {
      if (next.hasValue) unawaited(ref.read(transactionSyncProgressProvider.notifier).drainPending());
    });
    ref.listen(transactionSyncTickerProvider, (previous, next) {
      if (next.hasValue) unawaited(ref.read(transactionSyncProgressProvider.notifier).drainPending());
    });
    ref.listen(transactionSyncProgressProvider, (previous, next) {
      if (next != null && previous == null) {
        _showSyncProgressToast();
      } else if (next == null && previous != null) {
        scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      }
    });
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
      theme: fallbackTheme,
      builder: (context, child) {
        final content = OnScreenKeyboardScope(
          child: Column(
            children: [
              const ConnectivityStatusBanner(),
              Expanded(
                child: GlobalUnfocusOnTapOutside(child: child ?? const SizedBox.shrink()),
              ),
            ],
          ),
        );
        if (!kIsWeb && Platform.isWindows) {
          return _WindowCloseGuard(container: container, child: content);
        }
        return content;
      },
    );
  }
}

class _WindowCloseGuard extends StatefulWidget {
  const _WindowCloseGuard({required this.child, required this.container});
  final Widget child;
  final ProviderContainer container;

  @override
  State<_WindowCloseGuard> createState() => _WindowCloseGuardState();
}

class _WindowCloseGuardState extends State<_WindowCloseGuard> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    try {
      final confirmed = await _showExitDialog();
      if (confirmed ?? false) {
        widget.container.dispose();
        await windowManager.destroy();
        exit(0);
      }
    } catch (_) {
      widget.container.dispose();
      await windowManager.destroy();
      exit(0);
    }
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Exit Application',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to close POS Kiosk?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ColorSet.danger),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> _drainPendingSyncJittered(WidgetRef ref) async {
  await Future<void>.delayed(Duration(seconds: Random().nextInt(_syncJitterMaxSeconds)));
  await ref.read(transactionSyncProgressProvider.notifier).drainPending();
}

const _syncJitterMaxSeconds = 15;

void _showAuthToast(String message) {
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorSet.danger,
        duration: const Duration(seconds: 5),
      ),
    );
}

/// Live batch progress for any transaction-sync run, shown app-wide for as
/// long as the run lasts (hidden by the listener in [App.build] when it ends).
void _showSyncProgressToast() {
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        backgroundColor: ColorSet.primary,
        content: Consumer(
          builder: (context, ref, _) {
            final progress = ref.watch(transactionSyncProgressProvider);
            final label = progress == null
                ? 'Syncing transactions…'
                : 'Syncing transactions… batch ${progress.currentBatch} of ${progress.totalBatches}';
            return Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
              ],
            );
          },
        ),
      ),
    );
}

/// Toasts once per new `order.created` event. The feed prepends new events,
/// so anything ahead of the previous head (by event id) is new.
void _onNewOrderCreated(AsyncValue<OrdersFeedState>? previous, AsyncValue<OrdersFeedState> next) {
  final previousEvents = previous?.value?.events;
  final nextEvents = next.value?.events;
  if (nextEvents == null || nextEvents.isEmpty) return;

  final previousHeadId = previousEvents?.isEmpty ?? true ? null : previousEvents!.first.eventId;
  final newEvents = <OrderEvent>[];
  for (final event in nextEvents) {
    if (event.eventId == previousHeadId) break;
    newEvents.add(event);
  }

  for (final event in newEvents.reversed) {
    if (event.type != OrderEventType.created) continue;
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('New order #${event.data.id} · ${event.data.items.length} item(s)'),
        backgroundColor: ColorSet.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

void _onOrdersFeedStateChange(AsyncValue<OrdersFeedState>? previous, AsyncValue<OrdersFeedState> next) {
  final wasConnected = previous?.value?.connection == OrdersFeedConnection.connected;
  final isConnected = next.value?.connection == OrdersFeedConnection.connected;
  if (wasConnected || !isConnected) return;

  final kioskId = next.value?.kioskId;
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          kioskId == null ? 'Connected to live orders' : 'Connected to live orders (kiosk: $kioskId)',
        ),
        backgroundColor: ColorSet.success,
        duration: const Duration(seconds: 3),
      ),
    );
}
