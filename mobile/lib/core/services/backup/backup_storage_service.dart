import 'dart:io';

import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;

import 'backup_manifest_store.dart';

abstract final class BackupStorageService {
  /// Backups run hourly now, so this is a time window, not a count — 7 days
  /// caps storage at roughly 168 zips while still giving a week of history
  /// to fall back on.
  static const Duration retentionWindow = Duration(days: 7);

  /// Writes [localZip] into the public Downloads/POS Backups folder,
  /// records it in the manifest, and deletes backups older than
  /// [retentionWindow].
  static Future<void> writeAndRegister(
    File localZip, {
    required DateTime at,
    String? dataHash,
  }) async {
    final mediaStore = MediaStore();
    final fileName = p.basename(localZip.path);

    await mediaStore.saveFile(
      tempFilePath: localZip.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: fileName, createdAt: at, dataHash: dataHash),
    );

    final removed = await BackupManifestStore.removeOlderThan(retentionWindow);
    for (final name in removed) {
      await mediaStore.deleteFile(
        fileName: name,
        dirType: DirType.download,
        dirName: DirName.download,
      );
    }
  }

  static Future<DateTime?> lastBackupAt() => BackupManifestStore.lastBackupAt();
}
