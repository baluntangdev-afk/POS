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
import 'core/services/clock/app_clock.dart';
import 'core/services/backup/backup_service.dart';
import 'core/services/backup/backup_storage_service.dart';
import 'core/services/notifications/order_notifications_service.dart';
import 'core/services/transaction_sync/transaction_sync_progress_provider.dart';
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
import 'features/settings/state/merchant_verification_provider.dart';
import 'features/settings/state/store_info_notifier.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MediaStore.ensureInitialized();
  MediaStore.appFolder = 'POS Backups';

  final db = AppDatabase();
  await AdminSeeder(db).seed();
  final appClock = await AppClock.load();

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
        appClockProvider.overrideWithValue(appClock),
      ],
      child: const _App(),
    ),
  );
}

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

/// Drains every pending batch (not just one) right after login, via the same
/// shared notifier the Transactions screen's "Sync All" button uses — so the
/// Dashboard's progress pill reflects it as soon as the user lands there.
/// Skipped for an unverified merchant (same check gating device-approval on
/// the Store Information screen) rather than letting it fail quietly inside
/// [TransactionSyncService.syncPending]'s own `ensureToken` call.
Future<void> _syncAllOnLogin(WidgetRef ref) async {
  try {
    final storeId = (await ref.read(storeInfoProvider.future))?.storeId ?? '';
    if (storeId.isEmpty) return;
    final isVerified = await ref.read(merchantVerificationProvider.future);
    if (!isVerified) return;
    await ref.read(transactionSyncProgressProvider.notifier).syncAll(
          db: ref.read(databaseProvider),
          api: ref.read(transactionSyncApiProvider),
          auth: ref.read(webhookAuthRepositoryProvider),
          storeId: storeId,
        );
  } catch (_) {
    // Quiet — same as the reconnect trigger; retried on the next scheduled
    // tick, reconnect edge, or manual Sync All.
  }
}

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.listen(ordersFeedNotifierProvider, (previous, next) {
      _onOrderEvents(previous, next, ref);
    });
    ref.listen(authNotifierProvider, (previous, next) {
      final wasAuthenticated = previous is AuthAuthenticated;
      if (!wasAuthenticated && next is AuthAuthenticated) {
        unawaited(
          ref.read(merchantDeviceNotifierProvider.notifier).refreshStatus(),
        );
        unawaited(_syncAllOnLogin(ref));
      }
    });

    ref.listen(webhookAuthStatusProvider, (previous, next) {
      if (next != null && next != previous) _showAuthToast(next.message);
    });
    ref.listen(deviceTokenStatusProvider, (previous, next) {
      if (next != null && next != previous) _showAuthToast(next.message);
    });
    ref.listen(isOnlineProvider, (previous, next) {
      final wasOnline = previous?.value;
      final isOnline = next.value ?? false;
      if (wasOnline != false || !isOnline) return;
      unawaited(_syncTransactionsNow(ref));
    });
    ref.listen(transactionSyncProgressProvider, (previous, next) {
      if (next != null && previous == null) {
        _showSyncProgressToast();
      } else if (next == null && previous != null) {
        scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      }
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

/// Replaces the passive Dashboard header pill: any [transactionSyncProgressProvider]
/// run — login-triggered or the Transactions screen's manual "Sync All" —
/// surfaces its batch progress here instead, app-wide.
///
/// Shown once per run (see the `previous == null` gate in `_App.build`) and
/// its content watches the provider directly, so later batch updates rebuild
/// the text in place instead of tearing down and re-showing the SnackBar —
/// which previously caused it to flicker on every batch.
void _showSyncProgressToast() {
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Consumer(
          builder: (context, ref, _) {
            final progress = ref.watch(transactionSyncProgressProvider);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Syncing transactions ${progress?.currentBatch ?? 0}/${progress?.totalBatches ?? 0}',
                ),
              ],
            );
          },
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(minutes: 5),
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
