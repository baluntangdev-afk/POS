import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../config/environment/app_env.dart';
import '../../config/environment/env.dart';
import '../../config/environment/orders_server_url.dart';
import '../../data/backend_api/sources/transaction_sync_api.dart';
import '../../features/live_orders/repositories/webhook_auth_repository.dart';
import '../database/app_database.dart';
import '../services/transaction_sync/transaction_sync_service.dart';

const String kTransactionSyncTaskName = 'periodic_transaction_sync';

Future<void> runTransactionSyncTick(AppDatabase db) async {
  final storeInfo = await db.storeInfoDao.getStoreInfo();
  final storeId = storeInfo?.storeId ?? '';
  if (storeId.isEmpty) return;

  await Future.delayed(Duration(seconds: Random().nextInt(kTransactionSyncJitterMax.inSeconds)));

  final container = ProviderContainer(
    overrides: [
      appEnvProvider.overrideWithValue(Env()),
      savedOrdersServerUrlProvider.overrideWithValue(
        await loadSavedOrdersServerUrl(),
      ),
    ],
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

Future<void> schedulePeriodicTransactionSync() async {
  await Workmanager().registerPeriodicTask(
    kTransactionSyncTaskName,
    kTransactionSyncTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
