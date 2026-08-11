import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/backup/backup_storage_service.dart';

final lastBackupAtProvider = FutureProvider.autoDispose<DateTime?>((ref) {
  return BackupStorageService.lastBackupAt();
});
