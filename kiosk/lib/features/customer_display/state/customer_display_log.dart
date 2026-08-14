import 'dart:io';

/// Minimal append-only file logger for diagnosing the customer-display
/// catalog pipeline on real kiosk hardware, where there's no attached
/// console. Writes to `{app}\logs\<fileName>` — the same `logs` folder the
/// installer already creates (`be/installer/installer.iss`) and the same
/// "next to `Platform.resolvedExecutable`" base path `HistoryArchiveService`
/// already uses, so this doesn't introduce a new location to look in.
class CustomerDisplayLog {
  CustomerDisplayLog(this._fileName);

  final String _fileName;

  Future<void> write(String message) async {
    try {
      final baseDir = File(Platform.resolvedExecutable).parent.path;
      final dir = Directory('$baseDir${Platform.pathSeparator}logs');
      await dir.create(recursive: true);
      final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Logging must never throw into the caller's own error handling.
    }
  }
}
