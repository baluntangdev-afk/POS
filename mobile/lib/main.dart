import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';

import 'config/environment/app_env.dart';
import 'config/environment/env.dart';
import 'core/connectivity/connectivity_status_provider.dart';
import 'core/database/app_database.dart';
import 'core/navigation/router.dart';
import 'core/providers/database_provider.dart';
import 'core/seeder/admin_seeder.dart';
import 'core/services/backup/backup_service.dart';
import 'core/services/backup/backup_storage_service.dart';
import 'core/services/notifications/order_notifications_service.dart';
import 'core/services/transaction_sync/transaction_sync_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/workers/backup_worker.dart';
import 'core/workers/transaction_sync_worker.dart';
import 'data/backend_api/sources/transaction_sync_api.dart';
import 'features/auth/state/auth_providers.dart';
import 'features/auth/state/auth_state.dart';
import 'features/live_orders/entities/order_event.dart';
import 'features/live_orders/entities/orders_feed_state.dart';
import 'features/live_orders/repositories/webhook_auth_repository.dart';
import 'features/live_orders/state/device_token_status_provider.dart';
import 'features/live_orders/state/merchant_device_notifier.dart';
import 'features/live_orders/state/orders_feed_notifier.dart';
import 'features/live_orders/state/webhook_auth_status_provider.dart';
import 'features/settings/state/store_info_notifier.dart';

/// Lets non-widget code show a SnackBar without being tied to whichever
/// screen's Scaffold is currently on screen — needed since live-order
/// toasts must surface no matter which screen the cashier is on.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MediaStore.ensureInitialized();
  MediaStore.appFolder = 'POS Backups';

  final db = AppDatabase();
  await AdminSeeder(db).seed();

  await schedulePeriodicBackup();
  await schedulePeriodicTransactionSync();
  unawaited(_runStartupBackupSafetyNet(db));

  final orderNotifications = OrderNotificationsService();
  await orderNotifications.initialize();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        appEnvProvider.overrideWithValue(Env()),
        orderNotificationsServiceProvider.overrideWithValue(orderNotifications),
      ],
      child: const _App(),
    ),
  );
}

/// If it's been more than 3 hours since the last backup (or there's never
/// been one), run one now in the foreground. Covers periods the WorkManager
/// job never fired — e.g. the device was off or asleep, or Android's Doze
/// mode delayed it.
Future<void> _runStartupBackupSafetyNet(AppDatabase db) async {
  try {
    final lastBackup = await BackupStorageService.lastBackupAt();
    final isStale = lastBackup == null ||
        DateTime.now().difference(lastBackup) > const Duration(hours: 3);
    if (isStale) {
      await BackupService.createBackupIfChanged(db);
    }
  } catch (_) {
    // Best-effort — never block app startup on backup failure.
  }
}

/// Fires one immediate sync attempt on a false→true connectivity edge — i.e.
/// only after connectivity was previously confirmed offline, never on an
/// unresolved/cold-start transition — so a store doesn't wait out the
/// WorkManager 15-minute floor after reconnecting.
/// The random delay spreads out the case where many stores' devices regain
/// connectivity in the same instant (e.g. after a shared outage), instead of
/// every device's retry landing on the sync endpoint in the same second.
/// Silent on failure by design — see the sync design doc's error handling.
Future<void> _syncTransactionsNow(WidgetRef ref) async {
  await Future.delayed(Duration(seconds: Random().nextInt(kTransactionSyncJitterMax.inSeconds)));
  try {
    final storeId = (await ref.read(storeInfoProvider.future))?.storeId ?? '';
    if (storeId.isEmpty) return;
    await TransactionSyncService.syncPending(
      ref.read(databaseProvider),
      ref.read(transactionSyncApiProvider),
      ref.read(webhookAuthRepositoryProvider),
      storeId,
    );
  } catch (_) {
    // Retried on the next scheduled tick or the next reconnect edge.
  }
}

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Root-level, not Dashboard-level: a toast/notification for an order
    // that arrives while the cashier is mid-checkout on another screen must
    // still surface. (The socket connection itself is still booted and
    // checked from DashboardScreen — this only observes the same provider.)
    ref.listen(ordersFeedNotifierProvider, (previous, next) {
      _onOrderEvents(previous, next, ref);
    });
    // Re-checks device registration once per login (not on every dashboard
    // visit — DashboardScreen remounts on each `context.go`, and this
    // listener lives on the root App widget, so it only fires on a genuine
    // logged-out → logged-in transition).
    ref.listen(authNotifierProvider, (previous, next) {
      final wasAuthenticated = previous is AuthAuthenticated;
      if (!wasAuthenticated && next is AuthAuthenticated) {
        unawaited(
          ref.read(merchantDeviceNotifierProvider.notifier).refreshStatus(),
        );
      }
    });
    // Orders-service auth failures (a rejected `/auth/token`, e.g. a wrong
    // webhook secret) surface as a toast wherever the user is.
    ref.listen(webhookAuthStatusProvider, (previous, next) {
      if (next != null && next != previous) _showAuthToast(next.message);
    });
    // Same, for a rejected `/devices/token` (the live-orders WS bearer).
    ref.listen(deviceTokenStatusProvider, (previous, next) {
      if (next != null && next != previous) _showAuthToast(next.message);
    });
    // Fires one immediate sync attempt on reconnect instead of waiting out
    // the WorkManager 15-minute floor.
    ref.listen(isOnlineProvider, (previous, next) {
      final wasOnline = previous?.value;
      final isOnline = next.value ?? false;
      if (wasOnline != false || !isOnline) return;
      unawaited(_syncTransactionsNow(ref));
    });
    return MaterialApp.router(
      title: 'POS Mobile',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}

/// Toasts + local-notifies once per newly received event — every type
/// (`created`/`updated`/`cancelled`), not just new orders. The feed prepends
/// new events, so anything ahead of the previous head (by event id) is new.
void _onOrderEvents(
  AsyncValue<OrdersFeedState>? previous,
  AsyncValue<OrdersFeedState> next,
  WidgetRef ref,
) {
  final previousEvents = previous?.value?.events;
  final nextEvents = next.value?.events;
  if (nextEvents == null || nextEvents.isEmpty) return;

  final previousHeadId = (previousEvents?.isEmpty ?? true) ? null : previousEvents!.first.eventId;
  final newEvents = <OrderEvent>[];
  for (final event in nextEvents) {
    if (event.eventId == previousHeadId) break;
    newEvents.add(event);
  }

  for (final event in newEvents.reversed) {
    _showOrderToast(event);
    unawaited(ref.read(orderNotificationsServiceProvider).notify(event));
  }
}

void _showAuthToast(String message) {
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ),
    );
}

void _showOrderToast(OrderEvent event) {
  final data = event.data;
  final (message, color) = switch (event.type) {
    OrderEventType.created => (
        'New order #${data.id} · ${data.items.length} item${data.items.length == 1 ? '' : 's'}',
        AppColors.success,
      ),
    OrderEventType.updated => ('Order #${data.id} updated · ${data.status}', AppColors.primary),
    OrderEventType.cancelled => ('Order #${data.id} cancelled', AppColors.error),
    OrderEventType.deleted => ('Order #${data.id} removed', AppColors.error),
  };

  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
}
