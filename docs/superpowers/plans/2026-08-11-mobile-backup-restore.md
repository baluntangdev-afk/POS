# Mobile POS Backup & Restore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Git note:** This repo's `CLAUDE.md` prohibits creating git commits unless the user explicitly asks. Steps below do **not** include `git commit` — stage files as you go if useful, but stop short of committing. Ask the user before committing, same as any other work in this repo.

**Goal:** Give the offline-only `mobile/` POS app a real backup/restore story: an hourly automatic background backup (survives app uninstall), a manual "Back Up Now" export, and a "Restore Data" flow — all built around one PIN-protected `.zip` (JSON dump of all 18 tables + product images).

**Architecture:** Five small, independently-testable service files under `lib/core/services/backup/` handle serialization (DB ↔ JSON), archiving (JSON+images ↔ encrypted zip), PIN storage, and public-storage I/O with time-based retention bookkeeping; a thin orchestrator (`BackupService`) ties them together for both the WorkManager background job and the Settings UI. Settings gets a new `BackupScreen` (PIN management, manual backup, restore) reachable from a new tile, gated the same way "Import CSV" already is (`isAdminOrSupervisor`). The Backup PIN is entered via the app's existing `PinDots`/`PinKeypad` widgets (same as login/PIN-setup), not a free-text field.

**Tech Stack:** Flutter/Dart, Drift (raw `customSelect`/`customStatement`/`transaction`), `archive` (password-protected zip), `workmanager` (hourly background job), `media_store_plus` (public `Downloads/` writes via Android MediaStore), `flutter_secure_storage` (PIN persistence), existing `file_picker`/`share_plus`/`path_provider`.

> **Revision note (2026-08-11):** This plan originally shipped with a daily/2 AM trigger, count-based retention (keep newest 30), and a free-text password. After review, the trigger moved to hourly (with time-based 7-day retention to match, since a count cap made no sense at hourly frequency) and the password became a 6-digit PIN entered via the app's existing PIN keypad, for UX consistency with login. This document reflects the shipped state, not the original draft — see the design spec's own revision note for the reasoning behind each change.

---

## Design reference

Full design/rationale: `docs/superpowers/specs/2026-08-10-mobile-backup-restore-design.md`. This plan implements that spec as written. Two low-level details were resolved during planning (verified against current package docs, not guessed) and are called out where relevant:

- `media_store_plus` has no "list files in a folder" API, so retention (drop entries older than 7 days) is tracked via a small local JSON manifest file (`backup_manifest.json` in the app's documents directory) rather than by listing the public `Downloads/POS Backups/` folder directly. The manifest is bookkeeping only — the backups themselves still live in public storage and survive uninstall regardless of whether the manifest does.
- `workmanager`'s `registerPeriodicTask` schedules by *interval* (minimum 15 minutes), not wall-clock time. The job is scheduled with `frequency: Duration(hours: 1)` and no special `initialDelay` — Android's own Doze/battery-optimization behavior means exact wall-clock alignment was never guaranteed regardless, which is exactly why the spec has the startup safety-net check as a backstop (now triggering after 1 hour of staleness instead of 1 day, to match).

## Full table list and dependency order

Confirmed by reading every table file under `mobile/lib/core/database/tables/`. This exact order is used for JSON dump keys, restore insert order, and (reversed) restore delete order:

```
store_info, users, product_groups, products, product_variants, modifier_groups,
modifier_options, product_modifier_groups, payment_methods, sales, sale_items,
sale_item_modifiers, payments, refunds, refund_items, x_readings, z_readings,
daily_reports
```

All columns across all 18 tables are `IntColumn`, `TextColumn`, `RealColumn`, `BoolColumn`, or `DateTimeColumn` — no BLOBs. Drift stores booleans and datetimes as SQLite integers, so raw values read via `customSelect`/`QueryRow.data` are already `int`/`double`/`String`/`null` — directly JSON-encodable with no type conversion needed on dump, and directly usable as `customStatement` bind parameters on restore.

---

### Task 1: Add dependencies and Android manifest flag

**Files:**
- Modify: `mobile/pubspec.yaml`
- Modify: `mobile/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add the four new packages**

Run from the `mobile/` directory:

```bash
flutter pub add flutter_secure_storage archive workmanager media_store_plus
```

Expected: `pubspec.yaml` gains four new entries under `dependencies:` and `flutter pub get` runs automatically as part of `pub add`.

- [ ] **Step 2: Allow legacy external storage writes on Android 10 (API 29)**

`media_store_plus` needs this for older devices; API 30+ doesn't need it but the flag is harmless there. Edit `mobile/android/app/src/main/AndroidManifest.xml`, adding the attribute to the existing `<application>` tag:

```xml
    <application
        android:label="POS Mobile"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true">
```

- [ ] **Step 3: Bump the app version**

This app is sideloaded (not distributed via Play Store), so a version bump isn't strictly required for an update install to succeed — but it's good practice for tracking which build is on which device across a fleet of POS units. Edit `mobile/pubspec.yaml`:

```yaml
version: 1.1.0+2
```

(was `1.0.0+1`)

- [ ] **Step 4: Verify the project still analyzes cleanly**

Run: `dart analyze` (from `mobile/`)
Expected: no new errors (unused-import warnings are fine at this point since nothing uses the new packages yet).

---

### Task 2: `BackupPasswordService` — shared backup password storage

Stores one shared secret (not tied to any user's login PIN — see spec's "Backup PIN" section for why). The service itself is still generic string storage; the 6-digit PIN format is enforced entirely at the UI layer (Task 13's `_SetBackupPinDialog` and Task 12's restore keypad). Depends on an injected `SecureKeyValueStore` interface rather than `FlutterSecureStorage` directly, so it's fully unit-testable without mocking a platform channel.

**Files:**
- Create: `mobile/lib/core/services/backup/backup_password_service.dart`
- Test: `mobile/test/core/services/backup/backup_password_service_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// mobile/test/core/services/backup/backup_password_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/backup/backup_password_service.dart';

class _FakeSecureKeyValueStore implements SecureKeyValueStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

void main() {
  test('hasPassword is false until setPassword is called', () async {
    final service = BackupPasswordService(_FakeSecureKeyValueStore());
    expect(await service.hasPassword(), isFalse);
  });

  test('setPassword then getPassword round-trips the value', () async {
    final service = BackupPasswordService(_FakeSecureKeyValueStore());

    await service.setPassword('s3cret');

    expect(await service.hasPassword(), isTrue);
    expect(await service.getPassword(), 's3cret');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/backup/backup_password_service_test.dart`
Expected: FAIL — `backup_password_service.dart` doesn't exist yet.

- [ ] **Step 3: Write the implementation**

```dart
// mobile/lib/core/services/backup/backup_password_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin key/value interface so [BackupPasswordService] doesn't depend
/// directly on FlutterSecureStorage's platform channel — keeps it testable
/// without mocking third-party wire-format details.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore();
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class BackupPasswordService {
  final SecureKeyValueStore _store;
  const BackupPasswordService([
    this._store = const FlutterSecureKeyValueStore(),
  ]);

  static const _key = 'backup_password';

  Future<bool> hasPassword() async => (await _store.read(_key)) != null;

  Future<String?> getPassword() => _store.read(_key);

  Future<void> setPassword(String password) => _store.write(_key, password);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/backup/backup_password_service_test.dart`
Expected: PASS (2 tests)

---

### Task 3: `BackupManifestStore` — tracks created backups for retention

A small JSON file (`backup_manifest.json`) in the app's documents directory recording `{fileName, createdAt}` for every backup written to `Downloads/POS Backups/`. Needed because `media_store_plus` has no "list files" API (see Design reference above).

**Files:**
- Create: `mobile/lib/core/services/backup/backup_manifest_store.dart`
- Test: `mobile/test/core/services/backup/backup_manifest_store_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// mobile/test/core/services/backup/backup_manifest_store_test.dart
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/backup/backup_manifest_store_test.dart`
Expected: FAIL — `backup_manifest_store.dart` doesn't exist yet.

- [ ] **Step 3: Write the implementation**

```dart
// mobile/lib/core/services/backup/backup_manifest_store.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/backup/backup_manifest_store_test.dart`
Expected: PASS (4 tests)

---

### Task 4: `BackupDataSerializer.dumpAllTables` — DB → JSON

**Files:**
- Create: `mobile/lib/core/services/backup/backup_data_serializer.dart`
- Test: `mobile/test/core/services/backup/backup_data_serializer_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// mobile/test/core/services/backup/backup_data_serializer_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/services/backup/backup_data_serializer.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('dumpAllTables includes every table, populated and empty', () async {
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));
    await db.productsDao
        .insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));

    final dump = await BackupDataSerializer.dumpAllTables(db);

    expect(dump.keys, containsAll(kBackupTableOrder));
    expect(dump['product_groups'], hasLength(1));
    expect(dump['product_groups']!.first['name'], 'Drinks');
    expect(dump['products'], hasLength(1));
    expect(dump['products']!.first['name'], 'Latte');
    // A table with no rows still appears, as an empty list.
    expect(dump['sales'], isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/backup/backup_data_serializer_test.dart`
Expected: FAIL — `backup_data_serializer.dart` doesn't exist yet.

- [ ] **Step 3: Write the implementation**

```dart
// mobile/lib/core/services/backup/backup_data_serializer.dart
import '../../database/app_database.dart';

/// All 18 tables, in an order that respects foreign-key dependencies
/// (parents before children). Used for JSON dump keys, restore insert
/// order, and — reversed — restore delete order.
const List<String> kBackupTableOrder = [
  'store_info',
  'users',
  'product_groups',
  'products',
  'product_variants',
  'modifier_groups',
  'modifier_options',
  'product_modifier_groups',
  'payment_methods',
  'sales',
  'sale_items',
  'sale_item_modifiers',
  'payments',
  'refunds',
  'refund_items',
  'x_readings',
  'z_readings',
  'daily_reports',
];

abstract final class BackupDataSerializer {
  static Future<Map<String, List<Map<String, Object?>>>> dumpAllTables(
    AppDatabase db,
  ) async {
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in kBackupTableOrder) {
      final rows = await db.customSelect('SELECT * FROM $table').get();
      result[table] = [for (final row in rows) Map<String, Object?>.from(row.data)];
    }
    return result;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/backup/backup_data_serializer_test.dart`
Expected: PASS (1 test)

---

### Task 5: `BackupDataSerializer.restoreAllTables` — JSON → DB, transactional

**Files:**
- Modify: `mobile/lib/core/services/backup/backup_data_serializer.dart`
- Modify: `mobile/test/core/services/backup/backup_data_serializer_test.dart`

- [ ] **Step 1: Add the failing tests**

Append to `mobile/test/core/services/backup/backup_data_serializer_test.dart`, inside `main()`:

```dart
  test('restoreAllTables replaces existing data with the dumped data', () async {
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));
    await db.productsDao
        .insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));

    final dumped = await BackupDataSerializer.dumpAllTables(db);

    await db.customStatement('DELETE FROM products');
    await db.customStatement('DELETE FROM product_groups');

    await BackupDataSerializer.restoreAllTables(db, dumped);

    final groups = await db.customSelect('SELECT * FROM product_groups').get();
    expect(groups, hasLength(1));
    expect(groups.first.data['name'], 'Drinks');
    final products = await db.customSelect('SELECT * FROM products').get();
    expect(products, hasLength(1));
    expect(products.first.data['name'], 'Latte');
  });

  test('restoreAllTables rolls back entirely if any insert fails, leaving prior data intact', () async {
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));
    await db.productsDao
        .insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));

    final badData = await BackupDataSerializer.dumpAllTables(db);
    // products.name is NOT NULL — this must fail the insert and roll back
    // the whole transaction, including the deletes that ran before it.
    badData['products']![0]['name'] = null;

    await expectLater(
      BackupDataSerializer.restoreAllTables(db, badData),
      throwsA(anything),
    );

    final groups = await db.customSelect('SELECT * FROM product_groups').get();
    expect(groups, hasLength(1));
    expect(groups.first.data['name'], 'Drinks');
    final products = await db.customSelect('SELECT * FROM products').get();
    expect(products, hasLength(1));
    expect(products.first.data['name'], 'Latte');
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/services/backup/backup_data_serializer_test.dart`
Expected: FAIL — `restoreAllTables` doesn't exist yet.

- [ ] **Step 3: Add the implementation**

Append to `mobile/lib/core/services/backup/backup_data_serializer.dart`, inside the `BackupDataSerializer` class body (after `dumpAllTables`):

```dart
  static Future<void> restoreAllTables(
    AppDatabase db,
    Map<String, List<Map<String, Object?>>> data,
  ) async {
    await db.transaction(() async {
      for (final table in kBackupTableOrder.reversed) {
        await db.customStatement('DELETE FROM $table');
      }
      for (final table in kBackupTableOrder) {
        final rows = data[table] ?? const [];
        for (final row in rows) {
          final columns = row.keys.toList();
          final placeholders = List.filled(columns.length, '?').join(', ');
          await db.customStatement(
            'INSERT INTO $table (${columns.join(', ')}) VALUES ($placeholders)',
            [for (final c in columns) row[c]],
          );
        }
      }
    });
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/services/backup/backup_data_serializer_test.dart`
Expected: PASS (3 tests)

---

### Task 6: `BackupArchiveService` — JSON+images ↔ encrypted zip

Uses the `archive` package's built-in password support (`ZipEncoder(password:).encodeBytes()` / `ZipDecoder().decodeBytes(bytes, password:)`), verified against the current pub.dev API docs (package `archive` v4.0.9).

**Files:**
- Create: `mobile/lib/core/services/backup/backup_archive_service.dart`
- Test: `mobile/test/core/services/backup/backup_archive_service_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// mobile/test/core/services/backup/backup_archive_service_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/backup/backup_archive_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_archive_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('buildArchive then extractArchive round-trips data and images with the correct password', () async {
    final imagesDir = Directory('${tempDir.path}/images')..createSync();
    File('${imagesDir.path}/photo.png').writeAsStringSync('fake-image-bytes');

    final data = {
      'products': [
        {'id': 1, 'name': 'Latte', 'is_available': 1},
      ],
    };
    final outputFile = File('${tempDir.path}/backup.zip');

    await BackupArchiveService.buildArchive(
      data: data,
      imagesDir: imagesDir,
      password: 'correct horse battery staple',
      outputFile: outputFile,
    );

    expect(await outputFile.exists(), isTrue);

    final extractDir = Directory('${tempDir.path}/extracted')..createSync();
    final extracted = await BackupArchiveService.extractArchive(
      zipFile: outputFile,
      password: 'correct horse battery staple',
      extractImagesTo: extractDir,
    );

    expect(extracted.data['products']![0]['name'], 'Latte');
    expect(extracted.imageFiles, hasLength(1));
    expect(await extracted.imageFiles.first.readAsString(), 'fake-image-bytes');
  });

  test('extractArchive throws BackupArchiveException for the wrong password', () async {
    final imagesDir = Directory('${tempDir.path}/images')..createSync();
    final outputFile = File('${tempDir.path}/backup.zip');

    await BackupArchiveService.buildArchive(
      data: {'products': <Map<String, Object?>>[]},
      imagesDir: imagesDir,
      password: 'right-password',
      outputFile: outputFile,
    );

    final extractDir = Directory('${tempDir.path}/extracted')..createSync();

    expect(
      () => BackupArchiveService.extractArchive(
        zipFile: outputFile,
        password: 'wrong-password',
        extractImagesTo: extractDir,
      ),
      throwsA(isA<BackupArchiveException>()),
    );
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/services/backup/backup_archive_service_test.dart`
Expected: FAIL — `backup_archive_service.dart` doesn't exist yet.

- [ ] **Step 3: Write the implementation**

```dart
// mobile/lib/core/services/backup/backup_archive_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class BackupArchiveException implements Exception {
  final String message;
  BackupArchiveException(this.message);

  @override
  String toString() => message;
}

class ExtractedBackup {
  final Map<String, List<Map<String, Object?>>> data;
  final List<File> imageFiles;

  ExtractedBackup({required this.data, required this.imageFiles});
}

abstract final class BackupArchiveService {
  static Future<File> buildArchive({
    required Map<String, List<Map<String, Object?>>> data,
    required Directory imagesDir,
    required String password,
    required File outputFile,
  }) async {
    final archive = Archive();
    final jsonBytes = utf8.encode(jsonEncode(data));
    archive.addFile(ArchiveFile.bytes('data.json', jsonBytes));

    if (await imagesDir.exists()) {
      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          final bytes = await entity.readAsBytes();
          archive.addFile(
            ArchiveFile.bytes('product_images/${p.basename(entity.path)}', bytes),
          );
        }
      }
    }

    final zipBytes = ZipEncoder(password: password).encodeBytes(archive);
    await outputFile.writeAsBytes(zipBytes);
    return outputFile;
  }

  static Future<ExtractedBackup> extractArchive({
    required File zipFile,
    required String password,
    required Directory extractImagesTo,
  }) async {
    final bytes = await zipFile.readAsBytes();

    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, password: password);
    } catch (_) {
      throw BackupArchiveException('Incorrect password or corrupted backup file.');
    }

    final dataEntry = archive.findFile('data.json');
    if (dataEntry == null) {
      throw BackupArchiveException('Incorrect password or corrupted backup file.');
    }

    late final Map<String, List<Map<String, Object?>>> data;
    try {
      final decoded = jsonDecode(utf8.decode(dataEntry.content)) as Map<String, dynamic>;
      data = decoded.map(
        (table, rows) => MapEntry(
          table,
          [for (final r in (rows as List)) Map<String, Object?>.from(r as Map)],
        ),
      );
    } catch (_) {
      // Wrong password rarely throws inside decodeBytes itself — it usually
      // just produces garbage bytes, which then fail UTF-8/JSON decoding
      // here. This catch is what actually surfaces "wrong password" to
      // the user in the common case.
      throw BackupArchiveException('Incorrect password or corrupted backup file.');
    }

    if (!await extractImagesTo.exists()) {
      await extractImagesTo.create(recursive: true);
    }
    final imageFiles = <File>[];
    for (final entry in archive) {
      if (entry.isFile && entry.name.startsWith('product_images/')) {
        final destFile = File(p.join(extractImagesTo.path, p.basename(entry.name)));
        await destFile.writeAsBytes(entry.content);
        imageFiles.add(destFile);
      }
    }

    return ExtractedBackup(data: data, imageFiles: imageFiles);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/services/backup/backup_archive_service_test.dart`
Expected: PASS (2 tests)

---

### Task 7: `BackupStorageService` — write to public Downloads + enforce retention

Wraps `media_store_plus`. This talks to a real platform channel, so it isn't unit-tested here (no fake platform interface exists for this plugin) — Task 14 covers on-device verification. The retention logic it calls (`BackupManifestStore.removeOlderThan`) is already tested in Task 3.

**Files:**
- Create: `mobile/lib/core/services/backup/backup_storage_service.dart`

- [ ] **Step 1: Write the implementation**

```dart
// mobile/lib/core/services/backup/backup_storage_service.dart
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
  static Future<void> writeAndRegister(File localZip, {required DateTime at}) async {
    final mediaStore = MediaStore();
    final fileName = p.basename(localZip.path);

    await mediaStore.saveFile(
      tempFilePath: localZip.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );
    await BackupManifestStore.add(
      BackupManifestEntry(fileName: fileName, createdAt: at),
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
```

- [ ] **Step 2: Verify it compiles**

Run: `dart analyze` (from `mobile/`)
Expected: no errors in `backup_storage_service.dart`.

---

### Task 8: `BackupService` — orchestrator used by both UI and background job

Ties together serialization, archiving, and storage for `createBackup`, and adds the pre-restore safety snapshot + image directory swap for `restoreBackup`. Like Task 7, this isn't unit-tested (it transitively depends on the real `media_store_plus` platform channel) — covered by Task 14's manual verification, matching the spec's own testing section.

**Files:**
- Create: `mobile/lib/core/services/backup/backup_service.dart`

- [ ] **Step 1: Write the implementation**

```dart
// mobile/lib/core/services/backup/backup_service.dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../database/app_database.dart';
import 'backup_archive_service.dart';
import 'backup_data_serializer.dart';
import 'backup_password_service.dart';
import 'backup_storage_service.dart';

abstract final class BackupService {
  /// Dumps the DB + product images into a password-protected zip, writes it
  /// to Downloads/POS Backups, and returns the local temp copy (so callers
  /// can also share it via the OS share sheet).
  static Future<File> createBackup(
    AppDatabase db, {
    required String password,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    final data = await BackupDataSerializer.dumpAllTables(db);

    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docsDir.path, 'product_images'));

    final tempDir = await getTemporaryDirectory();
    final fileName = 'pos_backup_${_timestamp(now)}.zip';
    final outputFile = File(p.join(tempDir.path, fileName));

    await BackupArchiveService.buildArchive(
      data: data,
      imagesDir: imagesDir,
      password: password,
      outputFile: outputFile,
    );

    await BackupStorageService.writeAndRegister(outputFile, at: now);

    return outputFile;
  }

  /// Full replace: takes a safety backup of whatever's currently on-device,
  /// then wipes and reloads the DB + product images from [zipFile].
  static Future<void> restoreBackup(
    AppDatabase db, {
    required File zipFile,
    required String password,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(p.join(tempDir.path, 'restore_images'));
    if (await extractDir.exists()) await extractDir.delete(recursive: true);
    await extractDir.create(recursive: true);

    // Extract and validate the password/archive BEFORE touching any
    // existing data — a bad password must never trigger the safety backup
    // or wipe anything.
    final extracted = await BackupArchiveService.extractArchive(
      zipFile: zipFile,
      password: password,
      extractImagesTo: extractDir,
    );

    final passwordService = BackupPasswordService();
    final currentPassword = await passwordService.getPassword() ?? password;
    await createBackup(db, password: currentPassword);

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
```

- [ ] **Step 2: Verify it compiles**

Run: `dart analyze` (from `mobile/`)
Expected: no errors in `backup_service.dart`.

---

### Task 9: Hourly background backup job (WorkManager)

**Files:**
- Create: `mobile/lib/core/workers/backup_worker.dart`

- [ ] **Step 1: Write the implementation**

```dart
// mobile/lib/core/workers/backup_worker.dart
import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';
import '../services/backup/backup_password_service.dart';
import '../services/backup/backup_service.dart';

const String kBackupTaskName = 'hourly_pos_backup';

@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != kBackupTaskName) return Future.value(true);
    try {
      final password = await const BackupPasswordService().getPassword();
      if (password == null) return Future.value(true);

      final db = AppDatabase();
      await BackupService.createBackup(db, password: password);
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
```

- [ ] **Step 2: Verify it compiles**

Run: `dart analyze` (from `mobile/`)
Expected: no errors in `backup_worker.dart`.

---

### Task 10: Wire startup — MediaStore init, hourly job registration, safety-net check

**Files:**
- Modify: `mobile/lib/main.dart`

- [ ] **Step 1: Update `main.dart`**

```dart
// mobile/lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';

import 'core/database/app_database.dart';
import 'core/navigation/router.dart';
import 'core/providers/database_provider.dart';
import 'core/seeder/admin_seeder.dart';
import 'core/services/backup/backup_password_service.dart';
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
/// mode delayed it. Silently does nothing if no Backup PIN has been set yet.
Future<void> _runStartupBackupSafetyNet(AppDatabase db) async {
  try {
    final password = await const BackupPasswordService().getPassword();
    if (password == null) return;

    final lastBackup = await BackupStorageService.lastBackupAt();
    final isStale = lastBackup == null ||
        DateTime.now().difference(lastBackup) > const Duration(hours: 1);
    if (isStale) {
      await BackupService.createBackup(db, password: password);
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
```

- [ ] **Step 2: Verify it compiles**

Run: `dart analyze` (from `mobile/`)
Expected: no errors.

---

### Task 11: Riverpod providers for the backup UI

**Files:**
- Create: `mobile/lib/features/settings/state/backup_providers.dart`

- [ ] **Step 1: Write the implementation**

```dart
// mobile/lib/features/settings/state/backup_providers.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/backup/backup_password_service.dart';
import '../../../core/services/backup/backup_storage_service.dart';

final backupPasswordServiceProvider =
    Provider<BackupPasswordService>((ref) => const BackupPasswordService());

final hasBackupPasswordProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(backupPasswordServiceProvider).hasPassword();
});

final lastBackupAtProvider = FutureProvider.autoDispose<DateTime?>((ref) {
  return BackupStorageService.lastBackupAt();
});
```

- [ ] **Step 2: Verify it compiles**

Run: `dart analyze` (from `mobile/`)
Expected: no errors.

---

### Task 12: Restore Data dialog

**Files:**
- Create: `mobile/lib/features/settings/view/restore_backup_dialog.dart`

- [ ] **Step 1: Write the implementation**

```dart
// mobile/lib/features/settings/view/restore_backup_dialog.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/backup/backup_archive_service.dart';
import '../../../core/services/backup/backup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/view/widgets/pin_dots.dart';
import '../../auth/view/widgets/pin_keypad.dart';

class RestoreBackupDialog extends HookConsumerWidget {
  const RestoreBackupDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = useState('');
    final pickedFileName = useState<String?>(null);
    final pickedFilePath = useState<String?>(null);
    final isRestoring = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> pickFile() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      final file = result?.files.single;
      if (file?.path == null) return;
      pickedFileName.value = file!.name;
      pickedFilePath.value = file.path;
    }

    void appendDigit(String digit) {
      if (pin.value.length >= 6) return;
      errorMessage.value = null;
      pin.value += digit;
    }

    void deleteDigit() {
      if (pin.value.isEmpty) return;
      pin.value = pin.value.substring(0, pin.value.length - 1);
      errorMessage.value = null;
    }

    Future<void> confirmAndRestore() async {
      if (pin.value.length != 6) {
        errorMessage.value = 'Enter the 6-digit backup PIN.';
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace All Data?'),
          content: const Text(
            'This will replace all data currently on this device with the '
            'contents of this backup. A safety backup of the current data '
            'will be made first. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Restore'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      isRestoring.value = true;
      errorMessage.value = null;
      try {
        final db = ref.read(databaseProvider);
        await BackupService.restoreBackup(
          db,
          zipFile: File(pickedFilePath.value!),
          password: pin.value,
        );
        if (!context.mounted) return;
        Navigator.of(context).pop();
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Complete'),
            content: const Text(
              'Data has been restored. Close and reopen the app now for the '
              'change to take effect everywhere.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } on BackupArchiveException catch (e) {
        errorMessage.value = e.message;
      } catch (e) {
        errorMessage.value = 'Restore failed: $e';
      } finally {
        isRestoring.value = false;
      }
    }

    return AlertDialog(
      title: const Text('Restore Data'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a backup .zip file and enter the 6-digit Backup PIN '
                'to restore it onto this device.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
              ),
              const Gap(AppSpacing.md),
              OutlinedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: Text(pickedFileName.value ?? 'Choose backup file'),
              ),
              const Gap(AppSpacing.lg),
              Center(child: PinDots(length: pin.value.length)),
              const Gap(AppSpacing.sm),
              if (errorMessage.value != null)
                Center(
                  child: Text(
                    errorMessage.value!,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                  ),
                ),
              const Gap(AppSpacing.md),
              Center(
                child: PinKeypad(
                  onDigit: appendDigit,
                  onDelete: deleteDigit,
                  disabled: isRestoring.value,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isRestoring.value ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (!isRestoring.value &&
                  pickedFilePath.value != null &&
                  pin.value.length == 6)
              ? confirmAndRestore
              : null,
          child: isRestoring.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Restore'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `dart analyze` (from `mobile/`)
Expected: no errors.

---

### Task 13: Backup screen (PIN management + Back Up Now + Restore Data)

**Files:**
- Create: `mobile/lib/features/settings/view/backup_screen.dart`

- [ ] **Step 1: Write the implementation**

```dart
// mobile/lib/features/settings/view/backup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/backup/backup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/view/widgets/pin_dots.dart';
import '../../auth/view/widgets/pin_keypad.dart';
import '../state/backup_providers.dart';
import 'restore_backup_dialog.dart';

class BackupScreen extends HookConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPassword = ref.watch(hasBackupPasswordProvider);
    final lastBackupAt = ref.watch(lastBackupAtProvider);
    final isWorking = useState(false);

    Future<void> setOrChangePassword() async {
      final newPin = await showDialog<String>(
        context: context,
        builder: (context) => const _SetBackupPinDialog(),
      );
      if (newPin == null) return;

      await ref.read(backupPasswordServiceProvider).setPassword(newPin);
      ref.invalidate(hasBackupPasswordProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Backup PIN saved')));
    }

    Future<void> backUpNow() async {
      final password = await ref.read(backupPasswordServiceProvider).getPassword();
      if (password == null) return;

      isWorking.value = true;
      try {
        final db = ref.read(databaseProvider);
        final zip = await BackupService.createBackup(db, password: password);
        ref.invalidate(lastBackupAtProvider);
        await Share.shareXFiles([XFile(zip.path)], text: 'POS data backup');
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      } finally {
        isWorking.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          hasPassword.when(
            data: (isSet) => _PasswordCard(
              isSet: isSet,
              onTap: setOrChangePassword,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Gap(AppSpacing.lg),
          lastBackupAt.when(
            data: (at) => Text(
              at == null
                  ? 'No backup has been made yet.'
                  : 'Last backup: ${DateFormat.yMMMd().add_jm().format(at)}',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Gap(AppSpacing.md),
          _ActionTile(
            icon: Icons.backup_rounded,
            title: 'Back Up Now',
            subtitle: 'Create a backup and share it off this device',
            enabled: !isWorking.value && (hasPassword.value ?? false),
            loading: isWorking.value,
            onTap: backUpNow,
          ),
          const Gap(AppSpacing.sm),
          _ActionTile(
            icon: Icons.restore_rounded,
            title: 'Restore Data',
            subtitle: 'Replace all data on this device from a backup file',
            enabled: hasPassword.value ?? false,
            loading: false,
            onTap: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (context) => const RestoreBackupDialog(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordCard extends StatelessWidget {
  final bool isSet;
  final VoidCallback onTap;
  const _PasswordCard({required this.isSet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Backup PIN', style: AppTextStyles.headingSm),
                const Gap(2),
                Text(
                  isSet
                      ? 'A backup PIN is set. Any admin or supervisor can change it.'
                      : 'Backups are off until a Backup PIN is set.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          FilledButton(onPressed: onTap, child: Text(isSet ? 'Change' : 'Set')),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(title, style: AppTextStyles.headingSm),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}

/// Two-step keypad flow (enter PIN, then confirm it) using the same
/// PinDots/PinKeypad as login/setup-PIN, so entering the shared Backup PIN
/// feels identical to every other PIN entry in the app. Pops with the
/// confirmed 6-digit PIN, or null if cancelled.
class _SetBackupPinDialog extends HookConsumerWidget {
  const _SetBackupPinDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState(0); // 0 = enter PIN, 1 = confirm it
    final pin = useState('');
    final confirmPin = useState('');
    final errorText = useState<String?>(null);

    void reset({String? error}) {
      step.value = 0;
      pin.value = '';
      confirmPin.value = '';
      errorText.value = error;
    }

    void appendDigit(String digit) {
      if (step.value == 0) {
        if (pin.value.length >= 6) return;
        errorText.value = null;
        pin.value += digit;
        if (pin.value.length == 6) step.value = 1;
      } else {
        if (confirmPin.value.length >= 6) return;
        errorText.value = null;
        confirmPin.value += digit;
        if (confirmPin.value.length == 6) {
          if (confirmPin.value != pin.value) {
            reset(error: 'PINs do not match');
            return;
          }
          Navigator.of(context).pop(confirmPin.value);
        }
      }
    }

    void deleteDigit() {
      if (step.value == 0) {
        if (pin.value.isEmpty) return;
        pin.value = pin.value.substring(0, pin.value.length - 1);
      } else {
        if (confirmPin.value.isEmpty) return;
        confirmPin.value = confirmPin.value.substring(0, confirmPin.value.length - 1);
      }
      errorText.value = null;
    }

    final isConfirmStep = step.value == 1;

    return AlertDialog(
      title: Text(isConfirmStep ? 'Confirm Backup PIN' : 'Set Backup PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isConfirmStep
                ? 'Re-enter the 6-digit PIN to confirm.'
                : 'Choose a 6-digit PIN. Any admin or supervisor can use it '
                    'to back up or restore data.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          const Gap(AppSpacing.lg),
          PinDots(length: isConfirmStep ? confirmPin.value.length : pin.value.length),
          const Gap(AppSpacing.sm),
          if (errorText.value != null)
            Text(
              errorText.value!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          const Gap(AppSpacing.lg),
          PinKeypad(onDigit: appendDigit, onDelete: deleteDigit),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Wire it into Settings — add the tile**

Modify `mobile/lib/features/settings/view/settings_screen.dart`: add the import and a new tile right after the existing "Import CSV" tile (still inside the `if (isAdmin) ...[` block):

```dart
              _SettingsTile(
                icon: Icons.upload_file_rounded,
                title: 'Import CSV',
                subtitle:
                    'Import products, modifiers, users, or store info from CSV files',
                onTap: () => context.push('/settings/csv-import'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsTile(
                icon: Icons.backup_rounded,
                title: 'Backup & Restore',
                subtitle: 'Back up device data or restore from a backup file',
                onTap: () => context.push('/settings/backup'),
              ),
```

- [ ] **Step 3: Wire it into the router**

Modify `mobile/lib/core/navigation/router.dart`:

Add the import near the other settings view imports:

```dart
import '../../features/settings/view/backup_screen.dart';
```

Add the route under `/settings`, alongside `csv-import`/`store-info`/`printer`:

```dart
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'csv-import',
            builder: (context, state) => const CsvImportScreen(),
          ),
          GoRoute(
            path: 'backup',
            builder: (context, state) => const BackupScreen(),
          ),
          GoRoute(
            path: 'store-info',
            builder: (context, state) => const StoreInfoScreen(),
          ),
          GoRoute(
            path: 'printer',
            builder: (context, state) => const PrinterSetupScreen(),
          ),
        ],
      ),
```

Add `/settings/backup` to the cashier-restricted prefixes list (same admin/supervisor gate as CSV import and store info):

```dart
      const cashierRestrictedPrefixes = [
        '/inventory',
        '/users',
        '/settings/csv-import',
        '/settings/backup',
        '/settings/store-info',
      ];
```

- [ ] **Step 4: Verify it compiles**

Run: `dart analyze` (from `mobile/`)
Expected: no errors.

---

### Task 14: Full test suite pass + manual on-device verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full test suite**

Run: `flutter test` (from `mobile/`)
Expected: all tests pass, including the new `test/core/services/backup/*` files.

- [ ] **Step 2: Run analyzer on the whole project**

Run: `dart analyze` (from `mobile/`)
Expected: no errors.

- [ ] **Step 3: Manual verification checklist (physical or emulated Android device)**

Per the spec's Testing section — these can't be automated, so work through them by hand:

1. Launch the app, log in as an admin/supervisor, go to Settings → Backup & Restore. Confirm it shows "Backups are off until a Backup PIN is set."
2. Set a 6-digit Backup PIN via the keypad (enter, then confirm). Confirm the card updates and "Back Up Now" / "Restore Data" tiles become enabled. Confirm entering mismatched PINs on the confirm step shows "PINs do not match" and resets to the first step.
3. Tap "Back Up Now". Confirm a zip appears in the device's `Downloads/POS Backups/` folder (check via a file manager app) and the OS share sheet opens.
4. Confirm the WorkManager job is registered: `adb shell dumpsys jobscheduler | grep -i hourly_pos_backup` (or use WorkManager's own inspection tooling) shows a scheduled job with a ~1 hour period.
5. Restore flow: tap "Restore Data", pick the zip from step 3, enter the correct PIN via the keypad, confirm the warning dialog, confirm restore succeeds and shows the "close and reopen" dialog. Reopen the app and confirm products/sales/images are intact.
6. Restore with the wrong PIN: confirm it shows "Incorrect password or corrupted backup file." and does **not** touch existing data.
7. Confirm retention: create backups spanning more than 7 days apart (or temporarily lower `BackupStorageService.retentionWindow` for this test only, then revert it), confirm only backups within the window remain in `Downloads/POS Backups/`.
8. Uninstall and reinstall the app. Confirm the backup zip is still present in `Downloads/POS Backups/` (proves it survived the uninstall).
