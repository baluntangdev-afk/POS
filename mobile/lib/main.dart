import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';

import 'config/environment/app_env.dart';
import 'config/environment/env.dart';
import 'core/database/app_database.dart';
import 'core/navigation/router.dart';
import 'core/providers/database_provider.dart';
import 'core/seeder/admin_seeder.dart';
import 'core/services/backup/backup_service.dart';
import 'core/services/backup/backup_storage_service.dart';
import 'core/services/notifications/order_notifications_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/workers/backup_worker.dart';
import 'features/live_orders/entities/order_event.dart';
import 'features/live_orders/entities/orders_feed_state.dart';
import 'features/live_orders/state/orders_feed_notifier.dart';

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

void _showOrderToast(OrderEvent event) {
  final data = event.data;
  final (message, color) = switch (event.type) {
    OrderEventType.created => (
        'New order #${data.id} · ${data.items.length} item${data.items.length == 1 ? '' : 's'}',
        AppColors.success,
      ),
    OrderEventType.updated => ('Order #${data.id} updated · ${data.status}', AppColors.primary),
    OrderEventType.cancelled => ('Order #${data.id} cancelled', AppColors.error),
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
