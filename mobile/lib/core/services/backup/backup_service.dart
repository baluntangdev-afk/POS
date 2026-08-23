import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../database/app_database.dart';
import 'backup_archive_service.dart';
import 'backup_data_serializer.dart';
import 'backup_manifest_store.dart';
import 'backup_storage_service.dart';

abstract final class BackupService {
  /// Dumps the DB + product images into a zip, writes it to Downloads/POS
  /// Backups, and returns the local temp copy (so callers can also share it
  /// via the OS share sheet). Always produces a real backup file — used by
  /// manual "Back Up Now" and the pre-restore safety snapshot, both of which
  /// need a guaranteed file regardless of whether data changed.
  static Future<File> createBackup(AppDatabase db, {DateTime? at}) async {
    final data = await BackupDataSerializer.dumpAllTables(db);
    return _writeBackup(data, at: at ?? DateTime.now());
  }

  /// Same as [createBackup], but skips writing a new zip if nothing has
  /// changed since the most recent backup (compares a hash of the dumped
  /// data). Used only by the automatic periodic job and the app-open safety
  /// net, to avoid piling up identical zips in Downloads/POS Backups when a
  /// store has had no new activity. Returns null when skipped.
  static Future<File?> createBackupIfChanged(AppDatabase db, {DateTime? at}) async {
    final data = await BackupDataSerializer.dumpAllTables(db);
    final hash = BackupDataSerializer.hashData(data);
    if (hash == await BackupManifestStore.lastBackupHash()) return null;
    return _writeBackup(data, at: at ?? DateTime.now(), hash: hash);
  }

  static Future<File> _writeBackup(
    Map<String, List<Map<String, Object?>>> data, {
    required DateTime at,
    String? hash,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docsDir.path, 'product_images'));

    final tempDir = await getTemporaryDirectory();
    final fileName = 'pos_backup_${_timestamp(at)}.zip';
    final outputFile = File(p.join(tempDir.path, fileName));

    await BackupArchiveService.buildArchive(
      data: data,
      imagesDir: imagesDir,
      outputFile: outputFile,
    );

    // MediaStore's saveFile deletes its source file as a side effect of
    // copying it into Downloads — hand it a throwaway copy, since callers
    // (e.g. the share sheet) still need outputFile to exist afterward.
    final registerDir = Directory(p.join(tempDir.path, 'backup_registration'));
    await registerDir.create(recursive: true);
    final registerCopy = await outputFile.copy(p.join(registerDir.path, fileName));
    await BackupStorageService.writeAndRegister(
      registerCopy,
      at: at,
      dataHash: hash ?? BackupDataSerializer.hashData(data),
    );
    if (await registerDir.exists()) await registerDir.delete(recursive: true);

    return outputFile;
  }

  /// Full replace: takes a safety backup of whatever's currently on-device,
  /// then wipes and reloads the DB + product images from [zipFile].
  static Future<void> restoreBackup(
    AppDatabase db, {
    required File zipFile,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(p.join(tempDir.path, 'restore_images'));
    if (await extractDir.exists()) await extractDir.delete(recursive: true);
    await extractDir.create(recursive: true);

    // Extract and validate the archive BEFORE touching any existing data —
    // a corrupted file must never trigger the safety backup or wipe anything.
    final extracted = await BackupArchiveService.extractArchive(
      zipFile: zipFile,
      extractImagesTo: extractDir,
    );

    await createBackup(db);

    await BackupDataSerializer.restoreAllTables(db, extracted.data);

    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docsDir.path, 'product_images'));
    if (await imagesDir.exists()) {
      await imagesDir.delete(recursive: true);
    }
    await imagesDir.create(recursive: true);
    for (final file in extracted.imageFiles) {
      await file.copy(p.join(imagesDir.path, p.basename(file.path)));
    }

    await extractDir.delete(recursive: true);
  }

  static String _timestamp(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${at.year}${two(at.month)}${two(at.day)}_'
        '${two(at.hour)}${two(at.minute)}${two(at.second)}';
  }
}
