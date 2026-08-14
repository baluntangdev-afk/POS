import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';
import '../services/backup/backup_service.dart';

const String kBackupTaskName = 'hourly_pos_backup';

@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != kBackupTaskName) return Future.value(true);
    try {
      final db = AppDatabase();
      await BackupService.createBackupIfChanged(db);
      await db.close();
    } catch (_) {
      // A background job failing silently is fine here — the app-open
      // safety net (see main.dart) retries as a normal foreground backup
      // the next time the app is opened.
    }
    return Future.value(true);
  });
}

/// Registers WorkManager and schedules the backup job to run roughly every
/// hour. Safe to call on every app startup — `ExistingPeriodicWorkPolicy.keep`
/// means an already-registered job is left alone rather than being reset.
Future<void> scheduleHourlyBackup() async {
  await Workmanager().initialize(backupCallbackDispatcher);

  await Workmanager().registerPeriodicTask(
    kBackupTaskName,
    kBackupTaskName,
    frequency: const Duration(hours: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
