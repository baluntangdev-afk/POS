import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupManifestEntry {
  final String fileName;
  final DateTime createdAt;

  const BackupManifestEntry({required this.fileName, required this.createdAt});

  Map<String, Object?> toJson() => {
        'fileName': fileName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BackupManifestEntry.fromJson(Map<String, Object?> json) =>
      BackupManifestEntry(
        fileName: json['fileName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

abstract final class BackupManifestStore {
  static Future<File> _manifestFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'backup_manifest.json'));
  }

  static Future<List<BackupManifestEntry>> all() async {
    final file = await _manifestFile();
    if (!await file.exists()) return [];
    final decoded = jsonDecode(await file.readAsString()) as List;
    return [
      for (final e in decoded)
        BackupManifestEntry.fromJson(Map<String, Object?>.from(e as Map)),
    ];
  }

  static Future<void> add(BackupManifestEntry entry) async {
    final entries = await all();
    entries.add(entry);
    await _save(entries);
  }

  /// Drops entries older than [maxAge] from the manifest and returns the
  /// file names that were dropped, so the caller can delete the actual
  /// backup files too. Time-based rather than count-based because backups
  /// now run hourly — a count-based "keep the newest 30" would only cover
  /// a day and a bit, not the multi-day window this is meant to provide.
  static Future<List<String>> removeOlderThan(Duration maxAge) async {
    final entries = await all();
    final cutoff = DateTime.now().subtract(maxAge);

    final toKeep = <BackupManifestEntry>[];
    final toRemove = <BackupManifestEntry>[];
    for (final entry in entries) {
      if (entry.createdAt.isBefore(cutoff)) {
        toRemove.add(entry);
      } else {
        toKeep.add(entry);
      }
    }
    if (toRemove.isEmpty) return [];

    await _save(toKeep);
    return [for (final e in toRemove) e.fileName];
  }

  static Future<DateTime?> lastBackupAt() async {
    final entries = await all();
    if (entries.isEmpty) return null;
    return entries.map((e) => e.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  static Future<void> _save(List<BackupManifestEntry> entries) async {
    final file = await _manifestFile();
    await file.writeAsString(jsonEncode([for (final e in entries) e.toJson()]));
  }
}
