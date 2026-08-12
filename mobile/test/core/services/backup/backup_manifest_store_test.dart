import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/backup/backup_manifest_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempDir;
  _FakePathProvider(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_manifest_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('add persists entries and all() reads them back', () async {
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'a.zip', createdAt: DateTime(2026, 1, 1)),
    );
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'b.zip', createdAt: DateTime(2026, 1, 2)),
    );

    final entries = await BackupManifestStore.all();
    expect(entries.map((e) => e.fileName), containsAll(['a.zip', 'b.zip']));
  });

  test('removeOlderThan drops entries past the cutoff and returns their file names', () async {
    final now = DateTime.now();
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'old_1.zip', createdAt: now.subtract(const Duration(days: 10))),
    );
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'old_2.zip', createdAt: now.subtract(const Duration(days: 8))),
    );
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'recent_1.zip', createdAt: now.subtract(const Duration(days: 2))),
    );
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'recent_2.zip', createdAt: now.subtract(const Duration(hours: 1))),
    );

    final removed = await BackupManifestStore.removeOlderThan(const Duration(days: 7));

    expect(removed, containsAll(['old_1.zip', 'old_2.zip']));
    final remaining = await BackupManifestStore.all();
    expect(remaining, hasLength(2));
    expect(
      remaining.map((e) => e.fileName),
      containsAll(['recent_1.zip', 'recent_2.zip']),
    );
  });

  test('removeOlderThan returns an empty list when nothing is past the cutoff', () async {
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'recent.zip', createdAt: DateTime.now()),
    );

    final removed = await BackupManifestStore.removeOlderThan(const Duration(days: 7));

    expect(removed, isEmpty);
    expect(await BackupManifestStore.all(), hasLength(1));
  });

  test('lastBackupAt returns null when empty, otherwise the newest createdAt', () async {
    expect(await BackupManifestStore.lastBackupAt(), isNull);

    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'a.zip', createdAt: DateTime(2026, 1, 1)),
    );
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'b.zip', createdAt: DateTime(2026, 1, 5)),
    );

    expect(await BackupManifestStore.lastBackupAt(), DateTime(2026, 1, 5));
  });

  test('lastBackupHash returns null when empty, otherwise the newest entry\'s hash', () async {
    expect(await BackupManifestStore.lastBackupHash(), isNull);

    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'a.zip', createdAt: DateTime(2026, 1, 1), dataHash: 'hash-a'),
    );
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'b.zip', createdAt: DateTime(2026, 1, 5), dataHash: 'hash-b'),
    );

    expect(await BackupManifestStore.lastBackupHash(), 'hash-b');
  });

  test('lastBackupHash returns null when the newest entry predates hashing', () async {
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: 'a.zip', createdAt: DateTime(2026, 1, 1)),
    );

    expect(await BackupManifestStore.lastBackupHash(), isNull);
  });
}
