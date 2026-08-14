import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/services/history/history_archive_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('history_archive_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('writes bytes under History/<year>/<month>/<fileName>', () async {
    final service = HistoryArchiveService(baseDir: tempDir);
    final at = DateTime(2026, 3, 7);

    final file = await service.save(fileName: 'receipt_SO-001.pdf', bytes: [1, 2, 3], at: at);

    final expectedPath = '${tempDir.path}${Platform.pathSeparator}History'
        '${Platform.pathSeparator}2026${Platform.pathSeparator}03'
        '${Platform.pathSeparator}receipt_SO-001.pdf';
    expect(file.path, expectedPath);
    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), [1, 2, 3]);
  });

  test('creates the nested month directory when it does not exist yet', () async {
    final service = HistoryArchiveService(baseDir: tempDir);

    await service.save(fileName: 'zreading_1.pdf', bytes: [9], at: DateTime(2026, 12, 25));

    final monthDir = Directory('${tempDir.path}${Platform.pathSeparator}History'
        '${Platform.pathSeparator}2026${Platform.pathSeparator}12');
    expect(await monthDir.exists(), isTrue);
  });

  test('defaults to now when no date is given', () async {
    final service = HistoryArchiveService(baseDir: tempDir);
    final before = DateTime.now();

    final file = await service.save(fileName: 'xreading_1.pdf', bytes: [1]);

    final yearDir = Directory('${tempDir.path}${Platform.pathSeparator}History'
        '${Platform.pathSeparator}${before.year}');
    expect(await yearDir.exists(), isTrue);
    expect(await file.exists(), isTrue);
  });
}
