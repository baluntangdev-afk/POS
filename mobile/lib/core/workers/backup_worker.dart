import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';
import '../services/backup/backup_service.dart';
import 'transaction_sync_worker.dart';

const String kBackupTaskName = 'periodic_pos_backup';

@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final db = AppDatabase();
    try {
      if (task == kBackupTaskName) {
        await BackupService.createBackupIfChanged(db);
      } else if (task == kTransactionSyncTaskName) {
        await runTransactionSyncTick(db);
      }
    } catch (_) {
      // A background job failing silently is fine here — the app-open
      // safety net (see main.dart) retries as a normal foreground backup
      // the next time the app is opened, and the transaction-sync reconnect
      // listener retries the next time it gets a chance.
    } finally {
      await db.close();
    }
    return Future.value(true);
  });
}

/// Registers WorkManager (once, for every periodic task the app has) and
/// schedules the backup job to run roughly every 3 hours. Safe to call on
/// every app startup — `ExistingPeriodicWorkPolicy.keep` means an
/// already-registered job is left alone rather than being reset.
Future<void> schedulePeriodicBackup() async {
  await Workmanager().initialize(backupCallbackDispatcher);

  await Workmanager().registerPeriodicTask(
    kBackupTaskName,
    kBackupTaskName,
    frequency: const Duration(hours: 3),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
