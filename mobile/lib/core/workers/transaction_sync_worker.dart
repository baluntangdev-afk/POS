import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../config/environment/app_env.dart';
import '../../config/environment/env.dart';
import '../../data/backend_api/sources/transaction_sync_api.dart';
import '../../features/live_orders/repositories/webhook_auth_repository.dart';
import '../database/app_database.dart';
import '../services/transaction_sync/transaction_sync_service.dart';

const String kTransactionSyncTaskName = 'periodic_transaction_sync';

/// Runs one sync attempt against [db]. A throwaway [ProviderContainer] gives
/// access to the real `transactionSyncApiProvider`/`webhookAuthRepositoryProvider`
/// wiring (Dio client, auth interceptor, token storage) without hand-duplicating
/// it — only `appEnvProvider` needs overriding here, `databaseProvider` isn't on
/// that provider chain since [db] is passed straight into the service call.
Future<void> runTransactionSyncTick(AppDatabase db) async {
  final storeInfo = await db.storeInfoDao.getStoreInfo();
  final storeId = storeInfo?.storeId ?? '';
  if (storeId.isEmpty) return;

  await Future.delayed(Duration(seconds: Random().nextInt(kTransactionSyncJitterMax.inSeconds)));

  final container = ProviderContainer(
    overrides: [appEnvProvider.overrideWithValue(Env())],
  );
  try {
    await TransactionSyncService.syncPending(
      db,
      container.read(transactionSyncApiProvider),
      container.read(webhookAuthRepositoryProvider),
      storeId,
    );
  } finally {
    container.dispose();
  }
}

/// Safe to call on every app startup — `ExistingPeriodicWorkPolicy.keep`
/// leaves an already-registered job alone. Does NOT call
/// `Workmanager().initialize()` — that happens once, in `schedulePeriodicBackup()`,
/// against the single shared `backupCallbackDispatcher`.
Future<void> schedulePeriodicTransactionSync() async {
  await Workmanager().registerPeriodicTask(
    kTransactionSyncTaskName,
    kTransactionSyncTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
