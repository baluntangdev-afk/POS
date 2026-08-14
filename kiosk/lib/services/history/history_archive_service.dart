import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';

final historyArchiveServiceProvider = Provider<HistoryArchiveService>((ref) {
  return HistoryArchiveService();
});

/// Writes rendered receipt/cashier-report PDFs to `<app dir>\History\<year>\<month>\` --
/// a human-readable, read-only archive kept alongside the app for reprints, disputes,
/// and audits. This is separate from database backups: it cannot restore `pos_db`, it
/// just makes documents that were already printed easy to find again.
///
/// See docs/superpowers/specs/2026-08-10-backup-strategy-design.md for the full strategy.
class HistoryArchiveService {
  HistoryArchiveService({Directory? baseDir}) : _baseDir = baseDir ?? _defaultBaseDir();

  final Directory _baseDir;

  static Directory _defaultBaseDir() {
    // In production the installer lays pos_app.exe directly under C:\POSKiosk, so its
    // parent directory is {app} -- the same root scripts/README.md call {app} for
    // Backups\. In dev (flutter run), this resolves under build\windows\..., which is
    // fine: it just keeps a local History\ folder next to the debug executable.
    return Directory(File(Platform.resolvedExecutable).parent.path);
  }

  /// Saves [bytes] as [fileName] under History\<year>\<month>\ for [at] (defaults to now),
  /// creating the directory if needed. Returns the written file.
  Future<File> save({required String fileName, required List<int> bytes, DateTime? at}) async {
    final date = (at ?? DateTime.now()).toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final dir = Directory(
      '${_baseDir.path}${Platform.pathSeparator}History'
      '${Platform.pathSeparator}${date.year}'
      '${Platform.pathSeparator}$month',
    );
    await dir.create(recursive: true);

    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }
}
