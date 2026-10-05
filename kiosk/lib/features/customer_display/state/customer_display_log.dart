import 'dart:io';

import 'package:flutter/foundation.dart';

/// Minimal append-only file logger for diagnosing the customer-display
/// catalog pipeline on real kiosk hardware, where there's no attached
/// console. Writes to `{app}\logs\<fileName>` — the same `logs` folder the
/// installer already creates (`be/installer/installer.iss`) and the same
/// "next to `Platform.resolvedExecutable`" base path `HistoryArchiveService`
/// already uses, so this doesn't introduce a new location to look in.
///
/// The file is capped at [_maxBytes] and restarted when it grows past that.
/// Nothing else prunes this folder, so an uncapped log here reached 100 MB on
/// a live terminal.
class CustomerDisplayLog {
  CustomerDisplayLog(this._fileName);

  static const _maxBytes = 2 * 1024 * 1024;
  static const _checkEvery = 50;

  final String _fileName;
  int _writesSinceCheck = _checkEvery;

  /// Routine progress chatter. Dropped entirely in release builds.
  Future<void> trace(String message) async {
    if (!kDebugMode) return;
    return write(message);
  }

  /// Failures and state changes. Kept in release builds.
  Future<void> write(String message) async {
    try {
      final baseDir = File(Platform.resolvedExecutable).parent.path;
      final dir = Directory('$baseDir${Platform.pathSeparator}logs');
      await dir.create(recursive: true);
      final file = File('${dir.path}${Platform.pathSeparator}$_fileName');

      // Stat is a syscall, so only check periodically rather than per line.
      if (++_writesSinceCheck >= _checkEvery) {
        _writesSinceCheck = 0;
        if (file.existsSync() && file.lengthSync() > _maxBytes) {
          await file.writeAsString(
            '[${DateTime.now().toIso8601String()}] --- log restarted at $_maxBytes bytes ---\n',
          );
        }
      }

      final timestamp = DateTime.now().toIso8601String();
      // No flush: writeAsString closes the handle, which is enough. Forcing an
      // fsync per line stalled the UI isolate on a disk the backend was
      // already saturating.
      await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
    } catch (_) {
      // Logging must never throw into the caller's own error handling.
    }
  }
}
