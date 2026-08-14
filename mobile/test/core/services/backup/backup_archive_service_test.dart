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

  test('buildArchive then extractArchive round-trips data and images', () async {
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
      outputFile: outputFile,
    );

    expect(await outputFile.exists(), isTrue);

    final extractDir = Directory('${tempDir.path}/extracted')..createSync();
    final extracted = await BackupArchiveService.extractArchive(
      zipFile: outputFile,
      extractImagesTo: extractDir,
    );

    expect(extracted.data['products']![0]['name'], 'Latte');
    expect(extracted.imageFiles, hasLength(1));
    expect(await extracted.imageFiles.first.readAsString(), 'fake-image-bytes');
  });

  test('extractArchive throws BackupArchiveException for a corrupted file', () async {
    final outputFile = File('${tempDir.path}/backup.zip');
    await outputFile.writeAsBytes([1, 2, 3, 4]);

    final extractDir = Directory('${tempDir.path}/extracted')..createSync();

    expect(
      () => BackupArchiveService.extractArchive(
        zipFile: outputFile,
        extractImagesTo: extractDir,
      ),
      throwsA(isA<BackupArchiveException>()),
    );
  });
}
