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

    } finally {
      await db.close();
    }
    return Future.value(true);
  });
}

Future<void> schedulePeriodicBackup() async {
  await Workmanager().initialize(backupCallbackDispatcher);

  await Workmanager().registerPeriodicTask(
    kBackupTaskName,
    kBackupTaskName,
    frequency: const Duration(hours: 3),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
