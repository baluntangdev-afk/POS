import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';

import 'core/database/app_database.dart';
import 'core/navigation/router.dart';
import 'core/providers/database_provider.dart';
import 'core/seeder/admin_seeder.dart';
import 'core/services/backup/backup_service.dart';
import 'core/services/backup/backup_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/workers/backup_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MediaStore.ensureInitialized();
  MediaStore.appFolder = 'POS Backups';

  final db = AppDatabase();
  await AdminSeeder(db).seed();

  await scheduleHourlyBackup();
  unawaited(_runStartupBackupSafetyNet(db));

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const _App(),
    ),
  );
}

/// If it's been more than an hour since the last backup (or there's never
/// been one), run one now in the foreground. Covers periods the WorkManager
/// job never fired — e.g. the device was off or asleep, or Android's Doze
/// mode delayed it.
Future<void> _runStartupBackupSafetyNet(AppDatabase db) async {
  try {
    final lastBackup = await BackupStorageService.lastBackupAt();
    final isStale = lastBackup == null ||
        DateTime.now().difference(lastBackup) > const Duration(hours: 1);
    if (isStale) {
      await BackupService.createBackup(db);
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
    return MaterialApp.router(
      title: 'POS Mobile',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
